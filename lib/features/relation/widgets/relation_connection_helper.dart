import 'dart:ui';

import '../../../data/database/app_database.dart';
import '../painters/relation_label_helper.dart';

/// Helper methods for node connecting interactions and relation label hit testing.
class RelationConnectionHelper {
  /// Finds target character node within hitRadius of current connecting position.
  static int? findConnectTarget({
    required int? sourceId,
    required Offset? currentPos,
    required Map<int, Offset> positions,
    double hitRadius = 45.0,
  }) {
    if (sourceId == null || currentPos == null) return null;
    for (final entry in positions.entries) {
      if (entry.key != sourceId) {
        if ((entry.value - currentPos).distance <= hitRadius) {
          return entry.key;
        }
      }
    }
    return null;
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
}
