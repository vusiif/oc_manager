import 'package:flutter/material.dart';

import '../../../core/analytics/world_analytics_engine.dart';

/// Top metric row displaying character count, relation count, completion rate, and network density.
class AnalyticsMetricsRow extends StatelessWidget {
  final WorldAnalyticsData data;

  const AnalyticsMetricsRow({super.key, required this.data});

  static String getDensityLevel(double density) {
    if (density >= 0.5) return '高度紧密网络';
    if (density >= 0.2) return '常态群落网络';
    if (density > 0) return '分散星丛网络';
    return '独立孤立节点';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context,
            label: '人物总数',
            value: '${data.totalCharacters}',
            unit: '位',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            context,
            label: '人际纽带',
            value: '${data.totalRelations}',
            unit: '条',
            icon: Icons.hub_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            context,
            label: '设定定稿率',
            value: data.finalizedRate.toStringAsFixed(1),
            unit: '%',
            icon: Icons.verified_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            context,
            label: '网络紧密度',
            value: (data.networkDensity * 100).toStringAsFixed(1),
            unit: '%',
            icon: Icons.all_inclusive_rounded,
            color: const Color(0xFFF59E0B),
            subtitle: getDensityLevel(data.networkDensity),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    children: [
                      const WidgetSpan(child: SizedBox(width: 2)),
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: color)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
