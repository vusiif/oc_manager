import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'character_provider.dart';
import 'database_provider.dart';
import 'group_provider.dart';
import 'relation_provider.dart';
import 'world_provider.dart';

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
    final groupIds =
        await _db.groupDao.getGroupIdsByCharacter(character.id);

    final tagRows = await (_db.select(_db.characterTags)
          ..where((t) => t.characterId.equals(character.id)))
        .get();
    final tagIds = tagRows.map((r) => r.tagId).toList();

    final layoutRow = await (_db.select(_db.graphLayouts)
          ..where((l) => l.characterId.equals(character.id))
          ..orderBy([(l) => OrderingTerm.desc(l.id)])
          ..limit(1))
        .getSingleOrNull();

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
          }
      ],
      'tagIds': tagIds,
      'groupIds': groupIds,
      'layout': layoutRow != null
          ? {
              'worldId': layoutRow.worldId,
              'x': layoutRow.x,
              'y': layoutRow.y,
            }
          : null,
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
      await (_db.delete(_db.characterFields)
            ..where((t) => t.characterId.equals(character.id)))
          .go();
      await (_db.delete(_db.characterTags)
            ..where((t) => t.characterId.equals(character.id)))
          .go();
      await (_db.delete(_db.characterGroups)
            ..where((t) => t.characterId.equals(character.id)))
          .go();
      await (_db.delete(_db.graphLayouts)
            ..where((t) => t.characterId.equals(character.id)))
          .go();
      await (_db.delete(_db.relations)
            ..where((r) =>
                r.fromCharacterId.equals(character.id) |
                r.toCharacterId.equals(character.id)))
          .go();

      // 3. 删除主角色
      await _db.characterDao.deleteCharacter(character.id);
    });

    _invalidateRelated(character.worldId);
  }

  /// 软删除世界观：包含该世界观下所有角色、分组、关系和布局的完整快照
  Future<void> deleteWorld(World world) async {
    final characters =
        await _db.characterDao.getCharactersByWorld(world.id);
    final groups = await (_db.select(_db.groups)
          ..where((g) => g.worldId.equals(world.id)))
        .get();
    final relations =
        await _db.relationDao.getRelationsByWorld(world.id);
    final layouts = await (_db.select(_db.graphLayouts)
          ..where((l) => l.worldId.equals(world.id)))
        .get();

    // 收集所有人物的完整子数据
    final characterSnapshots = <Map<String, dynamic>>[];
    for (final c in characters) {
      final fields = await _db.characterDao.getCharacterFields(c.id);
      final groupIds = await _db.groupDao.getGroupIdsByCharacter(c.id);
      final tagRows = await (_db.select(_db.characterTags)
            ..where((t) => t.characterId.equals(c.id)))
          .get();

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
            }
        ],
        'tagIds': tagRows.map((r) => r.tagId).toList(),
        'groupIds': groupIds,
      });
    }

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
          }
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
          }
      ],
      'layouts': [
        for (final l in layouts)
          {
            'characterId': l.characterId,
            'worldId': l.worldId,
            'x': l.x,
            'y': l.y,
          }
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

      // 清除该世界观下所有关联数据
      for (final rel in relations) {
        await (_db.delete(_db.relations)..where((r) => r.id.equals(rel.id))).go();
      }
      for (final c in characters) {
        await (_db.delete(_db.characterFields)
              ..where((t) => t.characterId.equals(c.id)))
            .go();
        await (_db.delete(_db.characterTags)
              ..where((t) => t.characterId.equals(c.id)))
            .go();
        await (_db.delete(_db.characterGroups)
              ..where((t) => t.characterId.equals(c.id)))
            .go();
      }

      await (_db.delete(_db.characters)
            ..where((c) => c.worldId.equals(world.id)))
          .go();
      await (_db.delete(_db.groups)
            ..where((g) => g.worldId.equals(world.id)))
          .go();
      await (_db.delete(_db.graphLayouts)
            ..where((l) => l.worldId.equals(world.id)))
          .go();
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
    final tagIds = (parsed['tagIds'] as List<dynamic>?) ?? [];
    final groupIds = (parsed['groupIds'] as List<dynamic>?) ?? [];
    final layoutData = parsed['layout'] as Map<String, dynamic>?;

    final charId = charData['id'] as int;
    final worldId = charData['worldId'] as int;

    await _db.transaction(() async {
      // 1. 还原人物主表
      await _db.into(_db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              worldId: Value(worldId),
              name: Value(charData['name'] as String),
              avatarPath: Value(charData['avatarPath'] as String?),
              gender: Value(charData['gender'] as String? ?? ''),
              description: Value(charData['description'] as String? ?? ''),
              status: Value(charData['status'] as int? ?? 0),
              isFavorite: Value(charData['isFavorite'] as bool? ?? false),
              isPinned: Value(charData['isPinned'] as bool? ?? false),
              createdAt: Value(DateTime.parse(charData['createdAt'] as String)),
              updatedAt: Value(charData['updatedAt'] != null
                  ? DateTime.parse(charData['updatedAt'] as String)
                  : DateTime.now()),
            ),
          );

      // 2. 还原自定义字段
      for (final f in fieldsData) {
        final fieldMap = f as Map<String, dynamic>;
        await _db.into(_db.characterFields).insert(
              CharacterFieldsCompanion.insert(
                characterId: charId,
                fieldName: fieldMap['fieldName'] as String,
                fieldType: fieldMap['fieldType'] as String,
                value: Value(fieldMap['value'] as String?),
              ),
            );
      }

      // 3. 还原标签（确保标签库仍有该 tagId）
      for (final tid in tagIds) {
        final tagId = tid as int;
        final tagExists = await (_db.select(_db.tags)
              ..where((t) => t.id.equals(tagId)))
            .getSingleOrNull();
        if (tagExists != null) {
          await _db.into(_db.characterTags).insertOnConflictUpdate(
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
        final groupExists = await (_db.select(_db.groups)
              ..where((g) => g.id.equals(groupId)))
            .getSingleOrNull();
        if (groupExists != null) {
          await _db.into(_db.characterGroups).insertOnConflictUpdate(
                CharacterGroupsCompanion(
                  characterId: Value(charId),
                  groupId: Value(groupId),
                ),
              );
        }
      }

      // 5. 还原画布坐标
      if (layoutData != null) {
        await _db.into(_db.graphLayouts).insertOnConflictUpdate(
              GraphLayoutsCompanion(
                characterId: Value(charId),
                worldId: Value(layoutData['worldId'] as int),
                x: Value((layoutData['x'] as num).toDouble()),
                y: Value((layoutData['y'] as num).toDouble()),
              ),
            );
      }

      // 6. 移除回收站记录
      await _db.trashDao.removeFromTrash(trashItem.id);
    });

    _invalidateRelated(worldId);
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

    await _db.transaction(() async {
      // 1. 恢复世界观
      await _db.into(_db.worlds).insertOnConflictUpdate(
            WorldsCompanion(
              id: Value(worldId),
              name: Value(worldData['name'] as String),
              description: Value(worldData['description'] as String?),
              isLocked: Value(worldData['isLocked'] as bool? ?? false),
              createdAt:
                  Value(DateTime.parse(worldData['createdAt'] as String)),
            ),
          );

      // 2. 恢复分组
      for (final g in groupsData) {
        final gm = g as Map<String, dynamic>;
        await _db.into(_db.groups).insertOnConflictUpdate(
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

        await _db.into(_db.characters).insertOnConflictUpdate(
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
                createdAt:
                    Value(DateTime.parse(charMap['createdAt'] as String)),
                updatedAt: Value(charMap['updatedAt'] != null
                    ? DateTime.parse(charMap['updatedAt'] as String)
                    : DateTime.now()),
              ),
            );

        final fields = (cm['fields'] as List<dynamic>?) ?? [];
        for (final f in fields) {
          final fm = f as Map<String, dynamic>;
          await _db.into(_db.characterFields).insert(
                CharacterFieldsCompanion.insert(
                  characterId: cId,
                  fieldName: fm['fieldName'] as String,
                  fieldType: fm['fieldType'] as String,
                  value: Value(fm['value'] as String?),
                ),
              );
        }

        final tagIds = (cm['tagIds'] as List<dynamic>?) ?? [];
        for (final tid in tagIds) {
          await _db.into(_db.characterTags).insertOnConflictUpdate(
                CharacterTagsCompanion(
                  characterId: Value(cId),
                  tagId: Value(tid as int),
                ),
              );
        }

        final groupIds = (cm['groupIds'] as List<dynamic>?) ?? [];
        for (final gid in groupIds) {
          await _db.into(_db.characterGroups).insertOnConflictUpdate(
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
        await _db.into(_db.relations).insertOnConflictUpdate(
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

      // 5. 恢复布局
      for (final l in layoutsData) {
        final lm = l as Map<String, dynamic>;
        await _db.into(_db.graphLayouts).insertOnConflictUpdate(
              GraphLayoutsCompanion(
                characterId: Value(lm['characterId'] as int),
                worldId: Value(worldId),
                x: Value((lm['x'] as num).toDouble()),
                y: Value((lm['y'] as num).toDouble()),
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
    _refresh();
  }

  void _refresh() {
    _ref.read(trashRefreshProvider.notifier).state++;
  }
}
