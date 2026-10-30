import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/trash.dart';

part 'trash_dao.g.dart';

@DriftAccessor(tables: [Trash, Backups, GraphLayouts])
class TrashDao extends DatabaseAccessor<AppDatabase> with _$TrashDaoMixin {
  TrashDao(super.db);

  // 回收站
  Future<List<TrashData>> getAllTrash() => select(trash).get();

  Future<int> addToTrash(TrashCompanion entry) => into(trash).insert(entry);

  Future<int> removeFromTrash(int id) =>
      (delete(trash)..where((t) => t.id.equals(id))).go();

  Future<int> cleanOldTrash(DateTime before) =>
      (delete(trash)..where((t) => t.deletedAt.isSmallerThanValue(before)))
          .go();

  // 备份
  Future<List<Backup>> getAllBackups() => select(backups).get();

  Future<int> createBackup(BackupsCompanion entry) =>
      into(backups).insert(entry);

  Future<int> deleteBackup(int id) =>
      (delete(backups)..where((t) => t.id.equals(id))).go();

  // 图布局（按世界观获取，并确保单个角色仅保留最新一条有效坐标）
  Future<List<GraphLayout>> getLayoutsByWorld(int worldId) async {
    final rows = await (select(graphLayouts)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final latestByCharacter = <int, GraphLayout>{};
    for (final row in rows) {
      latestByCharacter[row.characterId] = row;
    }
    return latestByCharacter.values.toList();
  }

  // 幂等保存布局坐标（存在则更新最新行并清理重复历史冗余，不存在则插入）
  Future<int> saveLayout(GraphLayoutsCompanion entry) async {
    final worldId = entry.worldId.value;
    final characterId = entry.characterId.value;

    final existing = await (select(graphLayouts)
          ..where((t) =>
              t.worldId.equals(worldId) & t.characterId.equals(characterId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();

    if (existing.isNotEmpty) {
      final latestId = existing.first.id;
      await (update(graphLayouts)..where((t) => t.id.equals(latestId))).write(
        GraphLayoutsCompanion(
          x: entry.x,
          y: entry.y,
        ),
      );
      if (existing.length > 1) {
        await (delete(graphLayouts)
              ..where((t) =>
                  t.worldId.equals(worldId) &
                  t.characterId.equals(characterId) &
                  t.id.isNotValue(latestId)))
            .go();
      }
      return latestId;
    } else {
      return into(graphLayouts).insert(entry);
    }
  }

  Future<void> deleteLayoutsByWorld(int worldId) =>
      (delete(graphLayouts)..where((t) => t.worldId.equals(worldId))).go();

  Future<void> deleteLayout(int worldId, int characterId) =>
      (delete(graphLayouts)
            ..where((t) =>
                t.worldId.equals(worldId) &
                t.characterId.equals(characterId)))
          .go();
}
