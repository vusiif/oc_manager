import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../graph_history_manager.dart';
import '../painters/relation_label_helper.dart';
import '../relation_edit_dialogs.dart';
import 'relation_graph_commands.dart';

/// Helper methods for node connecting interactions and relation label hit testing.
class RelationConnectionHelper {
  /// Finds target character node within hitRadius of current connecting position.
  static int? findConnectTarget({
    required int? sourceId,
    required Offset? currentPos,
    required Map<int, Offset> positions,
    double hitRadius = 65.0,
  }) {
    if (sourceId == null || currentPos == null) return null;
    int? bestTargetId;
    double minDistance = hitRadius;

    for (final entry in positions.entries) {
      if (entry.key != sourceId) {
        final nodeCenter = entry.value;
        // Evaluate distance against visual center (slightly below avatar due to text)
        final visualCenter = Offset(nodeCenter.dx, nodeCenter.dy + 10.0);
        final dist = (visualCenter - currentPos).distance;
        if (dist <= minDistance) {
          minDistance = dist;
          bestTargetId = entry.key;
        }
      }
    }
    return bestTargetId;
  }

  /// Hit-tests relation labels and edges to find tapped relation ID.
  static int? hitTestRelation({
    required Offset tapPos,
    required List<Relation> relations,
    required Map<int, Offset> positions,
    double hitRadius = 28.0,
  }) {
    final labelCenters = calculateRelationLabelCenters(
      relations: relations,
      positions: positions,
    );

    int? hitRelId;
    double minDistance = hitRadius;

    // 1. 优先判定点击关系胶囊标签
    for (final entry in labelCenters.entries) {
      final dist = (entry.value - tapPos).distance;
      if (dist <= minDistance) {
        minDistance = dist;
        hitRelId = entry.key;
      }
    }

    // 2. 若未点击到标签，辅以线段临近距离检测 (容差 16px)
    if (hitRelId == null) {
      double minLineDist = 16.0;
      for (final rel in relations) {
        final p1 = positions[rel.fromCharacterId];
        final p2 = positions[rel.toCharacterId];
        if (p1 != null && p2 != null) {
          final dist = _distanceToSegment(tapPos, p1, p2);
          if (dist <= minLineDist) {
            minLineDist = dist;
            hitRelId = rel.id;
          }
        }
      }
    }

    return hitRelId;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 < 1e-4) return (p - a).distance;
    final t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(
      a.dx + clampedT * (b.dx - a.dx),
      a.dy + clampedT * (b.dy - a.dy),
    );
    return (p - projection).distance;
  }

  /// Handles relation tap:
  /// - First tap on an unselected relation selects it (shows Inspector & glow).
  /// - Second tap on an already-selected relation opens the full modal action dialog.
  /// - Tap on empty canvas deselects and hides Inspector.
  static void handleRelationTap({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required Offset tapPos,
    required List<Relation> relations,
    required List<Character> characters,
    required Map<int, Offset> positions,
    required GraphHistoryManager historyManager,
    required int? currentSelectedRelationId,
    required ValueChanged<int?> onSelectedRelationChanged,
  }) {
    final hitRelId = hitTestRelation(
      tapPos: tapPos,
      relations: relations,
      positions: positions,
    );

    if (hitRelId != null) {
      final hitRel = relations.where((r) => r.id == hitRelId).firstOrNull;
      if (hitRel != null) {
        if (currentSelectedRelationId == hitRelId) {
          // 第二次点击已选中的关系：打开完整编辑模态弹窗
          RelationEditDialogs.showRelationActionDialog(
            context: context,
            ref: ref,
            worldId: worldId,
            rel: hitRel,
            characters: characters,
            onRecordUpdate: (oldRel, newRel, desc) =>
                RelationGraphCommands.recordUpdateRelation(
                  ref: ref,
                  worldId: worldId,
                  oldRel: oldRel,
                  newRel: newRel,
                  desc: desc,
                  historyManager: historyManager,
                ),
            onRecordDelete: (rel, desc) =>
                RelationGraphCommands.recordDeleteRelation(
                  ref: ref,
                  worldId: worldId,
                  rel: rel,
                  desc: desc,
                  historyManager: historyManager,
                ),
            onRelationDeleted: () => onSelectedRelationChanged(null),
          );
        } else {
          // 首次点击：选中该关系，呼出属性检查面板与发光高亮
          onSelectedRelationChanged(hitRelId);
        }
      }
    } else if (currentSelectedRelationId != null) {
      // 点击空白处：取消选中
      onSelectedRelationChanged(null);
    }
  }
}
