import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/confirmation_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/design_tokens.dart';
import '../../providers/template_provider.dart';
import '../../data/database/app_database.dart';
import 'template_dialog.dart';
import 'template_transfer_dialogs.dart';

class TemplateManagementPage extends ConsumerWidget {
  const TemplateManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(globalTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: '官方预设模板库',
            onPressed: () =>
                TemplateTransferDialogs.showOfficialPresetsDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导入模板 (JSON)',
            onPressed: () =>
                TemplateTransferDialogs.importFromJsonFile(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导出全部模板 (JSON)',
            onPressed: () =>
                TemplateTransferDialogs.exportTemplates(context, ref),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyStateView(
              icon: Icons.description_outlined,
              title: '还没有人物模板',
              description: '创建自定义字段模板，或直接从官方预设库导入常用角色模板（奇幻、现代、科幻、TRPG 等）。',
              primaryActionLabel: '浏览官方预设模板',
              onPrimaryAction: () =>
                  TemplateTransferDialogs.showOfficialPresetsDialog(
                    context,
                    ref,
                  ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _TemplateTile(template: template);
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建模板'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const TemplateDialog());
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
              icon: const Icon(Icons.file_upload_outlined, size: 20),
              tooltip: '导出此模板',
              onPressed: () => TemplateTransferDialogs.exportTemplates(
                context,
                ref,
                targetTemplates: [template],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑模板',
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              tooltip: '删除模板',
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
                      subtitle: Text(
                        _fieldTypeName(field.fieldType) +
                            (field.defaultValue != null &&
                                    field.defaultValue!.isNotEmpty
                                ? '  |  默认：${field.defaultValue}'
                                : ''),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '删除模板',
      content: '确定要删除"${template.name}"吗？',
      confirmLabel: '删除',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref.read(templateActionsProvider).delete(template.id);
    ref.invalidate(globalTemplatesProvider);
  }

  Future<void> _deleteField(
    BuildContext context,
    WidgetRef ref,
    int fieldId,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '删除字段',
      content: '确定要删除这个字段吗？',
      confirmLabel: '删除',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref.read(templateActionsProvider).removeField(fieldId);
    ref.invalidate(templateFieldsProvider(template.id));
  }
}
