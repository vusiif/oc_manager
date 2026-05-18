import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../data/database/app_database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份功能开发中...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件恢复'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复功能开发中...')),
              );
            },
          ),

          const Divider(),

          // 关于
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于 OC Manager'),
            subtitle: const Text('版本 1.0.0'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清理')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
            Text('版本：1.0.0'),
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
