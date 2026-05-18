import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/characters.dart';

part 'character_dao.g.dart';

@DriftAccessor(tables: [Characters, CharacterFields])
class CharacterDao extends DatabaseAccessor<AppDatabase>
    with _$CharacterDaoMixin {
  CharacterDao(super.db);

  Future<List<Character>> getCharactersByWorld(int worldId) =>
      (select(characters)..where((t) => t.worldId.equals(worldId))).get();

  Future<List<Character>> getCharactersByIds(List<int> ids) =>
      (select(characters)..where((t) => t.id.isIn(ids))).get();

  Stream<List<Character>> watchCharactersByWorld(int worldId) =>
      (select(characters)..where((t) => t.worldId.equals(worldId))).watch();

  Future<Character> getCharacterById(int id) =>
      (select(characters)..where((t) => t.id.equals(id))).getSingle();

  Future<int> createCharacter(CharactersCompanion entry) =>
      into(characters).insert(entry);

  Future<bool> updateCharacter(CharactersCompanion entry) =>
      update(characters).replace(entry);

  Future<int> deleteCharacter(int id) =>
      (delete(characters)..where((t) => t.id.equals(id))).go();

  Future<List<CharacterField>> getCharacterFields(int characterId) =>
      (select(characterFields)
            ..where((t) => t.characterId.equals(characterId)))
          .get();

  Stream<List<CharacterField>> watchCharacterFields(int characterId) =>
      (select(characterFields)
            ..where((t) => t.characterId.equals(characterId)))
          .watch();

  Future<int> createCharacterField(CharacterFieldsCompanion entry) =>
      into(characterFields).insert(entry);

  Future<void> updateCharacterField(CharacterFieldsCompanion entry) =>
      update(characterFields).replace(entry);

  Future<int> deleteCharacterField(int id) =>
      (delete(characterFields)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllCharacterFields(int characterId) =>
      (delete(characterFields)
            ..where((t) => t.characterId.equals(characterId)))
          .go();

  Future<List<Character>> searchCharacters(String keyword) =>
      (select(characters)..where((t) => t.name.like('%$keyword%'))).get();

  Future<List<Character>> getFavoriteCharacters() =>
      (select(characters)..where((t) => t.isFavorite.equals(true))).get();

  Future<List<Character>> getDraftCharacters() =>
      (select(characters)..where((t) => t.status.equals(1))).get();
}
