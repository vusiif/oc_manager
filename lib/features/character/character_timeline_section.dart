import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';
import 'widgets/character_timeline_event_card.dart';
import 'widgets/timeline_event_edit_dialog.dart';

/// 角色详情页中的个人生平时间线卡片
class CharacterTimelineSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterTimelineSection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(characterTimelineEventsProvider(characterId));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.history_edu_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '生平大事记与时间线',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                eventsAsync.when(
                  data: (events) => events.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${events.length} 个纪元节点',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _openEventDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('记录生平'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 时间线主体
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return _buildTimelineList(context, ref, events);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '加载生平事件失败: $err',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无生平纪事记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '记录角色的出生觉醒、关键战役或命运转折，构建独一无二的生平编年史',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openEventDialog(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('添加第一条生平节点'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    WidgetRef ref,
    List<TimelineEvent> events,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        final categoryConfig = TimelineCategoryConfig.find(event.category);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间轴节点与贯穿线
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // 上半部分连接线
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: isFirst
                            ? Colors.transparent
                            : categoryConfig.color.withValues(alpha: 0.3),
                      ),
                    ),
                    // 节点徽标
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: categoryConfig.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: categoryConfig.color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        categoryConfig.icon,
                        size: 14,
                        color: categoryConfig.color,
                      ),
                    ),
                    // 下半部分连接线
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: 2,
                        color: isLast
                            ? Colors.transparent
                            : categoryConfig.color.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 事件卡片
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CharacterTimelineEventCard(
                    event: event,
                    categoryConfig: categoryConfig,
                    onEdit: () => _openEventDialog(context, ref, event: event),
                    onDelete: () => _confirmDelete(context, ref, event),
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
  }) {
    showDialog(
      context: context,
      builder: (context) => TimelineEventEditDialog(
        worldId: worldId,
        characterId: characterId,
        event: event,
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
        title: const Text('删除生平事件'),
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
