import 'package:flutter/material.dart';

import '../../../core/analytics/world_analytics_engine.dart';
import '../../../core/design/components/donut_chart.dart';

/// Card widget displaying a donut chart and legend for distribution analysis.
class AnalyticsDonutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<CategorySlice> slices;
  final String? centerValue;
  final String? centerTitle;

  const AnalyticsDonutCard({
    super.key,
    required this.title,
    required this.icon,
    required this.slices,
    this.centerValue,
    this.centerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              DonutChart(
                slices: slices,
                size: 110,
                strokeWidth: 20,
                centerValue: centerValue,
                centerTitle: centerTitle,
              ),
              const SizedBox(width: 16),
              Expanded(child: DonutLegend(slices: slices)),
            ],
          ),
        ],
      ),
    );
  }
}
