import 'package:flutter/material.dart';
import '../../core/design/design_tokens.dart';

/// Displays a categorized modal reference of all application keyboard shortcuts.
Future<void> showShortcutsHelpDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ShortcutsHelpDialog(),
  );
}

class _ShortcutEntry {
  final String keys;
  final String description;
  const _ShortcutEntry(this.keys, this.description);
}

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  static const _globalShortcuts = [
    _ShortcutEntry('Ctrl + K', '打开全局命令面板'),
    _ShortcutEntry('Ctrl + F', '跳转到全局搜索'),
    _ShortcutEntry('Ctrl + N', '新建人物 / 新建世界观'),
    _ShortcutEntry('Ctrl + G', '打开当前世界观关系图谱'),
    _ShortcutEntry('F1 / Ctrl + /', '打开快捷键帮助面板'),
  ];

  static const _graphShortcuts = [
    _ShortcutEntry('Ctrl + Z', '撤销上一步画布操作'),
    _ShortcutEntry('Ctrl + Y / Ctrl + Shift + Z', '重做已撤销操作'),
    _ShortcutEntry('Ctrl + A', '全选当前画布角色节点'),
    _ShortcutEntry('Shift + 拖拽空白处', '临时拉框批量选中节点'),
    _ShortcutEntry('Delete / Backspace', '删除当前选中的关系线'),
    _ShortcutEntry('Escape', '取消当前节点或关系选中'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Row(
        children: [
          const Icon(Icons.keyboard_rounded, color: AppColors.brand),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              '键盘快捷键指南',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGroup(context, '全局导航与创作', _globalShortcuts, isDark),
              const SizedBox(height: AppSpacing.md),
              _buildGroup(context, '关系图谱画布', _graphShortcuts, isDark),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String title,
    List<_ShortcutEntry> entries,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightSidebar,
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    entry.keys,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
