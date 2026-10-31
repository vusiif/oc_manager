import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:image_picker/image_picker.dart';

import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../providers/group_provider.dart';
import '../../data/database/app_database.dart';
import '../../core/storage/image_storage_service.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../core/design/components/radar_chart.dart';
import 'character_gallery_section.dart';
import 'character_poster_dialog.dart';
import '../tag/tag_selector.dart';
import 'character_dialog.dart';

class CharacterDetailPage extends ConsumerStatefulWidget {
  final int worldId;
  final int characterId;
  final VoidCallback? onDeleted;

  const CharacterDetailPage({
    super.key,
    required this.worldId,
    required this.characterId,
    this.onDeleted,
  });

  @override
  ConsumerState<CharacterDetailPage> createState() =>
      _CharacterDetailPageState();
}

class _CharacterDetailPageState extends ConsumerState<CharacterDetailPage> {
  final _descController = TextEditingController();
  bool _descInitialized = false;

  @override
  void didUpdateWidget(covariant CharacterDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _descInitialized = false;
      _descController.clear();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _initDesc(Character character) {
    if (!_descInitialized) {
      _descInitialized = true;
      _descController.text = character.description;
    }
  }

  void _saveDescription(Character character) {
    final text = _descController.text;
    if (text != character.description) {
      ref.read(characterActionsProvider).update(
            character.copyWith(description: text),
          );
      ref.invalidate(characterByIdProvider(widget.characterId));
    }
  }

  Future<void> _pickAndChangeAvatar(Character character) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final relPath = await ImageStorageService.instance.saveAvatarImage(
          sourcePath: picked.path,
          characterId: character.id,
        );
        await ref.read(characterActionsProvider).update(
              character.copyWith(avatarPath: Value(relPath)),
            );
        ref.invalidate(characterByIdProvider(widget.characterId));
        ref.invalidate(charactersByWorldProvider(widget.worldId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更换立绘失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterAsync =
        ref.watch(characterByIdProvider(widget.characterId));
    final fieldsAsync =
        ref.watch(characterFieldsProvider(widget.characterId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: characterAsync.when(
          data: (c) => Text(c.name),
          loading: () => const Text('加载中'),
          error: (err, stack) => const Text('错误'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.art_track_rounded),
            tooltip: '生成人设长图海报',
            onPressed: () {
              final character = characterAsync.valueOrNull;
              if (character != null) {
                showDialog(
                  context: context,
                  builder: (_) => CharacterPosterDialog(
                    character: character,
                    worldId: widget.worldId,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final character = characterAsync.valueOrNull;
              if (character != null) {
                showDialog(
                  context: context,
                  builder: (_) => CharacterDialog(
                    worldId: widget.worldId,
                    character: character,
                  ),
                ).then((_) {
                  ref.invalidate(
                      characterByIdProvider(widget.characterId));
                  ref.invalidate(
                      charactersByWorldProvider(widget.worldId));
                });
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_poster',
                child: Row(
                  children: [
                    Icon(Icons.art_track_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('生成长图海报'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_field',
                child: Text('添加字段'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child:
                    Text('删除人物', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'export_poster') {
                final character = characterAsync.valueOrNull;
                if (character != null) {
                  showDialog(
                    context: context,
                    builder: (_) => CharacterPosterDialog(
                      character: character,
                      worldId: widget.worldId,
                    ),
                  );
                }
              } else if (value == 'add_field') {
                _showAddFieldDialog(context, ref);
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
          ),
        ],
      ),
      body: characterAsync.when(
        data: (character) {
          _initDesc(character);
          final fields = fieldsAsync.valueOrNull ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === 基本信息 + 自定义字段 ===
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息
                      const Text('基本信息',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Center(
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () => _pickAndChangeAvatar(character),
                              borderRadius: BorderRadius.circular(44),
                              child: OcAvatar(
                                avatarPath: character.avatarPath,
                                name: character.name,
                                gender: character.gender,
                                size: 88,
                                isDraft: character.status == 1,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Tooltip(
                                message: '更换立绘/头像',
                                child: InkWell(
                                  onTap: () => _pickAndChangeAvatar(character),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: '名称', value: character.name),
                      if (character.gender.isNotEmpty)
                        _InfoRow(label: '性别', value: character.gender),
                      _InfoRow(
                        label: '状态',
                        value: character.status == 0 ? '正式' : '草稿',
                      ),
                      _InfoRow(
                        label: '创建时间',
                        value: _formatDate(character.createdAt),
                      ),

                      // 自定义字段紧贴基本信息
                      if (fields.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('附加信息',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _showAddFieldDialog(
                                  context, ref),
                            ),
                          ],
                        ),
                        const Divider(),
                        for (final field in fields)
                          _FieldRow(
                            field: field,
                            characterId: widget.characterId,
                          ),
                      ],
                      if (fields.isEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('添加附加字段'),
                            onPressed: () =>
                                _showAddFieldDialog(context, ref),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === 战力与属性雷达图 ===
              _CharacterStatsSection(characterId: widget.characterId),
              const SizedBox(height: 16),

              // === 立绘画廊与差分 ===
              CharacterGallerySection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 标签 ===
              TagSelector(characterId: widget.characterId),
              const SizedBox(height: 16),

              // === 分组 ===
              _GroupSelector(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 详细描述 ===
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('详细描述',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      TextField(
                        controller: _descController,
                        maxLines: null,
                        minLines: 6,
                        decoration: const InputDecoration(
                          hintText: '输入人物的详细描述…',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.6),
                        onSubmitted: (_) =>
                            _saveDescription(character),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === 关系 ===
              _RelationSection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('错误: $error')),
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
                decoration:
                    const InputDecoration(labelText: '字段类型'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('文本')),
                  DropdownMenuItem(value: 'number', child: Text('数字')),
                  DropdownMenuItem(
                      value: 'long_text', child: Text('长文本')),
                  DropdownMenuItem(value: 'select', child: Text('单选')),
                  DropdownMenuItem(
                      value: 'multi_select', child: Text('多选')),
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
                        widget.characterId,
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
                  .delete(widget.characterId);
              Navigator.pop(context);
              if (widget.onDeleted != null) {
                widget.onDeleted!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child:
                const Text('删除', style: TextStyle(color: Colors.red)),
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
            child:
                Text(label, style: const TextStyle(color: Colors.grey)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              widget.field.fieldName,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
            icon: const Icon(Icons.check, size: 18),
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

  const _RelationSection(
      {required this.worldId, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationsAsync =
        ref.watch(relationsByCharacterProvider(characterId));
    final charactersAsync =
        ref.watch(charactersByWorldProvider(worldId));

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
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
                    child: Text('暂无关系',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final allChars = charactersAsync.valueOrNull ?? [];

                return Column(
                  children: relations.map((rel) {
                    final otherId =
                        rel.fromCharacterId == characterId
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
                          Icon(directionIcon,
                              size: 18, color: Colors.grey),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('错误: $error'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRelationDialog(
      BuildContext context, WidgetRef ref, List<Character> allChars) {
    final others =
        allChars.where((c) => c.id != characterId).toList();
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
                decoration:
                    const InputDecoration(labelText: '目标人物'),
                items: others
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCharId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration:
                    const InputDecoration(labelText: '关系类型'),
                items: _relationTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
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
                onChanged: (v) =>
                    setState(() => isBidirectional = v),
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
                  ref.invalidate(
                      relationsByCharacterProvider(characterId));
                  ref.invalidate(
                      relationsByWorldProvider(worldId));
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
    final noteController =
        TextEditingController(text: rel.note ?? '');

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
                decoration:
                    const InputDecoration(labelText: '关系类型'),
                items: _relationTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
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
                onChanged: (v) =>
                    setState(() => isBidirectional = v),
              ),
              TextField(
                controller: noteController,
                decoration:
                    const InputDecoration(labelText: '备注（可选）'),
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
                        note: Value(
                            noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim()),
                      ),
                    );
                ref.invalidate(
                    relationsByCharacterProvider(characterId));
                ref.invalidate(
                    relationsByWorldProvider(worldId));
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
              await ref
                  .read(relationActionsProvider)
                  .delete(rel.id);
              ref.invalidate(
                  relationsByCharacterProvider(characterId));
              ref.invalidate(
                  relationsByWorldProvider(worldId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除',
                style: TextStyle(color: Colors.red)),
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

class _GroupSelector extends ConsumerStatefulWidget {
  final int worldId;
  final int characterId;

  const _GroupSelector({required this.worldId, required this.characterId});

  @override
  ConsumerState<_GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends ConsumerState<_GroupSelector> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.worldId));
    final characterGroupIdsAsync = ref.watch(characterGroupIdsProvider(widget.characterId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分组', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              await ref.read(groupActionsProvider).addCharacterToGroup(
                                widget.characterId,
                                group.id,
                              );
                            } else {
                              await ref.read(groupActionsProvider).removeCharacterFromGroup(
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

/// 战力与属性雷达图外层容器
class _CharacterStatsSection extends ConsumerWidget {
  final int characterId;

  const _CharacterStatsSection({required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(characterStatsProvider(characterId));

    return statsAsync.when(
      data: (stats) => _CharacterStatsCard(
        characterId: characterId,
        stats: stats,
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('加载属性失败: $e'),
        ),
      ),
    );
  }
}

/// 战力与属性雷达图卡片主体
class _CharacterStatsCard extends ConsumerStatefulWidget {
  final int characterId;
  final List<CharacterStat> stats;

  const _CharacterStatsCard({
    required this.characterId,
    required this.stats,
  });

  @override
  ConsumerState<_CharacterStatsCard> createState() =>
      _CharacterStatsCardState();
}

class _CharacterStatsCardState extends ConsumerState<_CharacterStatsCard> {
  final Map<int, double> _localValues = {};

  @override
  void initState() {
    super.initState();
    _syncLocalValues();
  }

  @override
  void didUpdateWidget(covariant _CharacterStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats != widget.stats) {
      _syncLocalValues();
    }
  }

  void _syncLocalValues() {
    for (final s in widget.stats) {
      if (!_localValues.containsKey(s.id)) {
        _localValues[s.id] = s.value;
      }
    }
    // 清理已删除的属性 ID
    final currentIds = widget.stats.map((s) => s.id).toSet();
    _localValues.removeWhere((id, _) => !currentIds.contains(id));
  }

  Future<void> _applyPreset(StatPreset preset) async {
    final companions = [
      for (var i = 0; i < preset.dimensions.length; i++)
        CharacterStatsCompanion.insert(
          characterId: widget.characterId,
          label: preset.dimensions[i],
          value: Value(preset.defaultValues?[preset.dimensions[i]] ??
              (preset.maxValue * 0.6)),
          maxValue: Value(preset.maxValue),
          sortOrder: Value(i),
        ),
    ];
    await ref.read(characterActionsProvider).setStats(widget.characterId, companions);
  }

  void _showPresetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high_rounded),
                    const SizedBox(width: 8),
                    Text(
                      '套用常用属性预设',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '选择预设将替换当前角色的属性维度列表，各维度可在套用后自由调节数值。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final preset in StatPreset.builtInPresets)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: Icon(preset.icon, size: 20),
                    ),
                    title: Text(
                      preset.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(preset.description),
                    trailing: Text(
                      '${preset.dimensions.length} 维 (满分 ${preset.maxValue.toInt()})',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyPreset(preset);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddStatDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '70');
    final maxCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加属性维度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '维度名称',
                hintText: '如：攻击力、意志、灵力',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '初始数值',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '满值上限',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final val = double.tryParse(valueCtrl.text) ?? 60.0;
              final max = double.tryParse(maxCtrl.text) ?? 100.0;

              await ref.read(characterActionsProvider).addStat(
                    CharacterStatsCompanion.insert(
                      characterId: widget.characterId,
                      label: label,
                      value: Value(val),
                      maxValue: Value(max > 0 ? max : 100.0),
                      sortOrder: Value(widget.stats.length),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditStatDialog(BuildContext context, CharacterStat stat) {
    final labelCtrl = TextEditingController(text: stat.label);
    final maxCtrl = TextEditingController(text: stat.maxValue.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改属性维度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '维度名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '满值上限'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final max = double.tryParse(maxCtrl.text) ?? stat.maxValue;

              await ref.read(characterActionsProvider).updateStat(
                    CharacterStatsCompanion(
                      id: Value(stat.id),
                      characterId: Value(stat.characterId),
                      label: Value(label),
                      value: Value(stat.value > max ? max : stat.value),
                      maxValue: Value(max > 0 ? max : 100.0),
                      sortOrder: Value(stat.sortOrder),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.stats;

    if (stats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '战力与属性 (六维雷达图)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '暂未配置属性维度。支持一键套用 TRPG 跑团、奇幻战力或心智性格预设，并在卡片上呈现多边形雷达图。',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('套用常用预设模版'),
                    onPressed: () => _showPresetPicker(context),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('自定义添加属性'),
                    onPressed: () => _showAddStatDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 构建雷达图数据项（使用实时滑动数值保证跟手动效）
    final radarItems = [
      for (final s in stats)
        RadarStatItem(
          label: s.label,
          value: (_localValues[s.id] ?? s.value).clamp(0.0, s.maxValue),
          maxValue: s.maxValue,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部标题栏
            Row(
              children: [
                Icon(Icons.radar_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '战力与属性',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stats.length} 维',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: '套用预设',
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('预设'),
                    onPressed: () => _showPresetPicker(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  tooltip: '添加新维度',
                  onPressed: () => _showAddStatDialog(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text(
                        '清空全部属性',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'clear_all') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认清空'),
                          content: const Text('确定要清空该角色的全部属性数据吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(characterActionsProvider)
                                    .setStats(widget.characterId, []);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('清空'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 自适应栅格：宽屏左右并排，窄屏上下排列
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 580;

                final chartPart = SizedBox(
                  width: isWide ? 260 : double.infinity,
                  height: 250,
                  child: Center(
                    child: RadarChart(
                      items: radarItems,
                      size: 240,
                    ),
                  ),
                );

                final slidersPart = Column(
                  children: [
                    for (final stat in stats)
                      _buildStatSliderRow(context, stat, theme),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      chartPart,
                      const SizedBox(width: 16),
                      Expanded(child: slidersPart),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      chartPart,
                      const SizedBox(height: 12),
                      slidersPart,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSliderRow(
    BuildContext context,
    CharacterStat stat,
    ThemeData theme,
  ) {
    final curVal = (_localValues[stat.id] ?? stat.value).clamp(0.0, stat.maxValue);
    final formattedVal = curVal.truncateToDouble() == curVal
        ? curVal.toInt().toString()
        : curVal.toStringAsFixed(1);
    final formattedMax = stat.maxValue.toInt().toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // 标签（点击支持修改维度名称或上限）
          InkWell(
            onTap: () => _showEditStatDialog(context, stat),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 拖动滑块
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                value: curVal,
                min: 0.0,
                max: stat.maxValue,
                onChanged: (v) {
                  setState(() {
                    _localValues[stat.id] = v;
                  });
                },
                onChangeEnd: (v) async {
                  await ref.read(characterActionsProvider).updateStat(
                        CharacterStatsCompanion(
                          id: Value(stat.id),
                          characterId: Value(stat.characterId),
                          label: Value(stat.label),
                          value: Value(v),
                          maxValue: Value(stat.maxValue),
                          sortOrder: Value(stat.sortOrder),
                        ),
                      );
                },
              ),
            ),
          ),

          // 数值展示
          SizedBox(
            width: 62,
            child: Text(
              '$formattedVal / $formattedMax',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // 删除维度按钮
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: '删除此维度',
            onPressed: () async {
              await ref
                  .read(characterActionsProvider)
                  .deleteStat(stat.id);
            },
          ),
        ],
      ),
    );
  }
}

