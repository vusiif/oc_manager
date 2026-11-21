import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../core/design/design_tokens.dart';
import 'package:flutter/services.dart';

import '../character/character_dialog.dart';
import 'graph_history_manager.dart';
import 'relation_advanced_analysis.dart';
import 'relation_graph_painters.dart';
import 'relation_graph_node.dart';
import 'widgets/graph_minimap.dart';

import 'relation_canvas_dialogs.dart';
import 'relation_canvas_selector.dart';
import 'relation_edit_dialogs.dart';
import 'relation_graph_exporter.dart';
import 'relation_sidebar.dart';
import 'relation_toolbar.dart';

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

  void _navigateToPosition(Offset targetWorldPos) {
    if (!mounted) return;
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final clampedScale = currentScale.clamp(0.1, 3.0);
    final tx = _currentViewport.width / 2 - targetWorldPos.dx * clampedScale;
    final ty = _currentViewport.height / 2 - targetWorldPos.dy * clampedScale;

    _transformController.value = Matrix4.identity()
      ..storage[0] = clampedScale
      ..storage[5] = clampedScale
      ..storage[12] = tx
      ..storage[13] = ty;
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
    _historyManager.dispose();
    _transformController.dispose();
    super.dispose();
  }

  bool _isEditingText() {
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    return focusedWidget is EditableText;
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
    if (_positions.isEmpty) {
      _transformController.value = Matrix4.identity();
      return;
    }

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pos in _positions.values) {
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    const padding = 140.0;
    final contentWidth = (maxX - minX) + padding * 2;
    final contentHeight = (maxY - minY) + padding * 2;
    final contentCenterX = (minX + maxX) / 2;
    final contentCenterY = (minY + maxY) / 2;

    final scaleX = viewportSize.width / max(contentWidth, 1.0);
    final scaleY = viewportSize.height / max(contentHeight, 1.0);
    final scale = min(scaleX, scaleY).clamp(0.2, 1.5);

    final tx = viewportSize.width / 2 - contentCenterX * scale;
    final ty = viewportSize.height / 2 - contentCenterY * scale;

    setState(() {
      _transformController.value = _matrixFromViewport(tx, ty, scale);
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

  Matrix4 _matrixFromViewport(double tx, double ty, double scale) {
    final s = scale > 0 ? scale : 1.0;
    return Matrix4.identity()
      ..storage[0] = s
      ..storage[5] = s
      ..storage[12] = tx
      ..storage[13] = ty;
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
    _transformController.value = _matrixFromViewport(
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
      _transformController.value = _matrixFromViewport(
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    _currentViewport = viewport;
                    final canvasSize = Size(
                      max(viewport.width, 2000),
                      max(viewport.height, 2000),
                    );

                    return Stack(
                      children: [
                        DragTarget<int>(
                          onAcceptWithDetails: (details) {
                            final renderBox =
                                context.findRenderObject() as RenderBox;
                            final localPos = renderBox.globalToLocal(
                              details.offset,
                            );
                            final charName =
                                characters
                                    .where((c) => c.id == details.data)
                                    .map((c) => c.name)
                                    .firstOrNull ??
                                '';
                            _dropCharacter(
                              details.data,
                              localPos,
                              characterName: charName,
                            );
                          },
                          builder: (context, candidateData, rejectedData) {
                            return InteractiveViewer(
                              transformationController: _transformController,
                              boundaryMargin: const EdgeInsets.all(500),
                              minScale: 0.1,
                              maxScale: 3.0,
                              onInteractionEnd: (_) =>
                                  _persistCurrentViewport(),
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapUp: (details) {
                                  _handleCanvasTap(
                                    details.localPosition,
                                    relations,
                                    characters,
                                  );
                                },
                                child: Container(
                                  width: canvasSize.width,
                                  height: canvasSize.height,
                                  color:
                                      theme.colorScheme.surfaceContainerLowest,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: GridPainter(
                                            color: theme
                                                .colorScheme
                                                .outlineVariant
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                      CustomPaint(
                                        size: canvasSize,
                                        painter: RelationPainter(
                                          relations: relations,
                                          positions: _positions,
                                          characters: characters,
                                          revision: _graphRevision,
                                          selectedRelationId:
                                              _selectedRelationId,
                                          isDark:
                                              theme.brightness ==
                                              Brightness.dark,
                                          filterState: _filterState,
                                        ),
                                      ),
                                      // 拖拽创建关系时的实时连线预览
                                      if (_connectingFromId != null &&
                                          _connectingCurrentPos != null &&
                                          _positions.containsKey(
                                            _connectingFromId,
                                          ))
                                        CustomPaint(
                                          size: canvasSize,
                                          painter: ConnectingLinePainter(
                                            from:
                                                _positions[_connectingFromId]!,
                                            to: _connectingCurrentPos!,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                      for (var character in characters)
                                        if (_positions.containsKey(
                                          character.id,
                                        ))
                                          DraggableNode(
                                            character: character,
                                            position: _positions[character.id]!,
                                            allCharacters: characters,
                                            relations: relations,
                                            isPathHighlighted:
                                                _filterState
                                                    .highlightedPath
                                                    ?.nodePath
                                                    .contains(character.id) ??
                                                false,
                                            isDimmed:
                                                _filterState.highlightedPath !=
                                                    null &&
                                                !(_filterState
                                                    .highlightedPath!
                                                    .nodePath
                                                    .contains(character.id)),
                                            onDragStart: (startPos) {
                                              _nodeDragStartPositions[character
                                                      .id] =
                                                  startPos;
                                            },
                                            onDragUpdate: (newPos) {
                                              setState(() {
                                                _positions[character.id] =
                                                    newPos;
                                                _graphRevision++;
                                              });
                                            },
                                            onDragEnd: (newPos) {
                                              final startPos =
                                                  _nodeDragStartPositions
                                                      .remove(character.id) ??
                                                  _positions[character.id];
                                              _savePosition(
                                                character.id,
                                                newPos,
                                              );
                                              if (startPos != null &&
                                                  ((startPos.dx - newPos.dx)
                                                              .abs() >
                                                          0.5 ||
                                                      (startPos.dy - newPos.dy)
                                                              .abs() >
                                                          0.5)) {
                                                final targetCanvasId =
                                                    _selectedCanvasId;
                                                _historyManager.record(
                                                  MoveNodeCommand(
                                                    characterId: character.id,
                                                    characterName:
                                                        character.name,
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
                                                          .read(
                                                            graphLayoutActionsProvider,
                                                          )
                                                          .savePosition(
                                                            widget.worldId,
                                                            id,
                                                            pos.dx,
                                                            pos.dy,
                                                            canvasId:
                                                                targetCanvasId,
                                                          );
                                                    },
                                                  ),
                                                );
                                              }
                                            },
                                            onConnectStart: (startPos) =>
                                                _onStartConnecting(
                                                  character.id,
                                                  startPos,
                                                ),
                                            onConnectUpdate:
                                                _onUpdateConnecting,
                                            onConnectEnd: () =>
                                                _onEndConnecting(characters),
                                            onRemove: () => _removeFromCanvas(
                                              character.id,
                                              characterName: character.name,
                                            ),
                                            onManageRelations: () =>
                                                _showRelationManager(
                                                  character,
                                                  characters,
                                                  relations,
                                                ),
                                            onEdit: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => CharacterDialog(
                                                  worldId: widget.worldId,
                                                  character: character,
                                                ),
                                              ).then((_) {
                                                ref.invalidate(
                                                  charactersByWorldProvider(
                                                    widget.worldId,
                                                  ),
                                                );
                                              });
                                            },
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '松开放置人物',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
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
                        if (_filterState.hasActiveFilter)
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
                                      _filterState.highlightedPath != null
                                          ? '最短路径: ${_filterState.highlightedPath!.hopCount} 步跃迁'
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
                                      onPressed: () {
                                        setState(() {
                                          _filterState =
                                              const RelationFilterState();
                                        });
                                        _persistCurrentFilterConfig();
                                      },
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
                            positions: _positions,
                            characters: characters,
                            relations: relations,
                            transformController: _transformController,
                            viewportSize: viewport,
                            isDark: theme.brightness == Brightness.dark,
                            onNavigate: _navigateToPosition,
                          ),
                        ),
                      ],
                    );
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (!_isEditingText() && _historyManager.canUndo) {
            _historyManager.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (!_isEditingText() && _historyManager.canUndo) {
            _historyManager.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (!_isEditingText() && _historyManager.canRedo) {
            _historyManager.redo();
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          if (!_isEditingText() && _historyManager.canRedo) {
            _historyManager.redo();
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () {
          if (!_isEditingText() && _historyManager.canRedo) {
            _historyManager.redo();
          }
        },
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}
