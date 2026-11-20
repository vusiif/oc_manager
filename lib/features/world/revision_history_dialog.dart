import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../core/history/models/character_snapshot.dart';
import '../../core/history/diff/character_revision_diff.dart';
import '../../core/history/diff/text_diff_util.dart';
import '../../providers/revision_provider.dart';
import '../../providers/character_provider.dart';

/// 设定版本历史、差异对比与选择性恢复工作台 (HISTORY-001 ~ HISTORY-003)
class RevisionHistoryDialog extends ConsumerStatefulWidget {
  final int worldId;
  final String entityType; // 'character', 'lore'
  final int entityId;
  final String entityName;
  final String currentContent;
  final Character? character;
  final Future<void> Function(EntityRevision revision)? onRestore;

  const RevisionHistoryDialog({
    super.key,
    required this.worldId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.currentContent,
    this.character,
    this.onRestore,
  });

  static Future<void> show(
    BuildContext context, {
    required int worldId,
    required String entityType,
    required int entityId,
    required String entityName,
    required String currentContent,
    Character? character,
    Future<void> Function(EntityRevision revision)? onRestore,
  }) {
    return showDialog(
      context: context,
      builder: (_) => RevisionHistoryDialog(
        worldId: worldId,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        currentContent: currentContent,
        character: character,
        onRestore: onRestore,
      ),
    );
  }

  @override
  ConsumerState<RevisionHistoryDialog> createState() =>
      _RevisionHistoryDialogState();
}

class _RevisionHistoryDialogState extends ConsumerState<RevisionHistoryDialog>
    with SingleTickerProviderStateMixin {
  EntityRevision? _selectedRevision;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Character? _getEffectiveCharacter() {
    if (widget.character != null) return widget.character;
    if (widget.entityType == 'character') {
      return ref.watch(characterByIdProvider(widget.entityId)).valueOrNull;
    }
    return null;
  }

  Future<void> _createSnapshot() async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    bool isMilestone = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text('保存新设定快照'),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '快照说明 / 版本标签 *',
                      hintText: '例如：初稿草案、大战后剧情大修',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '版本备注（可选）',
                      hintText: '记录本次快照的核心变动原因...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isMilestone,
                    onChanged: (val) {
                      setDialogState(() => isMilestone = val ?? false);
                    },
                    title: const Text(
                      '设为重要里程碑快照 (⭐)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      '里程碑快照受到永久保护，历史版本超出上限时绝不会被自动修剪淘汰。',
                      style: TextStyle(fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('保存快照'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final actions = ref.read(revisionActionsProvider);
      final customTitle = titleController.text.trim();
      final customNote = noteController.text.trim();

      final character = _getEffectiveCharacter();
      if (character != null) {
        await actions.recordCharacterSnapshot(
          character: character,
          title: customTitle.isNotEmpty ? customTitle : null,
          source: 'manual',
          isMilestone: isMilestone,
          note: customNote.isNotEmpty ? customNote : null,
        );
      } else {
        await actions.recordRevision(
          worldId: widget.worldId,
          entityType: widget.entityType,
          entityId: widget.entityId,
          content: widget.currentContent,
          title: customTitle.isNotEmpty ? customTitle : null,
        );
      }
    }
  }

  Future<void> _handleDelete(EntityRevision revision) async {
    final isMilestone = revision.content.contains('"isMilestone":true');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除此快照？'),
        content: Text(
          isMilestone
              ? '该快照已被标记为【重要里程碑快照 (⭐)】，确认仍要永久删除 “${revision.title}” 吗？'
              : '确认删除快照 “${revision.title}” 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(revisionActionsProvider)
          .deleteRevision(
            revision.id,
            entityType: widget.entityType,
            entityId: widget.entityId,
          );
      if (_selectedRevision?.id == revision.id) {
        setState(() => _selectedRevision = null);
      }
    }
  }

  Future<void> _toggleMilestone(EntityRevision revision) async {
    final isMilestone = revision.content.contains('"isMilestone":true');
    await ref
        .read(revisionActionsProvider)
        .toggleMilestone(
          revisionId: revision.id,
          isMilestone: !isMilestone,
          entityType: widget.entityType,
          entityId: widget.entityId,
        );
  }

  Future<void> _showSelectiveRestoreDialog(
    EntityRevision revision,
    CharacterDiffResult diff,
  ) async {
    final character = _getEffectiveCharacter();
    if (character == null) {
      // 非角色实体直接回滚
      if (widget.onRestore != null) {
        await widget.onRestore!(revision);
      }
      return;
    }

    bool restoreBasic = diff.hasBasicInfoChanges;
    bool restoreDesc = diff.hasDescriptionChanges;
    bool restoreCustom = diff.hasCustomFieldChanges;
    bool restoreTags = diff.hasTagChanges;

    // 默认若全无变更，全选以支持显式强制回滚
    if (!diff.hasAnyChanges) {
      restoreBasic = true;
      restoreDesc = true;
      restoreCustom = true;
      restoreTags = true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final options = SelectiveRestoreOptions(
            restoreBasicInfo: restoreBasic,
            restoreDescription: restoreDesc,
            restoreCustomFields: restoreCustom,
            restoreTags: restoreTags,
          );
          final affectedCount = diff.countAffectedFields(options);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.restore_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text('选择性安全恢复历史设定'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '准备将设定回滚至快照 “${revision.title}”。\n系统将在恢复前自动为您创建当前最新状态的归档备份，且人物既有的关联关系与相册媒体绝对不会丢失。',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '请选择要恢复的设定维度：',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      value: restoreDesc,
                      onChanged: (val) =>
                          setDialogState(() => restoreDesc = val ?? false),
                      title: const Text('人设小传正文 (Description)'),
                      subtitle: Text(
                        diff.hasDescriptionChanges
                            ? '差异: ${diff.charCountDelta >= 0 ? "+" : ""}${diff.charCountDelta} 字'
                            : '小传无内容差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreBasic,
                      onChanged: (val) =>
                          setDialogState(() => restoreBasic = val ?? false),
                      title: const Text('基本信息 (姓名、性别、年龄、立绘)'),
                      subtitle: Text(
                        diff.hasBasicInfoChanges ? '存在姓名/性别/立绘变动' : '基本信息无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreCustom,
                      onChanged: (val) =>
                          setDialogState(() => restoreCustom = val ?? false),
                      title: const Text('自定义扩展属性 (Custom Fields)'),
                      subtitle: Text(
                        diff.hasCustomFieldChanges ? '存在键值对属性差异' : '属性无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreTags,
                      onChanged: (val) =>
                          setDialogState(() => restoreTags = val ?? false),
                      title: const Text('角色所属标签体系 (Tags)'),
                      subtitle: Text(
                        diff.hasTagChanges ? '存在标签增减变动' : '标签无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '本次还原将影响约 $affectedCount 项字段变动。',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: options.hasAnySelected
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('确认并安全恢复'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final options = SelectiveRestoreOptions(
        restoreBasicInfo: restoreBasic,
        restoreDescription: restoreDesc,
        restoreCustomFields: restoreCustom,
        restoreTags: restoreTags,
      );

      final success = await ref
          .read(revisionActionsProvider)
          .restoreCharacterSelective(
            revisionId: revision.id,
            currentCharacter: character,
            options: options,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '已成功将设定选择性回滚至快照 “${revision.title}”' : '恢复失败，快照可能已失效',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revisionsAsync = ref.watch(
      revisionsProvider((
        entityType: widget.entityType,
        entityId: widget.entityId,
      )),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶栏：标题与操作
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history_rounded,
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
                          '设定版本历史与快照恢复',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.entityName} · 本地版本追踪、全字段差异比对与选择性恢复',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _createSnapshot,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('保存新快照'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: revisionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('加载历史快照失败：$err')),
                  data: (revisions) {
                    if (revisions.isEmpty) {
                      return _buildEmptyRevisions(context);
                    }

                    _selectedRevision ??= revisions.first;
                    if (!revisions.any((r) => r.id == _selectedRevision?.id)) {
                      _selectedRevision = revisions.first;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧版本列表栏 (290 宽)
                        SizedBox(
                          width: 290,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: revisions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final rev = revisions[index];
                                final isSelected =
                                    _selectedRevision?.id == rev.id;
                                final dateStr = rev.createdAt
                                    .toString()
                                    .substring(5, 16);
                                final isMilestone = rev.content.contains(
                                  '"isMilestone":true',
                                );
                                final isAutoBackup = rev.content.contains(
                                  '"restore_backup"',
                                );

                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedRevision = rev),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.4),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        // 里程碑星标或类型指示
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
                                          tooltip: isMilestone
                                              ? '已设为重要里程碑（受保护）'
                                              : '点击标记为重要里程碑',
                                          onPressed: () =>
                                              _toggleMilestone(rev),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                            ? theme
                                                                  .colorScheme
                                                                  .primary
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isMilestone)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        '里程碑',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                      color: theme
                                                          .colorScheme
                                                          .outline,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    '${rev.charCount} 字',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
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
                        ),
                        const SizedBox(width: 16),

                        // 右侧工作区
                        Expanded(
                          child: _selectedRevision != null
                              ? _buildRightWorkspace(
                                  context,
                                  _selectedRevision!,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRevisions(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无历史版本快照',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '在人设修改演进过程中，您可以随时保存快照或标记里程碑；支持全字段差异对比与选择性安全还原。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createSnapshot,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: const Text('保存当前内容为第一条快照'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightWorkspace(BuildContext context, EntityRevision revision) {
    final theme = Theme.of(context);
    final character = _getEffectiveCharacter();

    // 解析快照
    final baseSnapshot = CharacterSnapshot.parse(
      revision.content,
      defaultName: widget.entityName,
      defaultTimestamp: revision.createdAt,
    );

    // 计算当前比对快照
    final currentSnapshot = CharacterSnapshot(
      name: character?.name ?? widget.entityName,
      gender: character?.gender,
      avatarPath: character?.avatarPath,
      description: character?.description ?? widget.currentContent,
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
                    controller: _tabController,
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
              controller: _tabController,
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
                  onPressed: () => _handleDelete(revision),
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
                  onPressed: () => _showSelectiveRestoreDialog(revision, diff),
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
              _buildDiffChip(
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
                _buildDiffChip(
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

  Widget _buildDiffChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
