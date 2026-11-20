import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../core/history/diff/character_revision_diff.dart';
import '../../../core/history/diff/lore_revision_diff.dart';
import '../../../providers/revision_provider.dart';

/// 角色、百科词条与编年史大事件的选择性安全恢复弹窗集合 (HISTORY-003 & HISTORY-004)
class RevisionRestoreDialogs {
  /// 角色设定选择性恢复弹窗
  static Future<void> showCharacterSelectiveRestoreDialog(
    BuildContext context,
    WidgetRef ref, {
    required EntityRevision revision,
    required CharacterDiffResult diff,
    required Character? character,
    Future<void> Function(EntityRevision revision)? onFallbackRestore,
  }) async {
    if (character == null) {
      if (onFallbackRestore != null) {
        await onFallbackRestore(revision);
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

    if (confirmed == true && context.mounted) {
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

      if (context.mounted) {
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

  /// 百科词条选择性恢复弹窗
  static Future<void> showLoreSelectiveRestoreDialog(
    BuildContext context,
    WidgetRef ref, {
    required EntityRevision revision,
    required LoreDiffResult diff,
    required LoreEntity lore,
  }) async {
    bool restoreBasic = diff.hasBasicInfoChanges;
    bool restoreSummary = diff.hasSummaryChanges;
    bool restoreDesc = diff.hasContentChanges;
    bool restoreCustom = diff.hasCustomFieldChanges;
    bool restoreTags = diff.hasTagChanges;

    if (!diff.hasAnyChanges) {
      restoreBasic = true;
      restoreSummary = true;
      restoreDesc = true;
      restoreCustom = true;
      restoreTags = true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final options = LoreSelectiveRestoreOptions(
            restoreBasicInfo: restoreBasic,
            restoreSummary: restoreSummary,
            restoreContent: restoreDesc,
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
                const Text('选择性安全恢复词条设定'),
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
                        '准备将百科词条设定回滚至快照 “${revision.title}”。\n系统将在恢复前自动为您创建当前最新状态的归档备份，且词条现有的知识网络拓扑与上级归属绝对不会异常丢失。',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '请选择要恢复的词条维度：',
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
                      title: const Text('正文设定长文本 (Content)'),
                      subtitle: Text(
                        diff.hasContentChanges
                            ? '差异: ${diff.charCountDelta >= 0 ? "+" : ""}${diff.charCountDelta} 字'
                            : '正文无内容差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreSummary,
                      onChanged: (val) =>
                          setDialogState(() => restoreSummary = val ?? false),
                      title: const Text('梗概摘要 (Summary)'),
                      subtitle: Text(
                        diff.hasSummaryChanges ? '存在梗概变动' : '梗概无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreBasic,
                      onChanged: (val) =>
                          setDialogState(() => restoreBasic = val ?? false),
                      title: const Text('词条基本属性 (Name/Type/Cover)'),
                      subtitle: Text(
                        diff.hasBasicInfoChanges ? '存在基本属性变动' : '基本属性无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreCustom,
                      onChanged: (val) =>
                          setDialogState(() => restoreCustom = val ?? false),
                      title: const Text('专有扩展属性 (Custom Fields)'),
                      subtitle: Text(
                        diff.hasCustomFieldChanges ? '存在专有属性变动' : '属性无差异',
                        style: const TextStyle(fontSize: 11),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: restoreTags,
                      onChanged: (val) =>
                          setDialogState(() => restoreTags = val ?? false),
                      title: const Text('所属分类标签体系 (Tags)'),
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

    if (confirmed == true && context.mounted) {
      final options = LoreSelectiveRestoreOptions(
        restoreBasicInfo: restoreBasic,
        restoreSummary: restoreSummary,
        restoreContent: restoreDesc,
        restoreCustomFields: restoreCustom,
        restoreTags: restoreTags,
      );

      final success = await ref
          .read(revisionActionsProvider)
          .restoreLoreSelective(
            revisionId: revision.id,
            currentLore: lore,
            options: options,
          );

      if (context.mounted) {
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

  /// 编年史大事件恢复二次确认弹窗
  static Future<void> showEventRestoreDialog(
    BuildContext context,
    WidgetRef ref, {
    required EntityRevision revision,
    required TimelineEvent event,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认回滚编年史事件？'),
        content: Text(
          '准备将事件 “${event.title}” 恢复至快照 “${revision.title}”。\n系统将在恢复前自动为您创建当前最新状态的归档备份。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(revisionActionsProvider)
          .restoreEvent(revisionId: revision.id, currentEvent: event);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '已成功将事件回滚至快照 “${revision.title}”' : '恢复失败，快照可能已失效',
            ),
          ),
        );
      }
    }
  }
}
