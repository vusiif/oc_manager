import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';

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
  int _status = 0;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.character?.name ?? '');
    _status = widget.character?.status ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.character != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑人物' : '创建人物'),
      content: Column(
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

    final actions = ref.read(characterActionsProvider);
    if (widget.character != null) {
      actions.update(
        widget.character!.copyWith(
          name: name,
          status: _status,
        ),
      );
    } else {
      actions.create(
        worldId: widget.worldId,
        name: name,
        status: _status,
      );
    }

    Navigator.pop(context);
  }
}
