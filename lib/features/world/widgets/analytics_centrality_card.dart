import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/world_analytics_engine.dart';
import '../../../core/design/components/oc_avatar.dart';

/// Card widget showing the top hub characters ranked by network degree centrality.
class AnalyticsCentralityCard extends StatelessWidget {
  final int worldId;
  final WorldAnalyticsData data;

  const AnalyticsCentralityCard({
    super.key,
    required this.worldId,
    required this.data,
  });

  static Color getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFF59E0B); // 金
      case 1:
        return const Color(0xFF94A3B8); // 银
      case 2:
        return const Color(0xFFB45309); // 铜
      default:
        return const Color(0xFF6B7280); // 灰
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranking = data.centralityRanking.take(5).toList();

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
              const Icon(
                Icons.stars_rounded,
                size: 17,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '人际网络核心纽带人物 (Top Hubs)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ranking.isEmpty || ranking.first.totalDegree == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '尚未建立人际关系连线',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ranking.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = ranking[index];
                final char = item.character;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/world/$worldId/character/${char.id}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // 排名数字徽标
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: getRankColor(index),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OcAvatar(
                          avatarPath: char.avatarPath,
                          name: char.name,
                          gender: char.gender,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                char.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '关联度: ${item.totalDegree} (出:${item.outDegree} 入:${item.inDegree})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 纽带进度条
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: item.centralityScore,
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                getRankColor(index),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
