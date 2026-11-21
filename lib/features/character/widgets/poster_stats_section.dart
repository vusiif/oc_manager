import 'package:flutter/material.dart';

import '../../../core/design/components/radar_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import 'poster_theme_style.dart';

/// 角色海报中的六维雷达图与属性数值矩阵
class PosterStatsSection extends StatelessWidget {
  final List<CharacterStat> stats;
  final PosterStyle style;

  const PosterStatsSection({
    super.key,
    required this.stats,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final radarItems = [
      for (final s in stats)
        RadarStatItem(label: s.label, value: s.value, maxValue: s.maxValue),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: style.accentColor),
              const SizedBox(width: 6),
              Text(
                'ABILITIES & STATS MATRIX',
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: style.accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 雷达图多边形
              SizedBox(
                width: 220,
                height: 200,
                child: RadarChart(
                  items: radarItems,
                  size: 200,
                  strokeColor: style.accentColor,
                  fillColor: style.accentColor.withValues(alpha: 0.24),
                  gridColor: style.subtextColor.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 14),
              // 右侧数值网格
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.map((s) {
                    final val = s.value.truncateToDouble() == s.value
                        ? s.value.toInt()
                        : s.value.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.bgColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: style.cardBorderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.label,
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: style.textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$val',
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: style.accentColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
