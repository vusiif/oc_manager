import 'package:flutter/material.dart';

import 'graph_history_manager.dart';
import 'relation_advanced_analysis.dart';

/// Top bar actions for the relation graph page: undo/redo, add relations, fit, pathfinding, layout, export, sidebar toggle.
class RelationGraphAppBarActions extends StatelessWidget {
  final GraphHistoryManager historyManager;
  final bool showSidebar;
  final bool hasLayoutSnapshot;
  final VoidCallback onAddRelation;
  final VoidCallback onAddFamilyRelation;
  final VoidCallback onFitCanvas;
  final VoidCallback onOpenPathFinder;
  final ValueChanged<AutoLayoutMode> onApplyAutoLayout;
  final VoidCallback onUndoAutoLayout;
  final VoidCallback onExportImage;
  final VoidCallback onExportSvg;
  final VoidCallback onResetView;
  final VoidCallback onToggleSidebar;

  const RelationGraphAppBarActions({
    super.key,
    required this.historyManager,
    required this.showSidebar,
    required this.hasLayoutSnapshot,
    required this.onAddRelation,
    required this.onAddFamilyRelation,
    required this.onFitCanvas,
    required this.onOpenPathFinder,
    required this.onApplyAutoLayout,
    required this.onUndoAutoLayout,
    required this.onExportImage,
    required this.onExportSvg,
    required this.onResetView,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: historyManager,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: historyManager.canUndo
                      ? '撤销: ${historyManager.undoDescription} (Ctrl+Z)'
                      : '撤销 (Ctrl+Z)',
                  onPressed: historyManager.canUndo
                      ? () => historyManager.undo()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: historyManager.canRedo
                      ? '重做: ${historyManager.redoDescription} (Ctrl+Y)'
                      : '重做 (Ctrl+Y)',
                  onPressed: historyManager.canRedo
                      ? () => historyManager.redo()
                      : null,
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.add_link),
          tooltip: '添加人物关系',
          onPressed: onAddRelation,
        ),
        IconButton(
          icon: const Icon(Icons.family_restroom),
          tooltip: '添加家谱关系',
          onPressed: onAddFamilyRelation,
        ),
        IconButton(
          icon: const Icon(Icons.crop_free),
          tooltip: '适应画布 / 查看全部',
          onPressed: onFitCanvas,
        ),
        IconButton(
          icon: const Icon(Icons.route_rounded),
          tooltip: '人脉寻径 (最短关系链路分析)',
          onPressed: onOpenPathFinder,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.auto_awesome_mosaic_rounded),
          tooltip: '智能排版算法与布局',
          onSelected: (modeStr) {
            if (modeStr == 'undo') {
              onUndoAutoLayout();
              return;
            }
            final mode = AutoLayoutMode.values.firstWhere(
              (m) => m.name == modeStr,
            );
            onApplyAutoLayout(mode);
          },
          itemBuilder: (context) => [
            for (final m in AutoLayoutMode.values)
              PopupMenuItem(
                value: m.name,
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(m.label),
                  ],
                ),
              ),
            if (hasLayoutSnapshot) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'undo',
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('撤销排版恢复', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.download_rounded),
          tooltip: '导出关系图谱',
          onSelected: (value) {
            if (value == 'png') {
              onExportImage();
            } else if (value == 'svg') {
              onExportSvg();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'png',
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('导出为高清图片 (PNG)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'svg',
              child: Row(
                children: [
                  Icon(Icons.polyline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('导出为矢量图谱 (SVG)'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.restore),
          tooltip: '重置视图',
          onPressed: onResetView,
        ),
        IconButton(
          icon: Icon(showSidebar ? Icons.chevron_left : Icons.chevron_right),
          tooltip: showSidebar ? '隐藏侧栏' : '显示侧栏',
          onPressed: onToggleSidebar,
        ),
      ],
    );
  }
}
