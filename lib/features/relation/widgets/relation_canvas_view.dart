import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/util/graph_viewport_culling.dart';
import '../../../data/database/app_database.dart';
import '../relation_advanced_analysis.dart';
import '../relation_graph_node.dart';
import '../relation_graph_painters.dart';
import 'graph_minimap.dart';
import 'relation_connection_helper.dart';

/// Canvas view for relation graph rendering (nodes, edges, minimap, drag & drop, and filters).
class RelationCanvasView extends StatefulWidget {
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
  State<RelationCanvasView> createState() => _RelationCanvasViewState();
}

class _RelationCanvasViewState extends State<RelationCanvasView> {
  bool _isNodeInteracting = false;

  void _onNodeDragStart(int characterId, Offset startPos) {
    if (!_isNodeInteracting) {
      setState(() => _isNodeInteracting = true);
    }
    widget.onNodeDragStart(characterId, startPos);
  }

  void _onNodeDragEnd(int characterId, Offset newPos) {
    if (_isNodeInteracting) {
      setState(() => _isNodeInteracting = false);
    }
    widget.onNodeDragEnd(characterId, newPos);
  }

  void _onConnectStart(int characterId, Offset startPos) {
    if (!_isNodeInteracting) {
      setState(() => _isNodeInteracting = true);
    }
    widget.onConnectStart(characterId, startPos);
  }

  void _onConnectUpdate(Offset globalPos) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(globalPos);
    final inv = Matrix4.inverted(widget.transformController.value);
    final scenePos = MatrixUtils.transformPoint(inv, localPos);
    widget.onConnectUpdate(scenePos);
  }

  void _onConnectEnd() {
    if (_isNodeInteracting) {
      setState(() => _isNodeInteracting = false);
    }
    widget.onConnectEnd();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        widget.onViewportChanged(viewport);

        final visibleRect =
            widget.visibleWorldRect ??
            GraphViewportCulling.computeVisibleWorldRect(
              transform: widget.transformController.value,
              viewportSize: viewport,
              bufferMargin: 160.0,
            );
        final currentLod = GraphViewportCulling.getLodLevel(
          widget.currentScale,
        );
        final activeTargetId =
            (widget.connectingFromId != null &&
                widget.connectingCurrentPos != null)
            ? RelationConnectionHelper.findConnectTarget(
                sourceId: widget.connectingFromId,
                currentPos: widget.connectingCurrentPos,
                positions: widget.positions,
                hitRadius: 65.0,
              )
            : null;
        final connectTargetPos = activeTargetId != null
            ? widget.positions[activeTargetId]
            : null;

        double maxNodeX = 0, maxNodeY = 0;
        for (final pos in widget.positions.values) {
          if (pos.dx > maxNodeX) maxNodeX = pos.dx;
          if (pos.dy > maxNodeY) maxNodeY = pos.dy;
        }
        final canvasSize = Size(
          max(viewport.width, max(maxNodeX + 800, 3000)),
          max(viewport.height, max(maxNodeY + 800, 3000)),
        );

        return ClipRect(
          child: Stack(
            children: [
              // 1. 全屏统一画布底色 (Solid Infinite Canvas Background)
              Positioned.fill(
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerLowest,
                ),
              ),
              // 2. 全屏无限动态网格 (Infinite Dynamic Grid)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: widget.transformController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: viewport,
                      painter: InfiniteGridPainter(
                        transformMatrix: widget.transformController.value,
                        gridColor: theme.colorScheme.outlineVariant.withValues(
                          alpha: isDark ? 0.22 : 0.45,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 3. 关系图内容层与手势交互 (Infinite InteractiveViewer)
              Positioned.fill(
                child: DragTarget<int>(
                  onAcceptWithDetails: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(details.offset);
                    final charName =
                        widget.characters
                            .where((c) => c.id == details.data)
                            .map((c) => c.name)
                            .firstOrNull ??
                        '';
                    widget.onDropCharacter(details.data, localPos, charName);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return InteractiveViewer(
                      transformationController: widget.transformController,
                      constrained: false,
                      panEnabled: !_isNodeInteracting,
                      scaleEnabled: !_isNodeInteracting,
                      boundaryMargin: const EdgeInsets.all(5000.0),
                      clipBehavior: Clip.none,
                      minScale: 0.1,
                      maxScale: 3.0,
                      onInteractionEnd: (_) => widget.onPersistViewport(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) =>
                            widget.onCanvasTap(details.localPosition),
                        child: SizedBox(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                size: canvasSize,
                                painter: RelationPainter(
                                  relations: widget.relations,
                                  positions: widget.positions,
                                  characters: widget.characters,
                                  revision: widget.graphRevision,
                                  selectedRelationId: widget.selectedRelationId,
                                  isDark: isDark,
                                  filterState: widget.filterState,
                                  visibleRect: visibleRect,
                                  scale: widget.currentScale,
                                ),
                              ),
                              for (var character in widget.characters)
                                if (widget.positions.containsKey(
                                      character.id,
                                    ) &&
                                    GraphViewportCulling.isNodeVisible(
                                      widget.positions[character.id]!,
                                      visibleRect,
                                      radius: 40.0,
                                    ))
                                  DraggableNode(
                                    key: ValueKey(character.id),
                                    character: character,
                                    position: widget.positions[character.id]!,
                                    lodLevel: currentLod,
                                    allCharacters: widget.characters,
                                    relations: widget.relations,
                                    isPathHighlighted:
                                        widget
                                            .filterState
                                            .highlightedPath
                                            ?.nodePath
                                            .contains(character.id) ??
                                        false,
                                    isDimmed:
                                        widget.filterState.highlightedPath !=
                                            null &&
                                        !(widget
                                            .filterState
                                            .highlightedPath!
                                            .nodePath
                                            .contains(character.id)),
                                    isConnectTarget:
                                        character.id == activeTargetId,
                                    onDragStart: (startPos) => _onNodeDragStart(
                                      character.id,
                                      startPos,
                                    ),
                                    onDragUpdate: (newPos) => widget
                                        .onNodeDragUpdate(character.id, newPos),
                                    onDragEnd: (newPos) =>
                                        _onNodeDragEnd(character.id, newPos),
                                    onConnectStart: (startPos) =>
                                        _onConnectStart(character.id, startPos),
                                    onConnectUpdate: _onConnectUpdate,
                                    onConnectEnd: _onConnectEnd,
                                    onRemove: () =>
                                        widget.onRemoveCharacter(character),
                                    onManageRelations: () =>
                                        widget.onManageRelations(character),
                                    onEdit: () =>
                                        widget.onEditCharacter(character),
                                  ),
                              // 拖拽创建关系时的实时连线预览（置于最顶层，支持自动磁吸）
                              if (widget.connectingFromId != null &&
                                  widget.connectingCurrentPos != null &&
                                  widget.positions.containsKey(
                                    widget.connectingFromId,
                                  ))
                                CustomPaint(
                                  size: canvasSize,
                                  painter: ConnectingLinePainter(
                                    from: widget
                                        .positions[widget.connectingFromId]!,
                                    to:
                                        connectTargetPos ??
                                        widget.connectingCurrentPos!,
                                    color: AppColors.brand,
                                  ),
                                ),
                              if (candidateData.isNotEmpty)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
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
              ),
              if (widget.filterState.hasActiveFilter)
                Positioned(
                  top: 16,
                  right: 16,
                  child: RepaintBoundary(
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
                              widget.filterState.highlightedPath != null
                                  ? '最短路径: ${widget.filterState.highlightedPath!.hopCount} 步跃迁'
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
                              onPressed: widget.onClearFilter,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // GRAPH-005: 悬浮全局导览小地图
              Positioned(
                bottom: 16,
                right: 16,
                child: RepaintBoundary(
                  child: GraphMinimap(
                    positions: widget.positions,
                    characters: widget.characters,
                    relations: widget.relations,
                    transformController: widget.transformController,
                    viewportSize: viewport,
                    isDark: isDark,
                    onNavigate: widget.onNavigateToPosition,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
