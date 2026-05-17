import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/world_provider.dart';

class WorldDialog extends ConsumerStatefulWidget {
  final World? world;

  const WorldDialog({super.key, this.world});

  @override
  ConsumerState<WorldDialog> createState() => _WorldDialogState();
}

class _WorldDialogState extends ConsumerState<WorldDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.world?.name ?? '');
    _descController =
        TextEditingController(text: widget.world?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.world != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑世界观' : '创建世界观'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '世界观名称',
              hintText: '例如：魔法大陆',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '简要描述这个世界观',
            ),
            maxLines: 3,
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
        const SnackBar(content: Text('请输入世界观名称')),
      );
      return;
    }

    final actions = ref.read(worldActionsProvider);
    if (widget.world != null) {
      actions.update(
        widget.world!.id,
        name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
    } else {
      actions.create(
        name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
    }

    Navigator.pop(context);
  }
}
