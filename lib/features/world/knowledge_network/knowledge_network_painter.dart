import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/design_tokens.dart';
import 'knowledge_network_models.dart';

/// 统一知识网络高性能 Canvas 绘制器 (LORE-007)
/// 支持 LOD (Level of Detail)、视口裁剪 (Viewport Culling)、聚焦高亮与淡化
class KnowledgeNetworkPainter extends CustomPainter {
  final List<NetworkEdge> edges;
  final Map<String, Offset> positions;
  final Map<String, NetworkNode> nodes;
  final String? focusedNodeId;
  final Set<String> neighborNodeIds;
  final bool isDark;
  final double scale;
  final Rect? visibleRect; // 当前可见世界坐标视口 (用于裁剪)
  final Offset center;
  final bool showOrbitGuides;

  KnowledgeNetworkPainter({
    required this.edges,
    required this.positions,
    required this.nodes,
    this.focusedNodeId,
    this.neighborNodeIds = const {},
    this.isDark = false,
    this.scale = 1.0,
    this.visibleRect,
    this.center = const Offset(1600, 1200),
    this.showOrbitGuides = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制背景星系轨道辅助线 (Galaxy Orbit Guides)
    if (showOrbitGuides) {
      _drawOrbitGuides(canvas);
    }

    // 2. 绘制聚焦节点外圈扩散光晕
    if (focusedNodeId != null && positions.containsKey(focusedNodeId)) {
      _drawFocusHalo(canvas, positions[focusedNodeId]!);
    }

    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 3. 绘制所有关联边 (连线 + 箭头 + 标签)
    // 分为两趟绘制：第一趟绘制淡化背景边，第二趟绘制高亮边与正常边，确保高亮边置顶
    final normalEdges = <NetworkEdge>[];
    final highlightedEdges = <NetworkEdge>[];
    final dimmedEdges = <NetworkEdge>[];

    for (final edge in edges) {
      final p1 = positions[edge.fromId];
      final p2 = positions[edge.toId];
      if (p1 == null || p2 == null) continue;

      // 视口裁剪保护 (Viewport Culling)
      if (visibleRect != null) {
        final edgeBounds = Rect.fromPoints(p1, p2).inflate(80);
        if (!visibleRect!.overlaps(edgeBounds)) {
          continue; // 超出视口范围跳过绘制
        }
      }

      if (focusedNodeId != null) {
        final isConnectedToFocus =
            edge.fromId == focusedNodeId || edge.toId == focusedNodeId;
        if (isConnectedToFocus) {
          highlightedEdges.add(edge);
        } else {
          dimmedEdges.add(edge);
        }
      } else {
        normalEdges.add(edge);
      }
    }

    // 绘制淡化边
    for (final edge in dimmedEdges) {
      _drawEdge(
        canvas,
        edge,
        linePaint,
        textPainter,
        isDimmed: true,
        isHighlighted: false,
      );
    }

    // 绘制普通边
    for (final edge in normalEdges) {
      _drawEdge(
        canvas,
        edge,
        linePaint,
        textPainter,
        isDimmed: false,
        isHighlighted: false,
      );
    }

    // 绘制高亮边 (置顶)
    for (final edge in highlightedEdges) {
      _drawEdge(
        canvas,
        edge,
        linePaint,
        textPainter,
        isDimmed: false,
        isHighlighted: true,
      );
    }
  }

  /// 绘制单个边
  void _drawEdge(
    Canvas canvas,
    NetworkEdge edge,
    Paint linePaint,
    TextPainter tp, {
    required bool isDimmed,
    required bool isHighlighted,
  }) {
    final from = positions[edge.fromId]!;
    final to = positions[edge.toId]!;

    final baseColor = edge.customColor ?? edge.type.color;
    Color edgeColor;
    double strokeWidth;

    if (isHighlighted) {
      edgeColor = baseColor;
      strokeWidth = 2.8;

      // 聚焦连线绘制外发光底衬
      final haloPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.35)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, haloPaint);
    } else if (isDimmed) {
      edgeColor = (isDark ? Colors.white : Colors.black).withValues(
        alpha: 0.08,
      );
      strokeWidth = 1.0;
    } else {
      edgeColor = baseColor.withValues(alpha: 0.7);
      strokeWidth = 1.6;
    }

    linePaint.color = edgeColor;
    linePaint.strokeWidth = strokeWidth;

    // 空间层级使用虚线，其余使用实线
    if (edge.type == NetworkEdgeType.hierarchy) {
      _drawDashedLine(
        canvas,
        from,
        to,
        linePaint,
        dashWidth: 6.0,
        dashSpace: 4.0,
      );
    } else {
      canvas.drawLine(from, to, linePaint);
    }

    // 箭头指示
    if (!edge.isBidirectional && !isDimmed) {
      final dir = (to - from).direction;
      // 距离目标点适当偏移以防被节点 Widget 遮挡 (radius ~ 36)
      const targetPadding = 36.0;
      final arrowPos = Offset(
        to.dx - cos(dir) * targetPadding,
        to.dy - sin(dir) * targetPadding,
      );
      _drawArrow(
        canvas,
        arrowPos,
        dir,
        edgeColor,
        size: isHighlighted ? 10.0 : 7.0,
      );
    }

    // LOD 保护：大尺度缩放 (scale < 0.45) 或处于被淡化状态时，省略文本排版
    if (scale >= 0.45 && !isDimmed && edge.label.isNotEmpty) {
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      _drawLabel(
        canvas,
        tp,
        edge.label,
        mid,
        color: baseColor,
        isHighlighted: isHighlighted,
      );
    }
  }

  /// 绘制关系药丸小胶囊标签
  void _drawLabel(
    Canvas canvas,
    TextPainter tp,
    String text,
    Offset center, {
    required Color color,
    required bool isHighlighted,
  }) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: isHighlighted ? 11.5 : 10.0,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
        color: isHighlighted
            ? (isDark ? Colors.white : const Color(0xFF0F172A))
            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
      ),
    );
    tp.layout();

    final paddingH = isHighlighted ? 8.0 : 6.0;
    final paddingV = isHighlighted ? 3.0 : 2.0;
    final bgRect = Rect.fromCenter(
      center: center,
      width: tp.width + paddingH * 2,
      height: tp.height + paddingV * 2,
    );

    final bgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isHighlighted
          ? color
          : (isDark ? Colors.white24 : Colors.black12)
      ..strokeWidth = isHighlighted ? 1.5 : 0.8
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(10));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  /// 绘制虚线
  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashWidth = 5.0,
    double dashSpace = 3.0,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final cosA = dx / distance;
    final sinA = dy / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final start = Offset(
        p1.dx + cosA * currentDist,
        p1.dy + sinA * currentDist,
      );
      final nextDist = min(currentDist + dashWidth, distance);
      final end = Offset(p1.dx + cosA * nextDist, p1.dy + sinA * nextDist);
      canvas.drawLine(start, end, paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  /// 绘制方向箭头
  void _drawArrow(
    Canvas canvas,
    Offset tip,
    double angle,
    Color color, {
    double size = 8.0,
  }) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - size * cos(angle - pi / 6),
      tip.dy - size * sin(angle - pi / 6),
    );
    path.lineTo(
      tip.dx - (size * 0.6) * cos(angle),
      tip.dy - (size * 0.6) * sin(angle),
    );
    path.lineTo(
      tip.dx - size * cos(angle + pi / 6),
      tip.dy - size * sin(angle + pi / 6),
    );
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  /// 绘制背景星系轨道辅助线
  void _drawOrbitGuides(Canvas canvas) {
    final guidePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制 3 道同心轨道
    const orbits = [220.0, 480.0, 780.0, 1100.0];
    for (final r in orbits) {
      canvas.drawCircle(center, r, guidePaint);
    }
  }

  /// 绘制聚焦节点外圈高亮光晕
  void _drawFocusHalo(Canvas canvas, Offset pos) {
    final haloPaint = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 54.0, haloPaint);

    final borderHaloPaint = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, 54.0, borderHaloPaint);
  }

  @override
  bool shouldRepaint(covariant KnowledgeNetworkPainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.positions != positions ||
        oldDelegate.focusedNodeId != focusedNodeId ||
        oldDelegate.isDark != isDark ||
        oldDelegate.scale != scale ||
        oldDelegate.visibleRect != visibleRect;
  }
}
