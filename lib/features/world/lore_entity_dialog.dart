import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/storage/image_storage_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/lore_provider.dart';
import '../../providers/revision_provider.dart';
import 'widgets/lore_cover_image_picker.dart';
import 'widgets/lore_custom_fields_section.dart';

class LoreEntityDialog extends ConsumerStatefulWidget {
  final int worldId;
  final LoreEntity? entity;
  final String? initialType;

  const LoreEntityDialog({
    super.key,
    required this.worldId,
    this.entity,
    this.initialType,
  });

  static Future<int?> show(
    BuildContext context, {
    required int worldId,
    LoreEntity? entity,
    String? initialType,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => LoreEntityDialog(
        worldId: worldId,
        entity: entity,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<LoreEntityDialog> createState() => _LoreEntityDialogState();
}

class _LoreEntityDialogState extends ConsumerState<LoreEntityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;

  late LoreEntityType _selectedType;
  int? _selectedParentId;
  String? _coverImagePath;
  final List<MapEntry<TextEditingController, TextEditingController>>
  _customFieldControllers = [];

  @override
  void initState() {
    super.initState();
    final e = widget.entity;
    _nameController = TextEditingController(text: e?.name ?? '');
    _summaryController = TextEditingController(text: e?.summary ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _tagsController = TextEditingController(text: e?.tags ?? '');
    _coverImagePath = e?.coverImagePath;
    _selectedParentId = e?.parentId;

    if (e != null) {
      _selectedType = LoreEntityType.fromKey(e.entityType);
    } else if (widget.initialType != null) {
      _selectedType = LoreEntityType.fromKey(widget.initialType!);
    } else {
      _selectedType = LoreEntityType.location;
    }

    if (e != null && e.customFields.isNotEmpty) {
      try {
        final decoded = jsonDecode(e.customFields);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            _customFieldControllers.add(
              MapEntry(
                TextEditingController(text: entry.key.toString()),
                TextEditingController(text: entry.value.toString()),
              ),
            );
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    for (final pair in _customFieldControllers) {
      pair.key.dispose();
      pair.value.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final savedRelativePath = await ImageStorageService.instance
          .saveAvatarImage(sourcePath: picked.path);
      setState(() => _coverImagePath = savedRelativePath);
    }
  }

  void _addCustomField() {
    setState(() {
      _customFieldControllers.add(
        MapEntry(TextEditingController(), TextEditingController()),
      );
    });
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      for (final entry in template.entries) {
        if (!_customFieldControllers.any(
          (p) => p.key.text.trim() == entry.key,
        )) {
          _customFieldControllers.add(
            MapEntry(
              TextEditingController(text: entry.key),
              TextEditingController(text: entry.value),
            ),
          );
        }
      }
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      final pair = _customFieldControllers.removeAt(index);
      pair.key.dispose();
      pair.value.dispose();
    });
  }

  String _serializeCustomFields() {
    final map = <String, String>{};
    for (final pair in _customFieldControllers) {
      final key = pair.key.text.trim();
      final val = pair.value.text.trim();
      if (key.isNotEmpty) {
        map[key] = val;
      }
    }
    return jsonEncode(map);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final actions = ref.read(loreActionsProvider);
    final customFieldsJson = _serializeCustomFields();

    try {
      if (widget.entity == null) {
        final id = await actions.createEntity(
          worldId: widget.worldId,
          parentId: _selectedParentId,
          entityType: _selectedType.key,
          name: _nameController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          coverImagePath: _coverImagePath,
          tags: _tagsController.text,
          customFields: customFieldsJson,
        );
        if (mounted) Navigator.pop(context, id);
      } else {
        final hasChanged =
            widget.entity!.content != _contentController.text ||
            widget.entity!.name != _nameController.text.trim() ||
            widget.entity!.summary != _summaryController.text.trim() ||
            widget.entity!.tags != _tagsController.text.trim() ||
            widget.entity!.customFields != customFieldsJson ||
            widget.entity!.parentId != _selectedParentId ||
            widget.entity!.coverImagePath != _coverImagePath;

        if (hasChanged) {
          await ref
              .read(revisionActionsProvider)
              .recordLoreSnapshot(lore: widget.entity!, source: 'auto');
        }
        await actions.updateEntity(
          id: widget.entity!.id,
          worldId: widget.worldId,
          parentId: _selectedParentId,
          entityType: _selectedType.key,
          name: _nameController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          coverImagePath: _coverImagePath,
          tags: _tagsController.text,
          customFields: customFieldsJson,
        );
        if (mounted) Navigator.pop(context, widget.entity!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.entity != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedType.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedType.icon,
                        color: _selectedType.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? '编辑百科词条' : '新建百科实体',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('实体分类', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: LoreEntityType.values.map((type) {
                            final isSelected = _selectedType == type;
                            return ChoiceChip(
                              avatar: Icon(
                                type.icon,
                                size: 16,
                                color: isSelected ? Colors.white : type.color,
                              ),
                              label: Text(type.label),
                              selected: isSelected,
                              selectedColor: type.color,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedType = type);
                              },
                            );
                          }).toList(),
                        ),
                        if (_selectedType == LoreEntityType.location ||
                            _selectedType == LoreEntityType.faction ||
                            _selectedType == LoreEntityType.race ||
                            _selectedType == LoreEntityType.ability) ...[
                          const SizedBox(height: 12),
                          FutureBuilder<List<LoreEntity>>(
                            future: ref
                                .read(loreDaoProvider)
                                .getAvailableParents(
                                  widget.worldId,
                                  currentEntityId: widget.entity?.id,
                                  entityType: _selectedType.key,
                                ),
                            builder: (context, snapshot) {
                              final parents = snapshot.data ?? [];
                              final hasMatchingParent =
                                  _selectedParentId == null ||
                                  parents.any((p) => p.id == _selectedParentId);
                              final effectiveParentId = hasMatchingParent
                                  ? _selectedParentId
                                  : null;

                              return DropdownButtonFormField<int?>(
                                initialValue: effectiveParentId,
                                decoration: InputDecoration(
                                  labelText:
                                      _selectedType == LoreEntityType.location
                                      ? '所属上级地理空间 (如所属国家/省份/大区)'
                                      : _selectedType == LoreEntityType.faction
                                      ? '所属上级组织架构 (如总团/总公司/主阵营)'
                                      : _selectedType == LoreEntityType.race
                                      ? '所属起源母种族 / 祖族分支 (如精灵 -> 高等精灵/暗夜精灵)'
                                      : '所属前置基础体系 / 进阶法系 (如元素魔法 -> 禁断湮灭术)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(
                                    Icons.account_tree_outlined,
                                    size: 20,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('(无 - 独立顶级实体)'),
                                  ),
                                  ...parents.map(
                                    (p) => DropdownMenuItem<int?>(
                                      value: p.id,
                                      child: Text(p.name),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedParentId = val);
                                },
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    maxLength: 100,
                                    decoration: const InputDecoration(
                                      labelText: '实体名称 *',
                                      hintText: '如：阿瓦隆群岛、荒坂集团、圣剑誓约',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? '请输入实体名称'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _summaryController,
                                    maxLength: 500,
                                    decoration: const InputDecoration(
                                      labelText: '一句话摘要',
                                      hintText: '简明阐述该实体的核心定义与世界地位',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            LoreCoverImagePicker(
                              coverImagePath: _coverImagePath,
                              selectedType: _selectedType,
                              onPick: _pickImage,
                              onClear: () =>
                                  setState(() => _coverImagePath = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tagsController,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            labelText: '所属标签',
                            hintText: '多个标签请以逗号隔开，如：神圣, 古遗迹, 禁忌',
                            prefixIcon: Icon(Icons.label_outline, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LoreCustomFieldsSection(
                          selectedType: _selectedType,
                          controllers: _customFieldControllers,
                          onAddField: _addCustomField,
                          onRemoveField: _removeCustomField,
                          onApplyTemplate: _applyTemplate,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          maxLength: 10000,
                          decoration: const InputDecoration(
                            labelText: '详细设定 / 百科词条正文',
                            hintText: '支持 Markdown 格式与 [[角色名]] 双向链接引用...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _save,
                      child: Text(isEditing ? '保存修改' : '创建词条'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
