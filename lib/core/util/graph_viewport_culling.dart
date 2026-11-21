import 'package:flutter/material.dart';

/// Level of Detail (LOD) tier for large-scale graph canvases (PERF-001).
enum GraphLodLevel {
  /// High detail (zoomed in): full cards, names, avatars, edge labels, halos, and arrows.
  full,

  /// Medium detail (normal zoom): simplified shapes, edge lines and arrows, text labels omitted.
  medium,

  /// Overview (zoomed far out): lightweight micro-dots, simplified lines, arrows and labels omitted.
  overview,
}

/// Helper for viewport culling and Level-of-Detail (LOD) calculations on large interactive canvases (PERF-001).
class GraphViewportCulling {
  const GraphViewportCulling._();

  /// Computes the visible rectangle in world/canvas coordinates based on the transformation matrix
  /// and the container viewport (screen) size.
  static Rect computeVisibleWorldRect({
    required Matrix4 transform,
    required Size viewportSize,
    double bufferMargin = 120.0,
  }) {
    if (viewportSize.isEmpty ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return Rect.largest;
    }
    try {
      final inverse = Matrix4.inverted(transform);
      final tl = MatrixUtils.transformPoint(inverse, Offset.zero);
      final br = MatrixUtils.transformPoint(
        inverse,
        Offset(viewportSize.width, viewportSize.height),
      );
      final rawRect = Rect.fromPoints(tl, br);
      return bufferMargin > 0 ? rawRect.inflate(bufferMargin) : rawRect;
    } catch (_) {
      return Rect.largest;
    }
  }

  /// Determines the current Level of Detail (LOD) based on the zoom scale.
  static GraphLodLevel getLodLevel(double scale) {
    if (scale >= 0.55) {
      return GraphLodLevel.full;
    } else if (scale >= 0.28) {
      return GraphLodLevel.medium;
    } else {
      return GraphLodLevel.overview;
    }
  }

  /// Checks if a node at [center] with approximate radius [radius] overlaps [visibleRect].
  static bool isNodeVisible(
    Offset center,
    Rect visibleRect, {
    double radius = 40.0,
  }) {
    return visibleRect.overlaps(
      Rect.fromCircle(center: center, radius: radius),
    );
  }

  /// Checks if an edge between [from] and [to] overlaps [visibleRect].
  static bool isEdgeVisible(
    Offset from,
    Offset to,
    Rect visibleRect, {
    double padding = 60.0,
  }) {
    final edgeRect = Rect.fromPoints(from, to).inflate(padding);
    return visibleRect.overlaps(edgeRect);
  }

  /// Filters a map of node positions to only those visible within [visibleRect].
  static Map<K, Offset> filterVisiblePositions<K>(
    Map<K, Offset> positions,
    Rect visibleRect, {
    double radius = 40.0,
  }) {
    final result = <K, Offset>{};
    for (final entry in positions.entries) {
      if (isNodeVisible(entry.value, visibleRect, radius: radius)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
