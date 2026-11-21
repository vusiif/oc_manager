import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/history/diff/character_revision_diff.dart';
import '../../core/history/diff/lore_revision_diff.dart';
import '../../core/history/models/character_snapshot.dart';
import '../../core/history/models/lore_snapshot.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/revision_provider.dart';
import 'revision/character_revision_workspace.dart';
import 'revision/event_revision_workspace.dart';
import 'revision/lore_revision_workspace.dart';
import 'revision/revision_create_snapshot_dialog.dart';
import 'revision/revision_list_sidebar.dart';
import 'revision/revision_restore_dialogs.dart';

/// 设定版本历史、差异对比与选择性恢复工作台 (HISTORY-001 ~ HISTORY-004)
class RevisionHistoryDialog extends ConsumerStatefulWidget {
  final int worldId;
  final String entityType; // 'character', 'lore', 'event'
  final int entityId;
  final String entityName;
  final String currentContent;
  final Character? character;
  final LoreEntity? lore;
  final TimelineEvent? event;
  final Future<void> Function(EntityRevision revision)? onRestore;

  const RevisionHistoryDialog({
    super.key,
    required this.worldId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.currentContent,
    this.character,
    this.lore,
    this.event,
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
    LoreEntity? lore,
    TimelineEvent? event,
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
        lore: lore,
        event: event,
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
    final result = await showCreateSnapshotDialog(context);
    if (result == null || !mounted) return;

    final actions = ref.read(revisionActionsProvider);
    final customTitle = result.title;
    final customNote = result.note;
    final isMilestone = result.isMilestone;

    final character = _getEffectiveCharacter();
    if (character != null) {
      await actions.recordCharacterSnapshot(
        character: character,
        title: customTitle.isNotEmpty ? customTitle : null,
        source: 'manual',
        isMilestone: isMilestone,
        note: customNote.isNotEmpty ? customNote : null,
      );
    } else if (widget.lore != null) {
      await actions.recordLoreSnapshot(
        lore: widget.lore!,
        title: customTitle.isNotEmpty ? customTitle : null,
        source: 'manual',
        isMilestone: isMilestone,
        note: customNote.isNotEmpty ? customNote : null,
      );
    } else if (widget.event != null) {
      await actions.recordEventSnapshot(
        event: widget.event!,
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

  void _restoreCharacter(EntityRevision revision) {
    final character = _getEffectiveCharacter();
    final baseSnapshot = CharacterSnapshot.parse(
      revision.content,
      defaultName: widget.entityName,
      defaultTimestamp: revision.createdAt,
    );
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

    RevisionRestoreDialogs.showCharacterSelectiveRestoreDialog(
      context,
      ref,
      revision: revision,
      diff: diff,
      character: character,
      onFallbackRestore: widget.onRestore,
    );
  }

  void _restoreLore(EntityRevision revision, LoreEntity lore) {
    final baseSnapshot = LoreSnapshot.parse(
      revision.content,
      defaultName: lore.name,
      defaultType: lore.entityType,
      defaultTimestamp: revision.createdAt,
    );
    final currentSnapshot = LoreSnapshot.fromEntity(lore);
    final diff = LoreRevisionDiffEngine.compare(
      base: baseSnapshot,
      current: currentSnapshot,
    );

    RevisionRestoreDialogs.showLoreSelectiveRestoreDialog(
      context,
      ref,
      revision: revision,
      diff: diff,
      lore: lore,
    );
  }

  void _restoreEvent(EntityRevision revision, TimelineEvent event) {
    RevisionRestoreDialogs.showEventRestoreDialog(
      context,
      ref,
      revision: revision,
      event: event,
    );
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
                        RevisionListSidebar(
                          revisions: revisions,
                          selectedRevision: _selectedRevision,
                          onSelectRevision: (rev) =>
                              setState(() => _selectedRevision = rev),
                          onToggleMilestone: _toggleMilestone,
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
    if (widget.lore != null) {
      return LoreRevisionWorkspace(
        revision: revision,
        lore: widget.lore!,
        tabController: _tabController,
        onDelete: () => _handleDelete(revision),
        onRestore: () => _restoreLore(revision, widget.lore!),
      );
    }
    if (widget.event != null) {
      return EventRevisionWorkspace(
        revision: revision,
        event: widget.event!,
        tabController: _tabController,
        onDelete: () => _handleDelete(revision),
        onRestore: () => _restoreEvent(revision, widget.event!),
      );
    }

    final character = _getEffectiveCharacter();
    return CharacterRevisionWorkspace(
      revision: revision,
      character: character,
      entityName: widget.entityName,
      currentContent: widget.currentContent,
      tabController: _tabController,
      onDelete: () => _handleDelete(revision),
      onRestore: () => _restoreCharacter(revision),
    );
  }
}
