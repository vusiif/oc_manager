import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/relation_provider.dart';
import '../relation_advanced_analysis.dart';
import '../relation_viewport_helper.dart';

/// Helper for canvas state lifecycle, viewport persistence, and default canvas synchronization.
class RelationCanvasStateHelper {
  /// Persists current viewport transform and filter configuration to database for a canvas.
  static Future<void> persistCanvasState({
    required WidgetRef ref,
    required int? canvasId,
    required TransformationController transformController,
    required RelationFilterState filterState,
  }) async {
    if (canvasId == null) return;
    final matrix = transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.getTranslation().x;
    final ty = matrix.getTranslation().y;
    await ref.read(canvasActionsProvider).saveViewport(canvasId, tx, ty, scale);
    await ref
        .read(canvasActionsProvider)
        .saveFilterConfig(canvasId, filterState.toJsonString());
  }

  /// Restores target canvas viewport and filter configuration.
  static RelationFilterState restoreCanvasState({
    required GraphCanvas targetCanvas,
    required TransformationController transformController,
  }) {
    transformController.value = RelationViewportHelper.matrixFromViewport(
      targetCanvas.viewportX,
      targetCanvas.viewportY,
      targetCanvas.zoomScale,
    );

    if (targetCanvas.filterConfig != null &&
        targetCanvas.filterConfig!.isNotEmpty) {
      return RelationFilterState.fromJsonString(targetCanvas.filterConfig!);
    }
    return const RelationFilterState();
  }

  /// Synchronizes positions from DB layouts into the positions map.
  static bool syncPositions({
    required List<Character> characters,
    required List<GraphLayout> layouts,
    required Map<int, Offset> positions,
    required Set<int> loadedCharacters,
  }) {
    if (layouts.isEmpty) return false;
    final saved = {for (var l in layouts) l.characterId: Offset(l.x, l.y)};
    bool changed = false;
    for (final c in characters) {
      if (!loadedCharacters.contains(c.id) && saved.containsKey(c.id)) {
        positions[c.id] = saved[c.id]!;
        loadedCharacters.add(c.id);
        changed = true;
      }
    }
    return changed;
  }
}
