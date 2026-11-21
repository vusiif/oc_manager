import 'package:flutter/material.dart';

import '../../../core/consistency/consistency_checker_engine.dart';
import '../../../providers/consistency_provider.dart';

/// An individual issue card tile in the consistency checker list.
class ConsistencyIssueTile extends StatelessWidget {
  final ConsistencyIssue issue;
  final IssueHandlingStatus status;
  final ValueChanged<ConsistencyIssue> onNavigate;
  final void Function(String issueId) onIgnore;
  final void Function(String issueId) onResolve;
  final void Function(String issueId) onReset;

  const ConsistencyIssueTile({
    super.key,
    required this.issue,
    required this.status,
    required this.onNavigate,
    required this.onIgnore,
    required this.onResolve,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProcessed = status != IssueHandlingStatus.active;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isProcessed
              ? theme.colorScheme.outlineVariant
              : issue.severity.color.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    (isProcessed
                            ? theme.colorScheme.outline
                            : issue.severity.color)
                        .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProcessed
                    ? Icons.check_circle_outline_rounded
                    : issue.severity.icon,
                color: isProcessed
                    ? theme.colorScheme.outline
                    : issue.severity.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isProcessed
                                      ? theme.colorScheme.outline
                                      : issue.severity.color)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isProcessed
                              ? (status == IssueHandlingStatus.ignored
                                    ? '已忽略'
                                    : '已解决')
                              : issue.severity.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isProcessed
                                ? theme.colorScheme.outline
                                : issue.severity.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          issue.category.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: isProcessed
                                ? TextDecoration.lineThrough
                                : null,
                            color: isProcessed
                                ? theme.colorScheme.outline
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isProcessed
                          ? theme.colorScheme.outline
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (issue.evidence != null || issue.suggestion != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.evidence != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '依据: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    issue.evidence!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (issue.evidence != null &&
                              issue.suggestion != null)
                            const SizedBox(height: 3),
                          if (issue.suggestion != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '建议: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isProcessed
                                        ? theme.colorScheme.outline
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    issue.suggestion!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isProcessed
                                          ? theme.colorScheme.outline
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 操作按钮组
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => onNavigate(issue),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('定位'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                if (!isProcessed)
                  PopupMenuButton<String>(
                    tooltip: '更多操作',
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                    onSelected: (val) {
                      if (val == 'ignore') {
                        onIgnore(issue.id);
                      } else if (val == 'resolve') {
                        onResolve(issue.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'ignore',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('忽略此提示'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'resolve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16),
                            SizedBox(width: 8),
                            Text('标记为已解决'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () => onReset(issue.id),
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: const Text('恢复待办'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
