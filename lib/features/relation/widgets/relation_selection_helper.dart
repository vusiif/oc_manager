import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../graph_history_manager.dart';
import 'relation_graph_commands.dart';

/// Alignment modes supported for multi-selected graph nodes.
enum NodeAlignMode {
  left('左对齐', Icons.align_horizontal_left),
  centerH('水平居中', Icons.align_horizontal_center),
  top('顶部对齐', Icons.align_vertical_top),
  centerV('垂直居中', Icons.align_vertical_center),
  distributeH('水平等距分布', Icons.horizontal_distribute),
  distributeV('垂直等距分布', Icons.vertical_distribute);

  final String label;
  final IconData icon;
  const NodeAlignMode(this.label, this.icon);
}

/// Pure geometry and alignment utilities for multi-node box selection.
class RelationSelectionHelper {
  /// Returns IDs of all nodes whose bounding box overlaps [selectionRect].
  static Set<int> findNodesInRect(
    Rect selectionRect,
    Map<int, Offset> positions, {
    double nodeRadius = 26.0,
  }) {
    final normalized = Rect.fromLTRB(
      min(selectionRect.left, selectionRect.right),
      min(selectionRect.top, selectionRect.bottom),
      max(selectionRect.left, selectionRect.right),
      max(selectionRect.top, selectionRect.bottom),
    );
    final result = <int>{};
    for (final entry in positions.entries) {
      final nodeRect = Rect.fromCenter(
        center: entry.value,
        width: nodeRadius * 2,
        height: nodeRadius * 2,
      );
      if (normalized.overlaps(nodeRect)) {
        result.add(entry.key);
      }
    }
    return result;
  }

  /// Computes updated positions for [selectedIds] according to [mode].
  /// Returns only entries for [selectedIds] that should be updated.
  static Map<int, Offset> computeAlignedPositions(
    NodeAlignMode mode,
    Set<int> selectedIds,
    Map<int, Offset> positions,
  ) {
    final targets = selectedIds
        .where((id) => positions.containsKey(id))
        .toList();
    if (targets.length < 2) return {};

    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final id in targets) {
      final pos = positions[id]!;
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final result = <int, Offset>{};
    switch (mode) {
      case NodeAlignMode.left:
        final x = max(40.0, minX);
        for (final id in targets) {
          result[id] = Offset(x, positions[id]!.dy);
        }
      case NodeAlignMode.centerH:
        final x = max(40.0, (minX + maxX) / 2.0);
        for (final id in targets) {
          result[id] = Offset(x, positions[id]!.dy);
        }
      case NodeAlignMode.top:
        final y = max(40.0, minY);
        for (final id in targets) {
          result[id] = Offset(positions[id]!.dx, y);
        }
      case NodeAlignMode.centerV:
        final y = max(40.0, (minY + maxY) / 2.0);
        for (final id in targets) {
          result[id] = Offset(positions[id]!.dx, y);
        }
      case NodeAlignMode.distributeH:
        if (targets.length < 3) return {};
        targets.sort((a, b) => positions[a]!.dx.compareTo(positions[b]!.dx));
        final startX = positions[targets.first]!.dx;
        final endX = positions[targets.last]!.dx;
        final step = (endX - startX) / (targets.length - 1);
        for (var i = 0; i < targets.length; i++) {
          final id = targets[i];
          result[id] = Offset(max(40.0, startX + step * i), positions[id]!.dy);
        }
      case NodeAlignMode.distributeV:
        if (targets.length < 3) return {};
        targets.sort((a, b) => positions[a]!.dy.compareTo(positions[b]!.dy));
        final startY = positions[targets.first]!.dy;
        final endY = positions[targets.last]!.dy;
        final step = (endY - startY) / (targets.length - 1);
        for (var i = 0; i < targets.length; i++) {
          final id = targets[i];
          result[id] = Offset(positions[id]!.dx, max(40.0, startY + step * i));
        }
    }
    return result;
  }

  /// Prepares single or multi-node drag start snapshots.
  static void startNodeDrag({
    required int charId,
    required Offset startPos,
    required Set<int> selectedNodeIds,
    required Map<int, Offset> positions,
    required Map<int, Offset> singleStartPositions,
    required Map<int, Offset> multiStartPositions,
  }) {
    if (selectedNodeIds.contains(charId) && selectedNodeIds.length > 1) {
      multiStartPositions.clear();
      for (final id in selectedNodeIds) {
        final pos = positions[id];
        if (pos != null) multiStartPositions[id] = pos;
      }
    } else {
      multiStartPositions.clear();
      singleStartPositions[charId] = startPos;
    }
  }

  /// Applies drag delta to either the multi-selected group or a single node.
  static void updateNodeDrag({
    required int charId,
    required Offset newPos,
    required Set<int> selectedNodeIds,
    required Map<int, Offset> positions,
    required Map<int, Offset> multiStartPositions,
  }) {
    if (multiStartPositions.isNotEmpty && selectedNodeIds.contains(charId)) {
      final prev = positions[charId] ?? newPos;
      final delta = newPos - prev;
      for (final id in selectedNodeIds) {
        final cur = positions[id];
        if (cur != null) {
          positions[id] = Offset(
            max(40.0, cur.dx + delta.dx),
            max(40.0, cur.dy + delta.dy),
          );
        }
      }
    } else {
      positions[charId] = newPos;
    }
  }

  /// Finalizes node drag and records single or batch move into [historyManager].
  static void endNodeDrag({
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required int characterId,
    required Offset newPos,
    required List<Character> characters,
    required Set<int> selectedNodeIds,
    required Map<int, Offset> positions,
    required Map<int, Offset> singleStartPositions,
    required Map<int, Offset> multiStartPositions,
    required GraphHistoryManager historyManager,
    required void Function(int id, Offset pos) onUpdateSingle,
    required void Function(Map<int, Offset> updated) onUpdateBatch,
  }) {
    if (multiStartPositions.isNotEmpty &&
        selectedNodeIds.contains(characterId)) {
      final oldMap = Map<int, Offset>.of(multiStartPositions);
      final newMap = <int, Offset>{};
      for (final id in oldMap.keys) {
        if (positions[id] != null) newMap[id] = positions[id]!;
      }
      multiStartPositions.clear();
      RelationGraphCommands.recordBatchNodeMove(
        ref: ref,
        worldId: worldId,
        canvasId: canvasId,
        descriptionText: '批量移动 ${newMap.length} 个角色',
        oldPositions: oldMap,
        newPositions: newMap,
        historyManager: historyManager,
        onUpdateMemory: onUpdateBatch,
      );
      return;
    }

    final startPos =
        singleStartPositions.remove(characterId) ?? positions[characterId];
    if (startPos == null) return;
    final charName =
        characters
            .where((c) => c.id == characterId)
            .map((c) => c.name)
            .firstOrNull ??
        'ID:$characterId';
    RelationGraphCommands.recordNodeMove(
      ref: ref,
      worldId: worldId,
      canvasId: canvasId,
      characterId: characterId,
      characterName: charName,
      oldPos: startPos,
      newPos: newPos,
      historyManager: historyManager,
      onUpdateMemory: onUpdateSingle,
    );
  }

  /// Aligns [selectedNodeIds] according to [mode] and records undo history.
  static void alignSelectedNodes({
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required NodeAlignMode mode,
    required Set<int> selectedNodeIds,
    required Map<int, Offset> positions,
    required GraphHistoryManager historyManager,
    required void Function(Map<int, Offset> updated) onUpdateBatch,
  }) {
    final aligned = computeAlignedPositions(mode, selectedNodeIds, positions);
    if (aligned.isEmpty) return;
    final oldMap = {for (final id in aligned.keys) id: positions[id]!};
    onUpdateBatch(aligned);
    RelationGraphCommands.recordBatchNodeMove(
      ref: ref,
      worldId: worldId,
      canvasId: canvasId,
      descriptionText: '${mode.label} (${aligned.length}个角色)',
      oldPositions: oldMap,
      newPositions: aligned,
      historyManager: historyManager,
      onUpdateMemory: onUpdateBatch,
    );
  }

  /// Updates [selectedIds] when a node is tapped.
  static void applyNodeTap(Set<int> selectedIds, int charId, bool isAdditive) {
    if (isAdditive) {
      if (!selectedIds.remove(charId)) selectedIds.add(charId);
    } else {
      selectedIds
        ..clear()
        ..add(charId);
    }
  }

  /// Updates [selectedIds] after a marquee box selection.
  static void applyBoxSelect(
    Set<int> selectedIds,
    Set<int> hitIds,
    bool isAdditive,
  ) {
    if (!isAdditive) selectedIds.clear();
    selectedIds.addAll(hitIds);
  }
}

/// CustomPainter for rendering the dashed marquee box during drag selection.
class SelectionBoxPainter extends CustomPainter {
  final Rect? rect;
  final Color color;

  const SelectionBoxPainter({required this.rect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = rect;
    if (r == null) return;
    final normalized = Rect.fromLTRB(
      min(r.left, r.right),
      min(r.top, r.bottom),
      max(r.left, r.right),
      max(r.top, r.bottom),
    );
    if (normalized.width < 2 && normalized.height < 2) return;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(normalized, fillPaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawDashedRect(canvas, normalized, borderPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addRect(rect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SelectionBoxPainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.color != color;
  }
}
