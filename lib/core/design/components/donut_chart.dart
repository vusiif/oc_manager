import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../analytics/world_analytics_engine.dart';

/// 高保真原生自绘环形甜甜圈图 (Donut Chart)
class DonutChart extends StatelessWidget {
  final List<CategorySlice> slices;
  final double size;
  final double strokeWidth;
  final String? centerTitle;
  final String? centerValue;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 140,
    this.strokeWidth = 24,
    this.centerTitle,
    this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (slices.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '无数据',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              slices: slices,
              strokeWidth: strokeWidth,
            ),
          ),
          if (centerValue != null || centerTitle != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (centerValue != null)
                  Text(
                    centerValue!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (centerTitle != null)
                  Text(
                    centerTitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategorySlice> slices;
  final double strokeWidth;

  _DonutChartPainter({
    required this.slices,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double startAngle = -math.pi / 2; // 从正上方 12 点钟开始

    final totalCount = slices.fold<int>(0, (sum, s) => sum + s.count);
    if (totalCount == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.count / totalCount) * 2 * math.pi;

      paint.color = slice.color;

      // 绘制扇区弧线
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 图例面板 (Legend)
class DonutLegend extends StatelessWidget {
  final List<CategorySlice> slices;

  const DonutLegend({
    super.key,
    required this.slices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: '${s.label} ',
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text:
                              '${s.count}人 (${(s.ratio * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
