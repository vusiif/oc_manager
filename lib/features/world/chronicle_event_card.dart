import '../../core/design/components/oc_avatar.dart';
import 'revision_history_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';

class ChronicleEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineCategoryConfig category;
  final Character? character;
  final int worldId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChronicleEventCard({
    super.key,
    required this.event,
    required this.category,
    this.character,
    required this.worldId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEpic = event.importance >= 3;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEpic
                ? category.color.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isEpic ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：纪元年份 + 分类 + 关联人物胶囊 + 操作
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.year,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),

                // 星级重要度
                if (event.importance > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      event.importance,
                      (i) => const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),

                const Spacer(),

                // 关联角色胶囊
                if (character != null)
                  InkWell(
                    onTap: () {
                      context.push(
                        '/world/$worldId/character/${character!.id}',
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OcAvatar(
                            avatarPath: character!.avatarPath,
                            name: character!.name,
                            gender: character!.gender,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            character!.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '世界宏观纪事',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 17),
                  tooltip: '版本历史与差异恢复',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    RevisionHistoryDialog.show(
                      context,
                      worldId: worldId,
                      entityType: 'event',
                      entityId: event.id,
                      entityName: event.title,
                      currentContent: event.description,
                      event: event,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  tooltip: '编辑',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  tooltip: '删除',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 事件大标题
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),

            // 事件详细描述
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 编年史新增/编辑弹窗
