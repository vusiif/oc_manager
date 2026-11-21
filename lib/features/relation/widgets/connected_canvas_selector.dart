import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../relation_canvas_dialogs.dart';
import '../relation_canvas_selector.dart';

/// Connected canvas selector dropdown that binds directly to RelationCanvasDialogs.
class ConnectedCanvasSelector extends ConsumerWidget {
  final int worldId;
  final List<GraphCanvas> canvases;
  final int? selectedCanvasId;
  final bool isDark;
  final Matrix4 transformMatrix;
  final Future<void> Function(GraphCanvas) onSelectCanvas;
  final VoidCallback onCanvasRenamed;

  const ConnectedCanvasSelector({
    super.key,
    required this.worldId,
    required this.canvases,
    required this.selectedCanvasId,
    required this.isDark,
    required this.transformMatrix,
    required this.onSelectCanvas,
    required this.onCanvasRenamed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RelationCanvasSelector(
      canvases: canvases,
      selectedCanvasId: selectedCanvasId,
      isDark: isDark,
      onSelectCanvas: onSelectCanvas,
      onNewCanvas: () => RelationCanvasDialogs.showNewCanvasDialog(
        context: context,
        ref: ref,
        worldId: worldId,
        onCanvasSwitched: onSelectCanvas,
      ),
      onDuplicateCanvas: (currentCanvas) =>
          RelationCanvasDialogs.showDuplicateCanvasDialog(
            context: context,
            ref: ref,
            currentCanvas: currentCanvas,
            transformMatrix: transformMatrix,
            onCanvasSwitched: onSelectCanvas,
          ),
      onRenameCanvas: (currentCanvas) =>
          RelationCanvasDialogs.showRenameCanvasDialog(
            context: context,
            ref: ref,
            currentCanvas: currentCanvas,
            onRenamed: onCanvasRenamed,
          ),
      onSetDefaultCanvas: (canvas) => RelationCanvasDialogs.setDefaultCanvas(
        context: context,
        ref: ref,
        worldId: worldId,
        canvas: canvas,
      ),
      onDeleteCanvas: (canvas, allCanvases) =>
          RelationCanvasDialogs.showDeleteCanvasDialog(
            context: context,
            ref: ref,
            canvas: canvas,
            allCanvases: allCanvases,
            onCanvasSwitched: onSelectCanvas,
          ),
    );
  }
}
