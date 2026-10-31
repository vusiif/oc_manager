import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/world_analytics_engine.dart';
import '../../core/design/components/donut_chart.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/database_provider.dart';

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
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));
    final relationsAsync =
        ref.watch(relationsByWorldProvider(widget.worldId));
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
        constraints: const BoxConstraints(
          maxWidth: 920,
          maxHeight: 700,
        ),
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
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
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
                      _buildMetricCards(context, data),
                      const SizedBox(height: 20),

                      // 2. 双环形图（创作阶段 + 性别构成）
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildChartCard(
                              context,
                              title: '创作阶段分布',
                              icon: Icons.track_changes_rounded,
                              slices: data.statusStats,
                              centerValue: '${data.totalCharacters}',
                              centerTitle: '总人物',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildChartCard(
                              context,
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
                            child: _buildGroupBarsCard(context, data),
                          ),
                          const SizedBox(width: 16),
                          // 网络核心纽带榜
                          Expanded(
                            flex: 6,
                            child: _buildCentralityCard(context, data),
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

  /// 核心数字指标统计行
  Widget _buildMetricCards(BuildContext context, WorldAnalyticsData data) {
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
            subtitle: _getDensityLevel(data.networkDensity),
          ),
        ),
      ],
    );
  }

  String _getDensityLevel(double density) {
    if (density >= 0.5) return '高度紧密网络';
    if (density >= 0.2) return '常态群落网络';
    if (density > 0) return '分散星丛网络';
    return '独立孤立节点';
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
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 甜甜圈环形图卡片
  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<CategorySlice> slices,
    String? centerValue,
    String? centerTitle,
  }) {
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
              Expanded(
                child: DonutLegend(slices: slices),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 组织势力规模横向进度柱
  Widget _buildGroupBarsCard(
      BuildContext context, WorldAnalyticsData data) {
    final theme = Theme.of(context);
    final groups = data.groupStats;

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
              Icon(Icons.groups_rounded,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                '阵营与组织势力规模',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无组织阵营划分',
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
              itemCount: groups.length.clamp(0, 5),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final g = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          g.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${g.count}人 (${(g.ratio * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: g.ratio,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(g.color),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /// 关系网络中心性人物榜 (Top Hub Characters)
  Widget _buildCentralityCard(
      BuildContext context, WorldAnalyticsData data) {
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
              const Icon(Icons.stars_rounded,
                  size: 17, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '人际网络核心纽带人物 (Top Hubs)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
                    context.push(
                        '/world/${widget.worldId}/character/${char.id}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
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
                            color: _getRankColor(index),
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
                                _getRankColor(index),
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

  Color _getRankColor(int index) {
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
}
