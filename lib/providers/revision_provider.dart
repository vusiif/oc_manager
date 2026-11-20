import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database/app_database.dart';
import '../core/history/models/character_snapshot.dart';
import '../core/history/diff/character_revision_diff.dart';
import '../core/history/models/lore_snapshot.dart';
import '../core/history/diff/lore_revision_diff.dart';
import '../core/history/models/event_snapshot.dart';
import 'database_provider.dart';
import 'character_provider.dart';
import 'lore_provider.dart';
import 'timeline_provider.dart';

final revisionsProvider =
    FutureProvider.family<
      List<EntityRevision>,
      ({String entityType, int entityId})
    >((ref, arg) {
      return ref
          .watch(revisionDaoProvider)
          .getRevisions(arg.entityType, arg.entityId);
    });

final revisionActionsProvider = Provider((ref) => RevisionActions(ref));

class RevisionActions {
  final Ref _ref;

  RevisionActions(this._ref);

  /// 记录一条新快照（内容一致时幂等跳过）
  Future<int?> recordRevision({
    required int worldId,
    required String entityType,
    required int entityId,
    required String content,
    String? title,
    int maxRetain = 30,
  }) async {
    final dao = _ref.read(revisionDaoProvider);
    final id = await dao.recordRevision(
      worldId: worldId,
      entityType: entityType,
      entityId: entityId,
      content: content,
      title: title,
      maxRetain: maxRetain,
    );
    if (id != null) {
      _ref.invalidate(
        revisionsProvider((entityType: entityType, entityId: entityId)),
      );
    }
    return id;
  }

  /// 构建当前人物的完整设定快照 (HISTORY-001)
  Future<CharacterSnapshot> buildCurrentCharacterSnapshot(
    Character character, {
    String source = 'manual',
    bool isMilestone = false,
    String? note,
  }) async {
    final db = _ref.read(databaseProvider);
    final fields = await db.characterDao.getCharacterFields(character.id);
    final customFields = {for (final f in fields) f.fieldName: f.value ?? ''};
    final tags = await db.tagDao.getTagsByCharacter(character.id);
    final tagNames = tags.map((t) => t.name).toList();

    return CharacterSnapshot(
      schemaVersion: 1,
      source: source,
      isMilestone: isMilestone,
      note: note,
      name: character.name,
      gender: character.gender,
      avatarPath: character.avatarPath,
      description: character.description,
      customFields: customFields,
      tags: tagNames,
      timestamp: DateTime.now(),
    );
  }

  /// 记录一条人设全量结构化快照 (HISTORY-001)
  Future<int?> recordCharacterSnapshot({
    required Character character,
    String? title,
    String source = 'manual',
    bool isMilestone = false,
    String? note,
    int maxRetain = 30,
  }) async {
    final snapshot = await buildCurrentCharacterSnapshot(
      character,
      source: source,
      isMilestone: isMilestone,
      note: note,
    );
    final content = snapshot.toJsonString();
    return recordRevision(
      worldId: character.worldId,
      entityType: 'character',
      entityId: character.id,
      content: content,
      title: title,
      maxRetain: maxRetain,
    );
  }

  /// 切换快照里程碑保护标记 (HISTORY-001)
  Future<bool> toggleMilestone({
    required int revisionId,
    required bool isMilestone,
    required String entityType,
    required int entityId,
  }) async {
    final success = await _ref
        .read(revisionDaoProvider)
        .toggleMilestone(revisionId, isMilestone);
    if (success) {
      _ref.invalidate(
        revisionsProvider((entityType: entityType, entityId: entityId)),
      );
    }
    return success;
  }

  /// 选择性安全恢复人物设定 (HISTORY-003)
  Future<bool> restoreCharacterSelective({
    required int revisionId,
    required Character currentCharacter,
    required SelectiveRestoreOptions options,
  }) async {
    final dao = _ref.read(revisionDaoProvider);
    final targetRev = await dao.getRevisionById(revisionId);
    if (targetRev == null) return false;

    final targetSnapshot = CharacterSnapshot.parse(
      targetRev.content,
      defaultName: currentCharacter.name,
      defaultTimestamp: targetRev.createdAt,
    );

    // 1. 回滚前强制自动为当前完整状态创建安全备份快照
    await recordCharacterSnapshot(
      character: currentCharacter,
      title: '回滚前自动归档',
      source: 'restore_backup',
      note: '在恢复至快照 “${targetRev.title}” 前自动保存',
    );

    final db = _ref.read(databaseProvider);

    // 2. 根据选项分步选择性还原
    var updatedChar = currentCharacter;

    // 2.1 还原基本信息 (姓名、性别、立绘等)
    if (options.restoreBasicInfo) {
      updatedChar = updatedChar.copyWith(
        name: targetSnapshot.name.isNotEmpty
            ? targetSnapshot.name
            : updatedChar.name,
        gender: targetSnapshot.gender ?? updatedChar.gender,
        avatarPath: drift.Value(targetSnapshot.avatarPath),
      );
    }

    // 2.2 还原人设小传长文本
    if (options.restoreDescription) {
      updatedChar = updatedChar.copyWith(
        description: targetSnapshot.description,
      );
    }

    // 写入人物表更新
    if (options.restoreBasicInfo || options.restoreDescription) {
      await _ref.read(characterActionsProvider).update(updatedChar);
    }

    // 2.3 还原自定义字段
    if (options.restoreCustomFields && targetSnapshot.schemaVersion > 0) {
      await db.transaction(() async {
        await db.characterDao.deleteAllCharacterFields(currentCharacter.id);
        for (final entry in targetSnapshot.customFields.entries) {
          await db.characterDao.createCharacterField(
            CharacterFieldsCompanion.insert(
              characterId: currentCharacter.id,
              fieldName: entry.key,
              fieldType: 'text',
              value: drift.Value(entry.value),
            ),
          );
        }
      });
    }

    // 2.4 还原标签体系
    if (options.restoreTags && targetSnapshot.schemaVersion > 0) {
      await db.transaction(() async {
        final currentTags = await db.tagDao.getTagsByCharacter(
          currentCharacter.id,
        );
        for (final t in currentTags) {
          await db.tagDao.removeTagFromCharacter(currentCharacter.id, t.id);
        }

        final allTags = await db.tagDao.getAllTags();
        final tagMap = {for (final t in allTags) t.name: t.id};

        for (final tagName in targetSnapshot.tags) {
          if (tagName.trim().isEmpty) continue;
          int? tagId = tagMap[tagName];
          tagId ??= await db.tagDao.createTag(
            TagsCompanion.insert(name: tagName, color: '#3B82F6'),
          );
          await db.tagDao.addTagToCharacter(currentCharacter.id, tagId);
        }
      });
    }

    // 3. 刷新相关 Providers
    _ref.invalidate(characterByIdProvider(currentCharacter.id));
    _ref.invalidate(charactersByWorldProvider(currentCharacter.worldId));
    _ref.invalidate(characterFieldsProvider(currentCharacter.id));
    _ref.invalidate(
      revisionsProvider((
        entityType: 'character',
        entityId: currentCharacter.id,
      )),
    );

    return true;
  }

  /// 恢复角色人设小传版本（恢复前自动安全归档当前小传）
  Future<bool> restoreCharacterDescription({
    required int revisionId,
    required Character character,
  }) async {
    final dao = _ref.read(revisionDaoProvider);
    final targetRev = await dao.getRevisionById(revisionId);
    if (targetRev == null) return false;

    // 1. 先备份当前现有版本
    if (character.description.trim().isNotEmpty) {
      await recordRevision(
        worldId: character.worldId,
        entityType: 'character',
        entityId: character.id,
        content: character.description,
        title: '回滚前自动归档',
      );
    }

    // 2. 写入恢复目标版本
    await _ref
        .read(characterActionsProvider)
        .update(character.copyWith(description: targetRev.content));
    _ref.invalidate(characterByIdProvider(character.id));
    _ref.invalidate(charactersByWorldProvider(character.worldId));
    _ref.invalidate(
      revisionsProvider((entityType: 'character', entityId: character.id)),
    );
    return true;
  }

  /// 构建当前百科实体的完整设定快照 (HISTORY-004)
  LoreSnapshot buildCurrentLoreSnapshot(
    LoreEntity lore, {
    String source = 'manual',
    bool isMilestone = false,
    String? note,
  }) {
    return LoreSnapshot.fromEntity(
      lore,
      source: source,
      isMilestone: isMilestone,
      note: note,
    );
  }

  /// 记录一条百科实体全量结构化快照 (HISTORY-004)
  Future<int?> recordLoreSnapshot({
    required LoreEntity lore,
    String? title,
    String source = 'manual',
    bool isMilestone = false,
    String? note,
    int maxRetain = 30,
  }) async {
    final snapshot = buildCurrentLoreSnapshot(
      lore,
      source: source,
      isMilestone: isMilestone,
      note: note,
    );
    final content = snapshot.toJsonString();
    return recordRevision(
      worldId: lore.worldId,
      entityType: 'lore',
      entityId: lore.id,
      content: content,
      title: title,
      maxRetain: maxRetain,
    );
  }

  /// 选择性安全恢复百科实体设定 (HISTORY-004)
  Future<bool> restoreLoreSelective({
    required int revisionId,
    required LoreEntity currentLore,
    required LoreSelectiveRestoreOptions options,
  }) async {
    final dao = _ref.read(revisionDaoProvider);
    final targetRev = await dao.getRevisionById(revisionId);
    if (targetRev == null) return false;

    final targetSnapshot = LoreSnapshot.parse(
      targetRev.content,
      defaultName: currentLore.name,
      defaultType: currentLore.entityType,
      defaultTimestamp: targetRev.createdAt,
    );

    // 1. 回滚前强制自动为当前完整状态创建安全备份快照
    await recordLoreSnapshot(
      lore: currentLore,
      title: '回滚前自动归档',
      source: 'restore_backup',
      note: '在恢复至快照 “${targetRev.title}” 前自动保存',
    );

    // 2. 根据选项分步选择性还原
    String restoredName = currentLore.name;
    String restoredType = currentLore.entityType;
    String? restoredCover = currentLore.coverImagePath;
    int? restoredParentId = currentLore.parentId;
    String restoredSummary = currentLore.summary;
    String restoredContent = currentLore.content;
    String restoredCustomFields = currentLore.customFields;
    String restoredTags = currentLore.tags;

    if (options.restoreBasicInfo && targetSnapshot.schemaVersion > 0) {
      if (targetSnapshot.name.trim().isNotEmpty) {
        restoredName = targetSnapshot.name.trim();
      }
      restoredType = targetSnapshot.entityType;
      restoredCover = targetSnapshot.coverImagePath;
      restoredParentId = targetSnapshot.parentId;
    }

    if (options.restoreSummary && targetSnapshot.schemaVersion > 0) {
      restoredSummary = targetSnapshot.summary;
    }

    if (options.restoreContent) {
      restoredContent = targetSnapshot.content;
    }

    if (options.restoreCustomFields && targetSnapshot.schemaVersion > 0) {
      restoredCustomFields = jsonEncode(targetSnapshot.customFields);
    }

    if (options.restoreTags && targetSnapshot.schemaVersion > 0) {
      restoredTags = jsonEncode(targetSnapshot.tags);
    }

    // 写入数据库更新
    await _ref
        .read(loreActionsProvider)
        .updateEntity(
          id: currentLore.id,
          worldId: currentLore.worldId,
          parentId: restoredParentId,
          entityType: restoredType,
          name: restoredName,
          summary: restoredSummary,
          content: restoredContent,
          coverImagePath: restoredCover,
          tags: restoredTags,
          customFields: restoredCustomFields,
        );

    _ref.invalidate(loreEntitiesByWorldProvider(currentLore.worldId));
    _ref.invalidate(
      revisionsProvider((entityType: 'lore', entityId: currentLore.id)),
    );
    return true;
  }

  /// 恢复世界观百科实体正文版本（恢复前自动安全归档当前正文）
  Future<bool> restoreLoreContent({
    required int revisionId,
    required LoreEntity lore,
  }) async {
    return restoreLoreSelective(
      revisionId: revisionId,
      currentLore: lore,
      options: const LoreSelectiveRestoreOptions(),
    );
  }

  /// 构建当前编年事件的完整快照 (HISTORY-004)
  EventSnapshot buildCurrentEventSnapshot(
    TimelineEvent event, {
    String source = 'manual',
    bool isMilestone = false,
    String? note,
  }) {
    return EventSnapshot.fromEntity(
      event,
      source: source,
      isMilestone: isMilestone,
      note: note,
    );
  }

  /// 记录一条编年事件全量快照 (HISTORY-004)
  Future<int?> recordEventSnapshot({
    required TimelineEvent event,
    String? title,
    String source = 'manual',
    bool isMilestone = false,
    String? note,
    int maxRetain = 30,
  }) async {
    final snapshot = buildCurrentEventSnapshot(
      event,
      source: source,
      isMilestone: isMilestone,
      note: note,
    );
    final content = snapshot.toJsonString();
    return recordRevision(
      worldId: event.worldId,
      entityType: 'event',
      entityId: event.id,
      content: content,
      title: title,
      maxRetain: maxRetain,
    );
  }

  /// 安全恢复编年史事件 (HISTORY-004)
  Future<bool> restoreEvent({
    required int revisionId,
    required TimelineEvent currentEvent,
  }) async {
    final dao = _ref.read(revisionDaoProvider);
    final targetRev = await dao.getRevisionById(revisionId);
    if (targetRev == null) return false;

    final targetSnapshot = EventSnapshot.parse(
      targetRev.content,
      defaultTitle: currentEvent.title,
      defaultTimestamp: targetRev.createdAt,
    );

    // 1. 回滚前备份
    await recordEventSnapshot(
      event: currentEvent,
      title: '回滚前自动归档',
      source: 'restore_backup',
      note: '在恢复至快照 “${targetRev.title}” 前自动保存',
    );

    // 2. 写入还原
    await _ref
        .read(timelineActionsProvider)
        .updateEvent(
          id: currentEvent.id,
          worldId: currentEvent.worldId,
          characterId: currentEvent.characterId,
          year: targetSnapshot.year.isNotEmpty
              ? targetSnapshot.year
              : currentEvent.year,
          sortOrder: currentEvent.sortOrder,
          title: targetSnapshot.title.isNotEmpty
              ? targetSnapshot.title
              : currentEvent.title,
          description: targetSnapshot.description,
          category: targetSnapshot.category,
          importance: targetSnapshot.importance,
        );

    _ref.invalidate(worldTimelineEventsProvider(currentEvent.worldId));
    if (currentEvent.characterId != null) {
      _ref.invalidate(
        characterTimelineEventsProvider(currentEvent.characterId!),
      );
    }
    _ref.invalidate(
      revisionsProvider((entityType: 'event', entityId: currentEvent.id)),
    );
    return true;
  }

  Future<void> deleteRevision(
    int revisionId, {
    required String entityType,
    required int entityId,
  }) async {
    await _ref.read(revisionDaoProvider).deleteRevision(revisionId);
    _ref.invalidate(
      revisionsProvider((entityType: entityType, entityId: entityId)),
    );
  }
}
