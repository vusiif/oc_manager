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

  // 图布局
  Future<List<GraphLayout>> getLayoutsByWorld(int worldId) =>
      (select(graphLayouts)..where((t) => t.worldId.equals(worldId))).get();

  Future<int> saveLayout(GraphLayoutsCompanion entry) =>
      into(graphLayouts).insert(entry, mode: InsertMode.insertOrReplace);

  Future<void> deleteLayoutsByWorld(int worldId) =>
      (delete(graphLayouts)..where((t) => t.worldId.equals(worldId))).go();
}
