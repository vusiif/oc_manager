import 'dart:math';
import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

const familyRelationTypes = ['亲子', '父母', '父女', '父子', '母子', '母女', '家人'];

/// Helper function to calculate label centers for each relation in scene space.
Map<int, Offset> calculateRelationLabelCenters({
  required List<Relation> relations,
  required Map<int, Offset> positions,
}) {
  final centers = <int, Offset>{};
  final familyGroups = <String, List<Relation>>{};
  final normalGroups = <String, List<Relation>>{};

  for (final rel in relations) {
    if (!positions.containsKey(rel.fromCharacterId) ||
        !positions.containsKey(rel.toCharacterId)) {
      continue;
    }
    final minId = min(rel.fromCharacterId, rel.toCharacterId);
    final maxId = max(rel.fromCharacterId, rel.toCharacterId);
    final key = '$minId-$maxId';

    if (rel.relationGroupId != null &&
        familyRelationTypes.contains(rel.relationType)) {
      familyGroups.putIfAbsent(rel.relationGroupId!, () => []).add(rel);
    } else {
      normalGroups.putIfAbsent(key, () => []).add(rel);
    }
  }

  for (final entry in familyGroups.entries) {
    final group = entry.value;
    final parentIds = <int>{};
    for (final rel in group) {
      if (rel.fromCharacterId != rel.toCharacterId) {
        parentIds.add(rel.fromCharacterId);
      }
    }
    final parents = parentIds
        .map((id) => positions[id])
        .whereType<Offset>()
        .toList();
    if (parents.isEmpty) continue;

    final parentMid = parents.length >= 2
        ? Offset(
            (parents[0].dx + parents[1].dx) / 2,
            (parents[0].dy + parents[1].dy) / 2,
          )
        : parents[0];
    final labelOffset = Offset(parentMid.dx, parentMid.dy + 16);
    for (final rel in group) {
      centers[rel.id] = labelOffset;
    }
  }

  for (final entry in normalGroups.entries) {
    final group = entry.value;
    final baseFromId = group.first.fromCharacterId;
    final baseToId = group.first.toCharacterId;
    final from = positions[baseFromId]!;
    final to = positions[baseToId]!;
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final rel = group[i];
      final offset = count == 1 ? 0.0 : (i - (count - 1) / 2) * 40.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;

      if (count == 1) {
        centers[rel.id] = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      } else {
        final cp = Offset(
          (from.dx + to.dx) / 2 + nx * offset,
          (from.dy + to.dy) / 2 + ny * offset,
        );
        const t = 0.5;
        final labelX =
            (1 - t) * (1 - t) * from.dx +
            2 * (1 - t) * t * cp.dx +
            t * t * to.dx;
        final labelY =
            (1 - t) * (1 - t) * from.dy +
            2 * (1 - t) * t * cp.dy +
            t * t * to.dy;
        centers[rel.id] = Offset(labelX, labelY);
      }
    }
  }

  return centers;
}
