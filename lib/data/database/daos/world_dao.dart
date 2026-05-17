import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/worlds.dart';

part 'world_dao.g.dart';

@DriftAccessor(tables: [Worlds])
class WorldDao extends DatabaseAccessor<AppDatabase> with _$WorldDaoMixin {
  WorldDao(super.db);

  Future<List<World>> getAllWorlds() => select(worlds).get();

  Stream<List<World>> watchAllWorlds() => select(worlds).watch();

  Future<World> getWorldById(int id) =>
      (select(worlds)..where((t) => t.id.equals(id))).getSingle();

  Future<int> createWorld(WorldsCompanion entry) =>
      into(worlds).insert(entry);

  Future<bool> updateWorld(WorldsCompanion entry) =>
      update(worlds).replace(entry);

  Future<int> deleteWorld(int id) =>
      (delete(worlds)..where((t) => t.id.equals(id))).go();
}
