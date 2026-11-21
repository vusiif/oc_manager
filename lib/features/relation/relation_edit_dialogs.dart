import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/relation_provider.dart';
import 'graph_history_manager.dart';
import 'widgets/family_relation_dialog.dart' as family_dlg;
import 'widgets/relation_action_dialog.dart' as action_dlg;

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
                      label: const Text('自定义', style: TextStyle(fontSize: 12)),
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
                      labelText: '自定义关系名称',
                      hintText: '如：宿敌、前任、同门',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '补充关系背景或细节说明',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('双向关系'),
                  subtitle: Text(
                    isBidirectional ? '双方互为该关系' : '仅起始人物单向指向目标人物',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isBidirectional,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => isBidirectional = v),
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
                if (selectedFrom == null || selectedTo == null) return;
                if (selectedFrom == selectedTo) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('不能和自己建立关系')));
                  return;
                }
                final relType = isCustomType
                    ? customTypeController.text.trim()
                    : selectedType;
                if (relType.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入关系名称')));
                  return;
                }

                final note = noteController.text.trim();
                final id = await ref
                    .read(relationActionsProvider)
                    .create(
                      fromCharacterId: selectedFrom!,
                      toCharacterId: selectedTo!,
                      relationType: relType,
                      isBidirectional: isBidirectional,
                      note: note.isEmpty ? null : note,
                    );
                ref.invalidate(relationsByWorldProvider(worldId));

                // 录入撤销/重做命令栈
                final fromName = characters
                    .firstWhere((c) => c.id == selectedFrom)
                    .name;
                final toName = characters
                    .firstWhere((c) => c.id == selectedTo)
                    .name;
                historyManager.record(
                  CreateRelationCommand(
                    relation: Relation(
                      id: id,
                      fromCharacterId: selectedFrom!,
                      toCharacterId: selectedTo!,
                      relationType: relType,
                      isBidirectional: isBidirectional,
                      note: note.isEmpty ? null : note,
                    ),
                    descriptionText: '$fromName 与 $toName 的【$relType】',
                    onDelete: (id) async {
                      await ref.read(relationActionsProvider).delete(id);
                      ref.invalidate(relationsByWorldProvider(worldId));
                    },
                    onRestore: (r) async {
                      await ref.read(relationActionsProvider).restore(r);
                      ref.invalidate(relationsByWorldProvider(worldId));
                    },
                  ),
                );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    ).then((_) {
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
  }) => action_dlg.showRelationManagerDialog(
    context: context,
    ref: ref,
    worldId: worldId,
    character: character,
    allCharacters: allCharacters,
    relations: relations,
    historyManager: historyManager,
    onRecordDelete: onRecordDelete,
  );

  /// Dialog to create parent-child family relations among multiple characters.
  static void showFamilyRelationDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required List<Character> characters,
    required GraphHistoryManager historyManager,
  }) => family_dlg.showFamilyRelationDialog(
    context: context,
    ref: ref,
    worldId: worldId,
    characters: characters,
    historyManager: historyManager,
  );

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
  }) => action_dlg.showRelationActionDialog(
    context: context,
    ref: ref,
    worldId: worldId,
    rel: rel,
    characters: characters,
    onRecordUpdate: onRecordUpdate,
    onRecordDelete: onRecordDelete,
    onRelationDeleted: onRelationDeleted,
  );

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
