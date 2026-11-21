import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

/// Handler for cascading soft-deletion and safe restoration of Worlds in the trash bin.
class WorldTrashHandler {
  final AppDatabase db;
  final void Function(int worldId) onInvalidate;

  WorldTrashHandler({required this.db, required this.onInvalidate});

  /// 软删除世界观：包含该世界观下所有角色、分组、关系和布局的完整快照
  Future<void> deleteWorld(World world) async {
    final characters = await db.characterDao.getCharactersByWorld(world.id);
    final groups = await (db.select(
      db.groups,
    )..where((g) => g.worldId.equals(world.id))).get();
    final relations = await db.relationDao.getRelationsByWorld(world.id);
    final canvases = await (db.select(
      db.graphCanvases,
    )..where((c) => c.worldId.equals(world.id))).get();
    final layouts = await (db.select(
      db.graphLayouts,
    )..where((l) => l.worldId.equals(world.id))).get();
    final timelineEvents = await db.timelineDao.getEventsByWorld(world.id);

    // 收集所有人物的完整子数据
    final characterSnapshots = <Map<String, dynamic>>[];
    for (final c in characters) {
      final fields = await db.characterDao.getCharacterFields(c.id);
      final stats = await db.characterDao.getCharacterStats(c.id);
      final galleries = await db.characterDao.getCharacterGalleries(c.id);
      final groupIds = await db.groupDao.getGroupIdsByCharacter(c.id);
      final tagRows = await (db.select(
        db.characterTags,
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

    final lores = await db.loreDao.getEntitiesByWorld(world.id);
    final worldRevisions = await (db.select(
      db.entityRevisions,
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

    await db.transaction(() async {
      await db.trashDao.addToTrash(
        TrashCompanion(
          itemType: const Value('world'),
          itemId: Value(world.id),
          itemData: Value(jsonEncode(fullWorldData)),
        ),
      );

      // 清除该世界观下所有关联数据（严格依照外键拓扑依赖顺序清理，避免外键约束失败）
      if (relations.isNotEmpty) {
        final relIds = relations.map((r) => r.id).toSet();
        await (db.delete(db.relations)..where((r) => r.id.isIn(relIds))).go();
      }
      if (characters.isNotEmpty) {
        final charIds = characters.map((c) => c.id).toSet();
        await (db.delete(
          db.characterFields,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (db.delete(
          db.characterStats,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (db.delete(
          db.characterGalleries,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (db.delete(
          db.characterTags,
        )..where((t) => t.characterId.isIn(charIds))).go();
        await (db.delete(
          db.characterGroups,
        )..where((t) => t.characterId.isIn(charIds))).go();
      }

      // 时间线、图布局、画布、百科实体与关系引用了 characters 与 worlds，必须在 characters 之前删除
      await (db.delete(
        db.loreRelations,
      )..where((r) => r.worldId.equals(world.id))).go();
      await db.timelineDao.deleteAllEventsByWorld(world.id);
      await (db.delete(
        db.graphLayouts,
      )..where((l) => l.worldId.equals(world.id))).go();
      await (db.delete(
        db.graphCanvases,
      )..where((c) => c.worldId.equals(world.id))).go();
      await db.loreDao.deleteEntitiesByWorld(world.id);
      await db.revisionDao.deleteRevisionsByWorld(world.id);

      await (db.delete(
        db.characters,
      )..where((c) => c.worldId.equals(world.id))).go();
      await (db.delete(
        db.groups,
      )..where((g) => g.worldId.equals(world.id))).go();
      await db.worldDao.deleteWorld(world.id);
    });

    onInvalidate(world.id);
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

    await db.transaction(() async {
      // 1. 恢复世界观
      await db
          .into(db.worlds)
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
        await db
            .into(db.groups)
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

        await db
            .into(db.characters)
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
          await db
              .into(db.characterFields)
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
          await db
              .into(db.characterStats)
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
          await db
              .into(db.characterGalleries)
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
          await db
              .into(db.characterTags)
              .insertOnConflictUpdate(
                CharacterTagsCompanion(
                  characterId: Value(cId),
                  tagId: Value(tid as int),
                ),
              );
        }

        final groupIds = (cm['groupIds'] as List<dynamic>?) ?? [];
        for (final gid in groupIds) {
          await db
              .into(db.characterGroups)
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
        await db
            .into(db.relations)
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
        await db
            .into(db.graphCanvases)
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
        await db
            .into(db.graphLayouts)
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
        await db
            .into(db.timelineEvents)
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
        await db
            .into(db.loreEntities)
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
        await db
            .into(db.entityRevisions)
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
      await db.trashDao.removeFromTrash(trashItem.id);
    });

    onInvalidate(worldId);
  }
}
