import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagDaoProvider).watchAllTags();
});

final characterTagsProvider =
    FutureProvider.family<List<Tag>, int>((ref, characterId) {
  return ref.watch(tagDaoProvider).getTagsByCharacter(characterId);
});

final tagActionsProvider = Provider((ref) => TagActions(ref));

class TagActions {
  final Ref _ref;

  TagActions(this._ref);

  Future<int> create(String name, String color) async {
    return _ref.read(tagDaoProvider).createTag(
          TagsCompanion(
            name: Value(name),
            color: Value(color),
          ),
        );
  }

  Future<bool> update(Tag tag) async {
    return _ref.read(tagDaoProvider).updateTag(
          TagsCompanion(
            id: Value(tag.id),
            name: Value(tag.name),
            color: Value(tag.color),
          ),
        );
  }

  Future<void> delete(int id) async {
    await _ref.read(tagDaoProvider).deleteTag(id);
  }

  Future<void> addToCharacter(int characterId, int tagId) async {
    await _ref.read(tagDaoProvider).addTagToCharacter(characterId, tagId);
  }

  Future<void> removeFromCharacter(int characterId, int tagId) async {
    await _ref.read(tagDaoProvider).removeTagFromCharacter(characterId, tagId);
  }

  Future<List<int>> getCharacterIdsByTag(int tagId) async {
    return _ref.read(tagDaoProvider).getCharacterIdsByTag(tagId);
  }
}
