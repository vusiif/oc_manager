import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/characters.dart';
import '../tables/lore.dart';

part 'lore_dao.g.dart';

/// 实体关联角色视图模型
class LoreCharacterMember {
  final Character character;
  final LoreRelation relation;

  const LoreCharacterMember({required this.character, required this.relation});
}

/// 角色所属实体视图模型
class CharacterLoreAffiliation {
  final LoreEntity lore;
  final LoreRelation relation;

  const CharacterLoreAffiliation({required this.lore, required this.relation});
}

/// 百科实体相互关系视图模型 (LORE-003: 势力间同盟/敌对/从属/贸易关系)
class LoreEntityRelationItem {
  final LoreEntity otherEntity;
  final LoreEntityRelation relation;
  final bool isOutgoing;

  const LoreEntityRelationItem({
    required this.otherEntity,
    required this.relation,
    required this.isOutgoing,
  });
}

@DriftAccessor(
  tables: [LoreEntities, LoreRelations, LoreEntityRelations, Characters],
)
class LoreDao extends DatabaseAccessor<AppDatabase> with _$LoreDaoMixin {
  LoreDao(super.db);

  Future<List<LoreEntity>> getEntitiesByWorld(
    int worldId, {
    String? entityType,
  }) {
    final query = select(loreEntities)..where((t) => t.worldId.equals(worldId));
    if (entityType != null && entityType.isNotEmpty && entityType != 'all') {
      query.where((t) => t.entityType.equals(entityType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Stream<List<LoreEntity>> watchEntitiesByWorld(
    int worldId, {
    String? entityType,
  }) {
    final query = select(loreEntities)..where((t) => t.worldId.equals(worldId));
    if (entityType != null && entityType.isNotEmpty && entityType != 'all') {
      query.where((t) => t.entityType.equals(entityType));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<LoreEntity?> getEntityById(int id) =>
      (select(loreEntities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LoreEntity>> getEntitiesByName(int worldId, String name) =>
      (select(
        loreEntities,
      )..where((t) => t.worldId.equals(worldId) & t.name.equals(name))).get();

  Future<List<LoreEntity>> searchEntities(int worldId, String query) {
    final pattern = '%$query%';
    return (select(loreEntities)..where(
          (t) =>
              t.worldId.equals(worldId) &
              (t.name.like(pattern) |
                  t.summary.like(pattern) |
                  t.content.like(pattern) |
                  t.tags.like(pattern)),
        ))
        .get();
  }

  Future<int> createEntity(LoreEntitiesCompanion entry) =>
      into(loreEntities).insert(entry);

  Future<bool> updateEntity(LoreEntitiesCompanion entry) =>
      update(loreEntities).replace(entry);

  /// 级联清理并安全删除实体 (包含关系解除与子级脱钩)
  Future<int> deleteEntity(int id) async {
    return transaction(() async {
      // 1. 先解除所有引用该实体的 LoreRelations 与 LoreEntityRelations
      await (delete(loreRelations)..where((r) => r.loreId.equals(id))).go();
      await (delete(
        loreEntityRelations,
      )..where((r) => r.fromLoreId.equals(id) | r.toLoreId.equals(id))).go();

      // 2. 将以该实体为父级的子实体的 parentId 置空，防止悬空外键
      await (update(loreEntities)..where((t) => t.parentId.equals(id))).write(
        const LoreEntitiesCompanion(parentId: Value(null)),
      );

      // 2.5 将引用该实体为地点 (locationId) 的故事场景置空，防止外键约束失败
      await (db.update(db.storyScenes)..where((s) => s.locationId.equals(id)))
          .write(const StoryScenesCompanion(locationId: Value(null)));

      // 3. 最终删除实体本身
      return (delete(loreEntities)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<int> deleteEntitiesByWorld(int worldId) async {
    return transaction(() async {
      final entities = await (select(
        loreEntities,
      )..where((t) => t.worldId.equals(worldId))).get();
      final entityIds = entities.map((e) => e.id).toSet();
      if (entityIds.isNotEmpty) {
        await (db.update(db.storyScenes)
              ..where((s) => s.locationId.isIn(entityIds)))
            .write(const StoryScenesCompanion(locationId: Value(null)));
      }
      await (delete(
        loreEntityRelations,
      )..where((r) => r.worldId.equals(worldId))).go();
      await (delete(
        loreRelations,
      )..where((r) => r.worldId.equals(worldId))).go();
      return (delete(
        loreEntities,
      )..where((t) => t.worldId.equals(worldId))).go();
    });
  }

  // ==========================================
  // LORE-002: 地点/组织层级结构管理 (Hierarchy)
  // ==========================================

  /// 查询指定实体的直接子级列表 (如国家下的城市、组织下的分部)
  Future<List<LoreEntity>> getChildEntities(int parentId) {
    return (select(loreEntities)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// 监听指定实体的子级列表
  Stream<List<LoreEntity>> watchChildEntities(int parentId) {
    return (select(loreEntities)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// 向上获取祖先链路 (从当前节点向上回溯至顶级根节点，用于面包屑)
  Future<List<LoreEntity>> getAncestors(int entityId) async {
    final ancestors = <LoreEntity>[];
    var current = await getEntityById(entityId);
    final visited = <int>{entityId};

    while (current?.parentId != null) {
      final pid = current!.parentId!;
      if (visited.contains(pid)) break; // 防循环死链
      visited.add(pid);

      final parent = await getEntityById(pid);
      if (parent != null) {
        ancestors.insert(0, parent);
        current = parent;
      } else {
        break;
      }
    }
    return ancestors;
  }

  /// 获取可选作为父级的候选实体列表 (同类型、排除自身以及自身所有后代，彻底杜绝成环)
  Future<List<LoreEntity>> getAvailableParents(
    int worldId, {
    int? currentEntityId,
    String? entityType,
  }) async {
    final all = await getEntitiesByWorld(worldId, entityType: entityType);
    if (currentEntityId == null) return all;

    // 找出所有子孙节点的 ID 集合
    final descendantIds = <int>{currentEntityId};
    var added = true;
    while (added) {
      added = false;
      for (final e in all) {
        if (e.parentId != null &&
            descendantIds.contains(e.parentId) &&
            !descendantIds.contains(e.id)) {
          descendantIds.add(e.id);
          added = true;
        }
      }
    }

    return all.where((e) => !descendantIds.contains(e.id)).toList();
  }

  // =========================================================
  // LORE-002 & LORE-003: 稳定 ID 关联人物 (Lore-Character Relations)
  // =========================================================

  /// 添加或更新实体与人物的关联 (如常驻人物、组织领袖、成员)
  Future<int> addCharacterRelation({
    required int worldId,
    required int loreId,
    required int characterId,
    String role = '成员',
  }) async {
    return into(loreRelations).insertOnConflictUpdate(
      LoreRelationsCompanion(
        worldId: Value(worldId),
        loreId: Value(loreId),
        characterId: Value(characterId),
        role: Value(role),
      ),
    );
  }

  /// 移除实体与人物的关联
  Future<int> removeCharacterRelation(int loreId, int characterId) {
    return (delete(loreRelations)..where(
          (r) => r.loreId.equals(loreId) & r.characterId.equals(characterId),
        ))
        .go();
  }

  /// 查询实体关联的所有人物详情与职务 (JOIN 查询)
  Future<List<LoreCharacterMember>> getCharactersByLore(int loreId) async {
    final query = select(loreRelations).join([
      innerJoin(characters, characters.id.equalsExp(loreRelations.characterId)),
    ])..where(loreRelations.loreId.equals(loreId));

    query.orderBy([OrderingTerm.asc(loreRelations.id)]);

    final rows = await query.get();
    return rows.map((row) {
      return LoreCharacterMember(
        character: row.readTable(characters),
        relation: row.readTable(loreRelations),
      );
    }).toList();
  }

  /// 监听实体关联的人物列表
  Stream<List<LoreCharacterMember>> watchCharactersByLore(int loreId) {
    final query = select(loreRelations).join([
      innerJoin(characters, characters.id.equalsExp(loreRelations.characterId)),
    ])..where(loreRelations.loreId.equals(loreId));

    query.orderBy([OrderingTerm.asc(loreRelations.id)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return LoreCharacterMember(
          character: row.readTable(characters),
          relation: row.readTable(loreRelations),
        );
      }).toList();
    });
  }

  /// 查询指定角色关联的所有百科实体 (如所属势力、常驻地点)
  Future<List<CharacterLoreAffiliation>> getLoresByCharacter(
    int characterId,
  ) async {
    final query = select(loreRelations).join([
      innerJoin(loreEntities, loreEntities.id.equalsExp(loreRelations.loreId)),
    ])..where(loreRelations.characterId.equals(characterId));

    query.orderBy([OrderingTerm.asc(loreRelations.id)]);

    final rows = await query.get();
    return rows.map((row) {
      return CharacterLoreAffiliation(
        lore: row.readTable(loreEntities),
        relation: row.readTable(loreRelations),
      );
    }).toList();
  }

  /// 监听角色关联的所有百科实体
  Stream<List<CharacterLoreAffiliation>> watchLoresByCharacter(
    int characterId,
  ) {
    final query = select(loreRelations).join([
      innerJoin(loreEntities, loreEntities.id.equalsExp(loreRelations.loreId)),
    ])..where(loreRelations.characterId.equals(characterId));

    query.orderBy([OrderingTerm.asc(loreRelations.id)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CharacterLoreAffiliation(
          lore: row.readTable(loreEntities),
          relation: row.readTable(loreRelations),
        );
      }).toList();
    });
  }

  // =========================================================
  // LORE-003: 实体间相互关系 (如势力同盟/敌对/从属/贸易关系)
  // =========================================================

  /// 添加或更新实体间关系
  Future<int> addEntityRelation({
    required int worldId,
    required int fromLoreId,
    required int toLoreId,
    String relationType = '同盟',
    bool isBidirectional = true,
    String note = '',
  }) async {
    return into(loreEntityRelations).insert(
      LoreEntityRelationsCompanion.insert(
        worldId: worldId,
        fromLoreId: fromLoreId,
        toLoreId: toLoreId,
        relationType: Value(relationType),
        isBidirectional: Value(isBidirectional),
        note: Value(note),
      ),
    );
  }

  /// 移除实体间关系
  Future<int> removeEntityRelation(int relationId) {
    return (delete(
      loreEntityRelations,
    )..where((r) => r.id.equals(relationId))).go();
  }

  /// 查询指定实体关联的所有其他实体及关系类型 (合并作为发起方与接收方的关系)
  Future<List<LoreEntityRelationItem>> getEntityRelations(int loreId) async {
    final items = <LoreEntityRelationItem>[];

    // 1. 作为发起方 (fromLoreId == loreId)
    final outgoingQuery = select(loreEntityRelations).join([
      innerJoin(
        loreEntities,
        loreEntities.id.equalsExp(loreEntityRelations.toLoreId),
      ),
    ])..where(loreEntityRelations.fromLoreId.equals(loreId));

    final outgoingRows = await outgoingQuery.get();
    for (final row in outgoingRows) {
      items.add(
        LoreEntityRelationItem(
          otherEntity: row.readTable(loreEntities),
          relation: row.readTable(loreEntityRelations),
          isOutgoing: true,
        ),
      );
    }

    // 2. 作为接收方 (toLoreId == loreId)
    final incomingQuery = select(loreEntityRelations).join([
      innerJoin(
        loreEntities,
        loreEntities.id.equalsExp(loreEntityRelations.fromLoreId),
      ),
    ])..where(loreEntityRelations.toLoreId.equals(loreId));

    final incomingRows = await incomingQuery.get();
    for (final row in incomingRows) {
      final rel = row.readTable(loreEntityRelations);
      if (!items.any((item) => item.relation.id == rel.id)) {
        items.add(
          LoreEntityRelationItem(
            otherEntity: row.readTable(loreEntities),
            relation: rel,
            isOutgoing: false,
          ),
        );
      }
    }

    return items;
  }

  /// 响应式监听指定实体关联的外交/地缘关系
  Stream<List<LoreEntityRelationItem>> watchEntityRelations(int loreId) {
    return (select(loreEntityRelations)..where(
          (r) => r.fromLoreId.equals(loreId) | r.toLoreId.equals(loreId),
        ))
        .watch()
        .asyncMap((_) => getEntityRelations(loreId));
  }

  // =========================================================
  // LORE-007: 世界观全景关联查询 (用于知识网络视图 Knowledge Network)
  // =========================================================

  /// 查询指定世界观下的所有人物-实体关联 (LoreRelations)
  Future<List<LoreRelation>> getLoreRelationsByWorld(int worldId) {
    return (select(
      loreRelations,
    )..where((r) => r.worldId.equals(worldId))).get();
  }

  /// 监听指定世界观下的所有人物-实体关联
  Stream<List<LoreRelation>> watchLoreRelationsByWorld(int worldId) {
    return (select(
      loreRelations,
    )..where((r) => r.worldId.equals(worldId))).watch();
  }

  /// 查询指定世界观下的所有实体间相互关联 (LoreEntityRelations)
  Future<List<LoreEntityRelation>> getLoreEntityRelationsByWorld(int worldId) {
    return (select(
      loreEntityRelations,
    )..where((r) => r.worldId.equals(worldId))).get();
  }

  /// 监听指定世界观下的所有实体间相互关联
  Stream<List<LoreEntityRelation>> watchLoreEntityRelationsByWorld(
    int worldId,
  ) {
    return (select(
      loreEntityRelations,
    )..where((r) => r.worldId.equals(worldId))).watch();
  }
}
