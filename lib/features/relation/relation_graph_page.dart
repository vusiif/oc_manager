import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../character/character_dialog.dart';
import 'graph_history_manager.dart';
import 'relation_advanced_analysis.dart';
import 'relation_edit_dialogs.dart';
import 'relation_sidebar.dart';
import 'relation_viewport_helper.dart';
import 'widgets/relation_canvas_state_helper.dart';
import 'widgets/relation_canvas_view.dart';
import 'widgets/relation_connection_helper.dart';
import 'widgets/relation_graph_app_bar.dart';
import 'widgets/relation_graph_commands.dart';
import 'widgets/relation_graph_shortcuts.dart';

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
      onPositionsUpdated: (newPositions) {
        if (!mounted) return;
        setState(() {
          _positions.clear();
          _positions.addAll(newPositions);
          for (final cid in newPositions.keys) {
            _loadedFromDbCharacters.add(cid);
          }
          _graphRevision++;
        });
        final size = MediaQuery.of(context).size;
        _fitCanvasToNodes(size);
      },
      onFitCanvas: () {
        final size = MediaQuery.of(context).size;
        _fitCanvasToNodes(size);
      },
    );
  }

  void _undoAutoLayout() {
    if (_historyManager.canUndo) {
      _historyManager.undo();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已撤销自动排版')));
    }
  }

  void _dropCharacter(
    int characterId,
    Offset screenDropPos, {
    String characterName = '',
  }) {
    RelationGraphCommands.dropCharacter(
      ref: ref,
      worldId: widget.worldId,
      canvasId: _selectedCanvasId,
      characterId: characterId,
      characterName: characterName,
      screenDropPos: screenDropPos,
      transformMatrix: _transformController.value,
      historyManager: _historyManager,
      onAddMemory: (id, pos) {
        if (!mounted) return;
        setState(() {
          _positions[id] = pos;
          _loadedFromDbCharacters.add(id);
          _graphRevision++;
        });
      },
      onRemoveMemory: (id) {
        if (!mounted) return;
        setState(() {
          _positions.remove(id);
          _loadedFromDbCharacters.remove(id);
          _graphRevision++;
        });
      },
    );
  }

  void _removeFromCanvas(int characterId, {String characterName = ''}) {
    final currentPos = _positions[characterId];
    if (currentPos == null) return;
    RelationGraphCommands.removeCharacter(
      ref: ref,
      worldId: widget.worldId,
      canvasId: _selectedCanvasId,
      characterId: characterId,
      characterName: characterName,
      currentPos: currentPos,
      historyManager: _historyManager,
      onAddMemory: (id, pos) {
        if (!mounted) return;
        setState(() {
          _positions[id] = pos;
          _loadedFromDbCharacters.add(id);
          _graphRevision++;
        });
      },
      onRemoveMemory: (id) {
        if (!mounted) return;
        setState(() {
          _positions.remove(id);
          _loadedFromDbCharacters.remove(id);
          _graphRevision++;
        });
      },
    );
  }

  /// 适应画布：将所有节点自动居中并自适应缩放到视野中
  void _fitCanvasToNodes(Size viewportSize) {
    setState(() {
      _transformController.value =
          RelationViewportHelper.computeFitCanvasMatrix(
            viewportSize: viewportSize,
            positions: _positions,
          );
    });
    _persistCurrentViewport();
  }

  void _onStartConnecting(int characterId, Offset startPos) {
    setState(() {
      _connectingFromId = characterId;
      _connectingCurrentPos = startPos;
    });
  }

  void _onUpdateConnecting(Offset delta) {
    if (_connectingCurrentPos == null) return;
    final scale = _transformController.value.getMaxScaleOnAxis();
    final sceneDelta = delta / (scale > 0 ? scale : 1.0);
    setState(() {
      _connectingCurrentPos = _connectingCurrentPos! + sceneDelta;
    });
  }

  void _onEndConnecting(List<Character> characters) {
    final targetId = RelationConnectionHelper.findConnectTarget(
      sourceId: _connectingFromId,
      currentPos: _connectingCurrentPos,
      positions: _positions,
    );

    final sourceId = _connectingFromId;
    setState(() {
      _connectingFromId = null;
      _connectingCurrentPos = null;
    });

    if (targetId != null && sourceId != null) {
      RelationEditDialogs.showAddRelationDialog(
        context: context,
        ref: ref,
        worldId: widget.worldId,
        characters: characters,
        historyManager: _historyManager,
        fromId: sourceId,
        toId: targetId,
      );
    }
  }

  void _onNodeDragEnd(
    int characterId,
    Offset newPos,
    List<Character> characters,
  ) {
    final startPos =
        _nodeDragStartPositions.remove(characterId) ?? _positions[characterId];
    if (startPos == null) return;

    final charName =
        characters
            .where((c) => c.id == characterId)
            .map((c) => c.name)
            .firstOrNull ??
        'ID:$characterId';

    RelationGraphCommands.recordNodeMove(
      ref: ref,
      worldId: widget.worldId,
      canvasId: _selectedCanvasId,
      characterId: characterId,
      characterName: charName,
      oldPos: startPos,
      newPos: newPos,
      historyManager: _historyManager,
      onUpdateMemory: (id, pos) {
        if (!mounted) return;
        setState(() {
          _positions[id] = pos;
          _graphRevision++;
        });
      },
    );
  }

  void _handleCanvasTap(
    Offset tapPos,
    List<Relation> relations,
    List<Character> characters,
  ) {
    final hitRelId = RelationConnectionHelper.hitTestRelation(
      tapPos: tapPos,
      relations: relations,
      positions: _positions,
    );

    if (hitRelId != null) {
      final hitRel = relations.where((r) => r.id == hitRelId).firstOrNull;
      if (hitRel != null) {
        setState(() => _selectedRelationId = hitRelId);
        RelationEditDialogs.showRelationActionDialog(
          context: context,
          ref: ref,
          worldId: widget.worldId,
          rel: hitRel,
          characters: characters,
          onRecordUpdate: (oldRel, newRel, desc) =>
              RelationGraphCommands.recordUpdateRelation(
                ref: ref,
                worldId: widget.worldId,
                oldRel: oldRel,
                newRel: newRel,
                desc: desc,
                historyManager: _historyManager,
              ),
          onRecordDelete: (rel, desc) =>
              RelationGraphCommands.recordDeleteRelation(
                ref: ref,
                worldId: widget.worldId,
                rel: rel,
                desc: desc,
                historyManager: _historyManager,
              ),
          onRelationDeleted: () => setState(() => _selectedRelationId = null),
        );
      }
    } else {
      if (_selectedRelationId != null) {
        setState(() => _selectedRelationId = null);
      }
    }
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
    if (canvases.isEmpty &&
        !canvasesAsync.isLoading &&
        !_hasEnsuredDefaultCanvas) {
      _hasEnsuredDefaultCanvas = true;
      Future.microtask(() async {
        if (mounted) {
          final def = await ref
              .read(canvasActionsProvider)
              .ensureDefault(widget.worldId);
          if (mounted && _selectedCanvasId == null) {
            setState(() {
              _selectedCanvasId = def.id;
            });
          }
        }
      });
    } else if (canvases.isNotEmpty && _selectedCanvasId == null) {
      final defaultCanvas = canvases.firstWhere(
        (c) => c.isDefault,
        orElse: () => canvases.first,
      );
      _selectedCanvasId = defaultCanvas.id;
      _filterState = RelationCanvasStateHelper.restoreCanvasState(
        targetCanvas: defaultCanvas,
        transformController: _transformController,
      );
    }

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
        onFitCanvas: () => _fitCanvasToNodes(MediaQuery.of(context).size),
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

          if (layoutsAsync.isLoading) {
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
                  connectingFromId: _connectingFromId,
                  connectingCurrentPos: _connectingCurrentPos,
                  filterState: _filterState,
                  visibleWorldRect: _visibleWorldRect,
                  currentScale: _currentScale,
                  onViewportChanged: (vp) => _currentViewport = vp,
                  onDropCharacter: (charId, localPos, charName) =>
                      _dropCharacter(charId, localPos, characterName: charName),
                  onCanvasTap: (localPos) =>
                      _handleCanvasTap(localPos, relations, characters),
                  onPersistViewport: _persistCurrentViewport,
                  onNodeDragStart: (charId, startPos) =>
                      _nodeDragStartPositions[charId] = startPos,
                  onNodeDragUpdate: (charId, newPos) {
                    setState(() {
                      _positions[charId] = newPos;
                      _graphRevision++;
                    });
                  },
                  onNodeDragEnd: (charId, newPos) =>
                      _onNodeDragEnd(charId, newPos, characters),
                  onConnectStart: _onStartConnecting,
                  onConnectUpdate: _onUpdateConnecting,
                  onConnectEnd: () => _onEndConnecting(characters),
                  onRemoveCharacter: (char) =>
                      _removeFromCanvas(char.id, characterName: char.name),
                  onManageRelations: (char) =>
                      RelationEditDialogs.showRelationManager(
                        context: context,
                        ref: ref,
                        worldId: widget.worldId,
                        character: char,
                        allCharacters: characters,
                        relations: relations,
                        historyManager: _historyManager,
                        onRecordDelete: (rel, desc) =>
                            RelationGraphCommands.recordDeleteRelation(
                              ref: ref,
                              worldId: widget.worldId,
                              rel: rel,
                              desc: desc,
                              historyManager: _historyManager,
                            ),
                      ),
                  onEditCharacter: (char) {
                    showDialog(
                      context: context,
                      builder: (_) => CharacterDialog(
                        worldId: widget.worldId,
                        character: char,
                      ),
                    ).then((_) {
                      ref.invalidate(charactersByWorldProvider(widget.worldId));
                    });
                  },
                  onNavigateToPosition: _navigateToPosition,
                  onClearFilter: () {
                    setState(() {
                      _filterState = const RelationFilterState();
                    });
                    _persistCurrentViewport();
                  },
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
      child: scaffold,
    );
  }
}
