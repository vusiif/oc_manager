import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/database_provider.dart';
import '../../core/storage/image_storage_service.dart';
import '../../core/design/components/oc_avatar.dart';

const _genderOptions = [
  ('男', '♂'),
  ('女', '♀'),
  ('其他', '⚥'),
];

class CharacterDialog extends ConsumerStatefulWidget {
  final int worldId;
  final Character? character;

  const CharacterDialog({
    super.key,
    required this.worldId,
    this.character,
  });

  @override
  ConsumerState<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends ConsumerState<CharacterDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _customGenderController;
  int _status = 0;
  String _gender = '';
  bool _isCustomGender = false;
  int? _selectedTemplateId;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.character?.name ?? '');
    _customGenderController = TextEditingController();
    _avatarPath = widget.character?.avatarPath;
    final g = widget.character?.gender ?? '';
    if (g.isNotEmpty &&
        !_genderOptions.any((o) => o.$1 == g)) {
      _gender = g;
      _isCustomGender = true;
      _customGenderController.text = g;
    } else {
      _gender = g;
    }
    _status = widget.character?.status ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customGenderController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final relPath = await ImageStorageService.instance.saveAvatarImage(
          sourcePath: picked.path,
          characterId: widget.character?.id,
        );
        setState(() {
          _avatarPath = relPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.character != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑人物' : '创建人物'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像上传与预览
            Center(
              child: Stack(
                children: [
                  InkWell(
                    onTap: _pickAvatar,
                    borderRadius: BorderRadius.circular(36),
                    child: OcAvatar(
                      avatarPath: _avatarPath,
                      name: _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : '?',
                      gender: _gender,
                      size: 72,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickAvatar,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '人物名称',
                hintText: '例如：艾莉丝',
              ),
              autofocus: !isEditing,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // 性别选择
            Align(
              alignment: Alignment.centerLeft,
              child: Text('性别', style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final (label, icon) in _genderOptions)
                  ChoiceChip(
                    label: Text('$icon $label',
                        style: const TextStyle(fontSize: 12)),
                    selected: !_isCustomGender && _gender == label,
                    onSelected: (_) => setState(() {
                      _gender = label;
                      _isCustomGender = false;
                    }),
                  ),
                ChoiceChip(
                  label: const Text('自定义…',
                      style: TextStyle(fontSize: 12)),
                  selected: _isCustomGender,
                  onSelected: (_) =>
                      setState(() => _isCustomGender = true),
                ),
              ],
            ),
            if (_isCustomGender) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customGenderController,
                decoration: const InputDecoration(
                  labelText: '自定义性别',
                  hintText: '例如：非二元、流性别…',
                ),
                onChanged: (v) => _gender = v.trim(),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('正式')),
                ButtonSegment(value: 1, label: Text('草稿')),
              ],
              selected: {_status},
              onSelectionChanged: (values) {
                setState(() => _status = values.first);
              },
            ),
            if (!isEditing) ...[
              const SizedBox(height: 16),
              _TemplateSelector(
                selectedId: _selectedTemplateId,
                onChanged: (id) => setState(() => _selectedTemplateId = id),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入人物名称')),
      );
      return;
    }

    final gender = _isCustomGender
        ? _customGenderController.text.trim()
        : _gender;

    final actions = ref.read(characterActionsProvider);
    if (widget.character != null) {
      actions.update(
        widget.character!.copyWith(
          name: name,
          gender: gender,
          status: _status,
          avatarPath: Value(_avatarPath),
        ),
      );
    } else {
      final characterId = await actions.create(
        worldId: widget.worldId,
        name: name,
        status: _status,
        gender: gender,
        avatarPath: _avatarPath,
      );

      // 套用模板
      if (_selectedTemplateId != null) {
        final fields = await ref
            .read(templateDaoProvider)
            .getTemplateFields(_selectedTemplateId!);
        for (final field in fields) {
          await actions.updateField(
            characterId,
            field.fieldName,
            field.fieldType,
            field.defaultValue,
          );
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _TemplateSelector extends ConsumerWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _TemplateSelector({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(globalTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<int?>(
          initialValue: selectedId,
          decoration: const InputDecoration(
            labelText: '套用模板（可选）',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('不使用模板'),
            ),
            for (final t in templates)
              DropdownMenuItem<int?>(
                value: t.id,
                child: Text(t.name),
              ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
