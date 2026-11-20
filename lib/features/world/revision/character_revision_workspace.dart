import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../../../core/history/models/character_snapshot.dart';
import '../../../core/history/diff/character_revision_diff.dart';
import '../../../core/history/diff/text_diff_util.dart';
import 'revision_diff_widgets.dart';

/// 角色设定版本差异与预览工作区 (HISTORY-001 ~ HISTORY-003)
class CharacterRevisionWorkspace extends StatelessWidget {
  final EntityRevision revision;
  final Character? character;
  final String entityName;
  final String currentContent;
  final TabController tabController;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const CharacterRevisionWorkspace({
    super.key,
    required this.revision,
    required this.character,
    required this.entityName,
    required this.currentContent,
    required this.tabController,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 解析快照
    final baseSnapshot = CharacterSnapshot.parse(
      revision.content,
      defaultName: entityName,
      defaultTimestamp: revision.createdAt,
    );

    // 计算当前比对快照
    final currentSnapshot = CharacterSnapshot(
      name: character?.name ?? entityName,
      gender: character?.gender,
      avatarPath: character?.avatarPath,
      description: character?.description ?? currentContent,
      timestamp: DateTime.now(),
    );

    final diff = CharacterRevisionDiffEngine.compare(
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
          // 头部面板与 Tab
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
                      Tab(text: '设定差异 (Diff)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab 内容展示
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildPreviewTab(context, baseSnapshot, revision),
                _buildDiffTab(context, diff, baseSnapshot),
              ],
            ),
          ),
          const Divider(height: 1),

          // 底部操作栏
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

  /// 差异对比选项卡 (HISTORY-002)
  Widget _buildDiffTab(
    BuildContext context,
    CharacterDiffResult diff,
    CharacterSnapshot baseSnapshot,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 概览摘要胶囊
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
              if (diff.hasDescriptionChanges)
                buildDiffChip(
                  label:
                      '正文字数 ${diff.charCountDelta >= 0 ? "+" : ""}${diff.charCountDelta} 字',
                  color: diff.charCountDelta >= 0
                      ? Colors.green
                      : Colors.orange,
                  icon: Icons.text_fields_rounded,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. 基本信息变动卡片
          if (diff.hasBasicInfoChanges) ...[
            Text(
              '基本信息变更',
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
                children: diff.basicFieldDiffs.where((f) => f.hasChanged).map((
                  f,
                ) {
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

          // 2. 自定义字段变动卡片
          if (diff.hasCustomFieldChanges) ...[
            Text(
              '扩展属性与特征变更',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: diff.customFieldDiffs.where((f) => f.hasChanged).map((
                f,
              ) {
                Color c = Colors.orange;
                String op = '改';
                if (f.status == FieldChangeStatus.added) {
                  c = Colors.green;
                  op = '+新';
                } else if (f.status == FieldChangeStatus.removed) {
                  c = Colors.red;
                  op = '-删';
                }

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: c,
                    radius: 7,
                    child: Text(
                      op,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text('${f.key}: ${f.newValue ?? f.oldValue}'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // 3. 标签变动
          if (diff.hasTagChanges) ...[
            Text(
              '标签体系变动',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: diff.tagDiffs.map((t) {
                final isAdd = t.status == FieldChangeStatus.added;
                return Chip(
                  label: Text('${isAdd ? "+" : "-"}${t.key}'),
                  backgroundColor: isAdd
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: isAdd ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // 4. 小传长文本行级 Diff
          Text(
            '人设小传长文本行级对比',
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
                ? const Text('（正文内容无任何差异）', style: TextStyle(fontSize: 12))
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

  /// 快照内容完整预览选项卡
  Widget _buildPreviewTab(
    BuildContext context,
    CharacterSnapshot snapshot,
    EntityRevision revision,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息展示
          if (snapshot.schemaVersion > 0) ...[
            Text(
              '角色：${snapshot.name} · ${snapshot.gender ?? "未知性别"} · ${snapshot.age ?? "未知年龄"}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (snapshot.customFields.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: snapshot.customFields.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: ${e.value}'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (snapshot.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: snapshot.tags.map((t) {
                  return Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
          ],
          const SizedBox(height: 8),
          const Text(
            '小传描述正文：',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SelectableText(
            snapshot.description.isNotEmpty
                ? snapshot.description
                : '（该版本无小传正文）',
            style: const TextStyle(fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}
