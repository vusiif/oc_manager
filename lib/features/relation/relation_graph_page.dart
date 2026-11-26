import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import 'graph_history_manager.dart';
import 'relation_advanced_analysis.dart';
import 'relation_sidebar.dart';
import 'relation_viewport_helper.dart';
import 'widgets/relation_canvas_state_helper.dart';
import 'widgets/relation_canvas_view.dart';
import 'widgets/relation_connection_helper.dart';
import 'widgets/relation_graph_app_bar.dart';
import 'widgets/relation_graph_commands.dart';
import 'widgets/relation_graph_shortcuts.dart';
import 'widgets/relation_selection_helper.dart';

class RelationGraphPage extends ConsumerStatefulWidget {
  final int worldId;

  const RelationGraphPage({super.key, required this.worldId});

  @override
  ConsumerState<RelationGraphPage> createState() => _RelationGraphPageState();
}

class _RelationGraphPageState extends ConsumerState<RelationGraphPage> {
  final Map<int, Offset> _positions = {};
  final TransformationController _transformController =
      TransformationController();
  final Set<int> _loadedFromDbCharacters = {};
  int _graphRevision = 0;
  bool _showSidebar = true;
  int? _selectedRelationId;

  // 节点手柄连线交互状态
  int? _connectingFromId;
  Offset? _connectingCurrentPos;

  // P2-04 智能排版与高级分析状态
  Map<int, Offset>? _layoutSnapshotBeforeAuto;
  RelationFilterState _filterState = const RelationFilterState();

  // GRAPH-001 多命名画布状态
  int? _selectedCanvasId;
  bool _hasEnsuredDefaultCanvas = false;

  // GRAPH-002 撤销/重做历史管理器
  final GraphHistoryManager _historyManager = GraphHistoryManager();
  final Map<int, Offset> _nodeDragStartPositions = {};
  final Set<int> _selectedNodeIds = {};
  final Map<int, Offset> _multiDragStartPositions = {};

  // GRAPH-005 大画布全局导览视口状态
  Size _currentViewport = const Size(1200, 800);

  // PERF-001 大图谱视口裁剪与 LOD 状态
  Rect? _visibleWorldRect;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    if (!mounted) return;
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final rect = GraphViewportCulling.computeVisibleWorldRect(
      transform: matrix,
      viewportSize: _currentViewport,
      bufferMargin: 160.0,
    );
    final scaleChanged = (_currentScale - scale).abs() > 0.03;
    final rectMoved =
        _visibleWorldRect == null ||
        (_visibleWorldRect!.center - rect.center).distance > 50.0;
    if (scaleChanged || rectMoved) {
      setState(() {
        _currentScale = scale;
        _visibleWorldRect = rect;
      });
    }
  }

  void _navigateToPosition(Offset targetWorldPos) {
    if (!mounted) return;
    _transformController.value = RelationViewportHelper.computeNavigateMatrix(
      targetWorldPos: targetWorldPos,
      viewportSize: _currentViewport,
      currentScale: _transformController.value.getMaxScaleOnAxis(),
    );
    _persistCurrentViewport();
  }

  @override
  void didUpdateWidget(RelationGraphPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldId != widget.worldId) {
      _historyManager.clear();
      _selectedCanvasId = null;
      _hasEnsuredDefaultCanvas = false;
      _positions.clear();
      _selectedNodeIds.clear();
      _loadedFromDbCharacters.clear();
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _historyManager.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _persistCurrentViewport() {
    RelationCanvasStateHelper.persistCanvasState(
      ref: ref,
      canvasId: _selectedCanvasId,
      transformController: _transformController,
      filterState: _filterState,
    );
  }

  void _applyAutoLayout(
    AutoLayoutMode mode,
    List<Character> characters,
    List<Relation> relations,
  ) {
    RelationGraphCommands.applyAutoLayout(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      canvasId: _selectedCanvasId,
      mode: mode,
      characters: characters,
      relations: relations,
      currentPositions: _positions,
      historyManager: _historyManager,
      targetCenter: RelationViewportHelper.computeViewportCenter(
        context: context,
        currentViewport: _currentViewport,
        transformMatrix: _transformController.value,
      ),
      onPositionsUpdated: (newPositions) {
        if (!mounted) return;
        setState(() {
          _positions
            ..clear()
            ..addAll(newPositions);
          _loadedFromDbCharacters.addAll(newPositions.keys);
          _graphRevision++;
        });
        _fitCanvasToNodes(_currentViewport);
      },
      onFitCanvas: () => _fitCanvasToNodes(_currentViewport),
    );
  }

  void _undoAutoLayout() {
    if (!_historyManager.canUndo) return;
    _historyManager.undo();
    _fitCanvasToNodes(_currentViewport);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已撤销自动排版')));
  }

  void _addCharacterMemory(int id, Offset pos) {
    if (!mounted) return;
    setState(() {
      _positions[id] = pos;
      _loadedFromDbCharacters.add(id);
      _graphRevision++;
    });
  }

  void _removeCharacterMemory(int id) {
    if (!mounted) return;
    setState(() {
      _positions.remove(id);
      _loadedFromDbCharacters.remove(id);
      _graphRevision++;
    });
  }

  /// 适应画布：将所有节点自动居中并自适应缩放到视野中
  void _fitCanvasToNodes([Size? customViewport]) {
    if (_positions.isEmpty) return;
    final vp = RelationViewportHelper.resolveViewportSize(
      context,
      _currentViewport,
      customViewport,
    );
    final newMatrix = RelationViewportHelper.computeFitCanvasMatrix(
      viewportSize: vp,
      positions: _positions,
    );
    setState(() => _transformController.value = newMatrix);
    _persistCurrentViewport();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _positions.isNotEmpty) {
        _transformController.value = newMatrix;
      }
    });
  }

  void _onStartConnecting(int characterId, Offset startPos) => setState(() {
    _connectingFromId = characterId;
    _connectingCurrentPos = startPos;
  });

  void _onUpdateConnecting(Offset scenePos) {
    if (_connectingFromId != null) {
      setState(() => _connectingCurrentPos = scenePos);
    }
  }

  void _onEndConnecting(List<Character> characters) {
    final sourceId = _connectingFromId;
    final currentPos = _connectingCurrentPos;
    setState(() {
      _connectingFromId = null;
      _connectingCurrentPos = null;
    });
    RelationConnectionHelper.completeConnection(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      sourceId: sourceId,
      currentPos: currentPos,
      positions: _positions,
      characters: characters,
      historyManager: _historyManager,
    );
  }

  void _applyPositionsBatch(Map<int, Offset> updated) {
    if (!mounted) return;
    setState(() {
      _positions.addAll(updated);
      _graphRevision++;
    });
  }

  void _handleCanvasTap(
    Offset tapPos,
    List<Relation> relations,
    List<Character> characters,
  ) {
    RelationConnectionHelper.handleRelationTap(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      tapPos: tapPos,
      relations: relations,
      characters: characters,
      positions: _positions,
      historyManager: _historyManager,
      currentSelectedRelationId: _selectedRelationId,
      onSelectedRelationChanged: (relId) => setState(() {
        _selectedRelationId = relId;
        if (relId != null || _selectedNodeIds.isNotEmpty) {
          _selectedNodeIds.clear();
        }
      }),
    );
  }

  Future<void> _switchToCanvas(GraphCanvas targetCanvas) async {
    if (_selectedCanvasId == targetCanvas.id) return;

    await RelationCanvasStateHelper.persistCanvasState(
      ref: ref,
      canvasId: _selectedCanvasId,
      transformController: _transformController,
      filterState: _filterState,
    );

    setState(() {
      _selectedCanvasId = targetCanvas.id;
      _positions.clear();
      _selectedNodeIds.clear();
      _selectedRelationId = null;
      _loadedFromDbCharacters.clear();
      _filterState = RelationCanvasStateHelper.restoreCanvasState(
        targetCanvas: targetCanvas,
        transformController: _transformController,
      );
      _historyManager.clear();
      _graphRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );
    final relationsAsync = ref.watch(relationsByWorldProvider(widget.worldId));
    final canvasesAsync = ref.watch(canvasesByWorldProvider(widget.worldId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvases = canvasesAsync.valueOrNull ?? [];
    RelationCanvasStateHelper.handleCanvasInitialization(
      ref: ref,
      worldId: widget.worldId,
      canvases: canvases,
      isLoading: canvasesAsync.isLoading,
      hasEnsuredDefault: _hasEnsuredDefaultCanvas,
      currentSelectedId: _selectedCanvasId,
      transformController: _transformController,
      onMarkEnsured: () => _hasEnsuredDefaultCanvas = true,
      onCanvasSelected: (id) {
        if (mounted) setState(() => _selectedCanvasId = id);
      },
      onFilterRestored: (filter) {
        if (mounted) setState(() => _filterState = filter);
      },
    );

    final layoutsAsync = _selectedCanvasId != null
        ? ref.watch(layoutsByCanvasProvider(_selectedCanvasId!))
        : ref.watch(graphLayoutsProvider(widget.worldId));

    final scaffold = Scaffold(
      appBar: RelationGraphAppBar(
        worldId: widget.worldId,
        canvases: canvases,
        selectedCanvasId: _selectedCanvasId,
        isDark: isDark,
        transformMatrix: _transformController.value,
        historyManager: _historyManager,
        showSidebar: _showSidebar,
        hasLayoutSnapshot: _layoutSnapshotBeforeAuto != null,
        characters: charactersAsync.valueOrNull ?? [],
        relations: relationsAsync.valueOrNull ?? [],
        positions: _positions,
        graphRevision: _graphRevision,
        onSelectCanvas: _switchToCanvas,
        onCanvasRenamed: () => setState(() => _graphRevision++),
        onFitCanvas: () => _fitCanvasToNodes(_currentViewport),
        onApplyAutoLayout: (mode) => _applyAutoLayout(
          mode,
          charactersAsync.valueOrNull ?? [],
          relationsAsync.valueOrNull ?? [],
        ),
        onUndoAutoLayout: _undoAutoLayout,
        onHighlightPath: (pathResult) {
          setState(() {
            _filterState = _filterState.copyWith(
              highlightedPath: () => pathResult,
            );
            _graphRevision++;
          });
          _persistCurrentViewport();
        },
        onResetView: () => _transformController.value = Matrix4.identity(),
        onToggleSidebar: () => setState(() => _showSidebar = !_showSidebar),
      ),
      body: charactersAsync.when(
        data: (characters) {
          if (characters.isEmpty) {
            return const Center(
              child: Text('暂无人物', style: TextStyle(color: Colors.grey)),
            );
          }

          if (layoutsAsync.isLoading && !layoutsAsync.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }

          final relations = relationsAsync.valueOrNull ?? [];
          final layouts = layoutsAsync.valueOrNull ?? [];

          final changed = RelationCanvasStateHelper.syncPositions(
            characters: characters,
            layouts: layouts,
            positions: _positions,
            loadedCharacters: _loadedFromDbCharacters,
          );
          if (changed) {
            _graphRevision++;
          }

          return Row(
            children: [
              RelationCharacterDrawer(
                showSidebar: _showSidebar,
                characters: characters,
                positions: _positions,
              ),
              Expanded(
                child: RelationCanvasView(
                  transformController: _transformController,
                  characters: characters,
                  relations: relations,
                  positions: _positions,
                  graphRevision: _graphRevision,
                  selectedRelationId: _selectedRelationId,
                  selectedNodeIds: _selectedNodeIds,
                  connectingFromId: _connectingFromId,
                  connectingCurrentPos: _connectingCurrentPos,
                  filterState: _filterState,
                  visibleWorldRect: _visibleWorldRect,
                  currentScale: _currentScale,
                  onViewportChanged: (vp) => _currentViewport = vp,
                  onDropCharacter: (charId, localPos, charName) =>
                      RelationGraphCommands.dropCharacter(
                        ref: ref,
                        worldId: widget.worldId,
                        canvasId: _selectedCanvasId,
                        characterId: charId,
                        characterName: charName,
                        screenDropPos: localPos,
                        transformMatrix: _transformController.value,
                        historyManager: _historyManager,
                        onAddMemory: _addCharacterMemory,
                        onRemoveMemory: _removeCharacterMemory,
                      ),
                  onCanvasTap: (localPos) =>
                      _handleCanvasTap(localPos, relations, characters),
                  onPersistViewport: _persistCurrentViewport,
                  onNodeDragStart: (charId, startPos) =>
                      RelationSelectionHelper.startNodeDrag(
                        charId: charId,
                        startPos: startPos,
                        selectedNodeIds: _selectedNodeIds,
                        positions: _positions,
                        singleStartPositions: _nodeDragStartPositions,
                        multiStartPositions: _multiDragStartPositions,
                      ),
                  onNodeDragUpdate: (charId, newPos) => setState(() {
                    RelationSelectionHelper.updateNodeDrag(
                      charId: charId,
                      newPos: newPos,
                      selectedNodeIds: _selectedNodeIds,
                      positions: _positions,
                      multiStartPositions: _multiDragStartPositions,
                    );
                    _graphRevision++;
                  }),
                  onNodeDragEnd: (charId, newPos) =>
                      RelationSelectionHelper.endNodeDrag(
                        ref: ref,
                        worldId: widget.worldId,
                        canvasId: _selectedCanvasId,
                        characterId: charId,
                        newPos: newPos,
                        characters: characters,
                        selectedNodeIds: _selectedNodeIds,
                        positions: _positions,
                        singleStartPositions: _nodeDragStartPositions,
                        multiStartPositions: _multiDragStartPositions,
                        historyManager: _historyManager,
                        onUpdateSingle: (id, pos) =>
                            _applyPositionsBatch({id: pos}),
                        onUpdateBatch: _applyPositionsBatch,
                      ),
                  onNodeTap: (charId, isAdditive) => setState(() {
                    _selectedRelationId = null;
                    RelationSelectionHelper.applyNodeTap(
                      _selectedNodeIds,
                      charId,
                      isAdditive,
                    );
                  }),
                  onBoxSelectNodes: (hitIds, isAdditive) => setState(() {
                    _selectedRelationId = null;
                    RelationSelectionHelper.applyBoxSelect(
                      _selectedNodeIds,
                      hitIds,
                      isAdditive,
                    );
                  }),
                  onAlignSelectedNodes: (mode) =>
                      RelationSelectionHelper.alignSelectedNodes(
                        ref: ref,
                        worldId: widget.worldId,
                        canvasId: _selectedCanvasId,
                        mode: mode,
                        selectedNodeIds: _selectedNodeIds,
                        positions: _positions,
                        historyManager: _historyManager,
                        onUpdateBatch: _applyPositionsBatch,
                      ),
                  onClearNodeSelection: () =>
                      setState(() => _selectedNodeIds.clear()),
                  onConnectStart: _onStartConnecting,
                  onConnectUpdate: _onUpdateConnecting,
                  onConnectEnd: () => _onEndConnecting(characters),
                  onRemoveCharacter: (char) {
                    final pos = _positions[char.id];
                    if (pos == null) return;
                    RelationGraphCommands.removeCharacter(
                      ref: ref,
                      worldId: widget.worldId,
                      canvasId: _selectedCanvasId,
                      characterId: char.id,
                      characterName: char.name,
                      currentPos: pos,
                      historyManager: _historyManager,
                      onAddMemory: _addCharacterMemory,
                      onRemoveMemory: _removeCharacterMemory,
                    );
                  },
                  onManageRelations: (char) =>
                      RelationGraphCommands.openRelationManager(
                        context: context,
                        ref: ref,
                        worldId: widget.worldId,
                        character: char,
                        allCharacters: characters,
                        relations: relations,
                        historyManager: _historyManager,
                      ),
                  onEditCharacter: (char) =>
                      RelationGraphCommands.openCharacterEditor(
                        context: context,
                        ref: ref,
                        worldId: widget.worldId,
                        character: char,
                      ),
                  onNavigateToPosition: _navigateToPosition,
                  onClearFilter: () {
                    setState(() => _filterState = const RelationFilterState());
                    _persistCurrentViewport();
                  },
                  onDeselectRelation: () =>
                      setState(() => _selectedRelationId = null),
                  onOpenFullRelationDialog: (rel) =>
                      RelationGraphCommands.openFullRelationDialog(
                        context: context,
                        ref: ref,
                        worldId: widget.worldId,
                        rel: rel,
                        characters: characters,
                        historyManager: _historyManager,
                        onDeleteRelation: _handleDeleteRelation,
                        onRelationDeleted: () =>
                            setState(() => _selectedRelationId = null),
                      ),
                  onUpdateRelation: (newRel, desc) =>
                      RelationGraphCommands.updateRelationById(
                        ref: ref,
                        worldId: widget.worldId,
                        relations: relations,
                        newRel: newRel,
                        desc: desc,
                        historyManager: _historyManager,
                      ),
                  onDeleteRelation: _handleDeleteRelation,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('错误: $error')),
      ),
    );

    return RelationGraphShortcuts(
      historyManager: _historyManager,
      onDeleteSelected: () {
        if (_selectedRelationId == null) return;
        final relations =
            ref.read(relationsByWorldProvider(widget.worldId)).valueOrNull ??
            [];
        final rel = relations
            .where((r) => r.id == _selectedRelationId)
            .firstOrNull;
        if (rel != null) _handleDeleteRelation(rel);
      },
      onEscape: () {
        if (_selectedRelationId != null || _selectedNodeIds.isNotEmpty) {
          setState(() {
            _selectedRelationId = null;
            _selectedNodeIds.clear();
          });
        }
      },
      onSelectAll: () => setState(() {
        _selectedRelationId = null;
        _selectedNodeIds
          ..clear()
          ..addAll(_positions.keys);
      }),
      child: scaffold,
    );
  }

  void _handleDeleteRelation(Relation rel) {
    RelationGraphCommands.deleteRelationWithFeedback(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      rel: rel,
      historyManager: _historyManager,
      onCleared: () => setState(() => _selectedRelationId = null),
    );
  }
}
