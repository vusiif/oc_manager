import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database/app_database.dart';
import '../data/database/daos/lore_dao.dart';
import 'database_provider.dart';

export '../data/database/daos/lore_dao.dart';

enum LoreEntityType {
  location('location', '地点', Icons.location_on, Color(0xFF10B981)),
  faction('faction', '组织', Icons.shield, Color(0xFF6366F1)),
  race('race', '种族', Icons.diversity_3, Color(0xFFF59E0B)),
  item('item', '物品', Icons.diamond, Color(0xFFEC4899)),
  ability('ability', '能力', Icons.auto_awesome, Color(0xFF8B5CF6)),
  other('other', '其他', Icons.menu_book, Color(0xFF64748B));

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const LoreEntityType(this.key, this.label, this.icon, this.color);

  static LoreEntityType fromKey(String key) {
    return LoreEntityType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => LoreEntityType.other,
    );
  }
}

final loreEntitiesByWorldProvider =
    FutureProvider.family<List<LoreEntity>, int>((ref, worldId) {
      return ref.watch(loreDaoProvider).getEntitiesByWorld(worldId);
    });

final loreEntitiesByTypeProvider =
    FutureProvider.family<
      List<LoreEntity>,
      ({int worldId, String? entityType})
    >((ref, arg) {
      return ref
          .watch(loreDaoProvider)
          .getEntitiesByWorld(arg.worldId, entityType: arg.entityType);
    });

final loreChildEntitiesProvider = StreamProvider.family<List<LoreEntity>, int>((
  ref,
  parentId,
) {
  return ref.watch(loreDaoProvider).watchChildEntities(parentId);
});

final loreAncestorsProvider = FutureProvider.family<List<LoreEntity>, int>((
  ref,
  entityId,
) {
  return ref.watch(loreDaoProvider).getAncestors(entityId);
});

final loreCharactersProvider =
    StreamProvider.family<List<LoreCharacterMember>, int>((ref, loreId) {
      return ref.watch(loreDaoProvider).watchCharactersByLore(loreId);
    });

final characterLoresProvider =
    StreamProvider.family<List<CharacterLoreAffiliation>, int>((
      ref,
      characterId,
    ) {
      return ref.watch(loreDaoProvider).watchLoresByCharacter(characterId);
    });

final loreEntityRelationsProvider =
    StreamProvider.family<List<LoreEntityRelationItem>, int>((ref, loreId) {
      return ref.watch(loreDaoProvider).watchEntityRelations(loreId);
    });

final worldLoreRelationsProvider =
    StreamProvider.family<List<LoreRelation>, int>((ref, worldId) {
      return ref.watch(loreDaoProvider).watchLoreRelationsByWorld(worldId);
    });

final worldLoreEntityRelationsProvider =
    StreamProvider.family<List<LoreEntityRelation>, int>((ref, worldId) {
      return ref
          .watch(loreDaoProvider)
          .watchLoreEntityRelationsByWorld(worldId);
    });

final loreActionsProvider = Provider((ref) => LoreActions(ref));

class LoreActions {
  final Ref _ref;

  LoreActions(this._ref);

  Future<int> createEntity({
    required int worldId,
    int? parentId,
    required String entityType,
    required String name,
    String summary = '',
    String content = '',
    String? coverImagePath,
    String tags = '',
    String customFields = '{}',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Entity name cannot be empty.');
    }

    final id = await _ref
        .read(loreDaoProvider)
        .createEntity(
          LoreEntitiesCompanion.insert(
            worldId: worldId,
            parentId: drift.Value(parentId),
            entityType: entityType,
            name: trimmedName,
            summary: drift.Value(summary.trim()),
            content: drift.Value(content.trim()),
            coverImagePath: drift.Value(coverImagePath),
            tags: drift.Value(tags.trim()),
            customFields: drift.Value(customFields),
          ),
        );
    _ref.invalidate(loreEntitiesByWorldProvider(worldId));
    return id;
  }

  Future<bool> updateEntity({
    required int id,
    required int worldId,
    int? parentId,
    required String entityType,
    required String name,
    String summary = '',
    String content = '',
    String? coverImagePath,
    String tags = '',
    String customFields = '{}',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Entity name cannot be empty.');
    }

    final result = await _ref
        .read(loreDaoProvider)
        .updateEntity(
          LoreEntitiesCompanion(
            id: drift.Value(id),
            worldId: drift.Value(worldId),
            parentId: drift.Value(parentId),
            entityType: drift.Value(entityType),
            name: drift.Value(trimmedName),
            summary: drift.Value(summary.trim()),
            content: drift.Value(content.trim()),
            coverImagePath: drift.Value(coverImagePath),
            tags: drift.Value(tags.trim()),
            customFields: drift.Value(customFields),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
    _ref.invalidate(loreEntitiesByWorldProvider(worldId));
    return result;
  }

  Future<int> deleteEntity(int id, {int? worldId}) async {
    final count = await _ref.read(loreDaoProvider).deleteEntity(id);
    if (worldId != null) {
      _ref.invalidate(loreEntitiesByWorldProvider(worldId));
    }
    return count;
  }

  // ==========================================
  // LORE-002 & LORE-003: 人物与实体稳定关联操作
  // ==========================================

  Future<int> linkCharacter({
    required int worldId,
    required int loreId,
    required int characterId,
    String role = '成员',
  }) async {
    return _ref
        .read(loreDaoProvider)
        .addCharacterRelation(
          worldId: worldId,
          loreId: loreId,
          characterId: characterId,
          role: role,
        );
  }

  Future<int> unlinkCharacter({
    required int loreId,
    required int characterId,
  }) async {
    return _ref
        .read(loreDaoProvider)
        .removeCharacterRelation(loreId, characterId);
  }

  // ==========================================
  // LORE-003: 势力间外交关系管理 (Faction Relations)
  // ==========================================

  Future<int> linkEntityRelation({
    required int worldId,
    required int fromLoreId,
    required int toLoreId,
    String relationType = '同盟',
    bool isBidirectional = true,
    String note = '',
  }) async {
    return _ref
        .read(loreDaoProvider)
        .addEntityRelation(
          worldId: worldId,
          fromLoreId: fromLoreId,
          toLoreId: toLoreId,
          relationType: relationType,
          isBidirectional: isBidirectional,
          note: note,
        );
  }

  Future<int> unlinkEntityRelation(int relationId) async {
    return _ref.read(loreDaoProvider).removeEntityRelation(relationId);
  }
}
