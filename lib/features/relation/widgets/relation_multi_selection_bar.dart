import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import 'relation_selection_helper.dart';

/// Floating action bar shown when one or more character nodes are selected.
/// Provides quick alignment, distribution, and batch removal actions.
class RelationMultiSelectionBar extends StatelessWidget {
  final int selectedCount;
  final ValueChanged<NodeAlignMode> onAlign;
  final VoidCallback onClearSelection;

  const RelationMultiSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onAlign,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
      color: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.94)
          : Colors.white.withValues(alpha: 0.96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '已选 $selectedCount 位角色',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
            if (selectedCount >= 2) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 20,
                child: VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              const SizedBox(width: 4),
              for (final mode in NodeAlignMode.values)
                if (selectedCount >= 3 ||
                    (mode != NodeAlignMode.distributeH &&
                        mode != NodeAlignMode.distributeV))
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: mode.label,
                    onPressed: () => onAlign(mode),
                    icon: Icon(mode.icon),
                  ),
            ],
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 1,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              tooltip: '取消选中 (Esc)',
              onPressed: onClearSelection,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating pill toggle between canvas pan mode and marquee box-select mode.
class RelationCanvasModeToggle extends StatelessWidget {
  final bool isBoxSelectMode;
  final ValueChanged<bool> onModeChanged;

  const RelationCanvasModeToggle({
    super.key,
    required this.isBoxSelectMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      color: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.94),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeBtn(
              icon: Icons.pan_tool_alt_outlined,
              label: '浏览',
              tooltip: '平移浏览画布 (按住 Shift+拖拽可临时框选)',
              selected: !isBoxSelectMode,
              onTap: () => onModeChanged(false),
            ),
            const SizedBox(width: 2),
            _modeBtn(
              icon: Icons.select_all,
              label: '框选',
              tooltip: '拖拽拉框批量选中角色',
              selected: isBoxSelectMode,
              onTap: () => onModeChanged(true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.brand : null),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.brand : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
