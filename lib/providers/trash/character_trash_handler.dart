import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

/// Handler for cascading soft-deletion and safe restoration of Characters in the trash bin.
class CharacterTrashHandler {
  final AppDatabase db;
  final void Function(int worldId) onInvalidate;

  CharacterTrashHandler({required this.db, required this.onInvalidate});

  /// 软删除人物：完整快照（包含字段、标签、分组与关系图坐标）后事务删除
  Future<void> deleteCharacter(Character character) async {
    final fields = await db.characterDao.getCharacterFields(character.id);
    final stats = await db.characterDao.getCharacterStats(character.id);
    final galleries = await db.characterDao.getCharacterGalleries(character.id);
    final timelineEvents = await db.timelineDao.getEventsByCharacter(
      character.id,
    );
    final groupIds = await db.groupDao.getGroupIdsByCharacter(character.id);

    final tagRows = await (db.select(
      db.characterTags,
    )..where((t) => t.characterId.equals(character.id))).get();
    final tagIds = tagRows.map((r) => r.tagId).toList();

    final relations =
        await (db.select(db.relations)..where(
              (r) =>
                  r.fromCharacterId.equals(character.id) |
                  r.toCharacterId.equals(character.id),
            ))
            .get();

    final layoutRow =
        await (db.select(db.graphLayouts)
              ..where((l) => l.characterId.equals(character.id))
              ..orderBy([(l) => OrderingTerm.desc(l.id)])
              ..limit(1))
            .getSingleOrNull();

    final charRevisions =
        await (db.select(db.entityRevisions)..where(
              (r) =>
                  r.entityType.equals('character') &
                  r.entityId.equals(character.id),
            ))
            .get();

    final povScenes = await (db.select(
      db.storyScenes,
    )..where((s) => s.povCharacterId.equals(character.id))).get();
    final povSceneIds = povScenes.map((s) => s.id).toList();

    final fullData = {
      'character': {
        'id': character.id,
        'worldId': character.worldId,
        'name': character.name,
        'avatarPath': character.avatarPath,
        'gender': character.gender,
        'description': character.description,
        'status': character.status,
        'isFavorite': character.isFavorite,
        'isPinned': character.isPinned,
        'createdAt': character.createdAt.toIso8601String(),
        'updatedAt': character.updatedAt.toIso8601String(),
      },
      'fields': [
        for (final f in fields)
          {
            'fieldName': f.fieldName,
            'fieldType': f.fieldType,
            'value': f.value,
          },
      ],
      'stats': [
        for (final s in stats)
          {
            'label': s.label,
            'value': s.value,
            'maxValue': s.maxValue,
            'sortOrder': s.sortOrder,
          },
      ],
      'galleries': [
        for (final g in galleries)
          {
            'imagePath': g.imagePath,
            'caption': g.caption,
            'isPrimary': g.isPrimary,
            'sortOrder': g.sortOrder,
            'createdAt': g.createdAt.toIso8601String(),
          },
      ],
      'timelineEvents': [
        for (final t in timelineEvents)
          {
            'worldId': t.worldId,
            'characterId': t.characterId,
            'year': t.year,
            'sortOrder': t.sortOrder,
            'title': t.title,
            'description': t.description,
            'category': t.category,
            'importance': t.importance,
            'createdAt': t.createdAt.toIso8601String(),
          },
      ],
      'relations': [
        for (final r in relations)
          {
            'id': r.id,
            'fromCharacterId': r.fromCharacterId,
            'toCharacterId': r.toCharacterId,
            'relationType': r.relationType,
            'isBidirectional': r.isBidirectional,
            'note': r.note,
            'relationGroupId': r.relationGroupId,
          },
      ],
      'tagIds': tagIds,
      'groupIds': groupIds,
      'layout': layoutRow != null
          ? {'worldId': layoutRow.worldId, 'x': layoutRow.x, 'y': layoutRow.y}
          : null,
      'revisions': [
        for (final rev in charRevisions)
          {
            'id': rev.id,
            'worldId': rev.worldId,
            'entityType': rev.entityType,
            'entityId': rev.entityId,
            'title': rev.title,
            'content': rev.content,
            'charCount': rev.charCount,
            'createdAt': rev.createdAt.toIso8601String(),
          },
      ],
      'povSceneIds': povSceneIds,
    };

    await db.transaction(() async {
      // 1. 写入回收站
      await db.trashDao.addToTrash(
        TrashCompanion(
          itemType: const Value('character'),
          itemId: Value(character.id),
          itemData: Value(jsonEncode(fullData)),
        ),
      );

      // 2. 清除相关子表与关联
      await (db.delete(
        db.characterFields,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (db.delete(
        db.characterStats,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (db.delete(
        db.characterGalleries,
      )..where((t) => t.characterId.equals(character.id))).go();
      await db.timelineDao.deleteAllEventsByCharacter(character.id);
      await (db.delete(
        db.characterTags,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (db.delete(
        db.characterGroups,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (db.delete(
        db.graphLayouts,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (db.delete(db.relations)..where(
            (r) =>
                r.fromCharacterId.equals(character.id) |
                r.toCharacterId.equals(character.id),
          ))
          .go();
      await (db.delete(
        db.loreRelations,
      )..where((r) => r.characterId.equals(character.id))).go();
      await db.revisionDao.deleteRevisions('character', character.id);

      // 解除故事场景 POV 视点外键引用，防止硬约束崩溃
      if (povSceneIds.isNotEmpty) {
        await (db.update(db.storyScenes)
              ..where((s) => s.povCharacterId.equals(character.id)))
            .write(const StoryScenesCompanion(povCharacterId: Value(null)));
      }

      // 3. 删除主角色
      await db.characterDao.deleteCharacter(character.id);
    });

    onInvalidate(character.worldId);
  }

  /// 恢复人物（事务原子还原角色及字段、标签、分组映射与布局）
  Future<void> restoreCharacter(TrashData trashItem) async {
    final parsed = jsonDecode(trashItem.itemData) as Map<String, dynamic>;

    // 兼容新老快照格式
    final Map<String, dynamic> charData = parsed.containsKey('character')
        ? parsed['character'] as Map<String, dynamic>
        : parsed;

    final fieldsData = (parsed['fields'] as List<dynamic>?) ?? [];
    final statsData = (parsed['stats'] as List<dynamic>?) ?? [];
    final galleryData = (parsed['galleries'] as List<dynamic>?) ?? [];
    final timelineData = (parsed['timelineEvents'] as List<dynamic>?) ?? [];
    final tagIds = (parsed['tagIds'] as List<dynamic>?) ?? [];
    final groupIds = (parsed['groupIds'] as List<dynamic>?) ?? [];
    final relationsData = (parsed['relations'] as List<dynamic>?) ?? [];
    final layoutData = parsed['layout'] as Map<String, dynamic>?;

    final charId = charData['id'] as int;
    final worldId = charData['worldId'] as int;

    // 校验世界观存在性，若已被物理删除则自动降级归属，防止外键约束崩溃
    int effectiveWorldId = worldId;
    final worldExists = await (db.select(
      db.worlds,
    )..where((w) => w.id.equals(worldId))).getSingleOrNull();
    if (worldExists == null) {
      final availableWorlds = await db.select(db.worlds).get();
      if (availableWorlds.isNotEmpty) {
        effectiveWorldId = availableWorlds.first.id;
      } else {
        effectiveWorldId = await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(
                name: '恢复人物收纳世界',
                description: const Value('自动创建用于收纳已失去归属世界观的人物'),
              ),
            );
      }
    }

    await db.transaction(() async {
      // 1. 还原人物主表
      await db
          .into(db.characters)
          .insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              worldId: Value(effectiveWorldId),
              name: Value(charData['name'] as String),
              avatarPath: Value(charData['avatarPath'] as String?),
              gender: Value(charData['gender'] as String? ?? ''),
              description: Value(charData['description'] as String? ?? ''),
              status: Value(charData['status'] as int? ?? 0),
              isFavorite: Value(charData['isFavorite'] as bool? ?? false),
              isPinned: Value(charData['isPinned'] as bool? ?? false),
              createdAt: Value(DateTime.parse(charData['createdAt'] as String)),
              updatedAt: Value(
                charData['updatedAt'] != null
                    ? DateTime.parse(charData['updatedAt'] as String)
                    : DateTime.now(),
              ),
            ),
          );

      // 2. 还原自定义字段
      for (final f in fieldsData) {
        final fieldMap = f as Map<String, dynamic>;
        await db
            .into(db.characterFields)
            .insert(
              CharacterFieldsCompanion.insert(
                characterId: charId,
                fieldName: fieldMap['fieldName'] as String,
                fieldType: fieldMap['fieldType'] as String,
                value: Value(fieldMap['value'] as String?),
              ),
            );
      }

      // 2.1 还原属性数值
      for (final s in statsData) {
        final statMap = s as Map<String, dynamic>;
        await db
            .into(db.characterStats)
            .insert(
              CharacterStatsCompanion.insert(
                characterId: charId,
                label: statMap['label'] as String,
                value: Value((statMap['value'] as num).toDouble()),
                maxValue: Value(
                  (statMap['maxValue'] as num?)?.toDouble() ?? 100.0,
                ),
                sortOrder: Value(statMap['sortOrder'] as int? ?? 0),
              ),
            );
      }

      // 2.2 还原画廊立绘
      for (final g in galleryData) {
        final gm = g as Map<String, dynamic>;
        await db
            .into(db.characterGalleries)
            .insert(
              CharacterGalleriesCompanion.insert(
                characterId: charId,
                imagePath: gm['imagePath'] as String,
                caption: Value(gm['caption'] as String? ?? ''),
                isPrimary: Value(gm['isPrimary'] as bool? ?? false),
                sortOrder: Value(gm['sortOrder'] as int? ?? 0),
                createdAt: Value(
                  gm['createdAt'] != null
                      ? DateTime.parse(gm['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      // 2.3 还原个人生平时间线
      for (final t in timelineData) {
        final tm = t as Map<String, dynamic>;
        await db
            .into(db.timelineEvents)
            .insert(
              TimelineEventsCompanion.insert(
                worldId: effectiveWorldId,
                characterId: Value(charId),
                year: tm['year'] as String,
                sortOrder: Value((tm['sortOrder'] as num?)?.toDouble() ?? 0.0),
                title: tm['title'] as String,
                description: Value(tm['description'] as String? ?? ''),
                category: Value(tm['category'] as String? ?? 'general'),
                importance: Value(tm['importance'] as int? ?? 1),
                createdAt: Value(
                  tm['createdAt'] != null
                      ? DateTime.parse(tm['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      // 3. 还原标签（确保标签库仍有该 tagId）
      for (final tid in tagIds) {
        final tagId = tid as int;
        final tagExists = await (db.select(
          db.tags,
        )..where((t) => t.id.equals(tagId))).getSingleOrNull();
        if (tagExists != null) {
          await db
              .into(db.characterTags)
              .insertOnConflictUpdate(
                CharacterTagsCompanion(
                  characterId: Value(charId),
                  tagId: Value(tagId),
                ),
              );
        }
      }

      // 4. 还原分组关联（确保分组仍存在）
      for (final gid in groupIds) {
        final groupId = gid as int;
        final groupExists = await (db.select(
          db.groups,
        )..where((g) => g.id.equals(groupId))).getSingleOrNull();
        if (groupExists != null) {
          await db
              .into(db.characterGroups)
              .insertOnConflictUpdate(
                CharacterGroupsCompanion(
                  characterId: Value(charId),
                  groupId: Value(groupId),
                ),
              );
        }
      }

      // 5. 还原画布坐标
      if (layoutData != null) {
        await db
            .into(db.graphLayouts)
            .insertOnConflictUpdate(
              GraphLayoutsCompanion(
                characterId: Value(charId),
                worldId: Value(effectiveWorldId),
                x: Value((layoutData['x'] as num).toDouble()),
                y: Value((layoutData['y'] as num).toDouble()),
              ),
            );
      }

      // 6. 还原人际纽带（对端角色在数据库中且同世界观时自愈恢复，防止孤儿关系与外键崩溃）
      for (final r in relationsData) {
        final rMap = r as Map<String, dynamic>;
        final fromId = rMap['fromCharacterId'] as int;
        final toId = rMap['toCharacterId'] as int;
        final otherId = (fromId == charId) ? toId : fromId;

        final otherChar = await (db.select(
          db.characters,
        )..where((c) => c.id.equals(otherId))).getSingleOrNull();

        if (otherChar != null && otherChar.worldId == effectiveWorldId) {
          final relType = rMap['relationType'] as String? ?? '关联';
          final existingRel =
              await (db.select(db.relations)..where(
                    (rel) =>
                        rel.fromCharacterId.equals(fromId) &
                        rel.toCharacterId.equals(toId) &
                        rel.relationType.equals(relType),
                  ))
                  .getSingleOrNull();

          if (existingRel == null) {
            await db
                .into(db.relations)
                .insert(
                  RelationsCompanion.insert(
                    fromCharacterId: fromId,
                    toCharacterId: toId,
                    relationType: relType,
                    isBidirectional: Value(
                      rMap['isBidirectional'] as bool? ?? true,
                    ),
                    note: Value(rMap['note'] as String?),
                    relationGroupId: Value(rMap['relationGroupId'] as String?),
                  ),
                );
          }
        }
      }

      // 6.1 还原设定版本历史快照
      final revisionsData = (parsed['revisions'] as List<dynamic>?) ?? [];
      for (final rev in revisionsData) {
        final rm = rev as Map<String, dynamic>;
        await db
            .into(db.entityRevisions)
            .insertOnConflictUpdate(
              EntityRevisionsCompanion(
                id: Value(rm['id'] as int),
                worldId: Value(effectiveWorldId),
                entityType: Value('character'),
                entityId: Value(charId),
                title: Value(rm['title'] as String? ?? ''),
                content: Value(rm['content'] as String),
                charCount: Value(rm['charCount'] as int? ?? 0),
                createdAt: Value(DateTime.parse(rm['createdAt'] as String)),
              ),
            );
      }

      // 6.2 还原故事场景 POV 视点关联
      final povSceneIds =
          (parsed['povSceneIds'] as List<dynamic>?)?.cast<int>() ?? [];
      for (final sId in povSceneIds) {
        await (db.update(db.storyScenes)..where((s) => s.id.equals(sId))).write(
          StoryScenesCompanion(povCharacterId: Value(charId)),
        );
      }

      // 7. 移除回收站记录
      await db.trashDao.removeFromTrash(trashItem.id);
    });

    onInvalidate(effectiveWorldId);
  }
}
