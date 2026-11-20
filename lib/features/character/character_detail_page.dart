import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:image_picker/image_picker.dart';

import '../../providers/character_provider.dart';
import '../../data/database/app_database.dart';
import '../../core/storage/image_storage_service.dart';
import '../../core/constants/character_status.dart';
import '../../core/design/components/oc_avatar.dart';
import 'character_gallery_section.dart';
import 'character_timeline_section.dart';
import 'character_description_section.dart';
import 'character_poster_dialog.dart';
import '../tag/tag_selector.dart';
import 'character_dialog.dart';
import '../world/revision_history_dialog.dart';
import 'character_story_appearance_section.dart';
import 'character_stats_section.dart';
import 'character_lore_section.dart';
import 'character_relation_section.dart';

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
  Future<void> _pickAndChangeAvatar(Character character) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final relPath = await ImageStorageService.instance.saveAvatarImage(
          sourcePath: picked.path,
          characterId: character.id,
        );
        await ref
            .read(characterActionsProvider)
            .update(character.copyWith(avatarPath: Value(relPath)));
        ref.invalidate(characterByIdProvider(widget.characterId));
        ref.invalidate(charactersByWorldProvider(widget.worldId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更换立绘失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterAsync = ref.watch(characterByIdProvider(widget.characterId));
    final fieldsAsync = ref.watch(characterFieldsProvider(widget.characterId));
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
                  ref.invalidate(characterByIdProvider(widget.characterId));
                  ref.invalidate(charactersByWorldProvider(widget.worldId));
                });
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('设定版本历史'),
                  ],
                ),
              ),
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
              const PopupMenuItem(value: 'add_field', child: Text('添加字段')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除人物', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'history') {
                final character = characterAsync.valueOrNull;
                if (character != null) {
                  RevisionHistoryDialog.show(
                    context,
                    worldId: widget.worldId,
                    entityType: 'character',
                    entityId: character.id,
                    entityName: character.name,
                    currentContent: character.description,
                    character: character,
                  );
                }
              } else if (value == 'export_poster') {
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
                      const Text(
                        '基本信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                        color: Colors.white,
                                        width: 2,
                                      ),
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
                        value: CharacterCreationStatus.find(
                          character.status,
                        ).label,
                      ),
                      _InfoRow(
                        label: '创建时间',
                        value: _formatDate(character.createdAt),
                      ),

                      // 自定义字段紧贴基本信息
                      if (fields.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '附加信息',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () =>
                                  _showAddFieldDialog(context, ref),
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
                            onPressed: () => _showAddFieldDialog(context, ref),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === 战力与属性雷达图 ===
              CharacterStatsSection(characterId: widget.characterId),
              const SizedBox(height: 16),

              // === 立绘画廊与差分 ===
              CharacterGallerySection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 生平大事记与时间线 ===
              CharacterTimelineSection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 标签 ===
              TagSelector(characterId: widget.characterId),
              const SizedBox(height: 16),

              // === 分组 ===
              CharacterGroupSelector(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 详细设定与双向链接小传 ===
              CharacterDescriptionSection(
                worldId: widget.worldId,
                character: character,
              ),
              const SizedBox(height: 16),

              // === 关系 ===
              CharacterRelationSection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 所属势力与地点归属 (LORE-002 & LORE-003) ===
              CharacterLoreSection(
                worldId: widget.worldId,
                characterId: widget.characterId,
              ),
              const SizedBox(height: 16),

              // === 故事线出场记录 (STORY-003) ===
              CharacterStoryAppearanceSection(
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
                  ref
                      .read(characterActionsProvider)
                      .updateField(widget.characterId, name, fieldType, null);
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
            onPressed: () async {
              await ref
                  .read(characterActionsProvider)
                  .delete(widget.characterId);
              if (context.mounted) {
                Navigator.pop(context);
                if (widget.onDeleted != null) {
                  widget.onDeleted!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
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
    ref
        .read(characterActionsProvider)
        .updateField(
          widget.characterId,
          widget.field.fieldName,
          widget.field.fieldType,
          value,
        );
  }
}
