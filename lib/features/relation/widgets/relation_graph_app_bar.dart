import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../graph_history_manager.dart';
import '../relation_advanced_analysis.dart';
import '../relation_edit_dialogs.dart';
import '../relation_graph_exporter.dart';
import '../relation_toolbar.dart';
import 'connected_canvas_selector.dart';

/// App bar for RelationGraphPage displaying canvas selector and toolbar action buttons.
class RelationGraphAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  final int worldId;
  final List<GraphCanvas> canvases;
  final int? selectedCanvasId;
  final bool isDark;
  final Matrix4 transformMatrix;
  final GraphHistoryManager historyManager;
  final bool showSidebar;
  final bool hasLayoutSnapshot;
  final List<Character> characters;
  final List<Relation> relations;
  final Map<int, Offset> positions;
  final int graphRevision;
  final Future<void> Function(GraphCanvas) onSelectCanvas;
  final VoidCallback onCanvasRenamed;
  final VoidCallback onFitCanvas;
  final ValueChanged<AutoLayoutMode> onApplyAutoLayout;
  final VoidCallback onUndoAutoLayout;
  final ValueChanged<ShortestPathResult> onHighlightPath;
  final VoidCallback onResetView;
  final VoidCallback onToggleSidebar;

  const RelationGraphAppBar({
    super.key,
    required this.worldId,
    required this.canvases,
    required this.selectedCanvasId,
    required this.isDark,
    required this.transformMatrix,
    required this.historyManager,
    required this.showSidebar,
    required this.hasLayoutSnapshot,
    required this.characters,
    required this.relations,
    required this.positions,
    required this.graphRevision,
    required this.onSelectCanvas,
    required this.onCanvasRenamed,
    required this.onFitCanvas,
    required this.onApplyAutoLayout,
    required this.onUndoAutoLayout,
    required this.onHighlightPath,
    required this.onResetView,
    required this.onToggleSidebar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('关系图'),
          const SizedBox(width: 10),
          ConnectedCanvasSelector(
            worldId: worldId,
            canvases: canvases,
            selectedCanvasId: selectedCanvasId,
            isDark: isDark,
            transformMatrix: transformMatrix,
            onSelectCanvas: onSelectCanvas,
            onCanvasRenamed: onCanvasRenamed,
          ),
        ],
      ),
      actions: [
        RelationGraphAppBarActions(
          historyManager: historyManager,
          showSidebar: showSidebar,
          hasLayoutSnapshot: hasLayoutSnapshot,
          onAddRelation: () => RelationEditDialogs.showAddRelationDialog(
            context: context,
            ref: ref,
            worldId: worldId,
            characters: characters,
            historyManager: historyManager,
          ),
          onAddFamilyRelation: () =>
              RelationEditDialogs.showFamilyRelationDialog(
                context: context,
                ref: ref,
                worldId: worldId,
                characters: characters,
                historyManager: historyManager,
              ),
          onFitCanvas: onFitCanvas,
          onOpenPathFinder: () {
            showDialog(
              context: context,
              builder: (_) => RelationPathDialog(
                characters: characters,
                relations: relations,
                onHighlightPath: onHighlightPath,
              ),
            );
          },
          onApplyAutoLayout: onApplyAutoLayout,
          onUndoAutoLayout: onUndoAutoLayout,
          onExportImage: () => RelationGraphExporter.exportToImage(
            context: context,
            characters: characters,
            relations: relations,
            positions: positions,
            graphRevision: graphRevision,
          ),
          onExportSvg: () => RelationGraphExporter.exportToSvg(
            context: context,
            characters: characters,
            relations: relations,
            positions: positions,
          ),
          onResetView: onResetView,
          onToggleSidebar: onToggleSidebar,
        ),
      ],
    );
  }
}
