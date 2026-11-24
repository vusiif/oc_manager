import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import 'graph_geometry.dart';
import 'painters/relation_label_helper.dart';
import 'painters/relation_style_helper.dart';
import 'relation_advanced_analysis.dart';

export 'painters/background_painters.dart';
export 'painters/relation_label_helper.dart';
export 'painters/relation_style_helper.dart';

const _familyTypes = familyRelationTypes;

/// CustomPainter for rendering graph edges, arrowheads, and labels.
class RelationPainter extends CustomPainter {
  final List<Relation> relations;
  final Map<int, Offset> positions;
  final List<Character> characters;
  final int revision;
  final int? selectedRelationId;
  final bool isDark;
  final RelationFilterState? filterState;
  final Rect? visibleRect;
  final double scale;

  RelationPainter({
    required this.relations,
    required this.positions,
    required this.characters,
    required this.revision,
    this.selectedRelationId,
    this.isDark = false,
    this.filterState,
    this.visibleRect,
    this.scale = 1.0,
  });

  bool _isRelInPath(Relation rel) {
    final path = filterState?.highlightedPath;
    if (path == null) return false;
    return path.edgePath.any(
      (e) =>
          (e.fromCharacterId == rel.fromCharacterId &&
              e.toCharacterId == rel.toCharacterId) ||
          (rel.isBidirectional &&
              e.fromCharacterId == rel.toCharacterId &&
              e.toCharacterId == rel.fromCharacterId),
    );
  }

  bool _isRelDimmed(Relation rel) {
    if (filterState == null || !filterState!.hasActiveFilter) return false;
    if (filterState!.highlightedPath != null) {
      return !_isRelInPath(rel);
    }
    if (filterState!.selectedRelationType != null &&
        rel.relationType != filterState!.selectedRelationType) {
      return true;
    }
    if (filterState!.selectedGroupId != null &&
        rel.relationGroupId != filterState!.selectedGroupId.toString()) {
      return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final characterMap = {for (final c in characters) c.id: c};

    // Separate family pedigree groups and normal relations
    final familyGroups = <String, List<Relation>>{};
    final normalGroups = <String, List<Relation>>{};

    for (final rel in relations) {
      if (!positions.containsKey(rel.fromCharacterId) ||
          !positions.containsKey(rel.toCharacterId)) {
        continue;
      }
      final p1 = positions[rel.fromCharacterId]!;
      final p2 = positions[rel.toCharacterId]!;

      // Viewport Culling (PERF-001)
      if (visibleRect != null &&
          !GraphViewportCulling.isEdgeVisible(p1, p2, visibleRect!)) {
        continue;
      }

      final key = _pairKey(rel.fromCharacterId, rel.toCharacterId);
      if (rel.relationGroupId != null &&
          _familyTypes.contains(rel.relationType)) {
        familyGroups.putIfAbsent(rel.relationGroupId!, () => []).add(rel);
      } else {
        normalGroups.putIfAbsent(key, () => []).add(rel);
      }
    }

    // 1. Draw family pedigree trees
    for (final entry in familyGroups.entries) {
      _drawFamilyGroup(
        canvas,
        textPainter,
        linePaint,
        entry.value,
        characterMap,
      );
    }

    // 2. Draw normal relations (curved/straight lines)
    for (final entry in normalGroups.entries) {
      _drawNormalGroup(
        canvas,
        textPainter,
        linePaint,
        entry.value,
        characterMap,
      );
    }
  }

  void _drawFamilyGroup(
    Canvas canvas,
    TextPainter tp,
    Paint paint,
    List<Relation> group,
    Map<int, Character> characterMap,
  ) {
    final parentIds = <int>{};
    final childIds = <int>{};

    for (final rel in group) {
      if (rel.fromCharacterId != rel.toCharacterId) {
        parentIds.add(rel.fromCharacterId);
        childIds.add(rel.toCharacterId);
      }
    }

    final parents = parentIds
        .map((id) => positions[id])
        .whereType<Offset>()
        .toList();
    final children = childIds
        .map((id) => positions[id])
        .whereType<Offset>()
        .toList();

    if (parents.isEmpty || children.isEmpty) return;

    final isPathHit = group.any(_isRelInPath);
    final isDimmed = group.every(_isRelDimmed);
    final isSelected = group.any((r) => r.id == selectedRelationId);
    final relType = group.first.relationType;

    final color = RelationStyleHelper.getRelationColor(
      relType,
      isBidirectional: true,
      isDark: isDark,
      isSelected: isSelected || isPathHit,
      isDimmed: isDimmed && !isPathHit && !isSelected,
    );

    paint.color = color;
    paint.strokeWidth = isSelected || isPathHit ? 3.0 : (isDimmed ? 1.0 : 2.0);

    final childYs = children.map((c) => c.dy).toList();
    final minChildY = childYs.reduce(min);

    final Offset parentMid;
    if (parents.length >= 2) {
      final p1 = parents[0];
      final p2 = parents[1];
      final p1Id = parentIds.first;
      final p2Id = parentIds.skip(1).first;

      final edge1 = GraphGeometry.getExitPoint(
        fromCenter: p1,
        toCenter: p2,
        fromGender: characterMap[p1Id]?.gender ?? '',
      );
      final edge2 = GraphGeometry.getEntryPoint(
        fromCenter: p1,
        toCenter: p2,
        toGender: characterMap[p2Id]?.gender ?? '',
      );
      canvas.drawLine(edge1, edge2, paint);

      parentMid = Offset((edge1.dx + edge2.dx) / 2, (edge1.dy + edge2.dy) / 2);
      canvas.drawCircle(
        parentMid,
        3.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      for (var i = 2; i < parents.length; i++) {
        final pi = parents[i];
        final pid = parentIds.skip(i).first;
        final edge = GraphGeometry.getExitPoint(
          fromCenter: pi,
          toCenter: parentMid,
          fromGender: characterMap[pid]?.gender ?? '',
        );
        canvas.drawLine(edge, parentMid, paint);
      }
    } else {
      parentMid = parents[0];
    }

    double busY = minChildY > parentMid.dy
        ? parentMid.dy + (minChildY - parentMid.dy) * 0.4
        : parentMid.dy + 50;

    final busStart = Offset(parentMid.dx, busY);
    final topPoint = parents.length >= 2
        ? parentMid
        : GraphGeometry.calculateBoundaryIntersection(
            nodeCenter: parentMid,
            gender: characterMap[parentIds.first]?.gender ?? '',
            angle: pi / 2,
          );
    canvas.drawLine(topPoint, busStart, paint);
    canvas.drawCircle(
      busStart,
      3.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    const arrowLen = 10.0;
    if (children.length == 1) {
      final child = children[0];
      final childId = childIds.first;
      final junction = Offset(busStart.dx, busStart.dy);
      final midPoint = Offset(child.dx, busY);
      final cEdge = GraphGeometry.getEntryPoint(
        fromCenter: midPoint,
        toCenter: child,
        toGender: characterMap[childId]?.gender ?? '',
      );

      canvas.drawLine(junction, midPoint, paint);
      final childDir = (child - midPoint).direction;
      final childEnd =
          cEdge - Offset(arrowLen * cos(childDir), arrowLen * sin(childDir));
      canvas.drawLine(midPoint, childEnd, paint);
      RelationStyleHelper.drawFilledArrow(
        canvas,
        tip: cEdge,
        direction: childDir,
        color: color,
      );
    } else {
      final childXs = children.map((c) => c.dx).toList()..sort();
      final busLeft = Offset(childXs.first, busY);
      final busRight = Offset(childXs.last, busY);

      canvas.drawLine(
        Offset(min(busStart.dx, busLeft.dx), busY),
        Offset(max(busStart.dx, busRight.dx), busY),
        paint,
      );

      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final childId = childIds.skip(i).first;
        final junction = Offset(child.dx, busY);
        final cEdge = GraphGeometry.getEntryPoint(
          fromCenter: junction,
          toCenter: child,
          toGender: characterMap[childId]?.gender ?? '',
        );

        canvas.drawCircle(
          junction,
          2.6,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
        final childDir = (child - junction).direction;
        final childEnd =
            cEdge - Offset(arrowLen * cos(childDir), arrowLen * sin(childDir));
        canvas.drawLine(junction, childEnd, paint);
        RelationStyleHelper.drawFilledArrow(
          canvas,
          tip: cEdge,
          direction: childDir,
          color: color,
        );
      }
    }

    RelationStyleHelper.drawRelationBadge(
      canvas,
      tp,
      relType,
      Offset(parentMid.dx, parentMid.dy + 16),
      color: color,
      isSelected: isSelected || isPathHit,
      isDark: isDark,
      isDimmed: isDimmed && !isPathHit && !isSelected,
      scale: scale,
    );
  }

  void _drawNormalGroup(
    Canvas canvas,
    TextPainter tp,
    Paint paint,
    List<Relation> group,
    Map<int, Character> characterMap,
  ) {
    final baseFromId = group.first.fromCharacterId;
    final baseToId = group.first.toCharacterId;
    final from = positions[baseFromId]!;
    final to = positions[baseToId]!;
    final fromGender = characterMap[baseFromId]?.gender ?? '';
    final toGender = characterMap[baseToId]?.gender ?? '';
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final rel = group[i];
      final isSelected = (rel.id == selectedRelationId);
      final isPathHit = _isRelInPath(rel);
      final isDimmed = _isRelDimmed(rel);
      final isDashed = RelationStyleHelper.isDashedRelation(rel.relationType);

      final color = RelationStyleHelper.getRelationColor(
        rel.relationType,
        isBidirectional: rel.isBidirectional,
        isDark: isDark,
        isSelected: isSelected || isPathHit,
        isDimmed: isDimmed && !isPathHit && !isSelected,
      );

      paint.color = color;
      paint.strokeWidth = isSelected || isPathHit
          ? 3.0
          : (isDimmed ? 1.0 : 2.0);

      final isReversed = (rel.fromCharacterId != baseFromId);
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;
      const arrowLen = 10.0;

      final offset = count == 1
          ? RelationStyleHelper.computeSingleLineOffset(dist)
          : RelationStyleHelper.computeCurveOffset(i, count, dist);
      final cp = Offset(
        (from.dx + to.dx) / 2 + nx * offset,
        (from.dy + to.dy) / 2 + ny * offset,
      );

      final tStart = Offset(cp.dx - from.dx, cp.dy - from.dy).direction;
      final tEnd = Offset(to.dx - cp.dx, to.dy - cp.dy).direction;

      final p1 = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: from,
        gender: fromGender,
        angle: tStart,
        includeText: true,
      );
      final p2 = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: to,
        gender: toGender,
        angle: tEnd + pi,
        includeText: true,
      );

      final adjCp = Offset(
        (p1.dx + p2.dx) / 2 + nx * offset,
        (p1.dy + p2.dy) / 2 + ny * offset,
      );

      final tangentStart = (adjCp - p1).direction;
      final tangentEnd = (p2 - adjCp).direction;
      final chordDist = (p2 - p1).distance;

      final curveStart = (rel.isBidirectional && chordDist > arrowLen * 2.5)
          ? p1 +
                Offset(
                  arrowLen * cos(tangentStart),
                  arrowLen * sin(tangentStart),
                )
          : p1;
      final curveEnd = (chordDist > arrowLen * 2.5)
          ? p2 - Offset(arrowLen * cos(tangentEnd), arrowLen * sin(tangentEnd))
          : p2;

      final path = Path()
        ..moveTo(curveStart.dx, curveStart.dy)
        ..quadraticBezierTo(adjCp.dx, adjCp.dy, curveEnd.dx, curveEnd.dy);

      if (isSelected || isPathHit) {
        RelationStyleHelper.drawGlow(canvas, path, color);
      }

      if (isDashed) {
        RelationStyleHelper.drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      if (rel.isBidirectional) {
        RelationStyleHelper.drawFilledArrow(
          canvas,
          tip: p2,
          direction: tangentEnd,
          color: color,
        );
        RelationStyleHelper.drawFilledArrow(
          canvas,
          tip: p1,
          direction: tangentStart + pi,
          color: color,
        );
      } else {
        if (isReversed) {
          RelationStyleHelper.drawFilledArrow(
            canvas,
            tip: p1,
            direction: tangentStart + pi,
            color: color,
          );
        } else {
          RelationStyleHelper.drawFilledArrow(
            canvas,
            tip: p2,
            direction: tangentEnd,
            color: color,
          );
        }
      }

      const t = 0.5;
      final labelX =
          (1 - t) * (1 - t) * p1.dx +
          2 * (1 - t) * t * adjCp.dx +
          t * t * p2.dx;
      final labelY =
          (1 - t) * (1 - t) * p1.dy +
          2 * (1 - t) * t * adjCp.dy +
          t * t * p2.dy;
      RelationStyleHelper.drawRelationBadge(
        canvas,
        tp,
        rel.relationType,
        Offset(labelX, labelY),
        color: color,
        isSelected: isSelected || isPathHit,
        isDark: isDark,
        isDimmed: isDimmed && !isPathHit && !isSelected,
        scale: scale,
      );
    }
  }

  String _pairKey(int a, int b) {
    final minId = a < b ? a : b;
    final maxId = a < b ? b : a;
    return '$minId-$maxId';
  }

  @override
  bool shouldRepaint(covariant RelationPainter old) =>
      old.revision != revision ||
      old.relations != relations ||
      old.positions != positions ||
      old.selectedRelationId != selectedRelationId ||
      old.filterState != filterState ||
      old.isDark != isDark ||
      old.visibleRect != visibleRect ||
      old.scale != scale;
}
