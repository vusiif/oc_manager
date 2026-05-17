import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

// --- 关系 ---

final relationsByWorldProvider =
    FutureProvider.family<List<Relation>, int>((ref, worldId) {
  return ref.watch(relationDaoProvider).getRelationsByWorld(worldId);
});

final relationsByCharacterProvider =
    FutureProvider.family<List<Relation>, int>((ref, characterId) {
  return ref.watch(relationDaoProvider).getRelationsByCharacter(characterId);
});

final relationActionsProvider = Provider((ref) => RelationActions(ref));

class RelationActions {
  final Ref _ref;

  RelationActions(this._ref);

  Future<int> create({
    required int fromCharacterId,
    required int toCharacterId,
    required String relationType,
    bool isBidirectional = true,
    String? note,
  }) async {
    final id = await _ref.read(relationDaoProvider).createRelation(
          RelationsCompanion(
            fromCharacterId: Value(fromCharacterId),
            toCharacterId: Value(toCharacterId),
            relationType: Value(relationType),
            isBidirectional: Value(isBidirectional),
            note: Value(note),
          ),
        );
    return id;
  }

  Future<bool> update(Relation relation) async {
    return _ref.read(relationDaoProvider).updateRelation(
          RelationsCompanion(
            id: Value(relation.id),
            fromCharacterId: Value(relation.fromCharacterId),
            toCharacterId: Value(relation.toCharacterId),
            relationType: Value(relation.relationType),
            isBidirectional: Value(relation.isBidirectional),
            note: Value(relation.note),
          ),
        );
  }

  Future<void> delete(int id) async {
    await _ref.read(relationDaoProvider).deleteRelation(id);
  }
}

// --- 图布局 ---

final graphLayoutsProvider =
    FutureProvider.family<List<GraphLayout>, int>((ref, worldId) {
  return ref.watch(trashDaoProvider).getLayoutsByWorld(worldId);
});

final graphLayoutActionsProvider = Provider((ref) => GraphLayoutActions(ref));

class GraphLayoutActions {
  final Ref _ref;

  GraphLayoutActions(this._ref);

  Future<void> savePosition(int worldId, int characterId, double x, double y) async {
    await _ref.read(trashDaoProvider).saveLayout(
          GraphLayoutsCompanion(
            worldId: Value(worldId),
            characterId: Value(characterId),
            x: Value(x),
            y: Value(y),
          ),
        );
  }
}
