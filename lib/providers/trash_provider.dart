import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'character_provider.dart';
import 'database_provider.dart';
import 'group_provider.dart';
import 'relation_provider.dart';
import 'world_provider.dart';
import 'timeline_provider.dart';
import 'lore_provider.dart';

final trashListProvider = FutureProvider<List<TrashData>>((ref) {
  ref.watch(trashRefreshProvider);
  return ref.watch(trashDaoProvider).getAllTrash();
});

/// 用于触发回收站刷新
final trashRefreshProvider = StateProvider<int>((ref) => 0);

final trashActionsProvider = Provider((ref) => TrashActions(ref));

class TrashActions {
  final Ref _ref;

  TrashActions(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);

  /// 软删除人物：完整快照（包含字段、标签、分组与关系图坐标）后事务删除
  Future<void> deleteCharacter(Character character) async {
    final fields = await _db.characterDao.getCharacterFields(character.id);
    final stats = await _db.characterDao.getCharacterStats(character.id);
    final galleries = await _db.characterDao.getCharacterGalleries(
      character.id,
    );
    final timelineEvents = await _db.timelineDao.getEventsByCharacter(
      character.id,
    );
    final groupIds = await _db.groupDao.getGroupIdsByCharacter(character.id);

    final tagRows = await (_db.select(
      _db.characterTags,
    )..where((t) => t.characterId.equals(character.id))).get();
    final tagIds = tagRows.map((r) => r.tagId).toList();

    final relations =
        await (_db.select(_db.relations)..where(
              (r) =>
                  r.fromCharacterId.equals(character.id) |
                  r.toCharacterId.equals(character.id),
            ))
            .get();

    final layoutRow =
        await (_db.select(_db.graphLayouts)
              ..where((l) => l.characterId.equals(character.id))
              ..orderBy([(l) => OrderingTerm.desc(l.id)])
              ..limit(1))
            .getSingleOrNull();

    final charRevisions =
        await (_db.select(_db.entityRevisions)..where(
              (r) =>
                  r.entityType.equals('character') &
                  r.entityId.equals(character.id),
            ))
            .get();

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
    };

    await _db.transaction(() async {
      // 1. 写入回收站
      await _db.trashDao.addToTrash(
        TrashCompanion(
          itemType: const Value('character'),
          itemId: Value(character.id),
          itemData: Value(jsonEncode(fullData)),
        ),
      );

      // 2. 清除相关子表与关联
      await (_db.delete(
        _db.characterFields,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (_db.delete(
        _db.characterStats,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (_db.delete(
        _db.characterGalleries,
      )..where((t) => t.characterId.equals(character.id))).go();
      await _db.timelineDao.deleteAllEventsByCharacter(character.id);
      await (_db.delete(
        _db.characterTags,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (_db.delete(
        _db.characterGroups,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (_db.delete(
        _db.graphLayouts,
      )..where((t) => t.characterId.equals(character.id))).go();
      await (_db.delete(_db.relations)..where(
            (r) =>
                r.fromCharacterId.equals(character.id) |
                r.toCharacterId.equals(character.id),
          ))
          .go();
      await (_db.delete(
        _db.loreRelations,
      )..where((r) => r.characterId.equals(character.id))).go();
      await _db.revisionDao.deleteRevisions('character', character.id);

      // 3. 删除主角色
      await _db.characterDao.deleteCharacter(character.id);
    });

    _invalidateRelated(character.worldId);
  }

  /// 软删除世界观：包含该世界观下所有角色、分组、关系和布局的完整快照
  Future<void> deleteWorld(World world) async {
    final characters = await _db.characterDao.getCharactersByWorld(world.id);
    final groups = await (_db.select(
      _db.groups,
    )..where((g) => g.worldId.equals(world.id))).get();
    final relations = await _db.relationDao.getRelationsByWorld(world.id);
    final canvases = await (_db.select(
      _db.graphCanvases,
    )..where((c) => c.worldId.equals(world.id))).get();
    final layouts = await (_db.select(
      _db.graphLayouts,
    )..where((l) => l.worldId.equals(world.id))).get();
    final timelineEvents = await _db.timelineDao.getEventsByWorld(world.id);

    // 收集所有人物的完整子数据
    final characterSnapshots = <Map<String, dynamic>>[];
    for (final c in characters) {
      final fields = await _db.characterDao.getCharacterFields(c.id);
      final stats = await _db.characterDao.getCharacterStats(c.id);
      final galleries = await _db.characterDao.getCharacterGalleries(c.id);
      final groupIds = await _db.groupDao.getGroupIdsByCharacter(c.id);
      final tagRows = await (_db.select(
        _db.characterTags,
      )..where((t) => t.characterId.equals(c.id))).get();

      characterSnapshots.add({
        'character': {
          'id': c.id,
          'worldId': c.worldId,
          'name': c.name,
          'avatarPath': c.avatarPath,
          'gender': c.gender,
          'description': c.description,
          'status': c.status,
          'isFavorite': c.isFavorite,
          'isPinned': c.isPinned,
          'createdAt': c.createdAt.toIso8601String(),
          'updatedAt': c.updatedAt.toIso8601String(),
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
        'tagIds': tagRows.map((r) => r.tagId).toList(),
        'groupIds': groupIds,
      });
    }

    final lores = await _db.loreDao.getEntitiesByWorld(world.id);
    final worldRevisions = await (_db.select(
      _db.entityRevisions,
    )..where((r) => r.worldId.equals(world.id))).get();

    final fullWorldData = {
      'world': {
        'id': world.id,
        'name': world.name,
        'description': world.description,
        'isLocked': world.isLocked,
        'createdAt': world.createdAt.toIso8601String(),
      },
      'characters': characterSnapshots,
      'groups': [
        for (final g in groups)
          {
            'id': g.id,
            'worldId': g.worldId,
            'name': g.name,
            'sortOrder': g.sortOrder,
            'createdAt': g.createdAt.toIso8601String(),
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
      'canvases': [
        for (final c in canvases)
          {
            'id': c.id,
            'worldId': c.worldId,
            'name': c.name,
            'description': c.description,
            'isDefault': c.isDefault,
            'viewportX': c.viewportX,
            'viewportY': c.viewportY,
            'zoomScale': c.zoomScale,
            'filterConfig': c.filterConfig,
            'createdAt': c.createdAt.toIso8601String(),
            'updatedAt': c.updatedAt.toIso8601String(),
          },
      ],
      'layouts': [
        for (final l in layouts)
          {
            'characterId': l.characterId,
            'worldId': l.worldId,
            'canvasId': l.canvasId,
            'x': l.x,
            'y': l.y,
          },
      ],
      'timelineEvents': [
        for (final t in timelineEvents)
          {
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
      'lores': [
        for (final l in lores)
          {
            'id': l.id,
            'worldId': l.worldId,
            'name': l.name,
            'entityType': l.entityType,
            'summary': l.summary,
            'content': l.content,
            'customFields': l.customFields,
            'tags': l.tags,
            'coverImagePath': l.coverImagePath,
            'createdAt': l.createdAt.toIso8601String(),
            'updatedAt': l.updatedAt.toIso8601String(),
          },
      ],
      'revisions': [
        for (final rev in worldRevisions)
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
    };

    await _db.transaction(() async {
      await _db.trashDao.addToTrash(
        TrashCompanion(
          itemType: const Value('world'),
          itemId: Value(world.id),
          itemData: Value(jsonEncode(fullWorldData)),
        ),
      );

      // 清除该世界观下所有关联数据（严格依照外键拓扑依赖顺序清理，避免外键约束失败）
      if (relations.isNotEmpty) {
        final relIds = relations.map((r) => r.id).toSet();
        await (_db.delete(_db.relations)..where((r) => r.id.isIn(relIds))).go();
      }
      if (characters.isNotEmpty) {
        final charIds = characters.map((c) => c.id).toSet();
        await (_db.delete(
          _db.characterFields,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (_db.delete(
          _db.characterStats,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (_db.delete(
          _db.characterGalleries,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (_db.delete(
          _db.characterTags,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (_db.delete(
          _db.characterGroups,
        )..where((t) => t.characterId.isIn(charIds))).go();
      }

      // 时间线、图布局、画布、百科实体与关系引用了 characters 与 worlds，必须在 characters 之前删除
      await (_db.delete(
        _db.loreRelations,
      )..where((r) => r.worldId.equals(world.id))).go();
      await _db.timelineDao.deleteAllEventsByWorld(world.id);
      await (_db.delete(
        _db.graphLayouts,
      )..where((l) => l.worldId.equals(world.id))).go();
      await (_db.delete(
        _db.graphCanvases,
      )..where((c) => c.worldId.equals(world.id))).go();
      await _db.loreDao.deleteEntitiesByWorld(world.id);
      await _db.revisionDao.deleteRevisionsByWorld(world.id);

      await (_db.delete(
        _db.characters,
      )..where((c) => c.worldId.equals(world.id))).go();
      await (_db.delete(
        _db.groups,
      )..where((g) => g.worldId.equals(world.id))).go();
      await _db.worldDao.deleteWorld(world.id);
    });

    _invalidateRelated(world.id);
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
    final worldExists = await (_db.select(
      _db.worlds,
    )..where((w) => w.id.equals(worldId))).getSingleOrNull();
    if (worldExists == null) {
      final availableWorlds = await _db.select(_db.worlds).get();
      if (availableWorlds.isNotEmpty) {
        effectiveWorldId = availableWorlds.first.id;
      } else {
        effectiveWorldId = await _db
            .into(_db.worlds)
            .insert(
              WorldsCompanion.insert(
                name: '恢复人物收纳世界',
                description: const Value('自动创建用于收纳已失去归属世界观的人物'),
              ),
            );
      }
    }

    await _db.transaction(() async {
      // 1. 还原人物主表
      await _db
          .into(_db.characters)
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
        await _db
            .into(_db.characterFields)
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
        await _db
            .into(_db.characterStats)
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
        await _db
            .into(_db.characterGalleries)
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
        await _db
            .into(_db.timelineEvents)
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
        final tagExists = await (_db.select(
          _db.tags,
        )..where((t) => t.id.equals(tagId))).getSingleOrNull();
        if (tagExists != null) {
          await _db
              .into(_db.characterTags)
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
        final groupExists = await (_db.select(
          _db.groups,
        )..where((g) => g.id.equals(groupId))).getSingleOrNull();
        if (groupExists != null) {
          await _db
              .into(_db.characterGroups)
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
        await _db
            .into(_db.graphLayouts)
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

        final otherChar = await (_db.select(
          _db.characters,
        )..where((c) => c.id.equals(otherId))).getSingleOrNull();

        if (otherChar != null && otherChar.worldId == effectiveWorldId) {
          final relType = rMap['relationType'] as String? ?? '关联';
          final existingRel =
              await (_db.select(_db.relations)..where(
                    (rel) =>
                        rel.fromCharacterId.equals(fromId) &
                        rel.toCharacterId.equals(toId) &
                        rel.relationType.equals(relType),
                  ))
                  .getSingleOrNull();

          if (existingRel == null) {
            await _db
                .into(_db.relations)
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
        await _db
            .into(_db.entityRevisions)
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

      // 7. 移除回收站记录
      await _db.trashDao.removeFromTrash(trashItem.id);
    });

    _invalidateRelated(effectiveWorldId);
  }

  /// 恢复世界观
  Future<void> restoreWorld(TrashData trashItem) async {
    final parsed = jsonDecode(trashItem.itemData) as Map<String, dynamic>;
    final Map<String, dynamic> worldData = parsed.containsKey('world')
        ? parsed['world'] as Map<String, dynamic>
        : parsed;

    final worldId = worldData['id'] as int;
    final charactersData = (parsed['characters'] as List<dynamic>?) ?? [];
    final groupsData = (parsed['groups'] as List<dynamic>?) ?? [];
    final relationsData = (parsed['relations'] as List<dynamic>?) ?? [];
    final layoutsData = (parsed['layouts'] as List<dynamic>?) ?? [];
    final timelineData = (parsed['timelineEvents'] as List<dynamic>?) ?? [];

    await _db.transaction(() async {
      // 1. 恢复世界观
      await _db
          .into(_db.worlds)
          .insertOnConflictUpdate(
            WorldsCompanion(
              id: Value(worldId),
              name: Value(worldData['name'] as String),
              description: Value(worldData['description'] as String?),
              isLocked: Value(worldData['isLocked'] as bool? ?? false),
              createdAt: Value(
                DateTime.parse(worldData['createdAt'] as String),
              ),
            ),
          );

      // 2. 恢复分组
      for (final g in groupsData) {
        final gm = g as Map<String, dynamic>;
        await _db
            .into(_db.groups)
            .insertOnConflictUpdate(
              GroupsCompanion(
                id: Value(gm['id'] as int),
                worldId: Value(gm['worldId'] as int),
                name: Value(gm['name'] as String),
                sortOrder: Value(gm['sortOrder'] as int? ?? 0),
                createdAt: Value(DateTime.parse(gm['createdAt'] as String)),
              ),
            );
      }

      // 3. 恢复人物及子数据
      for (final c in charactersData) {
        final cm = c as Map<String, dynamic>;
        final charMap = cm['character'] as Map<String, dynamic>;
        final cId = charMap['id'] as int;

        await _db
            .into(_db.characters)
            .insertOnConflictUpdate(
              CharactersCompanion(
                id: Value(cId),
                worldId: Value(worldId),
                name: Value(charMap['name'] as String),
                avatarPath: Value(charMap['avatarPath'] as String?),
                gender: Value(charMap['gender'] as String? ?? ''),
                description: Value(charMap['description'] as String? ?? ''),
                status: Value(charMap['status'] as int? ?? 0),
                isFavorite: Value(charMap['isFavorite'] as bool? ?? false),
                isPinned: Value(charMap['isPinned'] as bool? ?? false),
                createdAt: Value(
                  DateTime.parse(charMap['createdAt'] as String),
                ),
                updatedAt: Value(
                  charMap['updatedAt'] != null
                      ? DateTime.parse(charMap['updatedAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );

        final fields = (cm['fields'] as List<dynamic>?) ?? [];
        for (final f in fields) {
          final fm = f as Map<String, dynamic>;
          await _db
              .into(_db.characterFields)
              .insert(
                CharacterFieldsCompanion.insert(
                  characterId: cId,
                  fieldName: fm['fieldName'] as String,
                  fieldType: fm['fieldType'] as String,
                  value: Value(fm['value'] as String?),
                ),
              );
        }

        final stats = (cm['stats'] as List<dynamic>?) ?? [];
        for (final s in stats) {
          final sm = s as Map<String, dynamic>;
          await _db
              .into(_db.characterStats)
              .insert(
                CharacterStatsCompanion.insert(
                  characterId: cId,
                  label: sm['label'] as String,
                  value: Value((sm['value'] as num).toDouble()),
                  maxValue: Value(
                    (sm['maxValue'] as num?)?.toDouble() ?? 100.0,
                  ),
                  sortOrder: Value(sm['sortOrder'] as int? ?? 0),
                ),
              );
        }

        final galleries = (cm['galleries'] as List<dynamic>?) ?? [];
        for (final g in galleries) {
          final gm = g as Map<String, dynamic>;
          await _db
              .into(_db.characterGalleries)
              .insert(
                CharacterGalleriesCompanion.insert(
                  characterId: cId,
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

        final tagIds = (cm['tagIds'] as List<dynamic>?) ?? [];
        for (final tid in tagIds) {
          await _db
              .into(_db.characterTags)
              .insertOnConflictUpdate(
                CharacterTagsCompanion(
                  characterId: Value(cId),
                  tagId: Value(tid as int),
                ),
              );
        }

        final groupIds = (cm['groupIds'] as List<dynamic>?) ?? [];
        for (final gid in groupIds) {
          await _db
              .into(_db.characterGroups)
              .insertOnConflictUpdate(
                CharacterGroupsCompanion(
                  characterId: Value(cId),
                  groupId: Value(gid as int),
                ),
              );
        }
      }

      // 4. 恢复关系
      for (final r in relationsData) {
        final rm = r as Map<String, dynamic>;
        await _db
            .into(_db.relations)
            .insertOnConflictUpdate(
              RelationsCompanion(
                id: Value(rm['id'] as int),
                fromCharacterId: Value(rm['fromCharacterId'] as int),
                toCharacterId: Value(rm['toCharacterId'] as int),
                relationType: Value(rm['relationType'] as String),
                isBidirectional: Value(rm['isBidirectional'] as bool? ?? true),
                note: Value(rm['note'] as String?),
                relationGroupId: Value(rm['relationGroupId'] as String?),
              ),
            );
      }

      // 4.1 恢复图画布
      final canvasesData = (parsed['canvases'] as List<dynamic>?) ?? [];
      for (final c in canvasesData) {
        final cm = c as Map<String, dynamic>;
        await _db
            .into(_db.graphCanvases)
            .insertOnConflictUpdate(
              GraphCanvasesCompanion(
                id: Value(cm['id'] as int),
                worldId: Value(worldId),
                name: Value(cm['name'] as String),
                description: Value(cm['description'] as String?),
                isDefault: Value(cm['isDefault'] as bool? ?? false),
                viewportX: Value((cm['viewportX'] as num?)?.toDouble() ?? 0.0),
                viewportY: Value((cm['viewportY'] as num?)?.toDouble() ?? 0.0),
                zoomScale: Value((cm['zoomScale'] as num?)?.toDouble() ?? 1.0),
                filterConfig: Value(cm['filterConfig'] as String?),
                createdAt: Value(DateTime.parse(cm['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(cm['updatedAt'] as String)),
              ),
            );
      }

      // 5. 恢复布局
      for (final l in layoutsData) {
        final lm = l as Map<String, dynamic>;
        await _db
            .into(_db.graphLayouts)
            .insertOnConflictUpdate(
              GraphLayoutsCompanion(
                characterId: Value(lm['characterId'] as int),
                worldId: Value(worldId),
                canvasId: Value(lm['canvasId'] as int?),
                x: Value((lm['x'] as num).toDouble()),
                y: Value((lm['y'] as num).toDouble()),
              ),
            );
      }

      // 5.1 恢复编年史时间线
      for (final t in timelineData) {
        final tm = t as Map<String, dynamic>;
        await _db
            .into(_db.timelineEvents)
            .insert(
              TimelineEventsCompanion.insert(
                worldId: worldId,
                characterId: Value(tm['characterId'] as int?),
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

      // 5.2 恢复世界观百科实体
      final loresData = (parsed['lores'] as List<dynamic>?) ?? [];
      for (final l in loresData) {
        final lm = l as Map<String, dynamic>;
        await _db
            .into(_db.loreEntities)
            .insertOnConflictUpdate(
              LoreEntitiesCompanion(
                id: Value(lm['id'] as int),
                worldId: Value(worldId),
                name: Value(lm['name'] as String),
                entityType: Value(lm['entityType'] as String),
                summary: Value(lm['summary'] as String? ?? ''),
                content: Value(lm['content'] as String? ?? ''),
                customFields: Value(lm['customFields'] as String? ?? '{}'),
                tags: Value(lm['tags'] as String? ?? ''),
                coverImagePath: Value(lm['coverImagePath'] as String?),
                createdAt: Value(DateTime.parse(lm['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(lm['updatedAt'] as String)),
              ),
            );
      }

      // 5.3 恢复设定版本历史快照
      final revisionsData = (parsed['revisions'] as List<dynamic>?) ?? [];
      for (final rev in revisionsData) {
        final rm = rev as Map<String, dynamic>;
        await _db
            .into(_db.entityRevisions)
            .insertOnConflictUpdate(
              EntityRevisionsCompanion(
                id: Value(rm['id'] as int),
                worldId: Value(worldId),
                entityType: Value(rm['entityType'] as String),
                entityId: Value(rm['entityId'] as int),
                title: Value(rm['title'] as String? ?? ''),
                content: Value(rm['content'] as String),
                charCount: Value(rm['charCount'] as int? ?? 0),
                createdAt: Value(DateTime.parse(rm['createdAt'] as String)),
              ),
            );
      }

      // 6. 移除回收站
      await _db.trashDao.removeFromTrash(trashItem.id);
    });

    _invalidateRelated(worldId);
  }

  /// 永久删除
  Future<void> permanentDelete(int trashId) async {
    await _db.trashDao.removeFromTrash(trashId);
    _refresh();
  }

  /// 清空回收站
  Future<void> emptyTrash() async {
    await _db.trashDao.cleanOldTrash(DateTime(2100));
    _refresh();
  }

  void _invalidateRelated(int worldId) {
    _ref.invalidate(worldsProvider);
    _ref.invalidate(worldByIdProvider(worldId));
    _ref.invalidate(charactersByWorldProvider(worldId));
    _ref.invalidate(groupsByWorldProvider(worldId));
    _ref.invalidate(relationsByWorldProvider(worldId));
    _ref.invalidate(graphLayoutsProvider(worldId));
    _ref.invalidate(worldTimelineEventsProvider(worldId));
    _ref.invalidate(loreEntitiesByWorldProvider(worldId));
    _refresh();
  }

  void _refresh() {
    _ref.read(trashRefreshProvider.notifier).state++;
  }
}
