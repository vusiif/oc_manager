import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/world_analytics_engine.dart';
import '../../providers/character_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/relation_provider.dart';
import 'widgets/analytics_centrality_card.dart';
import 'widgets/analytics_donut_card.dart';
import 'widgets/analytics_group_bars_card.dart';
import 'widgets/analytics_metrics_row.dart';

/// 世界全景分析与网络大盘弹窗
class WorldAnalyticsDialog extends ConsumerStatefulWidget {
  final int worldId;
  final String worldName;

  const WorldAnalyticsDialog({
    super.key,
    required this.worldId,
    required this.worldName,
  });

  @override
  ConsumerState<WorldAnalyticsDialog> createState() =>
      _WorldAnalyticsDialogState();
}

class _WorldAnalyticsDialogState extends ConsumerState<WorldAnalyticsDialog> {
  Map<int, List<int>> _characterGroupMap = {};
  bool _loadingGroups = true;

  @override
  void initState() {
    super.initState();
    _loadGroupMappings();
  }

  Future<void> _loadGroupMappings() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.select(db.characterGroups).get();
      final map = <int, List<int>>{};
      for (final r in rows) {
        map.putIfAbsent(r.characterId, () => []).add(r.groupId);
      }
      if (mounted) {
        setState(() {
          _characterGroupMap = map;
          _loadingGroups = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingGroups = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );
    final relationsAsync = ref.watch(relationsByWorldProvider(widget.worldId));
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.worldId));

    final characters = charactersAsync.valueOrNull ?? [];
    final relations = relationsAsync.valueOrNull ?? [];
    final groups = groupsAsync.valueOrNull ?? [];

    final data = WorldAnalyticsEngine.analyze(
      characters: characters,
      relations: relations,
      groups: groups,
      characterGroupMap: _characterGroupMap,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.worldName} · 全景数据大盘与人际网络分析',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '宏观审视创作进度、势力分布均衡性与人际核心枢纽',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // 主内容
              if (_loadingGroups)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '该世界观下暂无人物数据',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 1. 核心大盘指标卡片
                        AnalyticsMetricsRow(data: data),
                        const SizedBox(height: 20),

                        // 2. 双环形图（创作阶段 + 性别构成）
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnalyticsDonutCard(
                                title: '创作阶段分布',
                                icon: Icons.track_changes_rounded,
                                slices: data.statusStats,
                                centerValue: '${data.totalCharacters}',
                                centerTitle: '总人物',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnalyticsDonutCard(
                                title: '角色性别构成',
                                icon: Icons.pie_chart_rounded,
                                slices: data.genderStats,
                                centerValue:
                                    '${(data.finalizedRate).toStringAsFixed(0)}%',
                                centerTitle: '定稿率',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. 组织阵营分布与人际枢纽榜单
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 势力阵营分布
                            Expanded(
                              flex: 5,
                              child: AnalyticsGroupBarsCard(data: data),
                            ),
                            const SizedBox(width: 16),
                            // 网络核心纽带榜
                            Expanded(
                              flex: 6,
                              child: AnalyticsCentralityCard(
                                worldId: widget.worldId,
                                data: data,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
