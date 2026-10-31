import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/characters.dart';

part 'character_dao.g.dart';

@DriftAccessor(tables: [Characters, CharacterFields, CharacterStats, CharacterGalleries])
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

  Future<int> updatePartial(int id, CharactersCompanion entry) =>
      (update(characters)..where((t) => t.id.equals(id))).write(entry);

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

  Future<List<CharacterStat>> getCharacterStats(int characterId) =>
      (select(characterStats)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<List<CharacterStat>> watchCharacterStats(int characterId) =>
      (select(characterStats)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<int> createCharacterStat(CharacterStatsCompanion entry) =>
      into(characterStats).insert(entry);

  Future<void> updateCharacterStat(CharacterStatsCompanion entry) =>
      update(characterStats).replace(entry);

  Future<int> deleteCharacterStat(int id) =>
      (delete(characterStats)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllCharacterStats(int characterId) =>
      (delete(characterStats)
            ..where((t) => t.characterId.equals(characterId)))
          .go();

  Future<void> setCharacterStats(
    int characterId,
    List<CharacterStatsCompanion> stats,
  ) =>
      transaction(() async {
        await deleteAllCharacterStats(characterId);
        for (var i = 0; i < stats.length; i++) {
          final s = stats[i];
          await into(characterStats).insert(s.copyWith(
            characterId: Value(characterId),
            sortOrder: Value(i),
          ));
        }
      });

  Future<List<CharacterGallery>> getCharacterGalleries(int characterId) =>
      (select(characterGalleries)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<List<CharacterGallery>> watchCharacterGalleries(int characterId) =>
      (select(characterGalleries)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<int> addGalleryImage(CharacterGalleriesCompanion entry) =>
      into(characterGalleries).insert(entry);

  Future<void> updateGalleryImage(CharacterGalleriesCompanion entry) =>
      update(characterGalleries).replace(entry);

  Future<int> deleteGalleryImage(int id) =>
      (delete(characterGalleries)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllGalleryImages(int characterId) =>
      (delete(characterGalleries)
            ..where((t) => t.characterId.equals(characterId)))
          .go();

  Future<void> setPrimaryGalleryImage(int characterId, int galleryId) =>
      transaction(() async {
        final item = await (select(characterGalleries)
              ..where((t) => t.id.equals(galleryId)))
            .getSingleOrNull();
        if (item == null) return;

        await (update(characterGalleries)
              ..where((t) => t.characterId.equals(characterId)))
            .write(const CharacterGalleriesCompanion(isPrimary: Value(false)));

        await (update(characterGalleries)..where((t) => t.id.equals(galleryId)))
            .write(const CharacterGalleriesCompanion(isPrimary: Value(true)));

        await updatePartial(
          characterId,
          CharactersCompanion(
            avatarPath: Value(item.imagePath),
            updatedAt: Value(DateTime.now()),
          ),
        );
      });
}
