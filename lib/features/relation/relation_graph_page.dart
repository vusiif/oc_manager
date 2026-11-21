import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../character/character_dialog.dart';
import 'graph_history_manager.dart';
import 'relation_advanced_analysis.dart';
import 'relation_canvas_dialogs.dart';
import 'relation_canvas_selector.dart';
import 'relation_edit_dialogs.dart';
import 'relation_graph_exporter.dart';
import 'relation_graph_painters.dart';
import 'relation_sidebar.dart';
import 'relation_toolbar.dart';
import 'relation_viewport_helper.dart';
import 'widgets/relation_canvas_view.dart';
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
    if (_selectedCanvasId == null || !mounted) return;
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.getTranslation().x;
    final ty = matrix.getTranslation().y;
    ref
        .read(canvasActionsProvider)
        .saveViewport(_selectedCanvasId!, tx, ty, scale);
  }

  void _persistCurrentFilterConfig() {
    if (_selectedCanvasId == null || !mounted) return;
    ref
        .read(canvasActionsProvider)
        .saveFilterConfig(_selectedCanvasId!, _filterState.toJsonString());
  }

  void _applyAutoLayout(
    AutoLayoutMode mode,
    List<Character> characters,
    List<Relation> relations,
  ) {
    if (characters.isEmpty) return;

    // 1. 拍摄当前全量手工排版快照，用于撤销回滚
    final oldPositions = Map<int, Offset>.of(_positions);

    // 2. 计算算法排布坐标
    final newLayout = GraphAutoLayoutEngine.computeLayout(
      mode: mode,
      characters: characters,
      relations: relations,
    );

    setState(() {
      _positions.addAll(newLayout);
      for (final cid in newLayout.keys) {
        _loadedFromDbCharacters.add(cid);
      }
      _graphRevision++;
    });

    final targetCanvasId = _selectedCanvasId;

    // 3. 批量持久化到数据库
    ref
        .read(graphLayoutActionsProvider)
        .batchSavePositions(
          widget.worldId,
          newLayout,
          canvasId: targetCanvasId,
        );

    // 4. 记录到 Undo/Redo 历史栈 (GRAPH-002)
    _historyManager.record(
      BatchMoveCommand(
        descriptionText: '应用【${mode.label}】',
        oldPositions: oldPositions,
        newPositions: Map<int, Offset>.of(_positions),
        onUpdateMemory: (posMap) {
          if (!mounted) return;
          setState(() {
            _positions.clear();
            _positions.addAll(posMap);
            _graphRevision++;
          });
          final size = MediaQuery.of(context).size;
          _fitCanvasToNodes(size);
        },
        onPersist: (posMap) async {
          await ref
              .read(graphLayoutActionsProvider)
              .batchSavePositions(
                widget.worldId,
                posMap,
                canvasId: targetCanvasId,
              );
        },
      ),
    );

    // 5. 自适应居中展示
    final size = MediaQuery.of(context).size;
    _fitCanvasToNodes(size);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用【${mode.label}】'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '撤销排版',
          textColor: Colors.amberAccent,
          onPressed: _undoAutoLayout,
        ),
      ),
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

  void _syncPositions(List<Character> characters, List<GraphLayout> layouts) {
    if (layouts.isEmpty) return;
    final saved = {for (var l in layouts) l.characterId: Offset(l.x, l.y)};
    bool changed = false;
    for (final c in characters) {
      if (!_loadedFromDbCharacters.contains(c.id) && saved.containsKey(c.id)) {
        _positions[c.id] = saved[c.id]!;
        _loadedFromDbCharacters.add(c.id);
        changed = true;
      }
    }
    if (changed) {
      _graphRevision++;
    }
  }

  void _savePosition(int characterId, Offset pos) {
    ref
        .read(graphLayoutActionsProvider)
        .savePosition(
          widget.worldId,
          characterId,
          pos.dx,
          pos.dy,
          canvasId: _selectedCanvasId,
        );
  }

  void _dropCharacter(
    int characterId,
    Offset screenDropPos, {
    String characterName = '',
  }) {
    final inverse = Matrix4.inverted(_transformController.value);
    final canvasPos = MatrixUtils.transformPoint(inverse, screenDropPos);
    setState(() {
      _positions[characterId] = canvasPos;
      _loadedFromDbCharacters.add(characterId);
      _graphRevision++;
    });
    _savePosition(characterId, canvasPos);

    final targetCanvasId = _selectedCanvasId;
    _historyManager.record(
      AddNodeCommand(
        characterId: characterId,
        characterName: characterName.isEmpty
            ? 'ID:$characterId'
            : characterName,
        pos: canvasPos,
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
        onPersistAdd: (id, pos) async {
          await ref
              .read(graphLayoutActionsProvider)
              .savePosition(
                widget.worldId,
                id,
                pos.dx,
                pos.dy,
                canvasId: targetCanvasId,
              );
        },
        onPersistRemove: (id) async {
          await ref
              .read(graphLayoutActionsProvider)
              .removePosition(widget.worldId, id, canvasId: targetCanvasId);
        },
      ),
    );
  }

  void _removeFromCanvas(int characterId, {String characterName = ''}) {
    final currentPos = _positions[characterId];
    setState(() {
      _positions.remove(characterId);
      _loadedFromDbCharacters.remove(characterId);
      _graphRevision++;
    });
    final targetCanvasId = _selectedCanvasId;
    ref
        .read(graphLayoutActionsProvider)
        .removePosition(widget.worldId, characterId, canvasId: targetCanvasId);

    if (currentPos != null) {
      _historyManager.record(
        RemoveNodeCommand(
          characterId: characterId,
          characterName: characterName.isEmpty
              ? 'ID:$characterId'
              : characterName,
          pos: currentPos,
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
          onPersistAdd: (id, pos) async {
            await ref
                .read(graphLayoutActionsProvider)
                .savePosition(
                  widget.worldId,
                  id,
                  pos.dx,
                  pos.dy,
                  canvasId: targetCanvasId,
                );
          },
          onPersistRemove: (id) async {
            await ref
                .read(graphLayoutActionsProvider)
                .removePosition(widget.worldId, id, canvasId: targetCanvasId);
          },
        ),
      );
    }
  }

  void _recordUpdateRelation(Relation oldRel, Relation newRel, String desc) {
    _historyManager.record(
      UpdateRelationCommand(
        oldRelation: oldRel,
        newRelation: newRel,
        descriptionText: desc,
        onUpdate: (rel) async {
          await ref.read(relationActionsProvider).update(rel);
          ref.invalidate(relationsByWorldProvider(widget.worldId));
        },
      ),
    );
  }

  void _recordDeleteRelation(Relation rel, String desc) {
    _historyManager.record(
      DeleteRelationCommand(
        deletedRelation: rel,
        descriptionText: desc,
        onDelete: (id) async {
          await ref.read(relationActionsProvider).delete(id);
          ref.invalidate(relationsByWorldProvider(widget.worldId));
        },
        onRestore: (r) async {
          await ref.read(relationActionsProvider).restore(r);
          ref.invalidate(relationsByWorldProvider(widget.worldId));
        },
      ),
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
    if (_connectingFromId == null || _connectingCurrentPos == null) {
      setState(() {
        _connectingFromId = null;
        _connectingCurrentPos = null;
      });
      return;
    }

    int? targetId;
    for (final entry in _positions.entries) {
      if (entry.key != _connectingFromId) {
        if ((entry.value - _connectingCurrentPos!).distance <= 45.0) {
          targetId = entry.key;
          break;
        }
      }
    }

    final sourceId = _connectingFromId;
    setState(() {
      _connectingFromId = null;
      _connectingCurrentPos = null;
    });

    if (targetId != null && sourceId != null) {
      _showAddRelationDialog(characters, fromId: sourceId, toId: targetId);
    }
  }

  void _onNodeDragEnd(
    int characterId,
    Offset newPos,
    List<Character> characters,
  ) {
    final startPos =
        _nodeDragStartPositions.remove(characterId) ?? _positions[characterId];
    _savePosition(characterId, newPos);
    if (startPos != null &&
        ((startPos.dx - newPos.dx).abs() > 0.5 ||
            (startPos.dy - newPos.dy).abs() > 0.5)) {
      final targetCanvasId = _selectedCanvasId;
      final charName =
          characters
              .where((c) => c.id == characterId)
              .map((c) => c.name)
              .firstOrNull ??
          'ID:$characterId';
      _historyManager.record(
        MoveNodeCommand(
          characterId: characterId,
          characterName: charName,
          oldPos: startPos,
          newPos: newPos,
          onUpdateMemory: (id, pos) {
            if (!mounted) return;
            setState(() {
              _positions[id] = pos;
              _graphRevision++;
            });
          },
          onPersist: (id, pos) async {
            await ref
                .read(graphLayoutActionsProvider)
                .savePosition(
                  widget.worldId,
                  id,
                  pos.dx,
                  pos.dy,
                  canvasId: targetCanvasId,
                );
          },
        ),
      );
    }
  }

  // --- 添加关系对话框 ---

  void _showAddRelationDialog(
    List<Character> characters, {
    int? fromId,
    int? toId,
  }) {
    RelationEditDialogs.showAddRelationDialog(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      characters: characters,
      historyManager: _historyManager,
      fromId: fromId,
      toId: toId,
    );
  }

  // --- 管理人物关系对话框 ---

  void _showRelationManager(
    Character character,
    List<Character> allCharacters,
    List<Relation> relations,
  ) {
    RelationEditDialogs.showRelationManager(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      character: character,
      allCharacters: allCharacters,
      relations: relations,
      historyManager: _historyManager,
      onRecordDelete: _recordDeleteRelation,
    );
  }

  // --- 家谱关系对话框 ---

  void _showFamilyRelationDialog(List<Character> characters) {
    RelationEditDialogs.showFamilyRelationDialog(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      characters: characters,
      historyManager: _historyManager,
    );
  }

  void _handleCanvasTap(
    Offset tapPos,
    List<Relation> relations,
    List<Character> characters,
  ) {
    final labelCenters = calculateRelationLabelCenters(
      relations: relations,
      positions: _positions,
    );

    int? hitRelId;
    double minDistance = 28.0;

    for (final entry in labelCenters.entries) {
      final dist = (entry.value - tapPos).distance;
      if (dist <= minDistance) {
        minDistance = dist;
        hitRelId = entry.key;
      }
    }

    if (hitRelId != null) {
      final hitRel = relations.where((r) => r.id == hitRelId).firstOrNull;
      if (hitRel != null) {
        setState(() => _selectedRelationId = hitRelId);
        _showRelationActionDialog(hitRel, characters);
      }
    } else {
      if (_selectedRelationId != null) {
        setState(() => _selectedRelationId = null);
      }
    }
  }

  void _showRelationActionDialog(Relation rel, List<Character> characters) {
    RelationEditDialogs.showRelationActionDialog(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      rel: rel,
      characters: characters,
      onRecordUpdate: _recordUpdateRelation,
      onRecordDelete: _recordDeleteRelation,
      onRelationDeleted: () => setState(() => _selectedRelationId = null),
    );
  }

  Future<void> _exportToImage(
    List<Character> characters,
    List<Relation> relations,
  ) async {
    await RelationGraphExporter.exportToImage(
      context: context,
      characters: characters,
      relations: relations,
      positions: _positions,
      graphRevision: _graphRevision,
    );
  }

  Future<void> _exportToSvg(
    List<Character> characters,
    List<Relation> relations,
  ) async {
    await RelationGraphExporter.exportToSvg(
      context: context,
      characters: characters,
      relations: relations,
      positions: _positions,
    );
  }

  Future<void> _switchToCanvas(GraphCanvas targetCanvas) async {
    if (_selectedCanvasId == targetCanvas.id) return;

    // 1. Save current viewport and filter
    if (_selectedCanvasId != null) {
      final matrix = _transformController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final tx = matrix.getTranslation().x;
      final ty = matrix.getTranslation().y;
      await ref
          .read(canvasActionsProvider)
          .saveViewport(_selectedCanvasId!, tx, ty, scale);
      await ref
          .read(canvasActionsProvider)
          .saveFilterConfig(_selectedCanvasId!, _filterState.toJsonString());
    }

    // 2. Clear current in-memory positions & loaded flags
    setState(() {
      _selectedCanvasId = targetCanvas.id;
      _positions.clear();
      _loadedFromDbCharacters.clear();
    });

    // 3. Restore target viewport
    _transformController.value = RelationViewportHelper.matrixFromViewport(
      targetCanvas.viewportX,
      targetCanvas.viewportY,
      targetCanvas.zoomScale,
    );

    // 4. Restore target filter
    if (targetCanvas.filterConfig != null &&
        targetCanvas.filterConfig!.isNotEmpty) {
      setState(() {
        _filterState = RelationFilterState.fromJsonString(
          targetCanvas.filterConfig!,
        );
      });
    } else {
      setState(() {
        _filterState = const RelationFilterState();
      });
    }

    // 5. Clear undo/redo history to prevent cross-canvas contamination (GRAPH-002)
    _historyManager.clear();

    setState(() {
      _graphRevision++;
    });
  }

  Future<void> _showNewCanvasDialog() async {
    await RelationCanvasDialogs.showNewCanvasDialog(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      onCanvasSwitched: _switchToCanvas,
    );
  }

  Future<void> _showDuplicateCanvasDialog(GraphCanvas currentCanvas) async {
    await RelationCanvasDialogs.showDuplicateCanvasDialog(
      context: context,
      ref: ref,
      currentCanvas: currentCanvas,
      transformMatrix: _transformController.value,
      onCanvasSwitched: _switchToCanvas,
    );
  }

  Future<void> _showRenameCanvasDialog(GraphCanvas currentCanvas) async {
    await RelationCanvasDialogs.showRenameCanvasDialog(
      context: context,
      ref: ref,
      currentCanvas: currentCanvas,
      onRenamed: () => setState(() => _graphRevision++),
    );
  }

  Future<void> _setDefaultCanvas(GraphCanvas canvas) async {
    await RelationCanvasDialogs.setDefaultCanvas(
      context: context,
      ref: ref,
      worldId: widget.worldId,
      canvas: canvas,
    );
  }

  Future<void> _showDeleteCanvasDialog(
    GraphCanvas canvas,
    List<GraphCanvas> allCanvases,
  ) async {
    await RelationCanvasDialogs.showDeleteCanvasDialog(
      context: context,
      ref: ref,
      canvas: canvas,
      allCanvases: allCanvases,
      onCanvasSwitched: _switchToCanvas,
    );
  }

  Widget _buildCanvasSelector(List<GraphCanvas> canvases, bool isDark) {
    return RelationCanvasSelector(
      canvases: canvases,
      selectedCanvasId: _selectedCanvasId,
      isDark: isDark,
      onSelectCanvas: _switchToCanvas,
      onNewCanvas: _showNewCanvasDialog,
      onDuplicateCanvas: _showDuplicateCanvasDialog,
      onRenameCanvas: _showRenameCanvasDialog,
      onSetDefaultCanvas: _setDefaultCanvas,
      onDeleteCanvas: _showDeleteCanvasDialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );
    final relationsAsync = ref.watch(relationsByWorldProvider(widget.worldId));
    final canvasesAsync = ref.watch(canvasesByWorldProvider(widget.worldId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      _transformController.value = RelationViewportHelper.matrixFromViewport(
        defaultCanvas.viewportX,
        defaultCanvas.viewportY,
        defaultCanvas.zoomScale,
      );
      if (defaultCanvas.filterConfig != null &&
          defaultCanvas.filterConfig!.isNotEmpty) {
        _filterState = RelationFilterState.fromJsonString(
          defaultCanvas.filterConfig!,
        );
      }
    }

    final layoutsAsync = _selectedCanvasId != null
        ? ref.watch(layoutsByCanvasProvider(_selectedCanvasId!))
        : ref.watch(graphLayoutsProvider(widget.worldId));

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('关系图'),
            const SizedBox(width: 10),
            _buildCanvasSelector(canvases, isDark),
          ],
        ),
        actions: [
          RelationGraphAppBarActions(
            historyManager: _historyManager,
            showSidebar: _showSidebar,
            hasLayoutSnapshot: _layoutSnapshotBeforeAuto != null,
            onAddRelation: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showAddRelationDialog(chars);
            },
            onAddFamilyRelation: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showFamilyRelationDialog(chars);
            },
            onFitCanvas: () {
              final size = MediaQuery.of(context).size;
              _fitCanvasToNodes(size);
            },
            onOpenPathFinder: () {
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              showDialog(
                context: context,
                builder: (_) => RelationPathDialog(
                  characters: chars,
                  relations: rels,
                  onHighlightPath: (pathResult) {
                    setState(() {
                      _filterState = _filterState.copyWith(
                        highlightedPath: () => pathResult,
                      );
                      _graphRevision++;
                    });
                    _persistCurrentFilterConfig();
                  },
                ),
              );
            },
            onApplyAutoLayout: (mode) {
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              _applyAutoLayout(mode, chars, rels);
            },
            onUndoAutoLayout: _undoAutoLayout,
            onExportImage: () {
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              _exportToImage(chars, rels);
            },
            onExportSvg: () {
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              _exportToSvg(chars, rels);
            },
            onResetView: () => _transformController.value = Matrix4.identity(),
            onToggleSidebar: () => setState(() => _showSidebar = !_showSidebar),
          ),
        ],
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

          _syncPositions(characters, layouts);

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
                      _showRelationManager(char, characters, relations),
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
                    _persistCurrentFilterConfig();
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
