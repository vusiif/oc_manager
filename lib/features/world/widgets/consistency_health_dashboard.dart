import 'package:flutter/material.dart';

import '../../../core/consistency/consistency_checker_engine.dart';

/// Health overview dashboard card for the consistency checker.
class ConsistencyHealthDashboard extends StatelessWidget {
  final ConsistencyReport report;
  final int activeScore;
  final int activeCount;
  final int processedCount;

  const ConsistencyHealthDashboard({
    super.key,
    required this.report,
    required this.activeScore,
    required this.activeCount,
    required this.processedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color scoreColor;
    String scoreStatus;
    if (activeScore >= 90) {
      scoreColor = const Color(0xFF10B981);
      scoreStatus = '自洽优秀';
    } else if (activeScore >= 65) {
      scoreColor = const Color(0xFFF59E0B);
      scoreStatus = '存在隐患';
    } else {
      scoreColor = const Color(0xFFEF4444);
      scoreStatus = '矛盾较多';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 分数徽标
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$activeScore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '自洽健康指数：$scoreStatus',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '待办 $activeCount 项 · 已处理 $processedCount 项',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '覆盖时间生卒时序、人物社会关系闭环、维基双链断裂、沙盒资源完整性与设定完整度。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
