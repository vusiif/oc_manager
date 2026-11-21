import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/confirmation_dialog.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/relation_provider.dart';
import '../graph_history_manager.dart';
import '../relation_edit_dialogs.dart';

/// Shows a dialog to view and manage all relations of a single character.
void showRelationManagerDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int worldId,
  required Character character,
  required List<Character> allCharacters,
  required List<Relation> relations,
  required GraphHistoryManager historyManager,
  required void Function(Relation rel, String desc) onRecordDelete,
}) {
  String nameOf(int id) =>
      allCharacters.where((c) => c.id == id).map((c) => c.name).firstOrNull ??
      '?';

  showDialog(
    context: context,
    builder: (ctx) {
      List<Relation> localRelations = List.of(relations);

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final myRelations = localRelations
              .where(
                (r) =>
                    r.fromCharacterId == character.id ||
                    r.toCharacterId == character.id,
              )
              .toList();

          return AlertDialog(
            title: Text('${character.name} 的关系'),
            content: SizedBox(
              width: 360,
              child: myRelations.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '暂无关系',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: myRelations.length,
                      itemBuilder: (ctx, index) {
                        final rel = myRelations[index];
                        final otherName = rel.fromCharacterId == character.id
                            ? nameOf(rel.toCharacterId)
                            : nameOf(rel.fromCharacterId);
                        final arrow = rel.isBidirectional ? ' ↔ ' : ' → ';
                        final direction = rel.fromCharacterId == character.id
                            ? ''
                            : '(反向)';
                        final groupTag = rel.relationGroupId != null
                            ? ' [组]'
                            : '';

                        return ListTile(
                          dense: true,
                          title: Text(
                            '$otherName$arrow${rel.relationType}$direction$groupTag',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: rel.note != null && rel.note!.isNotEmpty
                              ? Text(
                                  rel.note!,
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(relationActionsProvider)
                                  .delete(rel.id);
                              setDialogState(() {
                                localRelations.removeWhere(
                                  (r) => r.id == rel.id,
                                );
                              });
                              ref.invalidate(relationsByWorldProvider(worldId));
                              onRecordDelete(
                                rel,
                                '${nameOf(rel.fromCharacterId)} 与 ${nameOf(rel.toCharacterId)} 的【${rel.relationType}】',
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加关系'),
                onPressed: () {
                  Navigator.pop(ctx);
                  RelationEditDialogs.showAddRelationDialog(
                    context: context,
                    ref: ref,
                    worldId: worldId,
                    characters: allCharacters,
                    historyManager: historyManager,
                    fromId: character.id,
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

/// Shows a dialog triggered when clicking a relation line in the graph.
void showRelationActionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int worldId,
  required Relation rel,
  required List<Character> characters,
  required void Function(Relation oldRel, Relation newRel, String desc)
  onRecordUpdate,
  required void Function(Relation rel, String desc) onRecordDelete,
  required VoidCallback onRelationDeleted,
}) {
  final charMap = {for (final c in characters) c.id: c};
  final fromChar = charMap[rel.fromCharacterId];
  final toChar = charMap[rel.toCharacterId];
  final fromName = fromChar?.name ?? '未知人物';
  final toName = toChar?.name ?? '未知人物';

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, size: 20),
            SizedBox(width: 8),
            Text('人物关系', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fromName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    rel.isBidirectional
                        ? Icons.compare_arrows
                        : Icons.arrow_forward,
                    size: 20,
                    color: rel.isBidirectional ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    toName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  '类型: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Chip(
                  label: Text(
                    rel.relationType,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  rel.isBidirectional ? '双向互通' : '单向指向',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (rel.note != null && rel.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '备注: ${rel.note}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          // 切换双向/单向
          TextButton.icon(
            icon: Icon(
              rel.isBidirectional ? Icons.arrow_forward : Icons.sync_alt,
              size: 16,
            ),
            label: Text(rel.isBidirectional ? '设为单向' : '设为双向'),
            onPressed: () async {
              Navigator.pop(ctx);
              final oldRel = rel;
              final newRel = rel.copyWith(
                isBidirectional: !rel.isBidirectional,
              );
              await ref.read(relationActionsProvider).update(newRel);
              ref.invalidate(relationsByWorldProvider(worldId));
              onRecordUpdate(oldRel, newRel, '$fromName 与 $toName 关系方向模式');
            },
          ),
          // 反转方向 (仅单向有效)
          if (!rel.isBidirectional)
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('反转'),
              onPressed: () async {
                Navigator.pop(ctx);
                final oldRel = rel;
                final newRel = rel.copyWith(
                  fromCharacterId: rel.toCharacterId,
                  toCharacterId: rel.fromCharacterId,
                );
                await ref.read(relationActionsProvider).update(newRel);
                ref.invalidate(relationsByWorldProvider(worldId));
                onRecordUpdate(oldRel, newRel, '$fromName 与 $toName 关系方向反转');
              },
            ),
          // 编辑类型与备注
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('编辑'),
            onPressed: () {
              Navigator.pop(ctx);
              RelationEditDialogs.showEditRelationDialog(
                context: context,
                ref: ref,
                worldId: worldId,
                rel: rel,
                fromName: fromName,
                toName: toName,
                onRecordUpdate: onRecordUpdate,
              );
            },
          ),
          // 删除关系
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('删除', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: '删除关系',
                content:
                    '确定要删除【$fromName】与【$toName】之间的“${rel.relationType}”关系吗？',
                confirmLabel: '删除',
                isDestructive: true,
              );
              if (confirmed == true) {
                if (ctx.mounted) Navigator.pop(ctx);
                await ref.read(relationActionsProvider).delete(rel.id);
                ref.invalidate(relationsByWorldProvider(worldId));
                onRelationDeleted();
                onRecordDelete(
                  rel,
                  '$fromName 与 $toName 的【${rel.relationType}】',
                );
              }
            },
          ),
        ],
      );
    },
  );
}
