import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/characters.dart';

part 'character_dao.g.dart';

class CharacterSearchResult {
  final Character character;
  final String matchedField;
  final String matchedSnippet;

  const CharacterSearchResult({
    required this.character,
    required this.matchedField,
    required this.matchedSnippet,
  });
}

@DriftAccessor(
  tables: [Characters, CharacterFields, CharacterStats, CharacterGalleries],
)
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

  Future<List<CharacterField>> getCharacterFields(int characterId) => (select(
    characterFields,
  )..where((t) => t.characterId.equals(characterId))).get();

  Stream<List<CharacterField>> watchCharacterFields(int characterId) => (select(
    characterFields,
  )..where((t) => t.characterId.equals(characterId))).watch();

  Future<int> createCharacterField(CharacterFieldsCompanion entry) =>
      into(characterFields).insert(entry);

  Future<void> updateCharacterField(CharacterFieldsCompanion entry) =>
      update(characterFields).replace(entry);

  Future<int> deleteCharacterField(int id) =>
      (delete(characterFields)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllCharacterFields(int characterId) => (delete(
    characterFields,
  )..where((t) => t.characterId.equals(characterId))).go();

  Future<List<Character>> searchCharacters(String keyword) =>
      (select(characters)..where((t) => t.name.like('%$keyword%'))).get();

  /// Performs deep multi-field search (name, description, custom fields, tags, groups)
  /// with optional worldId and status filters.
  Future<List<CharacterSearchResult>> searchCharactersDeep(
    String keyword, {
    int? worldId,
    int? status,
  }) async {
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty) return [];

    final charQuery = select(characters);
    if (worldId != null) {
      charQuery.where((t) => t.worldId.equals(worldId));
    }
    if (status != null) {
      charQuery.where((t) => t.status.equals(status));
    }
    final allEligibleChars = await charQuery.get();
    if (allEligibleChars.isEmpty) return [];

    final eligibleCharIds = allEligibleChars.map((c) => c.id).toSet();
    final charMap = {for (final c in allEligibleChars) c.id: c};
    final results = <int, CharacterSearchResult>{};

    // 1. Name match
    for (final c in allEligibleChars) {
      if (c.name.toLowerCase().contains(kw)) {
        results[c.id] = CharacterSearchResult(
          character: c,
          matchedField: '角色姓名',
          matchedSnippet: c.name,
        );
      }
    }

    // 2. Description match
    for (final c in allEligibleChars) {
      if (!results.containsKey(c.id) &&
          c.description.isNotEmpty &&
          c.description.toLowerCase().contains(kw)) {
        final desc = c.description;
        final matchIdx = desc.toLowerCase().indexOf(kw);
        final start = matchIdx > 15 ? matchIdx - 15 : 0;
        final end = (matchIdx + kw.length + 20 < desc.length)
            ? matchIdx + kw.length + 20
            : desc.length;
        final snippet =
            '${start > 0 ? "..." : ""}${desc.substring(start, end)}${end < desc.length ? "..." : ""}';
        results[c.id] = CharacterSearchResult(
          character: c,
          matchedField: '人设小传',
          matchedSnippet: snippet,
        );
      }
    }

    // 3. Custom fields match
    final matchedFields =
        await (db.select(db.characterFields)..where(
              (f) =>
                  f.characterId.isIn(eligibleCharIds) &
                  (f.fieldName.like('%$kw%') | f.value.like('%$kw%')),
            ))
            .get();
    for (final f in matchedFields) {
      if (!results.containsKey(f.characterId)) {
        final c = charMap[f.characterId];
        if (c != null) {
          results[f.characterId] = CharacterSearchResult(
            character: c,
            matchedField: '自定义字段: ${f.fieldName}',
            matchedSnippet: f.value ?? f.fieldName,
          );
        }
      }
    }

    // 4. Tags match
    final matchedTags = await (db.select(
      db.tags,
    )..where((t) => t.name.like('%$kw%'))).get();
    if (matchedTags.isNotEmpty) {
      final tagIds = matchedTags.map((t) => t.id).toSet();
      final tagMap = {for (final t in matchedTags) t.id: t.name};
      final charTags =
          await (db.select(db.characterTags)..where(
                (ct) =>
                    ct.tagId.isIn(tagIds) &
                    ct.characterId.isIn(eligibleCharIds),
              ))
              .get();
      for (final ct in charTags) {
        if (!results.containsKey(ct.characterId)) {
          final c = charMap[ct.characterId];
          if (c != null) {
            results[ct.characterId] = CharacterSearchResult(
              character: c,
              matchedField: '所属标签',
              matchedSnippet: tagMap[ct.tagId] ?? '',
            );
          }
        }
      }
    }

    // 5. Groups match
    final matchedGroups = await (db.select(
      db.groups,
    )..where((g) => g.name.like('%$kw%'))).get();
    if (matchedGroups.isNotEmpty) {
      final groupIds = matchedGroups.map((g) => g.id).toSet();
      final groupMap = {for (final g in matchedGroups) g.id: g.name};
      final charGroups =
          await (db.select(db.characterGroups)..where(
                (cg) =>
                    cg.groupId.isIn(groupIds) &
                    cg.characterId.isIn(eligibleCharIds),
              ))
              .get();
      for (final cg in charGroups) {
        if (!results.containsKey(cg.characterId)) {
          final c = charMap[cg.characterId];
          if (c != null) {
            results[cg.characterId] = CharacterSearchResult(
              character: c,
              matchedField: '组织阵营',
              matchedSnippet: groupMap[cg.groupId] ?? '',
            );
          }
        }
      }
    }

    return results.values.toList();
  }

  Future<List<Character>> getFavoriteCharacters() =>
      (select(characters)..where((t) => t.isFavorite.equals(true))).get();

  Future<List<Character>> getDraftCharacters() =>
      (select(characters)..where((t) => t.status.equals(1))).get();

  Future<List<CharacterStat>> getCharacterStats(int characterId) =>
      (select(characterStats)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  Stream<List<CharacterStat>> watchCharacterStats(int characterId) =>
      (select(characterStats)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<int> createCharacterStat(CharacterStatsCompanion entry) =>
      into(characterStats).insert(entry);

  Future<void> updateCharacterStat(CharacterStatsCompanion entry) =>
      update(characterStats).replace(entry);

  Future<int> deleteCharacterStat(int id) =>
      (delete(characterStats)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllCharacterStats(int characterId) => (delete(
    characterStats,
  )..where((t) => t.characterId.equals(characterId))).go();

  Future<void> setCharacterStats(
    int characterId,
    List<CharacterStatsCompanion> stats,
  ) => transaction(() async {
    await deleteAllCharacterStats(characterId);
    for (var i = 0; i < stats.length; i++) {
      final s = stats[i];
      await into(characterStats).insert(
        s.copyWith(characterId: Value(characterId), sortOrder: Value(i)),
      );
    }
  });

  Future<List<CharacterGallery>> getCharacterGalleries(int characterId) =>
      (select(characterGalleries)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  Stream<List<CharacterGallery>> watchCharacterGalleries(int characterId) =>
      (select(characterGalleries)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<int> addGalleryImage(CharacterGalleriesCompanion entry) =>
      into(characterGalleries).insert(entry);

  Future<void> updateGalleryImage(CharacterGalleriesCompanion entry) =>
      update(characterGalleries).replace(entry);

  Future<int> deleteGalleryImage(int id) =>
      (delete(characterGalleries)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllGalleryImages(int characterId) => (delete(
    characterGalleries,
  )..where((t) => t.characterId.equals(characterId))).go();

  Future<void> setPrimaryGalleryImage(int characterId, int galleryId) =>
      transaction(() async {
        final item = await (select(
          characterGalleries,
        )..where((t) => t.id.equals(galleryId))).getSingleOrNull();
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
