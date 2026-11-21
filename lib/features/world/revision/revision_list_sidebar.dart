import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// Left sidebar listing revision snapshots with milestone badges and character counts.
class RevisionListSidebar extends StatelessWidget {
  final List<EntityRevision> revisions;
  final EntityRevision? selectedRevision;
  final ValueChanged<EntityRevision> onSelectRevision;
  final ValueChanged<EntityRevision> onToggleMilestone;

  const RevisionListSidebar({
    super.key,
    required this.revisions,
    required this.selectedRevision,
    required this.onSelectRevision,
    required this.onToggleMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 290,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: revisions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final rev = revisions[index];
            final isSelected = selectedRevision?.id == rev.id;
            final dateStr = rev.createdAt.toString().substring(5, 16);
            final isMilestone = rev.content.contains('"isMilestone":true');
            final isAutoBackup = rev.content.contains('"restore_backup"');

            return InkWell(
              onTap: () => onSelectRevision(rev),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isMilestone
                            ? Icons.star_rounded
                            : isAutoBackup
                            ? Icons.restore_page_outlined
                            : Icons.commit_rounded,
                        size: 18,
                        color: isMilestone
                            ? Colors.amber.shade700
                            : isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      tooltip: isMilestone ? '已设为重要里程碑（受保护）' : '点击标记为重要里程碑',
                      onPressed: () => onToggleMilestone(rev),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rev.title,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMilestone)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '里程碑',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${rev.charCount} 字',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
