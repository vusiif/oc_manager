import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tags.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags, CharacterTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<Tag>> getAllTags() => select(tags).get();

  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  Future<int> createTag(TagsCompanion entry) => into(tags).insert(entry);

  Future<bool> updateTag(TagsCompanion entry) => update(tags).replace(entry);

  Future<int> deleteTag(int id) {
    return transaction(() async {
      await (delete(characterTags)..where((t) => t.tagId.equals(id))).go();
      return (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> addTagToCharacter(int characterId, int tagId) =>
      into(characterTags).insert(
        CharacterTagsCompanion.insert(
          characterId: characterId,
          tagId: tagId,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> removeTagFromCharacter(int characterId, int tagId) =>
      (delete(characterTags)
            ..where((t) =>
                t.characterId.equals(characterId) &
                t.tagId.equals(tagId)))
          .go();

  Future<List<Tag>> getTagsByCharacter(int characterId) async {
    final query = select(tags).join([
      innerJoin(
          characterTags, characterTags.tagId.equalsExp(tags.id)),
    ])
      ..where(characterTags.characterId.equals(characterId));
    final results = await query.get();
    return results.map((row) => row.readTable(tags)).toList();
  }

  Future<List<int>> getCharacterIdsByTag(int tagId) async {
    final results = await (select(characterTags)
          ..where((t) => t.tagId.equals(tagId)))
        .get();
    return results.map((row) => row.characterId).toList();
  }
}
