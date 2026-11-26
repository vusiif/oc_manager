import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_tokens.dart';
import '../../core/services/template_transfer_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';

/// UI dialogs for official template presets, JSON export, and conflict-aware import.
class TemplateTransferDialogs {
  /// Exports given [templates] (or all global templates) as a `.json` file.
  static Future<void> exportTemplates(
    BuildContext context,
    WidgetRef ref, {
    List<Template>? targetTemplates,
  }) async {
    final dao = ref.read(templateDaoProvider);
    final list = targetTemplates ?? await dao.getGlobalTemplates();
    if (list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前没有可导出的全局模板')));
      }
      return;
    }

    final items = <TemplatePackageItem>[];
    for (final t in list) {
      final fields = await dao.getTemplateFields(t.id);
      items.add(
        TemplatePackageItem(
          name: t.name,
          fields: fields
              .map(
                (f) => TemplateFieldSpec(
                  fieldName: f.fieldName,
                  fieldType: f.fieldType,
                  defaultValue: f.defaultValue,
                  sortOrder: f.sortOrder,
                ),
              )
              .toList(),
        ),
      );
    }

    final defaultName = list.length == 1
        ? '${list.first.name}.oc_templates.json'
        : 'oc_templates_bundle.json';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '导出人物模板',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return;

    await File(
      savePath,
    ).writeAsString(TemplateTransferService.encodeBundle(items));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出 ${items.length} 个模板到 $savePath')),
      );
    }
  }

  /// Picks a `.json` file, previews conflicts, and executes import.
  static Future<void> importFromJsonFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: '选择人物模板 JSON 文件',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    try {
      final raw = await File(path).readAsString();
      final existing = await ref.read(templateDaoProvider).getGlobalTemplates();
      final preview = TemplateTransferService.inspectJson(
        raw,
        existing.map((e) => e.name).toSet(),
      );
      if (!context.mounted) return;
      await _showImportPreviewDialog(context, ref, preview);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析模板失败: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Shows official starter preset templates and lets the user import selected ones.
  static Future<void> showOfficialPresetsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final existing = await ref.read(templateDaoProvider).getGlobalTemplates();
    final existingNames = existing.map((e) => e.name).toSet();
    if (!context.mounted) return;

    final selected = <String>{
      for (final p in TemplateTransferService.officialPresets)
        if (!existingNames.contains(p.name)) p.name,
    };

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: AppColors.brand),
              SizedBox(width: AppSpacing.sm),
              Text('官方预设模板库'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final preset in TemplateTransferService.officialPresets)
                    CheckboxListTile(
                      value: selected.contains(preset.name),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          selected.add(preset.name);
                        } else {
                          selected.remove(preset.name);
                        }
                      }),
                      title: Row(
                        children: [
                          Text(
                            preset.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (existingNames.contains(preset.name)) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: const Text(
                                '已存在',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${preset.description}\n字段：${preset.fields.map((f) => f.fieldName).join('、')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      final toImport = TemplateTransferService.officialPresets
                          .where((p) => selected.contains(p.name))
                          .toList();
                      final count =
                          await TemplateTransferService.importTemplates(
                            ref: ref,
                            items: toImport,
                            policy: TemplateConflictPolicy.renameCopy,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已导入 $count 套官方预设模板')),
                        );
                      }
                    },
              child: Text('导入已选 (${selected.length})'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showImportPreviewDialog(
    BuildContext context,
    WidgetRef ref,
    TemplateImportPreview preview,
  ) async {
    var policy = TemplateConflictPolicy.renameCopy;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          title: const Text('模板导入预览'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '共检测到 ${preview.templates.length} 个模板（格式 v${preview.formatVersion}）：',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final t in preview.templates)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        preview.conflictingNames.contains(t.name)
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: preview.conflictingNames.contains(t.name)
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.fields.length} 个字段${preview.conflictingNames.contains(t.name) ? ' · 同名冲突' : ''}',
                      ),
                    ),
                  if (preview.hasConflicts) ...[
                    const Divider(),
                    const Text(
                      '重名冲突处理策略：',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<TemplateConflictPolicy>(
                      initialValue: policy,
                      items: const [
                        DropdownMenuItem(
                          value: TemplateConflictPolicy.renameCopy,
                          child: Text('自动创建副本（保留原模板）'),
                        ),
                        DropdownMenuItem(
                          value: TemplateConflictPolicy.overwrite,
                          child: Text('覆盖同名模板字段'),
                        ),
                        DropdownMenuItem(
                          value: TemplateConflictPolicy.skip,
                          child: Text('跳过同名模板'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => policy = v);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final count = await TemplateTransferService.importTemplates(
                  ref: ref,
                  items: preview.templates,
                  policy: policy,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('成功导入 $count 个模板')));
                }
              },
              child: const Text('确认导入'),
            ),
          ],
        ),
      ),
    );
  }
}
