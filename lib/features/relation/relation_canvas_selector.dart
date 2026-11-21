import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../data/database/app_database.dart';

/// Top bar dropdown component for selecting and managing relation graph canvases.
class RelationCanvasSelector extends StatelessWidget {
  final List<GraphCanvas> canvases;
  final int? selectedCanvasId;
  final bool isDark;
  final ValueChanged<GraphCanvas> onSelectCanvas;
  final VoidCallback onNewCanvas;
  final ValueChanged<GraphCanvas> onDuplicateCanvas;
  final ValueChanged<GraphCanvas> onRenameCanvas;
  final ValueChanged<GraphCanvas> onSetDefaultCanvas;
  final void Function(GraphCanvas current, List<GraphCanvas> all)
  onDeleteCanvas;

  const RelationCanvasSelector({
    super.key,
    required this.canvases,
    required this.selectedCanvasId,
    required this.isDark,
    required this.onSelectCanvas,
    required this.onNewCanvas,
    required this.onDuplicateCanvas,
    required this.onRenameCanvas,
    required this.onSetDefaultCanvas,
    required this.onDeleteCanvas,
  });

  @override
  Widget build(BuildContext context) {
    if (canvases.isEmpty) {
      return const Text('关系图');
    }

    final currentCanvas = canvases.firstWhere(
      (c) => c.id == selectedCanvasId,
      orElse: () => canvases.first,
    );

    return PopupMenuButton<String>(
      tooltip: '切换或管理画布',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 16,
              color: AppColors.brand,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                currentCanvas.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (currentCanvas.isDefault) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.brand.withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.brand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              '当前世界观画布',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...canvases.map((c) {
            final isSelected = c.id == currentCanvas.id;
            return PopupMenuItem<String>(
              value: 'select_${c.id}',
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: isSelected ? AppColors.brand : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? AppColors.brand : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (c.isDefault)
                    const Text(
                      '默认',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'action_new',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.add_rounded, size: 20),
              title: Text('新建画布...'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'action_duplicate',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.copy_rounded, size: 18),
              title: Text('复制当前画布...'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'action_rename',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.drive_file_rename_outline_rounded, size: 18),
              title: Text('重命名画布...'),
            ),
          ),
          if (!currentCanvas.isDefault)
            const PopupMenuItem<String>(
              value: 'action_set_default',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.star_outline_rounded, size: 18),
                title: Text('设为默认画布'),
              ),
            ),
          if (canvases.length > 1)
            const PopupMenuItem<String>(
              value: 'action_delete',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                title: Text('删除此画布', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
        ];
      },
      onSelected: (val) {
        if (val.startsWith('select_')) {
          final id = int.tryParse(val.replaceFirst('select_', ''));
          if (id != null) {
            final target = canvases.firstWhere((c) => c.id == id);
            onSelectCanvas(target);
          }
        } else if (val == 'action_new') {
          onNewCanvas();
        } else if (val == 'action_duplicate') {
          onDuplicateCanvas(currentCanvas);
        } else if (val == 'action_rename') {
          onRenameCanvas(currentCanvas);
        } else if (val == 'action_set_default') {
          onSetDefaultCanvas(currentCanvas);
        } else if (val == 'action_delete') {
          onDeleteCanvas(currentCanvas, canvases);
        }
      },
    );
  }
}
