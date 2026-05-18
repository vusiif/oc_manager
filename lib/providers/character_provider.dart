import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';
import 'trash_provider.dart';

final charactersByWorldProvider =
    StreamProvider.family<List<Character>, int>((ref, worldId) {
  return ref.watch(characterDaoProvider).watchCharactersByWorld(worldId);
});

final characterByIdProvider =
    FutureProvider.family<Character, int>((ref, id) {
  return ref.watch(characterDaoProvider).getCharacterById(id);
});

final characterFieldsProvider =
    StreamProvider.family<List<CharacterField>, int>((ref, characterId) {
  return ref.watch(characterDaoProvider).watchCharacterFields(characterId);
});

final characterActionsProvider = Provider((ref) => CharacterActions(ref));

class CharacterActions {
  final Ref _ref;

  CharacterActions(this._ref);

  Future<int> create({
    required int worldId,
    required String name,
    int status = 0,
    String gender = '',
  }) async {
    return _ref.read(characterDaoProvider).createCharacter(
          CharactersCompanion(
            worldId: Value(worldId),
            name: Value(name),
            status: Value(status),
            gender: Value(gender),
          ),
        );
  }

  Future<bool> update(Character character) async {
    return _ref.read(characterDaoProvider).updateCharacter(
          CharactersCompanion(
            id: Value(character.id),
            worldId: Value(character.worldId),
            name: Value(character.name),
            avatarPath: Value(character.avatarPath),
            gender: Value(character.gender),
            status: Value(character.status),
            isFavorite: Value(character.isFavorite),
            isPinned: Value(character.isPinned),
            createdAt: Value(character.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> delete(int id) async {
    final character =
        await _ref.read(characterDaoProvider).getCharacterById(id);
    await _ref.read(trashActionsProvider).deleteCharacter(character);
  }

  Future<void> toggleFavorite(Character character) async {
    await _ref.read(characterDaoProvider).updateCharacter(
          CharactersCompanion(
            id: Value(character.id),
            worldId: Value(character.worldId),
            name: Value(character.name),
            avatarPath: Value(character.avatarPath),
            status: Value(character.status),
            isFavorite: Value(!character.isFavorite),
            isPinned: Value(character.isPinned),
            createdAt: Value(character.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> togglePin(Character character) async {
    await _ref.read(characterDaoProvider).updateCharacter(
          CharactersCompanion(
            id: Value(character.id),
            worldId: Value(character.worldId),
            name: Value(character.name),
            avatarPath: Value(character.avatarPath),
            status: Value(character.status),
            isFavorite: Value(character.isFavorite),
            isPinned: Value(!character.isPinned),
            createdAt: Value(character.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateField(
      int characterId, String fieldName, String fieldType, String? value) async {
    final fields = await _ref
        .read(characterDaoProvider)
        .getCharacterFields(characterId);
    final existing = fields.where((f) => f.fieldName == fieldName).firstOrNull;

    if (existing != null) {
      await _ref.read(characterDaoProvider).updateCharacterField(
            CharacterFieldsCompanion(
              id: Value(existing.id),
              characterId: Value(existing.characterId),
              fieldName: Value(existing.fieldName),
              fieldType: Value(existing.fieldType),
              value: Value(value),
            ),
          );
    } else {
      await _ref.read(characterDaoProvider).createCharacterField(
            CharacterFieldsCompanion(
              characterId: Value(characterId),
              fieldName: Value(fieldName),
              fieldType: Value(fieldType),
              value: Value(value),
            ),
          );
    }
  }
}
