import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/timeline_provider.dart';
import '../../world/revision_history_dialog.dart';

/// Card widget presenting a single character chronicle event with category and action shortcuts.
class CharacterTimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineCategoryConfig categoryConfig;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CharacterTimelineEventCard({
    super.key,
    required this.event,
    required this.categoryConfig,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.importance >= 3
              ? categoryConfig.color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: event.importance >= 3 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：年份 + 分类 + 重要度 + 更多操作
          Row(
            children: [
              // 年份纪元胶囊
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryConfig.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.year,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryConfig.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 分类名
              Text(
                categoryConfig.label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              // 重要度星标
              if (event.importance > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    event.importance,
                    (i) => const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              const Spacer(),
              // 操作按钮
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 16),
                tooltip: '版本历史与差异恢复',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  RevisionHistoryDialog.show(
                    context,
                    worldId: event.worldId,
                    entityType: 'event',
                    entityId: event.id,
                    entityName: event.title,
                    currentContent: event.description,
                    event: event,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: '编辑',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                tooltip: '删除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 事件标题
          Text(
            event.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),

          // 详细描述
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
