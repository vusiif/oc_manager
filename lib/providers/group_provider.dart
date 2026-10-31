import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final groupsByWorldProvider =
    StreamProvider.family<List<Group>, int>((ref, worldId) {
  return ref.watch(groupDaoProvider).watchGroupsByWorld(worldId);
});

final groupByIdProvider =
    FutureProvider.family<Group, int>((ref, id) {
  return ref.watch(groupDaoProvider).getGroupById(id);
});

// 获取分组下的人物列表
final charactersByGroupProvider =
    FutureProvider.family<List<Character>, int>((ref, groupId) async {
  final characterIds = await ref.read(groupDaoProvider).getCharacterIdsByGroup(groupId);
  if (characterIds.isEmpty) return [];
  final allChars = await ref.read(characterDaoProvider).getCharactersByIds(characterIds);
  return allChars;
});

// 获取世界观下未加入任何分组的人物列表
final unassignedCharactersByWorldProvider =
    FutureProvider.family<List<Character>, int>((ref, worldId) async {
  final db = ref.read(databaseProvider);
  final allWorldChars = await (db.select(db.characters)..where((c) => c.worldId.equals(worldId))).get();
  final allCharGroups = await db.select(db.characterGroups).get();
  final assignedCharIds = allCharGroups.map((cg) => cg.characterId).toSet();
  return allWorldChars.where((c) => !assignedCharIds.contains(c.id)).toList();
});

// 获取人物所属的分组 ID 列表
final characterGroupIdsProvider =
    FutureProvider.family<List<int>, int>((ref, characterId) async {
  return ref.read(groupDaoProvider).getGroupIdsByCharacter(characterId);
});

final groupActionsProvider = Provider((ref) => GroupActions(ref));

class GroupActions {
  final Ref _ref;

  GroupActions(this._ref);

  Future<int> create({
    required int worldId,
    required String name,
    int sortOrder = 0,
  }) async {
    return _ref.read(groupDaoProvider).createGroup(
          GroupsCompanion(
            worldId: Value(worldId),
            name: Value(name),
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<bool> update(Group group) async {
    return _ref.read(groupDaoProvider).updateGroup(group);
  }

  Future<void> delete(int id) async {
    await _ref.read(groupDaoProvider).deleteGroup(id);
  }

  Future<void> addCharacterToGroup(int characterId, int groupId) async {
    await _ref.read(groupDaoProvider).addCharacterToGroup(characterId, groupId);
    _ref.invalidate(charactersByGroupProvider);
  }

  Future<void> removeCharacterFromGroup(int characterId, int groupId) async {
    await _ref.read(groupDaoProvider).removeCharacterFromGroup(characterId, groupId);
    _ref.invalidate(charactersByGroupProvider);
  }

  Future<void> setCharacterGroups(int characterId, List<int> groupIds) async {
    await _ref.read(groupDaoProvider).setCharacterGroups(characterId, groupIds);
  }

  Future<List<int>> getGroupIdsByCharacter(int characterId) async {
    return _ref.read(groupDaoProvider).getGroupIdsByCharacter(characterId);
  }
}
