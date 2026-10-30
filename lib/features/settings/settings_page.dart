import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

import '../../providers/settings_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/database/app_database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
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

          // 缓存管理
          _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('清理缓存'),
            subtitle: const Text('清除临时文件和缓存数据'),
            onTap: () => _showClearCacheDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出数据库文件'),
            onTap: () => _backupDatabase(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件恢复'),
            onTap: () => _restoreDatabase(context, ref),
          ),

          const Divider(),

          // 关于
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于 OC Manager'),
            subtitle: const Text('版本 1.1.0'),
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
      BuildContext context, WidgetRef ref, ThemeMode current) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败：$e')),
        );
      }
    }
  }

  Future<void> _backupDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'oc_manager_backup_$dateStr.db';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择备份保存位置',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null) return;

      // 使用 SQLite 在线一致性备份 (VACUUM INTO)
      final db = ref.read(databaseProvider);
      await db.backupTo(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份成功，已生成一致性数据库快照')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败：$e')),
        );
      }
    }
  }

  void _restoreDatabase(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text(
          '恢复将覆盖当前所有数据，此操作不可撤销。\n\n建议先备份当前数据。确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _doRestore(context, ref);
            },
            child: const Text('选择备份文件', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _doRestore(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.single.path == null) return;

      final pickedFile = File(result.files.single.path!);
      if (!await pickedFile.exists() || await pickedFile.length() == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('选择的备份文件无效或为空')),
          );
        }
        return;
      }

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'oc_manager.db'));
      final walFile = File(p.join(dbFolder.path, 'oc_manager.db-wal'));
      final shmFile = File(p.join(dbFolder.path, 'oc_manager.db-shm'));
      final rollbackBakFile =
          File(p.join(dbFolder.path, 'oc_manager.db.rollback_bak'));

      // 创建还原点：在覆盖前备份当前主库
      if (await dbFile.exists()) {
        await dbFile.copy(rollbackBakFile.path);
      }

      try {
        // 关闭当前数据库连接
        await ref.read(databaseProvider).close();

        // 覆盖数据库文件
        await pickedFile.copy(dbFile.path);

        // 清理旧的 WAL / SHM 临时缓存，防止旧日志损坏新库
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        // 成功覆盖后移除临时还原点
        if (await rollbackBakFile.exists()) {
          await rollbackBakFile.delete();
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('恢复成功'),
              content: const Text('数据已安全恢复，请重启应用以生效。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      } catch (innerError) {
        // 恢复失败：自动从还原点回滚当前数据
        if (await rollbackBakFile.exists()) {
          await rollbackBakFile.copy(dbFile.path);
          await rollbackBakFile.delete();
        }
        rethrow;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
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
            Text('版本：1.1.0'),
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
      BuildContext context, WidgetRef ref, BasicInfoField field) {
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
          Switch(
            value: field.isVisible,
            onChanged: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
