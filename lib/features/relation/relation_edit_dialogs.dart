import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/design/components/confirmation_dialog.dart';
import '../../data/database/app_database.dart';
import '../../providers/relation_provider.dart';
import 'graph_history_manager.dart';

/// Predefined standard relation types.
const List<String> defaultRelationTypes = [
  '朋友',
  '敌人',
  '恋人',
  '亲人',
  '师徒',
  '宿敌',
  '同事',
  '同盟',
];

/// Helper icon for gender in chips.
Widget? relationGenderIcon(String gender) {
  if (gender == '男') return const Text('♂', style: TextStyle(fontSize: 14));
  if (gender == '女') return const Text('♀', style: TextStyle(fontSize: 14));
  if (gender.isNotEmpty) {
    return const Text('⚥', style: TextStyle(fontSize: 14));
  }
  return null;
}

/// Collection of relation editing and management dialogs.
class RelationEditDialogs {
  RelationEditDialogs._();

  /// Dialog to create a new relation between two characters.
  static void showAddRelationDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required List<Character> characters,
    required GraphHistoryManager historyManager,
    int? fromId,
    int? toId,
  }) {
    if (characters.length < 2) return;

    int? selectedFrom = fromId ?? characters[0].id;
    int? selectedTo =
        toId ??
        characters
            .firstWhere(
              (c) => c.id != selectedFrom,
              orElse: () => characters[0],
            )
            .id;
    String selectedType = '朋友';
    bool isCustomType = false;
    bool isBidirectional = true;
    final customTypeController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('添加关系'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedFrom,
                  decoration: const InputDecoration(labelText: '起始人物'),
                  items: characters
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedFrom = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTo,
                  decoration: const InputDecoration(labelText: '目标人物'),
                  items: characters
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedTo = v),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('关系类型', style: Theme.of(ctx).textTheme.bodySmall),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in defaultRelationTypes)
                      ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: !isCustomType && selectedType == t,
                        onSelected: (_) => setState(() {
                          selectedType = t;
                          isCustomType = false;
                        }),
                      ),
                    ChoiceChip(
                      label: const Text('自定义…', style: TextStyle(fontSize: 12)),
                      selected: isCustomType,
                      onSelected: (_) => setState(() => isCustomType = true),
                    ),
                  ],
                ),
                if (isCustomType) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customTypeController,
                    decoration: const InputDecoration(
                      labelText: '自定义关系类型',
                      hintText: '例如：宿敌、同事、师徒…',
                    ),
                    onChanged: (v) => selectedType = v.trim(),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('双向关系'),
                  value: isBidirectional,
                  onChanged: (v) => setState(() => isBidirectional = v),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final type = isCustomType
                    ? customTypeController.text.trim()
                    : selectedType;
                if (selectedFrom != null &&
                    selectedTo != null &&
                    selectedFrom != selectedTo &&
                    type.isNotEmpty) {
                  final note = noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim();
                  final id = await ref
                      .read(relationActionsProvider)
                      .create(
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: note,
                      );
                  ref.invalidate(relationsByWorldProvider(worldId));

                  final fromCharName =
                      characters
                          .where((c) => c.id == selectedFrom)
                          .map((c) => c.name)
                          .firstOrNull ??
                      '?';
                  final toCharName =
                      characters
                          .where((c) => c.id == selectedTo)
                          .map((c) => c.name)
                          .firstOrNull ??
                      '?';

                  historyManager.record(
                    CreateRelationCommand(
                      relation: Relation(
                        id: id,
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: note,
                        relationGroupId: null,
                      ),
                      descriptionText: '$fromCharName 与 $toCharName 的【$type】',
                      onDelete: (relId) async {
                        await ref.read(relationActionsProvider).delete(relId);
                        ref.invalidate(relationsByWorldProvider(worldId));
                      },
                      onRestore: (rel) async {
                        await ref.read(relationActionsProvider).restore(rel);
                        ref.invalidate(relationsByWorldProvider(worldId));
                      },
                    ),
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      customTypeController.dispose();
      noteController.dispose();
    });
  }

  /// Dialog to view and manage all relations of a single character.
  static void showRelationManager({
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
                                ref.invalidate(
                                  relationsByWorldProvider(worldId),
                                );
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
                    showAddRelationDialog(
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

  /// Dialog to create parent-child family relations among multiple characters.
  static void showFamilyRelationDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required List<Character> characters,
    required GraphHistoryManager historyManager,
  }) {
    if (characters.length < 3) return;

    List<int> parentIds = [];
    List<int> childIds = [];
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加家谱关系'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('父母（可多选）', style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: relationGenderIcon(c.gender),
                          label: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: parentIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              parentIds.add(c.id);
                              childIds.remove(c.id);
                            } else {
                              parentIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('子女（可多选）', style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: relationGenderIcon(c.gender),
                          label: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: childIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              childIds.add(c.id);
                              parentIds.remove(c.id);
                            } else {
                              childIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: '备注（可选）'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (parentIds.length < 2 || childIds.isEmpty) return;
                  final created = await ref
                      .read(relationActionsProvider)
                      .createFamilyRelation(
                        parentIds: parentIds,
                        childIds: childIds,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(relationsByWorldProvider(worldId));

                  historyManager.record(
                    BatchCreateRelationsCommand(
                      relations: created,
                      descriptionText: '添加家谱亲子关系',
                      onDelete: (relId) async {
                        await ref.read(relationActionsProvider).delete(relId);
                        ref.invalidate(relationsByWorldProvider(worldId));
                      },
                      onRestore: (rel) async {
                        await ref.read(relationActionsProvider).restore(rel);
                        ref.invalidate(relationsByWorldProvider(worldId));
                      },
                    ),
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog triggered when clicking a relation line in the graph.
  static void showRelationActionDialog({
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                showEditRelationDialog(
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
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
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

  /// Dialog to edit relation type and note.
  static void showEditRelationDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required Relation rel,
    required String fromName,
    required String toName,
    required void Function(Relation oldRel, Relation newRel, String desc)
    onRecordUpdate,
  }) {
    String currentType = rel.relationType;
    final noteController = TextEditingController(text: rel.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑关系: $fromName ⇄ $toName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '关系类型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in defaultRelationTypes)
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: currentType == t,
                      onSelected: (_) => setDialogState(() => currentType = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = noteController.text.trim();
                final oldRel = rel;
                final newRel = rel.copyWith(
                  relationType: currentType,
                  note: Value(note.isEmpty ? null : note),
                );
                await ref.read(relationActionsProvider).update(newRel);
                ref.invalidate(relationsByWorldProvider(worldId));
                onRecordUpdate(oldRel, newRel, '$fromName 与 $toName 关系');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
