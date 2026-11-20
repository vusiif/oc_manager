import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../../../core/history/models/event_snapshot.dart';
import '../../../core/history/diff/event_revision_diff.dart';
import '../../../core/history/diff/text_diff_util.dart';
import 'revision_diff_widgets.dart';

/// 编年史大事件设定版本差异与预览工作区 (HISTORY-004)
class EventRevisionWorkspace extends StatelessWidget {
  final EntityRevision revision;
  final TimelineEvent event;
  final TabController tabController;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const EventRevisionWorkspace({
    super.key,
    required this.revision,
    required this.event,
    required this.tabController,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseSnapshot = EventSnapshot.parse(
      revision.content,
      defaultTitle: event.title,
      defaultTimestamp: revision.createdAt,
    );
    final currentSnapshot = EventSnapshot.fromEntity(event);
    final diff = EventRevisionDiffEngine.compare(
      base: baseSnapshot,
      current: currentSnapshot,
    );

    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.25,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              revision.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (baseSnapshot.note != null &&
                              baseSnapshot.note!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: baseSnapshot.note!,
                              child: Icon(
                                Icons.info_outline,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '记录时间：${revision.createdAt.toString().substring(0, 19)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 220,
                  height: 32,
                  child: TabBar(
                    controller: tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: '快照内容'),
                      Tab(text: '事件差异 (Diff)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildEventPreviewTab(context, baseSnapshot, revision),
                _buildEventDiffTab(context, diff, baseSnapshot),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    '删除快照',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12.5),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('恢复为此版本'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreviewTab(
    BuildContext context,
    EventSnapshot snapshot,
    EntityRevision revision,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  snapshot.year.isNotEmpty ? snapshot.year : '未知年份',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '★' * snapshot.importance,
                style: const TextStyle(color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '事件描述内容：',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SelectableText(
            snapshot.description.isNotEmpty
                ? snapshot.description
                : '（该版本无描述内容）',
            style: const TextStyle(fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDiffTab(
    BuildContext context,
    EventDiffResult diff,
    EventSnapshot baseSnapshot,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildDiffChip(
                label: diff.hasAnyChanges ? '存在设定差异' : '与当前完全一致',
                color: diff.hasAnyChanges
                    ? Colors.amber.shade700
                    : Colors.green,
                icon: diff.hasAnyChanges
                    ? Icons.difference_outlined
                    : Icons.check_circle_outline,
              ),
              const SizedBox(width: 8),
              buildDiffChip(
                label:
                    '描述字数 ${diff.charCountDelta >= 0 ? "+" : ""}${diff.charCountDelta} 字',
                color: diff.charCountDelta >= 0 ? Colors.green : Colors.orange,
                icon: Icons.text_fields_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (diff.hasFieldChanges) ...[
            Text(
              '事件属性变更',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Column(
                children: diff.fieldDiffs.where((f) => f.hasChanged).map((f) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${f.label ?? f.key}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          f.oldValue?.isNotEmpty == true ? f.oldValue! : '（空）',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Icon(Icons.arrow_right_alt, size: 14),
                        Text(
                          f.newValue?.isNotEmpty == true ? f.newValue! : '（空）',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            '详细描述内容行级对比',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: diff.descriptionLineDiffs.isEmpty
                ? const Text('（描述内容无任何差异）', style: TextStyle(fontSize: 12))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: diff.descriptionLineDiffs.map((line) {
                      Color? bg;
                      Color textCol = theme.colorScheme.onSurface;
                      String prefix = '  ';

                      if (line.type == DiffType.added) {
                        bg = Colors.green.withValues(alpha: 0.15);
                        textCol = Colors.green.shade800;
                        prefix = '+ ';
                      } else if (line.type == DiffType.deleted) {
                        bg = Colors.red.withValues(alpha: 0.15);
                        textCol = Colors.red.shade800;
                        prefix = '- ';
                      }

                      return Container(
                        width: double.infinity,
                        color: bg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        child: Text(
                          '$prefix${line.text}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.5,
                            color: textCol,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
