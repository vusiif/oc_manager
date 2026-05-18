import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.character?.name ?? '');
    _customGenderController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.character != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑人物' : '创建人物'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '人物名称',
                hintText: '例如：艾莉丝',
              ),
              autofocus: true,
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

  void _save() {
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
        ),
      );
    } else {
      actions.create(
        worldId: widget.worldId,
        name: name,
        status: _status,
        gender: gender,
      );
    }

    Navigator.pop(context);
  }
}
