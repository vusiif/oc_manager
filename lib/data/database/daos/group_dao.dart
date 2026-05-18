import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/groups.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [Groups, CharacterGroups])
class GroupDao extends DatabaseAccessor<AppDatabase>
    with _$GroupDaoMixin {
  GroupDao(AppDatabase db) : super(db);

  // 获取世界观下的所有分组
  Stream<List<Group>> watchGroupsByWorld(int worldId) {
    return (select(groups)
          ..where((g) => g.worldId.equals(worldId))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .watch();
  }

  // 获取分组
  Future<Group> getGroupById(int id) {
    return (select(groups)..where((g) => g.id.equals(id))).getSingle();
  }

  // 创建分组
  Future<int> createGroup(GroupsCompanion group) {
    return into(groups).insert(group);
  }

  // 更新分组
  Future<bool> updateGroup(Group group) {
    return update(groups).replace(group);
  }

  // 删除分组
  Future<void> deleteGroup(int id) {
    return (delete(groups)..where((g) => g.id.equals(id))).go();
  }

  // 获取分组下的人物 ID 列表
  Future<List<int>> getCharacterIdsByGroup(int groupId) async {
    final rows = await (select(characterGroups)
          ..where((cg) => cg.groupId.equals(groupId)))
        .get();
    return rows.map((r) => r.characterId).toList();
  }

  // 获取人物所属的分组 ID 列表
  Future<List<int>> getGroupIdsByCharacter(int characterId) async {
    final rows = await (select(characterGroups)
          ..where((cg) => cg.characterId.equals(characterId)))
        .get();
    return rows.map((r) => r.groupId).toList();
  }

  // 添加人物到分组
  Future<void> addCharacterToGroup(int characterId, int groupId) {
    return into(characterGroups).insert(
      CharacterGroupsCompanion.insert(
        characterId: characterId,
        groupId: groupId,
      ),
    );
  }

  // 从分组移除人物
  Future<void> removeCharacterFromGroup(int characterId, int groupId) {
    return (delete(characterGroups)
          ..where((cg) =>
              cg.characterId.equals(characterId) &
              cg.groupId.equals(groupId)))
        .go();
  }

  // 设置人物的分组（替换）
  Future<void> setCharacterGroups(int characterId, List<int> groupIds) async {
    await (delete(characterGroups)
          ..where((cg) => cg.characterId.equals(characterId)))
        .go();
    for (final groupId in groupIds) {
      await addCharacterToGroup(characterId, groupId);
    }
  }

  // 获取世界观下未分组的人物 ID 列表
  Future<List<int>> getUngroupedCharacterIds(int worldId) async {
    final allCharacters = await (select(characters)
          ..where((c) => c.worldId.equals(worldId)))
        .get();
    final groupedRows = await (select(characterGroups)).get();
    final groupedIds = groupedRows.map((r) => r.characterId).toSet();
    return allCharacters
        .where((c) => !groupedIds.contains(c.id))
        .map((c) => c.id)
        .toList();
  }

  // 删除世界观下的所有分组
  Future<void> deleteGroupsByWorld(int worldId) async {
    final worldGroupIds = await (select(groups)
          ..where((g) => g.worldId.equals(worldId)))
        .get();
    for (final group in worldGroupIds) {
      await (delete(characterGroups)
            ..where((cg) => cg.groupId.equals(group.id)))
          .go();
    }
    await (delete(groups)..where((g) => g.worldId.equals(worldId))).go();
  }
}
