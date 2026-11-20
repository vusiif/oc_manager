import 'dart:ui' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

// --- 关系 ---

final relationsByWorldProvider = FutureProvider.family<List<Relation>, int>((
  ref,
  worldId,
) {
  return ref.watch(relationDaoProvider).getRelationsByWorld(worldId);
});

final relationsByCharacterProvider = FutureProvider.family<List<Relation>, int>(
  (ref, characterId) {
    return ref.watch(relationDaoProvider).getRelationsByCharacter(characterId);
  },
);

final relationActionsProvider = Provider((ref) => RelationActions(ref));

class RelationActions {
  final Ref _ref;

  RelationActions(this._ref);

  Future<int> create({
    required int fromCharacterId,
    required int toCharacterId,
    required String relationType,
    bool isBidirectional = true,
    String? note,
    String? relationGroupId,
  }) async {
    if (fromCharacterId == toCharacterId) {
      throw ArgumentError(
        'Cannot create a relation from a character to themselves.',
      );
    }

    final charDao = _ref.read(characterDaoProvider);
    final chars = await charDao.getCharactersByIds([
      fromCharacterId,
      toCharacterId,
    ]);
    if (chars.length < 2) {
      throw ArgumentError('Both characters must exist to create a relation.');
    }
    if (chars[0].worldId != chars[1].worldId) {
      throw ArgumentError(
        'Characters must belong to the same world to create a relation.',
      );
    }

    final id = await _ref
        .read(relationDaoProvider)
        .createRelation(
          RelationsCompanion(
            fromCharacterId: Value(fromCharacterId),
            toCharacterId: Value(toCharacterId),
            relationType: Value(relationType),
            isBidirectional: Value(isBidirectional),
            note: Value(note),
            relationGroupId: Value(relationGroupId),
          ),
        );
    return id;
  }

  /// 创建多人关系：以 hubId 为中心，hubId 与其他每个 characterId 各建一条 pair relation
  Future<void> createGroupRelation({
    required int hubId,
    required List<int> characterIds,
    required String relationType,
    bool isBidirectional = true,
    String? note,
  }) async {
    final distinctIds = characterIds
        .where((id) => id != hubId)
        .toSet()
        .toList();
    if (distinctIds.isEmpty) return;

    final charDao = _ref.read(characterDaoProvider);
    final allIds = {hubId, ...distinctIds}.toList();
    final chars = await charDao.getCharactersByIds(allIds);
    if (chars.length != allIds.length) {
      throw ArgumentError(
        'All characters must exist to create group relations.',
      );
    }
    final worldId = chars.first.worldId;
    if (chars.any((c) => c.worldId != worldId)) {
      throw ArgumentError(
        'All characters in a group relation must belong to the same world.',
      );
    }

    final groupId = DateTime.now().microsecondsSinceEpoch.toString();
    for (final cid in distinctIds) {
      await _ref
          .read(relationDaoProvider)
          .createRelation(
            RelationsCompanion(
              fromCharacterId: Value(hubId),
              toCharacterId: Value(cid),
              relationType: Value(relationType),
              isBidirectional: Value(isBidirectional),
              note: Value(note),
              relationGroupId: Value(groupId),
            ),
          );
    }
  }

  /// 创建家谱关系：每个父母到每个子女各一条 relation，共用 groupId
  Future<List<Relation>> createFamilyRelation({
    required List<int> parentIds,
    required List<int> childIds,
    String? note,
  }) async {
    final parentSet = parentIds.toSet();
    final childSet = childIds.toSet();
    if (parentSet.isEmpty || childSet.isEmpty) {
      throw ArgumentError(
        'Family relation requires at least one parent and one child.',
      );
    }
    if (parentSet.intersection(childSet).isNotEmpty) {
      throw ArgumentError(
        'A character cannot be both a parent and a child in the same family relation.',
      );
    }

    final allIds = parentSet.union(childSet).toList();
    final charDao = _ref.read(characterDaoProvider);
    final chars = await charDao.getCharactersByIds(allIds);
    if (chars.length != allIds.length) {
      throw ArgumentError(
        'All characters must exist to create family relations.',
      );
    }
    final worldId = chars.first.worldId;
    if (chars.any((c) => c.worldId != worldId)) {
      throw ArgumentError('All family members must belong to the same world.');
    }

    final List<Relation> createdRelations = [];
    final groupId = 'family_${DateTime.now().microsecondsSinceEpoch}';
    for (final pid in parentSet) {
      for (final cid in childSet) {
        final id = await _ref
            .read(relationDaoProvider)
            .createRelation(
              RelationsCompanion(
                fromCharacterId: Value(pid),
                toCharacterId: Value(cid),
                relationType: const Value('亲子'),
                isBidirectional: const Value(false),
                note: Value(note),
                relationGroupId: Value(groupId),
              ),
            );
        createdRelations.add(
          Relation(
            id: id,
            fromCharacterId: pid,
            toCharacterId: cid,
            relationType: '亲子',
            isBidirectional: false,
            note: note,
            relationGroupId: groupId,
          ),
        );
      }
    }
    return createdRelations;
  }

  Future<bool> update(Relation relation) async {
    return _ref
        .read(relationDaoProvider)
        .updateRelation(
          RelationsCompanion(
            id: Value(relation.id),
            fromCharacterId: Value(relation.fromCharacterId),
            toCharacterId: Value(relation.toCharacterId),
            relationType: Value(relation.relationType),
            isBidirectional: Value(relation.isBidirectional),
            note: Value(relation.note),
          ),
        );
  }

  Future<void> restore(Relation relation) async {
    await _ref
        .read(relationDaoProvider)
        .createRelation(
          RelationsCompanion(
            id: Value(relation.id),
            fromCharacterId: Value(relation.fromCharacterId),
            toCharacterId: Value(relation.toCharacterId),
            relationType: Value(relation.relationType),
            isBidirectional: Value(relation.isBidirectional),
            note: Value(relation.note),
            relationGroupId: Value(relation.relationGroupId),
          ),
        );
  }

  Future<void> delete(int id) async {
    await _ref.read(relationDaoProvider).deleteRelation(id);
  }
}

// --- 图画布管理 (Multiple Named Canvases) ---

final canvasesByWorldProvider = StreamProvider.family<List<GraphCanvas>, int>((
  ref,
  worldId,
) {
  return ref.watch(canvasDaoProvider).watchCanvasesByWorld(worldId);
});

final activeCanvasIdProvider = StateProvider.family<int?, int>((ref, worldId) {
  return null;
});

final layoutsByCanvasProvider = FutureProvider.family<List<GraphLayout>, int>((
  ref,
  canvasId,
) {
  return ref.watch(canvasDaoProvider).getLayoutsByCanvas(canvasId);
});

final canvasActionsProvider = Provider((ref) => CanvasActions(ref));

class CanvasActions {
  final Ref _ref;

  CanvasActions(this._ref);

  Future<GraphCanvas> ensureDefault(int worldId) async {
    return _ref.read(canvasDaoProvider).ensureDefaultCanvas(worldId);
  }

  Future<GraphCanvas> create(
    int worldId,
    String name, {
    String? description,
  }) async {
    final now = DateTime.now();
    final id = await _ref
        .read(canvasDaoProvider)
        .createCanvas(
          GraphCanvasesCompanion(
            worldId: Value(worldId),
            name: Value(name),
            description: Value(description),
            isDefault: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (await _ref.read(canvasDaoProvider).getCanvasById(id))!;
  }

  Future<void> rename(int canvasId, String newName, {String? newDesc}) async {
    final canvas = await _ref.read(canvasDaoProvider).getCanvasById(canvasId);
    if (canvas == null) return;
    await _ref
        .read(canvasDaoProvider)
        .updateCanvas(
          GraphCanvasesCompanion(
            id: Value(canvas.id),
            worldId: Value(canvas.worldId),
            name: Value(newName),
            description: Value(newDesc ?? canvas.description),
            isDefault: Value(canvas.isDefault),
            viewportX: Value(canvas.viewportX),
            viewportY: Value(canvas.viewportY),
            zoomScale: Value(canvas.zoomScale),
            filterConfig: Value(canvas.filterConfig),
            createdAt: Value(canvas.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<GraphCanvas> duplicate(int sourceCanvasId, String newName) async {
    return _ref
        .read(canvasDaoProvider)
        .duplicateCanvas(sourceCanvasId, newName);
  }

  Future<void> setDefault(int worldId, int canvasId) async {
    await _ref.read(canvasDaoProvider).setDefaultCanvas(worldId, canvasId);
  }

  Future<void> delete(int canvasId) async {
    await _ref.read(canvasDaoProvider).deleteCanvas(canvasId);
  }

  Future<void> saveViewport(
    int canvasId,
    double x,
    double y,
    double scale,
  ) async {
    await _ref
        .read(canvasDaoProvider)
        .updateViewport(canvasId, x: x, y: y, scale: scale);
  }

  Future<void> saveFilterConfig(int canvasId, String? filterConfigJson) async {
    await _ref
        .read(canvasDaoProvider)
        .updateFilterConfig(canvasId, filterConfigJson);
  }
}

// --- 图布局 ---

final graphLayoutsProvider = FutureProvider.family<List<GraphLayout>, int>((
  ref,
  worldId,
) {
  return ref.watch(trashDaoProvider).getLayoutsByWorld(worldId);
});

final graphLayoutActionsProvider = Provider((ref) => GraphLayoutActions(ref));

class GraphLayoutActions {
  final Ref _ref;

  GraphLayoutActions(this._ref);

  Future<void> savePosition(
    int worldId,
    int characterId,
    double x,
    double y, {
    int? canvasId,
  }) async {
    if (canvasId != null) {
      await _ref
          .read(canvasDaoProvider)
          .savePosition(
            worldId: worldId,
            canvasId: canvasId,
            characterId: characterId,
            x: x,
            y: y,
          );
      _ref.invalidate(layoutsByCanvasProvider(canvasId));
    } else {
      await _ref
          .read(trashDaoProvider)
          .saveLayout(
            GraphLayoutsCompanion(
              worldId: Value(worldId),
              characterId: Value(characterId),
              x: Value(x),
              y: Value(y),
            ),
          );
      _ref.invalidate(graphLayoutsProvider(worldId));
    }
  }

  Future<void> batchSavePositions(
    int worldId,
    Map<int, Offset> positions, {
    int? canvasId,
  }) async {
    if (canvasId != null) {
      await _ref
          .read(canvasDaoProvider)
          .batchSavePositions(worldId, canvasId, positions);
      _ref.invalidate(layoutsByCanvasProvider(canvasId));
    } else {
      await _ref.read(trashDaoProvider).batchSaveLayouts(worldId, positions);
      _ref.invalidate(graphLayoutsProvider(worldId));
    }
  }

  Future<int> cleanupDuplicates({int? worldId}) async {
    return _ref
        .read(trashDaoProvider)
        .cleanupDuplicateLayouts(worldId: worldId);
  }

  Future<void> removePosition(
    int worldId,
    int characterId, {
    int? canvasId,
  }) async {
    if (canvasId != null) {
      await _ref.read(canvasDaoProvider).deletePosition(canvasId, characterId);
      _ref.invalidate(layoutsByCanvasProvider(canvasId));
    } else {
      await _ref.read(trashDaoProvider).deleteLayout(worldId, characterId);
      _ref.invalidate(graphLayoutsProvider(worldId));
    }
  }
}
