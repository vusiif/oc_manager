import 'chronicle_event_card.dart';
import 'chronicle_event_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';

/// 世界编年史全景页面
class ChroniclePage extends ConsumerStatefulWidget {
  final int worldId;

  const ChroniclePage({super.key, required this.worldId});

  @override
  ConsumerState<ChroniclePage> createState() => _ChroniclePageState();
}

class _ChroniclePageState extends ConsumerState<ChroniclePage> {
  String? _selectedCategory; // null = 全部
  int _minImportance = 1; // 1 = 全部, 2 = 关键及以上, 3 = 仅史诗
  int? _selectedCharacterFilter; // null = 全部, -1 = 仅独立世界大事件, >0 = 指定角色

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final eventsAsync = ref.watch(worldTimelineEventsProvider(widget.worldId));
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );

    final characters = charactersAsync.valueOrNull ?? [];
    final charMap = {for (final c in characters) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (w) => Text('${w.name} · 编年史大事件'),
          loading: () => const Text('世界编年史'),
          error: (_, _) => const Text('世界编年史'),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () =>
                _openEventDialog(context, ref, characters: characters),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新撰纪事'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 顶部筛选器
          _buildFilterBar(context, characters),
          const Divider(height: 1),

          // 事件列表区域
          Expanded(
            child: eventsAsync.when(
              data: (allEvents) {
                // 执行多维过滤
                final filtered = allEvents.where((ev) {
                  if (_selectedCategory != null &&
                      ev.category != _selectedCategory) {
                    return false;
                  }
                  if (ev.importance < _minImportance) {
                    return false;
                  }
                  if (_selectedCharacterFilter != null) {
                    if (_selectedCharacterFilter == -1) {
                      if (ev.characterId != null) return false;
                    } else if (ev.characterId != _selectedCharacterFilter) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (allEvents.isEmpty) {
                  return _buildEmptyState(context, characters);
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '没有符合当前筛选条件的事件',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _minImportance = 1;
                              _selectedCharacterFilter = null;
                            });
                          },
                          child: const Text('重置筛选条件'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildChronicleView(
                  context,
                  filtered,
                  charMap,
                  characters,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  '加载编年史失败: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, List<Character> characters) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签过滤
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部类型'),
                  selected: _selectedCategory == null,
                  onSelected: (sel) {
                    setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                for (final cat in TimelineCategoryConfig.all) ...[
                  FilterChip(
                    avatar: Icon(cat.icon, size: 14, color: cat.color),
                    label: Text(cat.label),
                    selected: _selectedCategory == cat.key,
                    onSelected: (sel) {
                      setState(() {
                        _selectedCategory = sel ? cat.key : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 重要度与角色筛选
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 重要度分级
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '重要度: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('全部')),
                      ButtonSegment(value: 2, label: Text('关键 (★★+)')),
                      ButtonSegment(value: 3, label: Text('史诗 (★★★)')),
                    ],
                    selected: {_minImportance},
                    onSelectionChanged: (set) {
                      setState(() => _minImportance = set.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              // 角色筛选下拉
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '关联角色: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int?>(
                    value: _selectedCharacterFilter,
                    hint: const Text('全域视角'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('全域视角 (含人物与世界)'),
                      ),
                      const DropdownMenuItem<int?>(
                        value: -1,
                        child: Text('仅世界宏观事件 (无人物绑定)'),
                      ),
                      for (final c in characters)
                        DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text('人物: ${c.name}'),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCharacterFilter = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, List<Character> characters) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '编年史长卷尚待书写',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '记录世界的创世纪元、文明更迭、重大灾变，或将人物的英雄传说编织进宏大的历史脉络之中。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  _openEventDialog(context, ref, characters: characters),
              icon: const Icon(Icons.history_edu_rounded),
              label: const Text('撰写第一部纪事'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronicleView(
    BuildContext context,
    List<TimelineEvent> events,
    Map<int, Character> charMap,
    List<Character> characters,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        final cat = TimelineCategoryConfig.find(ev.category);
        final boundChar = ev.characterId != null
            ? charMap[ev.characterId]
            : null;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间轴节点轴线
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2.5,
                        color: isFirst
                            ? Colors.transparent
                            : cat.color.withValues(alpha: 0.35),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: cat.color, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.2),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(cat.icon, size: 18, color: cat.color),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: 2.5,
                        color: isLast
                            ? Colors.transparent
                            : cat.color.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 主体卡片
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ChronicleEventCard(
                    event: ev,
                    category: cat,
                    character: boundChar,
                    worldId: widget.worldId,
                    onEdit: () => _openEventDialog(
                      context,
                      ref,
                      event: ev,
                      characters: characters,
                    ),
                    onDelete: () => _confirmDelete(context, ref, ev),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEventDialog(
    BuildContext context,
    WidgetRef ref, {
    TimelineEvent? event,
    required List<Character> characters,
  }) {
    showDialog(
      context: context,
      builder: (context) => ChronicleEventEditDialog(
        worldId: widget.worldId,
        event: event,
        characters: characters,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TimelineEvent event,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除纪事'),
        content: Text('确定要删除纪事“${event.title}”吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(timelineActionsProvider).deleteEvent(event.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}
