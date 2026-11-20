import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../providers/group_provider.dart';

const _relationTypes = ['亲属', '朋友', '恋人', '师徒', '敌对', '宿敌', '同事', '其他'];

/// 人物关系展示与编辑卡片 (REL-001 ~ REL-004)
class CharacterRelationSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterRelationSection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationsAsync = ref.watch(relationsByCharacterProvider(characterId));
    final charactersAsync = ref.watch(charactersByWorldProvider(worldId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '关系',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddRelationDialog(
                    context,
                    ref,
                    charactersAsync.valueOrNull ?? [],
                  ),
                ),
              ],
            ),
            const Divider(),
            relationsAsync.when(
              data: (relations) {
                if (relations.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('暂无关系', style: TextStyle(color: Colors.grey)),
                  );
                }

                final allChars = charactersAsync.valueOrNull ?? [];

                return Column(
                  children: relations.map((rel) {
                    final otherId = rel.fromCharacterId == characterId
                        ? rel.toCharacterId
                        : rel.fromCharacterId;
                    final other = allChars
                        .where((c) => c.id == otherId)
                        .firstOrNull;
                    final otherName = other?.name ?? '未知人物';
                    final directionIcon = rel.isBidirectional
                        ? Icons.swap_horiz
                        : (rel.fromCharacterId == characterId
                              ? Icons.arrow_forward
                              : Icons.arrow_back);

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(otherName.isNotEmpty ? otherName[0] : '?'),
                      ),
                      title: Text(otherName),
                      subtitle: Text(rel.relationType),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(directionIcon, size: 18, color: Colors.grey),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditRelationDialog(
                              context,
                              ref,
                              rel,
                              allChars,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmDeleteRelation(context, ref, rel),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('错误: $error'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRelationDialog(
    BuildContext context,
    WidgetRef ref,
    List<Character> allChars,
  ) {
    final others = allChars.where((c) => c.id != characterId).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该世界观下暂无其他人物')));
      return;
    }

    int? selectedCharId = others.first.id;
    String selectedType = '朋友';
    bool isBidirectional = true;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加关系'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedCharId,
                decoration: const InputDecoration(labelText: '目标人物'),
                items: others
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedCharId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '关系类型'),
                items: _relationTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedType = v);
                },
              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCharId != null) {
                  await ref
                      .read(relationActionsProvider)
                      .create(
                        fromCharacterId: characterId,
                        toCharacterId: selectedCharId!,
                        relationType: selectedType,
                        isBidirectional: isBidirectional,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(relationsByCharacterProvider(characterId));
                  ref.invalidate(relationsByWorldProvider(worldId));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRelationDialog(
    BuildContext context,
    WidgetRef ref,
    Relation rel,
    List<Character> allChars,
  ) {
    String selectedType = rel.relationType;
    bool isBidirectional = rel.isBidirectional;
    final noteController = TextEditingController(text: rel.note ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑关系'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '关系类型'),
                items: _relationTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedType = v);
                },
              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(relationActionsProvider)
                    .update(
                      rel.copyWith(
                        relationType: selectedType,
                        isBidirectional: isBidirectional,
                        note: Value(
                          noteController.text.trim().isEmpty
                              ? null
                              : noteController.text.trim(),
                        ),
                      ),
                    );
                ref.invalidate(relationsByCharacterProvider(characterId));
                ref.invalidate(relationsByWorldProvider(worldId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRelation(
    BuildContext context,
    WidgetRef ref,
    Relation rel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除关系'),
        content: const Text('确定要删除这条关系吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(relationActionsProvider).delete(rel.id);
              ref.invalidate(relationsByCharacterProvider(characterId));
              ref.invalidate(relationsByWorldProvider(worldId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 人物分组选择器组件
class CharacterGroupSelector extends ConsumerStatefulWidget {
  final int worldId;
  final int characterId;

  const CharacterGroupSelector({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  ConsumerState<CharacterGroupSelector> createState() =>
      _CharacterGroupSelectorState();
}

class _CharacterGroupSelectorState
    extends ConsumerState<CharacterGroupSelector> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.worldId));
    final characterGroupIdsAsync = ref.watch(
      characterGroupIdsProvider(widget.characterId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分组',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('暂无分组', style: TextStyle(color: Colors.grey)),
                  );
                }

                return characterGroupIdsAsync.when(
                  data: (selectedIds) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: groups.map((group) {
                        final isSelected = selectedIds.contains(group.id);
                        return FilterChip(
                          label: Text(group.name),
                          selected: isSelected,
                          onSelected: (selected) async {
                            if (selected) {
                              await ref
                                  .read(groupActionsProvider)
                                  .addCharacterToGroup(
                                    widget.characterId,
                                    group.id,
                                  );
                            } else {
                              await ref
                                  .read(groupActionsProvider)
                                  .removeCharacterFromGroup(
                                    widget.characterId,
                                    group.id,
                                  );
                            }
                            ref.invalidate(characterGroupIdsProvider);
                            ref.invalidate(charactersByGroupProvider);
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('错误: $e'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('错误: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
