import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../data/database/app_database.dart';
import '../tag/tag_selector.dart';
import 'character_dialog.dart';

class CharacterDetailPage extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterDetailPage({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterByIdProvider(characterId));
    final fieldsAsync = ref.watch(characterFieldsProvider(characterId));

    return Scaffold(
      appBar: AppBar(
        title: characterAsync.when(
          data: (character) => Text(character.name),
          loading: () => const Text('加载中'),
          error: (_, __) => const Text('错误'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final character = characterAsync.valueOrNull;
              if (character != null) {
                showDialog(
                  context: context,
                  builder: (context) => CharacterDialog(
                    worldId: worldId,
                    character: character,
                  ),
                );
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_field',
                child: Text('添加字段'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除人物', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'add_field') {
                _showAddFieldDialog(context, ref);
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
          ),
        ],
      ),
      body: characterAsync.when(
        data: (character) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 头像区域
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  character.name.isNotEmpty
                      ? character.name[0]
                      : '?',
                  style: TextStyle(
                    fontSize: 36,
                    color:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 基本信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('基本信息',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _InfoRow(label: '名称', value: character.name),
                    _InfoRow(
                      label: '状态',
                      value: character.status == 0 ? '正式' : '草稿',
                    ),
                    _InfoRow(
                      label: '创建时间',
                      value: _formatDate(character.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 标签
            TagSelector(characterId: characterId),
            const SizedBox(height: 16),

            // 关系
            _RelationSection(
              worldId: worldId,
              characterId: characterId,
            ),
            const SizedBox(height: 16),

            // 自定义字段
            fieldsAsync.when(
              data: (fields) {
                if (fields.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('自定义字段',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text('还没有自定义字段',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('添加字段'),
                            onPressed: () =>
                                _showAddFieldDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('自定义字段',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _showAddFieldDialog(context, ref),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...fields.map((field) => _FieldRow(
                              field: field,
                              characterId: characterId,
                            )),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('错误: $error'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
    );
  }

  void _showAddFieldDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String fieldType = 'text';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加字段'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '字段名称',
                  hintText: '例如：种族、魔法属性',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: fieldType,
                decoration: const InputDecoration(labelText: '字段类型'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('文本')),
                  DropdownMenuItem(value: 'number', child: Text('数字')),
                  DropdownMenuItem(value: 'long_text', child: Text('长文本')),
                  DropdownMenuItem(value: 'select', child: Text('单选')),
                  DropdownMenuItem(value: 'multi_select', child: Text('多选')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => fieldType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(characterActionsProvider).updateField(
                        characterId,
                        name,
                        fieldType,
                        null,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除人物'),
        content: const Text('确定要删除这个人物吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(characterActionsProvider)
                  .delete(characterId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _FieldRow extends ConsumerStatefulWidget {
  final dynamic field;
  final int characterId;

  const _FieldRow({required this.field, required this.characterId});

  @override
  ConsumerState<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends ConsumerState<_FieldRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              widget.field.fieldName,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: widget.field.fieldType == 'long_text'
                ? TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onSubmitted: _save,
                  )
                : TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onSubmitted: _save,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: () => _save(_controller.text),
          ),
        ],
      ),
    );
  }

  void _save(String value) {
    ref.read(characterActionsProvider).updateField(
          widget.characterId,
          widget.field.fieldName,
          widget.field.fieldType,
          value,
        );
  }
}

class _RelationSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const _RelationSection({required this.worldId, required this.characterId});

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
                const Text('关系',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddRelationDialog(
                      context, ref, charactersAsync.valueOrNull ?? []),
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
                        child: Text(
                          otherName.isNotEmpty ? otherName[0] : '?',
                        ),
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
                                context, ref, rel, allChars),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () => _confirmDeleteRelation(
                                context, ref, rel),
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
      BuildContext context, WidgetRef ref, List<Character> allChars) {
    final others = allChars.where((c) => c.id != characterId).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该世界观下暂无其他人物')),
      );
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
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
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
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                ),
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
                  await ref.read(relationActionsProvider).create(
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

  void _showEditRelationDialog(BuildContext context, WidgetRef ref,
      Relation rel, List<Character> allChars) {
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
                await ref.read(relationActionsProvider).update(
                      rel.copyWith(
                        relationType: selectedType,
                        isBidirectional: isBidirectional,
                        note: Value(noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim()),
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
      BuildContext context, WidgetRef ref, Relation rel) {
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

const _relationTypes = [
  '亲属',
  '朋友',
  '恋人',
  '师徒',
  '敌对',
  '宿敌',
  '同事',
  '其他',
];
