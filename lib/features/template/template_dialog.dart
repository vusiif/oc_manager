import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/template_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/database/app_database.dart';

const _fieldTypes = [
  ('text', '文本'),
  ('number', '数字'),
  ('long_text', '长文本'),
  ('select', '单选'),
  ('multi_select', '多选'),
];

class TemplateDialog extends ConsumerStatefulWidget {
  final Template? template;

  const TemplateDialog({super.key, this.template});

  @override
  ConsumerState<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<TemplateDialog> {
  late final TextEditingController _nameController;
  List<_FieldEntry> _fields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.template?.name ?? '');
    _loadFields();
  }

  Future<void> _loadFields() async {
    if (widget.template != null) {
      final fields = await ref
          .read(templateDaoProvider)
          .getTemplateFields(widget.template!.id);
      _fields = fields
          .map((f) => _FieldEntry(
                id: f.id,
                nameController: TextEditingController(text: f.fieldName),
                type: f.fieldType,
                defaultController:
                    TextEditingController(text: f.defaultValue ?? ''),
              ))
          .toList();
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final f in _fields) {
      f.nameController.dispose();
      f.defaultController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑模板' : '创建模板'),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '模板名称',
                        hintText: '例如：奇幻角色、现代角色',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('字段列表',
                            style: Theme.of(context).textTheme.titleSmall),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('添加字段'),
                          onPressed: _addField,
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_fields.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('还没有字段，点击上方添加',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    for (int i = 0; i < _fields.length; i++)
                      _buildFieldTile(i),
                  ],
                ),
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

  Widget _buildFieldTile(int index) {
    final field = _fields[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: field.nameController,
                    decoration: const InputDecoration(
                      labelText: '字段名',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: field.type,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      isDense: true,
                    ),
                    items: _fieldTypes
                        .map((t) => DropdownMenuItem(
                              value: t.$1,
                              child: Text(t.$2,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => field.type = v);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => setState(() => _fields.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: field.defaultController,
              decoration: const InputDecoration(
                labelText: '默认值（可选）',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldEntry(
        nameController: TextEditingController(),
        type: 'text',
        defaultController: TextEditingController(),
      ));
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }

    final actions = ref.read(templateActionsProvider);

    int templateId;
    if (widget.template != null) {
      await actions.update(widget.template!.id, name);
      templateId = widget.template!.id;
      // 删除旧字段，重新创建
      await ref
          .read(templateDaoProvider)
          .deleteAllTemplateFields(templateId);
    } else {
      templateId = await actions.create(name: name);
    }

    // 保存字段
    for (int i = 0; i < _fields.length; i++) {
      final f = _fields[i];
      final fieldName = f.nameController.text.trim();
      if (fieldName.isEmpty) continue;

      await actions.addField(
        templateId: templateId,
        fieldName: fieldName,
        fieldType: f.type,
        defaultValue: f.defaultController.text.trim().isEmpty
            ? null
            : f.defaultController.text.trim(),
        sortOrder: i,
      );
    }

    ref.invalidate(globalTemplatesProvider);

    if (mounted) Navigator.pop(context);
  }
}

class _FieldEntry {
  final int? id;
  final TextEditingController nameController;
  String type;
  final TextEditingController defaultController;

  _FieldEntry({
    this.id,
    required this.nameController,
    required this.type,
    required this.defaultController,
  });
}
