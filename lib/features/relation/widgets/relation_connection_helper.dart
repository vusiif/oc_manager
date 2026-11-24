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

  /// Hit-tests relation labels to find tapped relation ID.
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

    for (final entry in labelCenters.entries) {
      final dist = (entry.value - tapPos).distance;
      if (dist <= minDistance) {
        minDistance = dist;
        hitRelId = entry.key;
      }
    }
    return hitRelId;
  }

  /// Handles relation label tap, opening action dialog or clearing selection.
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
        onSelectedRelationChanged(hitRelId);
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
      }
    } else if (currentSelectedRelationId != null) {
      onSelectedRelationChanged(null);
    }
  }
}
