import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/util/graph_viewport_culling.dart';
import '../../../data/database/app_database.dart';
import '../relation_advanced_analysis.dart';
import '../relation_graph_node.dart';
import '../relation_graph_painters.dart';
import 'graph_minimap.dart';

/// Canvas view for relation graph rendering (nodes, edges, minimap, drag & drop, and filters).
class RelationCanvasView extends StatelessWidget {
  final TransformationController transformController;
  final List<Character> characters;
  final List<Relation> relations;
  final Map<int, Offset> positions;
  final int graphRevision;
  final int? selectedRelationId;
  final int? connectingFromId;
  final Offset? connectingCurrentPos;
  final RelationFilterState filterState;
  final Rect? visibleWorldRect;
  final double currentScale;
  final ValueChanged<Size> onViewportChanged;
  final void Function(int characterId, Offset localPos, String charName)
  onDropCharacter;
  final ValueChanged<Offset> onCanvasTap;
  final VoidCallback onPersistViewport;
  final void Function(int characterId, Offset startPos) onNodeDragStart;
  final void Function(int characterId, Offset newPos) onNodeDragUpdate;
  final void Function(int characterId, Offset newPos) onNodeDragEnd;
  final void Function(int characterId, Offset startPos) onConnectStart;
  final ValueChanged<Offset> onConnectUpdate;
  final VoidCallback onConnectEnd;
  final ValueChanged<Character> onRemoveCharacter;
  final ValueChanged<Character> onManageRelations;
  final ValueChanged<Character> onEditCharacter;
  final ValueChanged<Offset> onNavigateToPosition;
  final VoidCallback onClearFilter;

  const RelationCanvasView({
    super.key,
    required this.transformController,
    required this.characters,
    required this.relations,
    required this.positions,
    required this.graphRevision,
    this.selectedRelationId,
    this.connectingFromId,
    this.connectingCurrentPos,
    required this.filterState,
    this.visibleWorldRect,
    required this.currentScale,
    required this.onViewportChanged,
    required this.onDropCharacter,
    required this.onCanvasTap,
    required this.onPersistViewport,
    required this.onNodeDragStart,
    required this.onNodeDragUpdate,
    required this.onNodeDragEnd,
    required this.onConnectStart,
    required this.onConnectUpdate,
    required this.onConnectEnd,
    required this.onRemoveCharacter,
    required this.onManageRelations,
    required this.onEditCharacter,
    required this.onNavigateToPosition,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        onViewportChanged(viewport);

        final visibleRect =
            visibleWorldRect ??
            GraphViewportCulling.computeVisibleWorldRect(
              transform: transformController.value,
              viewportSize: viewport,
              bufferMargin: 160.0,
            );
        final currentLod = GraphViewportCulling.getLodLevel(currentScale);
        final canvasSize = Size(
          max(viewport.width, 2000),
          max(viewport.height, 2000),
        );

        return Stack(
          children: [
            DragTarget<int>(
              onAcceptWithDetails: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.offset);
                final charName =
                    characters
                        .where((c) => c.id == details.data)
                        .map((c) => c.name)
                        .firstOrNull ??
                    '';
                onDropCharacter(details.data, localPos, charName);
              },
              builder: (context, candidateData, rejectedData) {
                return InteractiveViewer(
                  transformationController: transformController,
                  boundaryMargin: const EdgeInsets.all(500),
                  minScale: 0.1,
                  maxScale: 3.0,
                  onInteractionEnd: (_) => onPersistViewport(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) => onCanvasTap(details.localPosition),
                    child: Container(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      color: theme.colorScheme.surfaceContainerLowest,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: canvasSize,
                            painter: RelationPainter(
                              relations: relations,
                              positions: positions,
                              characters: characters,
                              revision: graphRevision,
                              selectedRelationId: selectedRelationId,
                              isDark: isDark,
                              filterState: filterState,
                              visibleRect: visibleRect,
                              scale: currentScale,
                            ),
                          ),
                          // 拖拽创建关系时的实时连线预览
                          if (connectingFromId != null &&
                              connectingCurrentPos != null &&
                              positions.containsKey(connectingFromId))
                            CustomPaint(
                              size: canvasSize,
                              painter: ConnectingLinePainter(
                                from: positions[connectingFromId]!,
                                to: connectingCurrentPos!,
                                color: AppColors.brand,
                              ),
                            ),
                          for (var character in characters)
                            if (positions.containsKey(character.id) &&
                                GraphViewportCulling.isNodeVisible(
                                  positions[character.id]!,
                                  visibleRect,
                                  radius: 40.0,
                                ))
                              DraggableNode(
                                character: character,
                                position: positions[character.id]!,
                                lodLevel: currentLod,
                                allCharacters: characters,
                                relations: relations,
                                isPathHighlighted:
                                    filterState.highlightedPath?.nodePath
                                        .contains(character.id) ??
                                    false,
                                isDimmed:
                                    filterState.highlightedPath != null &&
                                    !(filterState.highlightedPath!.nodePath
                                        .contains(character.id)),
                                onDragStart: (startPos) =>
                                    onNodeDragStart(character.id, startPos),
                                onDragUpdate: (newPos) =>
                                    onNodeDragUpdate(character.id, newPos),
                                onDragEnd: (newPos) =>
                                    onNodeDragEnd(character.id, newPos),
                                onConnectStart: (startPos) =>
                                    onConnectStart(character.id, startPos),
                                onConnectUpdate: onConnectUpdate,
                                onConnectEnd: onConnectEnd,
                                onRemove: () => onRemoveCharacter(character),
                                onManageRelations: () =>
                                    onManageRelations(character),
                                onEdit: () => onEditCharacter(character),
                              ),
                          if (candidateData.isNotEmpty)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '松开放置人物',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (filterState.hasActiveFilter)
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alt_route,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          filterState.highlightedPath != null
                              ? '最短路径: ${filterState.highlightedPath!.hopCount} 步跃迁'
                              : '已应用过滤条件',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: '清除高亮',
                          onPressed: onClearFilter,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // GRAPH-005: 悬浮全局导览小地图
            Positioned(
              bottom: 16,
              right: 16,
              child: GraphMinimap(
                positions: positions,
                characters: characters,
                relations: relations,
                transformController: transformController,
                viewportSize: viewport,
                isDark: isDark,
                onNavigate: onNavigateToPosition,
              ),
            ),
          ],
        );
      },
    );
  }
}
