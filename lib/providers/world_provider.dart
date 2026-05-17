import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final worldsProvider = StreamProvider<List<World>>((ref) {
  return ref.watch(worldDaoProvider).watchAllWorlds();
});

final worldByIdProvider = FutureProvider.family<World, int>((ref, id) {
  return ref.watch(worldDaoProvider).getWorldById(id);
});

final worldActionsProvider = Provider((ref) => WorldActions(ref));

class WorldActions {
  final Ref _ref;

  WorldActions(this._ref);

  Future<int> create(String name, {String? description}) async {
    return _ref.read(worldDaoProvider).createWorld(
          WorldsCompanion(
            name: Value(name),
            description: Value(description),
          ),
        );
  }

  Future<bool> update(int id, String name, {String? description}) async {
    final world = await _ref.read(worldDaoProvider).getWorldById(id);
    return _ref.read(worldDaoProvider).updateWorld(
          WorldsCompanion(
            id: Value(id),
            name: Value(name),
            description: Value(description),
            createdAt: Value(world.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> delete(int id) async {
    await _ref.read(worldDaoProvider).deleteWorld(id);
  }
}
