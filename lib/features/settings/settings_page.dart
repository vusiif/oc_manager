import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/settings_provider.dart';
import '../../data/database/app_database.dart';
import '../../core/backup/project_backup_service.dart';
import '../world/oc_package_dialogs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 主题设置
          _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeName(themeMode)),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          const Divider(),

          // 基本信息字段配置
          _SectionHeader(title: '基本信息字段'),
          _BasicInfoFieldsSection(),

          const Divider(),

          // 数据管理
          _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('清理缓存'),
            subtitle: const Text('清除临时文件和缓存数据'),
            onTap: () => _showClearCacheDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('导出数据库快照 (.db)'),
            subtitle: const Text('仅结构化数据，生成事务一致性 SQLite 快照'),
            onTap: () => _backupDatabaseSnapshot(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('导出完整项目包 (.zip)'),
            subtitle: const Text('打包 SQLite 数据库及全部本地立绘与差分画廊'),
            onTap: () => _backupFullProject(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从 .db 快照或 .zip 完整项目包还原（含安全还原点）'),
            onTap: () => _restoreBackupDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.unarchive_outlined),
            title: const Text('导入数据分享包 (.ocpkg)'),
            subtitle: const Text('解析并合并外部角色与世界观'),
            onTap: () => OcPackageImportDialog.show(context),
          ),

          const Divider(),

          // 关于
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于 OC Manager'),
            subtitle: const Text('版本 1.5.1'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeModeProvider.notifier).setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('跟随系统'),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: Text('浅色模式'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('深色模式'),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理缓存吗？这不会删除您的数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearCache(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      int fileCount = 0;
      int totalSize = 0;

      if (await tempDir.exists()) {
        final files = tempDir.listSync(recursive: true);
        for (final entity in files) {
          if (entity is File) {
            totalSize += await entity.length();
            await entity.delete();
            fileCount++;
          }
        }
      }

      if (context.mounted) {
        final sizeStr = totalSize > 1024 * 1024
            ? '${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB'
            : '${(totalSize / 1024).toStringAsFixed(1)} KB';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 $fileCount 个文件，释放 $sizeStr')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清理失败：$e')));
      }
    }
  }

  Future<void> _backupDatabaseSnapshot(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'oc_manager_db_$dateStr.db';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择数据库快照保存位置',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null) return;

      final backupService = ref.read(projectBackupServiceProvider);
      await backupService.exportDatabaseSnapshot(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据库快照导出成功 (SQLite 一致性快照)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出数据库快照失败：$e')));
      }
    }
  }

  Future<void> _backupFullProject(BuildContext context, WidgetRef ref) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'oc_manager_project_$dateStr.zip';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择完整项目包保存位置',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['zip', 'ocproject'],
      );

      if (result == null) return;

      final backupService = ref.read(projectBackupServiceProvider);
      await backupService.exportFullProjectBundle(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('完整项目备份包导出成功（含数据库与全部本地立绘）')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出完整项目包失败：$e')));
      }
    }
  }

  Future<void> _restoreBackupDialog(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'zip', 'ocproject'],
        dialogTitle: '选择备份文件 (.db 或 .zip)',
      );

      if (result == null || result.files.single.path == null) return;

      final pickedPath = result.files.single.path!;
      final backupService = ref.read(projectBackupServiceProvider);

      // Pre-inspection & integrity check
      final inspection = await backupService.inspectBackup(pickedPath);

      if (!context.mounted) return;

      final typeLabel = inspection.type == BackupType.databaseOnly
          ? '数据库快照 (.db)'
          : '完整项目包 (.zip)';
      final sizeStr = (inspection.fileSizeBytes / 1024 / 1024).toStringAsFixed(
        2,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认恢复数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '备份类型：$typeLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('文件大小：$sizeStr MB'),
              Text('包含世界观：${inspection.worldCount} 个'),
              Text('包含人物角色：${inspection.characterCount} 位'),
              if (inspection.type == BackupType.fullProject)
                Text('包含本地图片：${inspection.mediaCount} 张'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '警告：恢复将覆盖当前数据库与关联图片！恢复开始前系统将自动创建防灾还原点，若恢复失败将自动安全回滚。',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await _executeRestore(context, ref, backupService, pickedPath);
              },
              child: const Text('确认覆盖并恢复'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('校验备份文件失败：$e')));
      }
    }
  }

  Future<void> _executeRestore(
    BuildContext context,
    WidgetRef ref,
    ProjectBackupService backupService,
    String backupPath,
  ) async {
    try {
      final restoreResult = await backupService.restoreBackup(
        backupPath: backupPath,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('恢复成功'),
            content: Text(
              '数据已安全恢复！共恢复 ${restoreResult.restoredWorlds} 个世界观、${restoreResult.restoredCharacters} 位角色'
              '${restoreResult.type == BackupType.fullProject ? '、${restoreResult.restoredMediaFiles} 张本地立绘' : ''}。\n\n请重启应用以刷新全部缓存。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('恢复失败（已自动触发还原点回滚）：$e')));
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 OC Manager'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OC Manager 是一个角色管理工具，'),
            Text('用于管理原创角色（OC）的世界观、人物关系等信息。'),
            SizedBox(height: 16),
            Text('版本：1.5.0'),
            Text('技术栈：Flutter + Riverpod + drift'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _BasicInfoFieldsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(basicInfoFieldsProvider);

    return fieldsAsync.when(
      data: (fields) => Column(
        children: [
          for (final field in fields)
            _FieldTile(
              field: field,
              onToggle: (value) {
                ref
                    .read(basicInfoFieldActionsProvider)
                    .updateVisibility(field.id, value);
              },
              onDelete: () {
                _confirmDeleteField(context, ref, field);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加自定义字段'),
            onTap: () => _showAddFieldDialog(context, ref),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('错误: $error'),
    );
  }

  void _showAddFieldDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加字段'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '字段名称',
            hintText: '例如：种族、年龄',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(basicInfoFieldActionsProvider).addField(name);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteField(
    BuildContext context,
    WidgetRef ref,
    BasicInfoField field,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除字段'),
        content: Text('确定要删除"${field.fieldName}"字段吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(basicInfoFieldActionsProvider).deleteField(field.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final BasicInfoField field;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _FieldTile({
    required this.field,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(field.fieldName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: field.isVisible, onChanged: onToggle),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
