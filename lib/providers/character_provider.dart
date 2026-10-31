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

final characterStatsProvider =
    StreamProvider.family<List<CharacterStat>, int>((ref, characterId) {
  return ref.watch(characterDaoProvider).watchCharacterStats(characterId);
});

final characterGalleriesProvider =
    StreamProvider.family<List<CharacterGallery>, int>((ref, characterId) {
  return ref.watch(characterDaoProvider).watchCharacterGalleries(characterId);
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
    String? avatarPath,
  }) async {
    return _ref.read(characterDaoProvider).createCharacter(
          CharactersCompanion(
            worldId: Value(worldId),
            name: Value(name),
            status: Value(status),
            gender: Value(gender),
            avatarPath: Value(avatarPath),
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
            description: Value(character.description),
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
    await _ref.read(characterDaoProvider).updatePartial(
          character.id,
          CharactersCompanion(
            isFavorite: Value(!character.isFavorite),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> togglePin(Character character) async {
    await _ref.read(characterDaoProvider).updatePartial(
          character.id,
          CharactersCompanion(
            isPinned: Value(!character.isPinned),
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

  Future<void> setStats(
    int characterId,
    List<CharacterStatsCompanion> stats,
  ) async {
    await _ref
        .read(characterDaoProvider)
        .setCharacterStats(characterId, stats);
  }

  Future<void> updateStat(CharacterStatsCompanion stat) async {
    await _ref.read(characterDaoProvider).updateCharacterStat(stat);
  }

  Future<int> addStat(CharacterStatsCompanion stat) async {
    return _ref.read(characterDaoProvider).createCharacterStat(stat);
  }

  Future<void> deleteStat(int statId) async {
    await _ref.read(characterDaoProvider).deleteCharacterStat(statId);
  }

  Future<int> addGalleryImage({
    required int characterId,
    required String imagePath,
    String caption = '',
    bool isPrimary = false,
  }) async {
    final dao = _ref.read(characterDaoProvider);
    final count = (await dao.getCharacterGalleries(characterId)).length;
    final id = await dao.addGalleryImage(
      CharacterGalleriesCompanion.insert(
        characterId: characterId,
        imagePath: imagePath,
        caption: Value(caption),
        isPrimary: Value(isPrimary),
        sortOrder: Value(count),
      ),
    );
    if (isPrimary) {
      await dao.setPrimaryGalleryImage(characterId, id);
    }
    return id;
  }

  Future<void> updateGalleryCaption(int galleryId, String caption) async {
    final dao = _ref.read(characterDaoProvider);
    final item = await (dao.select(dao.characterGalleries)
          ..where((t) => t.id.equals(galleryId)))
        .getSingleOrNull();
    if (item != null) {
      await dao.updateGalleryImage(
        CharacterGalleriesCompanion(
          id: Value(item.id),
          characterId: Value(item.characterId),
          imagePath: Value(item.imagePath),
          caption: Value(caption),
          isPrimary: Value(item.isPrimary),
          sortOrder: Value(item.sortOrder),
          createdAt: Value(item.createdAt),
        ),
      );
    }
  }

  Future<void> deleteGalleryImage(int galleryId) async {
    await _ref.read(characterDaoProvider).deleteGalleryImage(galleryId);
  }

  Future<void> setPrimaryGalleryImage(int characterId, int galleryId) async {
    await _ref
        .read(characterDaoProvider)
        .setPrimaryGalleryImage(characterId, galleryId);
  }
}
