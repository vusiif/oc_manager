import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/graph_viewport_culling.dart';

/// Style and drawing helper for relation graph edges, arrowheads, and badges.
class RelationStyleHelper {
  const RelationStyleHelper._();

  /// Resolves the semantic color of a relation based on its type and state.
  static Color getRelationColor(
    String relationType, {
    bool isBidirectional = true,
    bool isDark = false,
    bool isSelected = false,
    bool isDimmed = false,
  }) {
    if (isSelected) {
      return AppColors.brand;
    }

    final type = relationType.trim();
    Color baseColor;

    if (type.contains('恋') ||
        type.contains('爱') ||
        type.contains('情') ||
        type.contains('配偶') ||
        type.contains('夫妻') ||
        type.contains('心上人') ||
        type.contains('暗恋') ||
        type.contains('喜欢')) {
      // 爱情/羁绊: 绮丽玫瑰粉
      baseColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E);
    } else if (type.contains('敌') ||
        type.contains('仇') ||
        type.contains('对立') ||
        type.contains('背叛') ||
        type.contains('戒备') ||
        type.contains('决裂') ||
        type.contains('断绝')) {
      // 敌对/冲突: 警示赤红
      baseColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
    } else if (type.contains('友') ||
        type.contains('盟') ||
        type.contains('伴') ||
        type.contains('知己') ||
        type.contains('战友') ||
        type.contains('结拜') ||
        type.contains('青梅竹马')) {
      // 友情/同盟: 翡翠青绿
      baseColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    } else if (type.contains('亲') ||
        type.contains('父') ||
        type.contains('母') ||
        type.contains('子') ||
        type.contains('女') ||
        type.contains('兄') ||
        type.contains('弟') ||
        type.contains('姐') ||
        type.contains('妹') ||
        type.contains('家')) {
      // 亲情/血缘: 暖金琥珀
      baseColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
    } else if (type.contains('师') ||
        type.contains('徒') ||
        type.contains('指导') ||
        type.contains('教导') ||
        type.contains('导') ||
        type.contains('引路') ||
        type.contains('学')) {
      // 师生/传承: 睿智紫罗兰
      baseColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
    } else if (type.contains('事') ||
        type.contains('僚') ||
        type.contains('级') ||
        type.contains('搭档') ||
        type.contains('雇') ||
        type.contains('主仆') ||
        type.contains('合伙')) {
      // 职场/同事: 商务天蓝
      baseColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    } else if (isBidirectional) {
      // 通用双向: 优雅靛蓝
      baseColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
    } else {
      // 通用单向: 活力暖橙
      baseColor = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    }

    if (isDimmed) {
      return baseColor.withValues(alpha: 0.18);
    }
    return baseColor;
  }

  /// Determines if a relation should be rendered with a dashed stroke.
  static bool isDashedRelation(String relationType) {
    final type = relationType.trim();
    return type.contains('敌') ||
        type.contains('仇') ||
        type.contains('对立') ||
        type.contains('背叛') ||
        type.contains('戒备') ||
        type.contains('决裂') ||
        type.contains('断绝');
  }

  /// Computes the dynamic curve offset for bezier lines in a group.
  static double computeCurveOffset(int index, int total, double dist) {
    if (total <= 1) return 0.0;
    final multiplier = index - (total - 1) / 2.0;
    final baseOffset = (dist * 0.16).clamp(30.0, 52.0);
    return multiplier * baseOffset;
  }

  /// Draws a modern filled arrowhead with an aerodynamic dart notch.
  static void drawFilledArrow(
    Canvas canvas, {
    required Offset tip,
    required double direction,
    required Color color,
    double length = 10.5,
    double width = 8.0,
  }) {
    final cosD = cos(direction);
    final sinD = sin(direction);
    final normX = -sinD;
    final normY = cosD;

    final halfW = width / 2.0;
    final baseCenter = Offset(tip.dx - length * cosD, tip.dy - length * sinD);
    final left = Offset(
      baseCenter.dx + halfW * normX,
      baseCenter.dy + halfW * normY,
    );
    final right = Offset(
      baseCenter.dx - halfW * normX,
      baseCenter.dy - halfW * normY,
    );
    final notch = Offset(
      tip.dx - (length - 2.0) * cosD,
      tip.dy - (length - 2.0) * sinD,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  /// Draws a dashed path using PathMetrics.
  static void drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashLength = 7.0,
    double dashSpace = 4.5,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = min(dashLength, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  /// Draws glowing halo layers for selected or highlighted paths.
  static void drawGlow(Canvas canvas, Path path, Color color) {
    // Outer atmospheric glow
    final outerHalo = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawPath(path, outerHalo);

    // Inner focused neon core
    final innerHalo = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(path, innerHalo);
  }

  /// Draws an elegant pill badge for the relation label.
  static void drawRelationBadge(
    Canvas canvas,
    TextPainter tp,
    String text,
    Offset center, {
    required Color color,
    bool isSelected = false,
    bool isDark = false,
    bool isDimmed = false,
    double scale = 1.0,
  }) {
    if (GraphViewportCulling.getLodLevel(scale) != GraphLodLevel.full &&
        !isSelected) {
      return;
    }

    final alphaMultiplier = isDimmed ? 0.25 : 1.0;
    final textColor =
        (isSelected
                ? AppColors.brand
                : (isDark
                      ? Colors.white.withValues(alpha: 0.95)
                      : AppColors.lightTextPrimary))
            .withValues(alpha: alphaMultiplier);

    final bgBase = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgColor =
        (isSelected
                ? (isDark
                      ? AppColors.brand.withValues(alpha: 0.25)
                      : AppColors.brandLight)
                : Color.alphaBlend(
                    color.withValues(alpha: isDark ? 0.16 : 0.09),
                    bgBase,
                  ))
            .withValues(alpha: alphaMultiplier);

    final borderColor =
        (isSelected
                ? AppColors.brand
                : color.withValues(alpha: isDark ? 0.5 : 0.4))
            .withValues(alpha: alphaMultiplier);

    tp.text = TextSpan(
      text: text,
      style: AppFonts.textStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    tp.layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 16,
      height: tp.height + 7,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Badge shadow
    if (!isDimmed) {
      final shadowColor = isSelected
          ? AppColors.brand.withValues(alpha: 0.35)
          : (isDark
                ? Colors.black.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.15));
      final shadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawRRect(rrect.shift(const Offset(0, 1.2)), shadowPaint);
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
        ..strokeWidth = isSelected ? 1.6 : 1.0,
    );

    // Label text
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}
