import 'dart:math';
import 'package:flutter/material.dart';

/// Helper for viewport and transformation matrix calculations on relation graph canvases.
class RelationViewportHelper {
  const RelationViewportHelper._();

  /// Constructs a transformation Matrix4 from translation (tx, ty) and scale.
  static Matrix4 matrixFromViewport(double tx, double ty, double scale) {
    final s = scale > 0 ? scale : 1.0;
    return Matrix4.identity()
      ..storage[0] = s
      ..storage[5] = s
      ..storage[12] = tx
      ..storage[13] = ty;
  }

  /// Calculates a Matrix4 that fits all nodes within the given [viewportSize].
  static Matrix4 computeFitCanvasMatrix({
    required Size viewportSize,
    required Map<int, Offset> positions,
    double padding = 140.0,
    double minScale = 0.2,
    double maxScale = 1.5,
  }) {
    if (positions.isEmpty) {
      return Matrix4.identity();
    }

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pos in positions.values) {
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final contentWidth = (maxX - minX) + padding * 2;
    final contentHeight = (maxY - minY) + padding * 2;
    final contentCenterX = (minX + maxX) / 2;
    final contentCenterY = (minY + maxY) / 2;

    final scaleX = viewportSize.width / max(contentWidth, 1.0);
    final scaleY = viewportSize.height / max(contentHeight, 1.0);
    final scale = min(scaleX, scaleY).clamp(minScale, maxScale);

    final tx = viewportSize.width / 2 - contentCenterX * scale;
    final ty = viewportSize.height / 2 - contentCenterY * scale;

    return matrixFromViewport(tx, ty, scale);
  }

  /// Calculates a Matrix4 that centers the viewport on [targetWorldPos].
  static Matrix4 computeNavigateMatrix({
    required Offset targetWorldPos,
    required Size viewportSize,
    required double currentScale,
    double minScale = 0.1,
    double maxScale = 3.0,
  }) {
    final clampedScale = currentScale.clamp(minScale, maxScale);
    final tx = viewportSize.width / 2 - targetWorldPos.dx * clampedScale;
    final ty = viewportSize.height / 2 - targetWorldPos.dy * clampedScale;
    return matrixFromViewport(tx, ty, clampedScale);
  }
}
