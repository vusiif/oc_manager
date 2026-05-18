import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/group_provider.dart';
import '../../data/database/app_database.dart';

class GroupDialog extends ConsumerStatefulWidget {
  final int worldId;
  final Group? group;

  const GroupDialog({
    super.key,
    required this.worldId,
    this.group,
  });

  @override
  ConsumerState<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends ConsumerState<GroupDialog> {
  late final TextEditingController _nameController;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.group != null;
    _nameController = TextEditingController(
      text: widget.group?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? '编辑分组' : '新建分组'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: '分组名称',
          hintText: '例如：主角团、反派、路人',
        ),
        autofocus: true,
      ),
      actions: [
        if (_isEdit)
          TextButton(
            onPressed: () => _delete(context),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => _save(context),
          child: Text(_isEdit ? '保存' : '创建'),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_isEdit) {
      ref.read(groupActionsProvider).update(
            widget.group!.copyWith(name: name),
          );
    } else {
      ref.read(groupActionsProvider).create(
            worldId: widget.worldId,
            name: name,
          );
    }
    Navigator.pop(context);
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除"${widget.group!.name}"吗？\n分组下的人物不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(groupActionsProvider).delete(widget.group!.id);
              Navigator.pop(context); // 关闭确认对话框
              Navigator.pop(context); // 关闭编辑对话框
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
