import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/lore_provider.dart';
import '../../providers/revision_provider.dart';
import '../../core/storage/image_storage_service.dart';
import 'lore_cover_image.dart';

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

  void _applyFactionTemplate() {
    final defaultFactionFields = {
      '组织类别': '军事军团/法师行会',
      '核心宗旨': '坚守信条，维护秩序与正义',
      '势力现状': '活跃兴盛',
      '组织规模': '跨区域大型组织',
    };
    setState(() {
      for (final entry in defaultFactionFields.entries) {
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

  void _applyItemTemplate() {
    final defaultItemFields = {
      '物品类别': '神兵利刃/防具圣物',
      '品阶稀有度': '传说 (Legendary)',
      '持有状态': '现世活跃',
      '来源出处': '远古巨匠铸造/遗迹出土',
      '特殊效果': '注入元素威能，附带破甲冲击',
      '使用代价': '需契约者灵魂同调',
    };
    setState(() {
      for (final entry in defaultItemFields.entries) {
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

  void _applyRaceTemplate() {
    final defaultRaceFields = {
      '种族分类': '类人种族/妖精幻兽/异界生灵',
      '平均寿命': '~350岁 (长生种)',
      '生理特征': '尖耳长眸，敏捷感知出众',
      '生活习性': '聚居于林海圣所，崇尚自然与星辰',
      '社会文化': '长老议会制，通用古精灵语与符文',
      '信仰崇拜': '月神艾露恩 / 自然母神',
    };
    setState(() {
      for (final entry in defaultRaceFields.entries) {
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

  void _applyAbilityTemplate() {
    final defaultAbilityFields = {
      '能力分类': '元素魔法/超能觉醒/秘术法则',
      '威能阶位': '超阶禁咒 (Rank S)',
      '生效方式': '瞬发吟唱/大范围法阵侵蚀',
      '前置条件': '需掌握高阶冰霜与奥术亲和',
      '限制条件': '施法时不可移动，需媒介法杖引导',
      '反噬代价': '过量汲取将灼伤经络神识',
    };
    setState(() {
      for (final entry in defaultAbilityFields.entries) {
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
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                child: _coverImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            LoreCoverImage(
                                              imagePath: _coverImagePath,
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: InkWell(
                                                onTap: () => setState(
                                                  () => _coverImagePath = null,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedType ==
                                                    LoreEntityType.faction
                                                ? '组织徽记'
                                                : _selectedType ==
                                                      LoreEntityType.item
                                                ? '装备立绘'
                                                : _selectedType ==
                                                      LoreEntityType.race
                                                ? '种族特征'
                                                : _selectedType ==
                                                      LoreEntityType.ability
                                                ? '符文法阵'
                                                : '上传图鉴',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: '所属标签',
                            hintText: '多个标签请以逗号隔开，如：神圣, 古遗迹, 禁忌',
                            prefixIcon: Icon(Icons.label_outline, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '专有属性 / 结构化设定',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (_selectedType ==
                                    LoreEntityType.faction) ...[
                                  TextButton.icon(
                                    onPressed: _applyFactionTemplate,
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 15,
                                    ),
                                    label: const Text('填入组织预设'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ] else if (_selectedType ==
                                    LoreEntityType.item) ...[
                                  TextButton.icon(
                                    onPressed: _applyItemTemplate,
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 15,
                                    ),
                                    label: const Text('填入装备预设'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ] else if (_selectedType ==
                                    LoreEntityType.race) ...[
                                  TextButton.icon(
                                    onPressed: _applyRaceTemplate,
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 15,
                                    ),
                                    label: const Text('填入种族预设'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ] else if (_selectedType ==
                                    LoreEntityType.ability) ...[
                                  TextButton.icon(
                                    onPressed: _applyAbilityTemplate,
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 15,
                                    ),
                                    label: const Text('填入能力预设'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                TextButton.icon(
                                  onPressed: _addCustomField,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('添加属性'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_customFieldControllers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '暂无专有属性。可点击上方按钮添加（如：领袖、坐标、危险等级、法力消耗等）。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          )
                        else
                          ...List.generate(_customFieldControllers.length, (
                            index,
                          ) {
                            final pair = _customFieldControllers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: TextField(
                                      controller: pair.key,
                                      decoration: InputDecoration(
                                        hintText: '属性名 (如坐标)',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: pair.value,
                                      decoration: InputDecoration(
                                        hintText: '属性值 (如北境深渊)',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    onPressed: () => _removeCustomField(index),
                                    tooltip: '移除',
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
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
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
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
