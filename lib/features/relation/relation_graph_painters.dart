import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import 'graph_geometry.dart';
import 'relation_advanced_analysis.dart';

const familyRelationTypes = ['亲子', '父母', '父女', '父子', '母子', '母女', '家人'];
const _familyTypes = familyRelationTypes;

class ConnectingLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  ConnectingLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, haloPaint);
    canvas.drawLine(from, to, paint);

    final endCircle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 5.0, endCircle);
  }

  @override
  bool shouldRepaint(covariant ConnectingLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
}

// --- 网格背景 ---

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.color != color;
}

// --- 关系连线绘制 ---

// --- 关系连线绘制 ---

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
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final characterMap = {for (final c in characters) c.id: c};

    // 分离家谱组和普通组
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

    // 绘制家谱
    for (final entry in familyGroups.entries) {
      _drawFamilyGroup(
        canvas,
        textPainter,
        linePaint,
        entry.value,
        characterMap,
      );
    }

    // 绘制普通关系
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

  // --- 家谱图：遗传图风格 ---

  void _drawFamilyGroup(
    Canvas canvas,
    TextPainter tp,
    Paint paint,
    List<Relation> group,
    Map<int, Character> characterMap,
  ) {
    // 收集父母和子女
    final parentIds = <int>{};
    final childIds = <int>{};

    for (final rel in group) {
      // fromCharacterId = 父母, toCharacterId = 子女
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
    Color color = Colors.blue.shade300;
    if (isPathHit) {
      color = AppColors.brand;
    } else if (isDimmed) {
      color = color.withValues(alpha: 0.15);
    }
    paint.color = color;
    paint.strokeWidth = isPathHit ? 3.5 : (isDimmed ? 1.0 : 2.0);

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

      // 父母中点
      parentMid = Offset((edge1.dx + edge2.dx) / 2, (edge1.dy + edge2.dy) / 2);

      // 更多父母连到中点
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
      // 单亲家庭支持
      parentMid = parents[0];
    }

    // 确定 busY：在 parentMid 下方
    double busY;
    if (minChildY > parentMid.dy) {
      busY = parentMid.dy + (minChildY - parentMid.dy) * 0.4;
    } else {
      busY = parentMid.dy + 50;
    }

    final busStart = Offset(parentMid.dx, busY);
    final topPoint = parents.length >= 2
        ? parentMid
        : GraphGeometry.calculateBoundaryIntersection(
            nodeCenter: parentMid,
            gender: characterMap[parentIds.first]?.gender ?? '',
            angle: pi / 2,
          );
    canvas.drawLine(topPoint, busStart, paint);

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
      canvas.drawLine(midPoint, cEdge, paint);

      final childDir = (child - midPoint).direction;
      _drawArrowDir(canvas, cEdge, childDir, color);
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
        canvas.drawLine(junction, cEdge, paint);
        final childDir = (child - junction).direction;
        _drawArrowDir(canvas, cEdge, childDir, color);
      }
    }

    final isSelected = group.any((r) => r.id == selectedRelationId);
    final relType = group.first.relationType;
    _drawLabel(
      canvas,
      tp,
      relType,
      Offset(parentMid.dx, parentMid.dy + 16),
      isSelected: isSelected || isPathHit,
      isDark: isDark,
      isDimmed: isDimmed && !isPathHit && !isSelected,
    );
  }

  // --- 普通关系：弧线/直线 ---

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

      Color color = isSelected || isPathHit
          ? AppColors.brand
          : (rel.isBidirectional
                ? Colors.blue.shade300
                : Colors.orange.shade300);

      if (isDimmed && !isPathHit && !isSelected) {
        color = color.withValues(alpha: 0.15);
      }

      paint.color = color;
      paint.strokeWidth = isSelected || isPathHit
          ? 3.5
          : (isDimmed ? 1.0 : 2.0);

      final isReversed = (rel.fromCharacterId != baseFromId);

      final offset = count == 1 ? 0.0 : (i - (count - 1) / 2) * 40.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;

      if (count == 1) {
        final p1 = GraphGeometry.getExitPoint(
          fromCenter: from,
          toCenter: to,
          fromGender: fromGender,
        );
        final p2 = GraphGeometry.getEntryPoint(
          fromCenter: from,
          toCenter: to,
          toGender: toGender,
        );

        if (isSelected || isPathHit) {
          final haloPaint = Paint()
            ..color = AppColors.brand.withValues(alpha: 0.35)
            ..strokeWidth = 7.0
            ..style = PaintingStyle.stroke;
          canvas.drawLine(p1, p2, haloPaint);
        }

        canvas.drawLine(p1, p2, paint);

        if (rel.isBidirectional) {
          _drawArrow(canvas, p1, p2, color);
          _drawArrow(canvas, p2, p1, color);
        } else {
          if (isReversed) {
            _drawArrow(canvas, p2, p1, color);
          } else {
            _drawArrow(canvas, p1, p2, color);
          }
        }

        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        _drawLabel(
          canvas,
          tp,
          rel.relationType,
          mid,
          isSelected: isSelected || isPathHit,
          isDark: isDark,
          isDimmed: isDimmed && !isPathHit && !isSelected,
        );
      } else {
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
        );
        final p2 = GraphGeometry.calculateBoundaryIntersection(
          nodeCenter: to,
          gender: toGender,
          angle: tEnd + pi,
        );

        final adjCp = Offset(
          (p1.dx + p2.dx) / 2 + nx * offset,
          (p1.dy + p2.dy) / 2 + ny * offset,
        );

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(adjCp.dx, adjCp.dy, p2.dx, p2.dy);

        if (isSelected || isPathHit) {
          final haloPaint = Paint()
            ..color = AppColors.brand.withValues(alpha: 0.35)
            ..strokeWidth = 7.0
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path, haloPaint);
        }

        canvas.drawPath(path, paint);

        if (rel.isBidirectional) {
          _drawArrowDir(canvas, p2, tEnd, color);
          _drawArrowDir(canvas, p1, tStart + pi, color);
        } else {
          if (isReversed) {
            _drawArrowDir(canvas, p1, tStart + pi, color);
          } else {
            _drawArrowDir(canvas, p2, tEnd, color);
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
        _drawLabel(
          canvas,
          tp,
          rel.relationType,
          Offset(labelX, labelY),
          isSelected: isSelected || isPathHit,
          isDark: isDark,
          isDimmed: isDimmed && !isPathHit && !isSelected,
        );
      }
    }
  }

  String _pairKey(int a, int b) {
    final minId = a < b ? a : b;
    final maxId = a < b ? b : a;
    return '$minId-$maxId';
  }

  void _drawLabel(
    Canvas canvas,
    TextPainter tp,
    String text,
    Offset center, {
    bool isSelected = false,
    bool isDark = false,
    bool isDimmed = false,
  }) {
    // LOD Protection (PERF-001): When zoomed out (scale < 0.55), skip label text and badge layout unless selected
    if (GraphViewportCulling.getLodLevel(scale) != GraphLodLevel.full &&
        !isSelected) {
      return;
    }

    final alphaMultiplier = isDimmed ? 0.25 : 1.0;
    final textColor =
        (isSelected
                ? AppColors.brand
                : (isDark ? Colors.white70 : Colors.grey.shade800))
            .withValues(alpha: alphaMultiplier);
    final bgColor =
        (isSelected
                ? (isDark
                      ? AppColors.brand.withValues(alpha: 0.25)
                      : AppColors.brandLight)
                : (isDark ? const Color(0xFF2C2C2E) : Colors.white))
            .withValues(alpha: alphaMultiplier);
    final borderColor =
        (isSelected
                ? AppColors.brand
                : (isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade300))
            .withValues(alpha: alphaMultiplier);

    tp.text = TextSpan(
      text: text,
      style: AppFonts.textStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
    tp.layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 12,
      height: tp.height + 6,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    if (isSelected) {
      final shadowPaint = Paint()
        ..color = AppColors.brand.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawRRect(rrect, shadowPaint);
    }

    // Badge background
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    // Badge border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0,
    );

    // Label text
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    _drawArrowDir(canvas, to, (to - from).direction, color);
  }

  void _drawArrowDir(Canvas canvas, Offset pos, double direction, Color color) {
    const arrowSize = 10.0;
    const arrowAngle = 0.5;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction - arrowAngle),
        pos.dy - arrowSize * sin(direction - arrowAngle),
      )
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction + arrowAngle),
        pos.dy - arrowSize * sin(direction + arrowAngle),
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
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
        _familyTypes.contains(rel.relationType)) {
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
