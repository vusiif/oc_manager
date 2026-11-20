import 'dart:ui' show Offset;
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/canvases.dart';
import '../tables/trash.dart';

part 'canvas_dao.g.dart';

@DriftAccessor(tables: [GraphCanvases, GraphLayouts])
class CanvasDao extends DatabaseAccessor<AppDatabase> with _$CanvasDaoMixin {
  CanvasDao(super.db);

  /// Gets all canvases belonging to a world, ordered by isDefault DESC, createdAt ASC
  Future<List<GraphCanvas>> getCanvasesByWorld(int worldId) {
    return (select(graphCanvases)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Stream<List<GraphCanvas>> watchCanvasesByWorld(int worldId) {
    return (select(graphCanvases)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<GraphCanvas?> getCanvasById(int id) {
    return (select(
      graphCanvases,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<GraphCanvas?> getDefaultCanvas(int worldId) {
    return (select(graphCanvases)
          ..where((t) => t.worldId.equals(worldId) & t.isDefault.equals(true)))
        .getSingleOrNull();
  }

  /// Ensures a default canvas exists for the world. If none exists, creates '主画布'.
  /// Also links any unassigned legacy layouts (canvasId is null) to this default canvas.
  Future<GraphCanvas> ensureDefaultCanvas(int worldId) async {
    final existingDefault = await getDefaultCanvas(worldId);
    if (existingDefault != null) {
      // Migrate any unlinked layouts
      await (update(graphLayouts)
            ..where((t) => t.worldId.equals(worldId) & t.canvasId.isNull()))
          .write(GraphLayoutsCompanion(canvasId: Value(existingDefault.id)));
      return existingDefault;
    }

    final allCanvases = await getCanvasesByWorld(worldId);
    if (allCanvases.isNotEmpty) {
      final first = allCanvases.first;
      await (update(graphCanvases)..where((t) => t.id.equals(first.id))).write(
        const GraphCanvasesCompanion(isDefault: Value(true)),
      );
      await (update(graphLayouts)
            ..where((t) => t.worldId.equals(worldId) & t.canvasId.isNull()))
          .write(GraphLayoutsCompanion(canvasId: Value(first.id)));
      return (await getCanvasById(first.id))!;
    }

    // Create a new default canvas
    final now = DateTime.now();
    final newId = await into(graphCanvases).insert(
      GraphCanvasesCompanion(
        worldId: Value(worldId),
        name: const Value('主画布'),
        description: const Value('默认全局关系网络画布'),
        isDefault: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // Link any legacy layouts to this new default canvas
    await (update(graphLayouts)
          ..where((t) => t.worldId.equals(worldId) & t.canvasId.isNull()))
        .write(GraphLayoutsCompanion(canvasId: Value(newId)));

    return (await getCanvasById(newId))!;
  }

  Future<int> createCanvas(GraphCanvasesCompanion entry) async {
    return into(graphCanvases).insert(entry);
  }

  Future<bool> updateCanvas(GraphCanvasesCompanion entry) async {
    return update(graphCanvases).replace(entry);
  }

  Future<void> setDefaultCanvas(int worldId, int canvasId) async {
    await db.transaction(() async {
      await (update(graphCanvases)..where((t) => t.worldId.equals(worldId)))
          .write(const GraphCanvasesCompanion(isDefault: Value(false)));
      await (update(graphCanvases)..where((t) => t.id.equals(canvasId))).write(
        const GraphCanvasesCompanion(isDefault: Value(true)),
      );
    });
  }

  Future<void> updateViewport(
    int canvasId, {
    required double x,
    required double y,
    required double scale,
  }) async {
    await (update(graphCanvases)..where((t) => t.id.equals(canvasId))).write(
      GraphCanvasesCompanion(
        viewportX: Value(x),
        viewportY: Value(y),
        zoomScale: Value(scale),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateFilterConfig(
    int canvasId,
    String? filterConfigJson,
  ) async {
    await (update(graphCanvases)..where((t) => t.id.equals(canvasId))).write(
      GraphCanvasesCompanion(
        filterConfig: Value(filterConfigJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Duplicates a canvas: copies canvas settings and all character layout positions.
  Future<GraphCanvas> duplicateCanvas(
    int sourceCanvasId,
    String newName,
  ) async {
    final source = await getCanvasById(sourceCanvasId);
    if (source == null) throw ArgumentError('Source canvas not found.');

    final now = DateTime.now();
    final newCanvasId = await into(graphCanvases).insert(
      GraphCanvasesCompanion(
        worldId: Value(source.worldId),
        name: Value(newName),
        description: Value(source.description),
        isDefault: const Value(false),
        viewportX: Value(source.viewportX),
        viewportY: Value(source.viewportY),
        zoomScale: Value(source.zoomScale),
        filterConfig: Value(source.filterConfig),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // Copy all node positions from source canvas
    final sourceLayouts = await getLayoutsByCanvas(sourceCanvasId);
    for (final l in sourceLayouts) {
      await into(graphLayouts).insert(
        GraphLayoutsCompanion(
          worldId: Value(source.worldId),
          canvasId: Value(newCanvasId),
          characterId: Value(l.characterId),
          x: Value(l.x),
          y: Value(l.y),
        ),
      );
    }

    return (await getCanvasById(newCanvasId))!;
  }

  /// Deletes a canvas and all its layout coordinates.
  /// Characters and Relations in the world are NEVER touched.
  Future<void> deleteCanvas(int canvasId) async {
    final canvas = await getCanvasById(canvasId);
    if (canvas == null) return;

    await db.transaction(() async {
      await (delete(
        graphLayouts,
      )..where((t) => t.canvasId.equals(canvasId))).go();
      await (delete(graphCanvases)..where((t) => t.id.equals(canvasId))).go();

      // If the deleted canvas was default, pick the next available canvas and set as default
      if (canvas.isDefault) {
        final remaining = await getCanvasesByWorld(canvas.worldId);
        if (remaining.isNotEmpty) {
          await (update(graphCanvases)
                ..where((t) => t.id.equals(remaining.first.id)))
              .write(const GraphCanvasesCompanion(isDefault: Value(true)));
        }
      }
    });
  }

  Future<void> deleteCanvasesByWorld(int worldId) async {
    await db.transaction(() async {
      await (delete(
        graphLayouts,
      )..where((t) => t.worldId.equals(worldId))).go();
      await (delete(
        graphCanvases,
      )..where((t) => t.worldId.equals(worldId))).go();
    });
  }

  // --- Layout Queries per Canvas ---

  Future<List<GraphLayout>> getLayoutsByCanvas(int canvasId) async {
    final rows =
        await (select(graphLayouts)
              ..where((t) => t.canvasId.equals(canvasId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    final latestByCharacter = <int, GraphLayout>{};
    for (final row in rows) {
      latestByCharacter[row.characterId] = row;
    }
    return latestByCharacter.values.toList();
  }

  Future<void> savePosition({
    required int worldId,
    required int canvasId,
    required int characterId,
    required double x,
    required double y,
  }) async {
    final existing =
        await (select(graphLayouts)
              ..where(
                (t) =>
                    t.canvasId.equals(canvasId) &
                    t.characterId.equals(characterId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)]))
            .get();

    if (existing.isNotEmpty) {
      final latestId = existing.first.id;
      await (update(graphLayouts)..where((t) => t.id.equals(latestId))).write(
        GraphLayoutsCompanion(x: Value(x), y: Value(y)),
      );
      if (existing.length > 1) {
        await (delete(graphLayouts)..where(
              (t) =>
                  t.canvasId.equals(canvasId) &
                  t.characterId.equals(characterId) &
                  t.id.isNotValue(latestId),
            ))
            .go();
      }
    } else {
      await into(graphLayouts).insert(
        GraphLayoutsCompanion(
          worldId: Value(worldId),
          canvasId: Value(canvasId),
          characterId: Value(characterId),
          x: Value(x),
          y: Value(y),
        ),
      );
    }
  }

  Future<void> batchSavePositions(
    int worldId,
    int canvasId,
    Map<int, Offset> positions,
  ) async {
    if (positions.isEmpty) return;
    await db.transaction(() async {
      for (final entry in positions.entries) {
        await savePosition(
          worldId: worldId,
          canvasId: canvasId,
          characterId: entry.key,
          x: entry.value.dx,
          y: entry.value.dy,
        );
      }
    });
  }

  Future<void> deletePosition(int canvasId, int characterId) =>
      (delete(graphLayouts)..where(
            (t) =>
                t.canvasId.equals(canvasId) & t.characterId.equals(characterId),
          ))
          .go();
}
