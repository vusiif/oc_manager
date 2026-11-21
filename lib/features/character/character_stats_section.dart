import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/design/components/radar_chart.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import 'widgets/stat_dimension_dialogs.dart';
import 'widgets/stat_slider_row.dart';

/// 角色战斗力与六维属性雷达图组件 (P1)
class CharacterStatsSection extends ConsumerWidget {
  final int characterId;

  const CharacterStatsSection({super.key, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(characterStatsProvider(characterId));

    return statsAsync.when(
      data: (stats) =>
          _CharacterStatsCard(characterId: characterId, stats: stats),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('加载属性失败: $e'),
        ),
      ),
    );
  }
}

/// 战力与属性雷达图卡片主体
class _CharacterStatsCard extends ConsumerStatefulWidget {
  final int characterId;
  final List<CharacterStat> stats;

  const _CharacterStatsCard({required this.characterId, required this.stats});

  @override
  ConsumerState<_CharacterStatsCard> createState() =>
      _CharacterStatsCardState();
}

class _CharacterStatsCardState extends ConsumerState<_CharacterStatsCard> {
  final Map<int, double> _localValues = {};

  @override
  void initState() {
    super.initState();
    _syncLocalValues();
  }

  @override
  void didUpdateWidget(covariant _CharacterStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats != widget.stats) {
      _syncLocalValues();
    }
  }

  void _syncLocalValues() {
    for (final s in widget.stats) {
      if (!_localValues.containsKey(s.id)) {
        _localValues[s.id] = s.value;
      }
    }
    // 清理已删除的属性 ID
    final currentIds = widget.stats.map((s) => s.id).toSet();
    _localValues.removeWhere((id, _) => !currentIds.contains(id));
  }

  Future<void> _applyPreset(StatPreset preset) async {
    final companions = [
      for (var i = 0; i < preset.dimensions.length; i++)
        CharacterStatsCompanion.insert(
          characterId: widget.characterId,
          label: preset.dimensions[i],
          value: Value(
            preset.defaultValues?[preset.dimensions[i]] ??
                (preset.maxValue * 0.6),
          ),
          maxValue: Value(preset.maxValue),
          sortOrder: Value(i),
        ),
    ];
    await ref
        .read(characterActionsProvider)
        .setStats(widget.characterId, companions);
  }

  void _showPresetPicker(BuildContext context) {
    showStatPresetPicker(context, onSelect: _applyPreset);
  }

  void _showAddStatDialog(BuildContext context) {
    showAddStatDialog(
      context,
      characterId: widget.characterId,
      currentCount: widget.stats.length,
      ref: ref,
    );
  }

  void _showEditStatDialog(BuildContext context, CharacterStat stat) {
    showEditStatDialog(context, stat: stat, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.stats;

    if (stats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '战力与属性 (六维雷达图)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '暂未配置属性维度。支持一键套用 TRPG 跑团、奇幻战力或心智性格预设，并在卡片上呈现多边形雷达图。',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('套用常用预设模版'),
                    onPressed: () => _showPresetPicker(context),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('自定义添加属性'),
                    onPressed: () => _showAddStatDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 构建雷达图数据项（使用实时滑动数值保证跟手动效）
    final radarItems = [
      for (final s in stats)
        RadarStatItem(
          label: s.label,
          value: (_localValues[s.id] ?? s.value).clamp(0.0, s.maxValue),
          maxValue: s.maxValue,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部标题栏
            Row(
              children: [
                Icon(Icons.radar_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '战力与属性',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stats.length} 维',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: '套用预设',
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('预设'),
                    onPressed: () => _showPresetPicker(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  tooltip: '添加新维度',
                  onPressed: () => _showAddStatDialog(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text(
                        '清空全部属性',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'clear_all') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认清空'),
                          content: const Text('确定要清空该角色的全部属性数据吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(characterActionsProvider)
                                    .setStats(widget.characterId, []);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('清空'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 自适应栅格：宽屏左右并排，窄屏上下排列
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 580;

                final chartPart = SizedBox(
                  width: isWide ? 260 : double.infinity,
                  height: 250,
                  child: Center(
                    child: RadarChart(items: radarItems, size: 240),
                  ),
                );

                final slidersPart = Column(
                  children: [
                    for (final stat in stats)
                      StatSliderRow(
                        stat: stat,
                        currentValue: _localValues[stat.id] ?? stat.value,
                        onChanged: (v) {
                          setState(() {
                            _localValues[stat.id] = v;
                          });
                        },
                        onChangeEnd: (v) async {
                          await ref
                              .read(characterActionsProvider)
                              .updateStat(
                                CharacterStatsCompanion(
                                  id: Value(stat.id),
                                  characterId: Value(stat.characterId),
                                  label: Value(stat.label),
                                  value: Value(v),
                                  maxValue: Value(stat.maxValue),
                                  sortOrder: Value(stat.sortOrder),
                                ),
                              );
                        },
                        onEdit: () => _showEditStatDialog(context, stat),
                        onDelete: () async {
                          await ref
                              .read(characterActionsProvider)
                              .deleteStat(stat.id);
                        },
                      ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      chartPart,
                      const SizedBox(width: 16),
                      Expanded(child: slidersPart),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      chartPart,
                      const SizedBox(height: 12),
                      slidersPart,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
