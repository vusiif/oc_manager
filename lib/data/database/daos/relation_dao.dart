import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/relations.dart';
import '../tables/characters.dart';

part 'relation_dao.g.dart';

@DriftAccessor(tables: [Relations, Characters])
class RelationDao extends DatabaseAccessor<AppDatabase>
    with _$RelationDaoMixin {
  RelationDao(super.db);

  Future<List<Relation>> getRelationsByCharacter(int characterId) =>
      (select(relations)
            ..where((t) =>
                t.fromCharacterId.equals(characterId) |
                t.toCharacterId.equals(characterId)))
          .get();

  Future<List<Relation>> getRelationsByWorld(int worldId) async {
    final query = select(relations).join([
      innerJoin(characters, characters.id.equalsExp(relations.fromCharacterId)),
    ])
      ..where(characters.worldId.equals(worldId));
    final results = await query.get();
    return results.map((row) => row.readTable(relations)).toList();
  }

  Future<int> createRelation(RelationsCompanion entry) =>
      into(relations).insert(entry);

  Future<bool> updateRelation(RelationsCompanion entry) =>
      update(relations).replace(entry);

  Future<int> deleteRelation(int id) =>
      (delete(relations)..where((t) => t.id.equals(id))).go();

  Future<void> deleteRelationsByCharacter(int characterId) =>
      (delete(relations)
            ..where((t) =>
                t.fromCharacterId.equals(characterId) |
                t.toCharacterId.equals(characterId)))
          .go();
}
