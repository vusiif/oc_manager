import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 属性数据项
class RadarStatItem {
  final String label;
  final double value;
  final double maxValue;

  const RadarStatItem({
    required this.label,
    required this.value,
    this.maxValue = 100.0,
  });

  double get ratio => (value / (maxValue <= 0 ? 1.0 : maxValue)).clamp(0.0, 1.0);
}

/// 常用属性预设模型
class StatPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final double maxValue;
  final List<String> dimensions;
  final Map<String, double>? defaultValues;

  const StatPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.maxValue = 100.0,
    required this.dimensions,
    this.defaultValues,
  });

  /// 开箱即用的预设库
  static const List<StatPreset> builtInPresets = [
    StatPreset(
      id: 'anime_battle',
      name: '二次元通用战力',
      description: '适合奇幻冒险、战斗番及异世界题材（6 维）',
      icon: Icons.flash_on_rounded,
      maxValue: 100.0,
      dimensions: ['力量', '敏捷', '智力', '体质', '精神', '幸运'],
      defaultValues: {
        '力量': 70,
        '敏捷': 75,
        '智力': 60,
        '体质': 65,
        '精神': 80,
        '幸运': 50,
      },
    ),
    StatPreset(
      id: 'dnd_classic',
      name: 'D&D 经典六维',
      description: '龙与地下城 TRPG 标准属性，满值 20 分（6 维）',
      icon: Icons.casino_rounded,
      maxValue: 20.0,
      dimensions: ['力量 (STR)', '敏捷 (DEX)', '体质 (CON)', '智力 (INT)', '感知 (WIS)', '魅力 (CHA)'],
      defaultValues: {
        '力量 (STR)': 14,
        '敏捷 (DEX)': 16,
        '体质 (CON)': 12,
        '智力 (INT)': 10,
        '感知 (WIS)': 13,
        '魅力 (CHA)': 15,
      },
    ),
    StatPreset(
      id: 'personality_compass',
      name: '性格心智罗盘',
      description: '多角度刻画角色性格倾向与心智特征（6 维）',
      icon: Icons.psychology_rounded,
      maxValue: 100.0,
      dimensions: ['理智', '同理心', '秩序', '勇气', '进取', '感性'],
      defaultValues: {
        '理智': 80,
        '同理心': 65,
        '秩序': 70,
        '勇气': 60,
        '进取': 75,
        '感性': 50,
      },
    ),
    StatPreset(
      id: 'coc_investigator',
      name: 'CoC 调查员属性',
      description: '克苏鲁神话 TRPG 调查员核心主属性（8 维）',
      icon: Icons.visibility_rounded,
      maxValue: 100.0,
      dimensions: ['力量', '体质', '体型', '敏捷', '外貌', '智力', '意志', '教育'],
      defaultValues: {
        '力量': 50,
        '体质': 60,
        '体型': 55,
        '敏捷': 70,
        '外貌': 65,
        '智力': 80,
        '意志': 75,
        '教育': 70,
      },
    ),
  ];
}

/// 高保真属性雷达图组件
class RadarChart extends StatelessWidget {
  final List<RadarStatItem> items;
  final double? size;
  final int ringCount;
  final Color? fillColor;
  final Color? strokeColor;
  final Color? gridColor;
  final bool showLabels;
  final bool showValues;

  const RadarChart({
    super.key,
    required this.items,
    this.size,
    this.ringCount = 4,
    this.fillColor,
    this.strokeColor,
    this.gridColor,
    this.showLabels = true,
    this.showValues = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = strokeColor ?? theme.colorScheme.primary;
    final fill = fillColor ?? primary.withValues(alpha: isDark ? 0.28 : 0.20);
    final grid = gridColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08));

    if (items.length < 3) {
      return Container(
        height: size ?? 240,
        alignment: Alignment.center,
        child: Text(
          '至少需要 3 项属性以构成雷达多边形',
          style: AppFonts.textStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final chartWidget = CustomPaint(
      size: size != null ? Size(size!, size!) : Size.infinite,
      painter: _RadarChartPainter(
        items: items,
        ringCount: ringCount,
        fillColor: fill,
        strokeColor: primary,
        gridColor: grid,
        showLabels: showLabels,
        showValues: showValues,
        textColor: theme.colorScheme.onSurface,
        secondaryTextColor: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: chartWidget,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dim = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 260.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 260.0,
        );
        return SizedBox(
          width: dim,
          height: dim,
          child: chartWidget,
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarStatItem> items;
  final int ringCount;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final bool showLabels;
  final bool showValues;
  final Color textColor;
  final Color secondaryTextColor;

  _RadarChartPainter({
    required this.items,
    required this.ringCount,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.showLabels,
    required this.showValues,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = items.length;
    if (count < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    // 留出标签与数值所占外边距
    final margin = (showLabels || showValues) ? 38.0 : 12.0;
    final radius = math.max(10.0, math.min(size.width, size.height) / 2 - margin);

    final angleStep = (2 * math.pi) / count;
    // 起始角置于正上方 12 点钟位置 (-pi/2)
    const startAngle = -math.pi / 2;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. 绘制正多边形环与放射轴线
    for (var k = 1; k <= ringCount; k++) {
      final ringRadius = radius * (k / ringCount);
      final ringPath = Path();

      for (var i = 0; i < count; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + ringRadius * math.cos(angle);
        final y = center.dy + ringRadius * math.sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // 放射轴线
    for (var i = 0; i < count; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // 2. 绘制数据多边形
    final dataPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < count; i++) {
      final angle = startAngle + i * angleStep;
      final valueRadius = radius * items[i].ratio;
      final x = center.dx + valueRadius * math.cos(angle);
      final y = center.dy + valueRadius * math.sin(angle);
      final pt = Offset(x, y);
      points.add(pt);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // 填充与描边
    final dataFillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // 顶点圆点
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, dotPaint);
      canvas.drawCircle(pt, 2.0, dotInnerPaint);
    }

    // 3. 绘制文字标签与当前数值
    if (showLabels || showValues) {
      for (var i = 0; i < count; i++) {
        final item = items[i];
        final angle = startAngle + i * angleStep;
        final cosA = math.cos(angle);
        final sinA = math.sin(angle);

        // 顶点外部偏移距离
        final labelDist = radius + 14.0;
        final lx = center.dx + labelDist * cosA;
        final ly = center.dy + labelDist * sinA;

        final formattedVal = item.value.truncateToDouble() == item.value
            ? item.value.toInt().toString()
            : item.value.toStringAsFixed(1);

        final textSpan = TextSpan(
          children: [
            if (showLabels)
              TextSpan(
                text: item.label,
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            if (showLabels && showValues)
              TextSpan(
                text: ' ',
                style: AppFonts.textStyle(fontSize: 8),
              ),
            if (showValues)
              TextSpan(
                text: formattedVal,
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: strokeColor,
                ),
              ),
          ],
        );

        final tp = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        // 根据角度自适应对齐锚点
        var offsetX = -tp.width / 2;
        var offsetY = -tp.height / 2;

        if (cosA > 0.3) {
          offsetX = 0;
        } else if (cosA < -0.3) {
          offsetX = -tp.width;
        }

        if (sinA > 0.4) {
          offsetY = 0;
        } else if (sinA < -0.4) {
          offsetY = -tp.height;
        }

        tp.paint(canvas, Offset(lx + offsetX, ly + offsetY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    if (oldDelegate.items.length != items.length ||
        oldDelegate.ringCount != ringCount ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.showValues != showValues) {
      return true;
    }
    for (var i = 0; i < items.length; i++) {
      if (oldDelegate.items[i].label != items[i].label ||
          oldDelegate.items[i].value != items[i].value ||
          oldDelegate.items[i].maxValue != items[i].maxValue) {
        return true;
      }
    }
    return false;
  }
}
