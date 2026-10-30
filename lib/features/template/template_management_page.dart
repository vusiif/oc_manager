import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/template_provider.dart';
import '../../data/database/app_database.dart';
import 'template_dialog.dart';

class TemplateManagementPage extends ConsumerWidget {
  const TemplateManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(globalTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '还没有模板',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角按钮创建模板',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateTile(template: template);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TemplateDialog(),
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  final Template template;

  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(templateFieldsProvider(template.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.description),
        title: Text(template.name),
        subtitle: fieldsAsync.when(
          data: (fields) => Text('${fields.length} 个字段'),
          loading: () => const Text('加载中...'),
          error: (err, stack) => const Text(''),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        children: [
          fieldsAsync.when(
            data: (fields) {
              if (fields.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('暂无字段', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children: [
                  for (final field in fields)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.short_text, size: 18),
                      title: Text(field.fieldName),
                      subtitle: Text(_fieldTypeName(field.fieldType) +
                          (field.defaultValue != null &&
                                  field.defaultValue!.isNotEmpty
                              ? '  |  默认：${field.defaultValue}'
                              : '')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete,
                            size: 16, color: Colors.red),
                        onPressed: () => _deleteField(context, ref, field.id),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('错误: $e'),
            ),
          ),
        ],
      ),
    );
  }

  String _fieldTypeName(String type) {
    switch (type) {
      case 'text':
        return '文本';
      case 'number':
        return '数字';
      case 'long_text':
        return '长文本';
      case 'select':
        return '单选';
      case 'multi_select':
        return '多选';
      default:
        return type;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => TemplateDialog(template: template),
    ).then((_) {
      ref.invalidate(globalTemplatesProvider);
      ref.invalidate(templateFieldsProvider(template.id));
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除"${template.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(templateActionsProvider).delete(template.id);
              ref.invalidate(globalTemplatesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteField(BuildContext context, WidgetRef ref, int fieldId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除字段'),
        content: const Text('确定要删除这个字段吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(templateActionsProvider).removeField(fieldId);
              ref.invalidate(templateFieldsProvider(template.id));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
