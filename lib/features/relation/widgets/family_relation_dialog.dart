import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/relation_provider.dart';
import '../graph_history_manager.dart';
import '../relation_edit_dialogs.dart';

/// Shows a dialog to create parent-child family relations among multiple characters.
void showFamilyRelationDialog({
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
