import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../core/design/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design/components/confirmation_dialog.dart';
import 'package:flutter/services.dart';

import '../character/character_dialog.dart';
import 'graph_history_manager.dart';
import 'graph_svg_exporter.dart';
import 'relation_advanced_analysis.dart';
import 'relation_graph_painters.dart';
import 'relation_graph_node.dart';
import 'widgets/graph_minimap.dart';

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
    if (characters.length < 2) return;

    int? selectedFrom = fromId ?? characters[0].id;
    int? selectedTo =
        toId ??
        characters
            .firstWhere(
              (c) => c.id != selectedFrom,
              orElse: () => characters[0],
            )
            .id;
    String selectedType = '朋友';
    bool isCustomType = false;
    bool isBidirectional = true;
    final customTypeController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加关系'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedFrom,
                  decoration: const InputDecoration(labelText: '起始人物'),
                  items: characters
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedFrom = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTo,
                  decoration: const InputDecoration(labelText: '目标人物'),
                  items: characters
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedTo = v),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '关系类型',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in _relationTypes)
                      ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: !isCustomType && selectedType == t,
                        onSelected: (_) => setState(() {
                          selectedType = t;
                          isCustomType = false;
                        }),
                      ),
                    ChoiceChip(
                      label: const Text('自定义…', style: TextStyle(fontSize: 12)),
                      selected: isCustomType,
                      onSelected: (_) => setState(() => isCustomType = true),
                    ),
                  ],
                ),
                if (isCustomType) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customTypeController,
                    decoration: const InputDecoration(
                      labelText: '自定义关系类型',
                      hintText: '例如：宿敌、同事、师徒…',
                    ),
                    onChanged: (v) => selectedType = v.trim(),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('双向关系'),
                  value: isBidirectional,
                  onChanged: (v) => setState(() => isBidirectional = v),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final type = isCustomType
                    ? customTypeController.text.trim()
                    : selectedType;
                if (selectedFrom != null &&
                    selectedTo != null &&
                    selectedFrom != selectedTo &&
                    type.isNotEmpty) {
                  final note = noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim();
                  final id = await ref
                      .read(relationActionsProvider)
                      .create(
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: note,
                      );
                  ref.invalidate(relationsByWorldProvider(widget.worldId));

                  final fromCharName =
                      characters
                          .where((c) => c.id == selectedFrom)
                          .map((c) => c.name)
                          .firstOrNull ??
                      '?';
                  final toCharName =
                      characters
                          .where((c) => c.id == selectedTo)
                          .map((c) => c.name)
                          .firstOrNull ??
                      '?';

                  _historyManager.record(
                    CreateRelationCommand(
                      relation: Relation(
                        id: id,
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: note,
                        relationGroupId: null,
                      ),
                      descriptionText: '$fromCharName 与 $toCharName 的【$type】',
                      onDelete: (relId) async {
                        await ref.read(relationActionsProvider).delete(relId);
                        ref.invalidate(
                          relationsByWorldProvider(widget.worldId),
                        );
                      },
                      onRestore: (rel) async {
                        await ref.read(relationActionsProvider).restore(rel);
                        ref.invalidate(
                          relationsByWorldProvider(widget.worldId),
                        );
                      },
                    ),
                  );

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      customTypeController.dispose();
      noteController.dispose();
    });
  }

  // --- 管理人物关系对话框 ---

  void _showRelationManager(
    Character character,
    List<Character> allCharacters,
    List<Relation> relations,
  ) {
    String nameOf(int id) =>
        allCharacters.where((c) => c.id == id).map((c) => c.name).firstOrNull ??
        '?';

    showDialog(
      context: context,
      builder: (context) {
        List<Relation> localRelations = List.of(relations);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final myRelations = localRelations
                .where(
                  (r) =>
                      r.fromCharacterId == character.id ||
                      r.toCharacterId == character.id,
                )
                .toList();

            return AlertDialog(
              title: Text('${character.name} 的关系'),
              content: SizedBox(
                width: 360,
                child: myRelations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            '暂无关系',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: myRelations.length,
                        itemBuilder: (context, index) {
                          final rel = myRelations[index];
                          final otherName = rel.fromCharacterId == character.id
                              ? nameOf(rel.toCharacterId)
                              : nameOf(rel.fromCharacterId);
                          final arrow = rel.isBidirectional ? ' ↔ ' : ' → ';
                          final direction = rel.fromCharacterId == character.id
                              ? ''
                              : '(反向)';
                          final groupTag = rel.relationGroupId != null
                              ? ' [组]'
                              : '';

                          return ListTile(
                            dense: true,
                            title: Text(
                              '$otherName$arrow${rel.relationType}$direction$groupTag',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: rel.note != null && rel.note!.isNotEmpty
                                ? Text(
                                    rel.note!,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(relationActionsProvider)
                                    .delete(rel.id);
                                setDialogState(() {
                                  localRelations.removeWhere(
                                    (r) => r.id == rel.id,
                                  );
                                });
                                ref.invalidate(
                                  relationsByWorldProvider(widget.worldId),
                                );
                                _recordDeleteRelation(
                                  rel,
                                  '${nameOf(rel.fromCharacterId)} 与 ${nameOf(rel.toCharacterId)} 的【${rel.relationType}】',
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加关系'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddRelationDialog(allCharacters, fromId: character.id);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 家谱关系对话框 ---

  void _showFamilyRelationDialog(List<Character> characters) {
    if (characters.length < 3) return;

    List<int> parentIds = [];
    List<int> childIds = [];
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('添加家谱关系'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('父母（可多选）', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: parentIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              parentIds.add(c.id);
                              childIds.remove(c.id);
                            } else {
                              parentIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('子女（可多选）', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: childIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              childIds.add(c.id);
                              parentIds.remove(c.id);
                            } else {
                              childIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: '备注（可选）'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (parentIds.length < 2 || childIds.isEmpty) return;
                  final created = await ref
                      .read(relationActionsProvider)
                      .createFamilyRelation(
                        parentIds: parentIds,
                        childIds: childIds,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(relationsByWorldProvider(widget.worldId));

                  _historyManager.record(
                    BatchCreateRelationsCommand(
                      relations: created,
                      descriptionText: '添加家谱亲子关系',
                      onDelete: (relId) async {
                        await ref.read(relationActionsProvider).delete(relId);
                        ref.invalidate(
                          relationsByWorldProvider(widget.worldId),
                        );
                      },
                      onRestore: (rel) async {
                        await ref.read(relationActionsProvider).restore(rel);
                        ref.invalidate(
                          relationsByWorldProvider(widget.worldId),
                        );
                      },
                    ),
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
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
    final charMap = {for (final c in characters) c.id: c};
    final fromChar = charMap[rel.fromCharacterId];
    final toChar = charMap[rel.toCharacterId];
    final fromName = fromChar?.name ?? '未知人物';
    final toName = toChar?.name ?? '未知人物';

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.hub_outlined, size: 20),
              SizedBox(width: 8),
              Text('人物关系', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fromName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      rel.isBidirectional
                          ? Icons.compare_arrows
                          : Icons.arrow_forward,
                      size: 20,
                      color: rel.isBidirectional ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      toName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    '类型: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Chip(
                    label: Text(
                      rel.relationType,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    rel.isBidirectional ? '双向互通' : '单向指向',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (rel.note != null && rel.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '备注: ${rel.note}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // 切换双向/单向
            TextButton.icon(
              icon: Icon(
                rel.isBidirectional ? Icons.arrow_forward : Icons.sync_alt,
                size: 16,
              ),
              label: Text(rel.isBidirectional ? '设为单向' : '设为双向'),
              onPressed: () async {
                Navigator.pop(ctx);
                final oldRel = rel;
                final newRel = rel.copyWith(
                  isBidirectional: !rel.isBidirectional,
                );
                await ref.read(relationActionsProvider).update(newRel);
                ref.invalidate(relationsByWorldProvider(widget.worldId));
                _recordUpdateRelation(
                  oldRel,
                  newRel,
                  '$fromName 与 $toName 关系方向模式',
                );
              },
            ),
            // 反转方向 (仅单向有效)
            if (!rel.isBidirectional)
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('反转'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final oldRel = rel;
                  final newRel = rel.copyWith(
                    fromCharacterId: rel.toCharacterId,
                    toCharacterId: rel.fromCharacterId,
                  );
                  await ref.read(relationActionsProvider).update(newRel);
                  ref.invalidate(relationsByWorldProvider(widget.worldId));
                  _recordUpdateRelation(
                    oldRel,
                    newRel,
                    '$fromName 与 $toName 关系方向反转',
                  );
                },
              ),
            // 编辑类型与备注
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('编辑'),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditRelationDialog(rel, fromName, toName);
              },
            ),
            // 删除关系
            TextButton.icon(
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
              label: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: '删除关系',
                  content:
                      '确定要删除【$fromName】与【$toName】之间的“${rel.relationType}”关系吗？',
                  confirmLabel: '删除',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  await ref.read(relationActionsProvider).delete(rel.id);
                  ref.invalidate(relationsByWorldProvider(widget.worldId));
                  setState(() => _selectedRelationId = null);
                  _recordDeleteRelation(
                    rel,
                    '$fromName 与 $toName 的【${rel.relationType}】',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditRelationDialog(Relation rel, String fromName, String toName) {
    String currentType = rel.relationType;
    final noteController = TextEditingController(text: rel.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑关系: $fromName ⇄ $toName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '关系类型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in _relationTypes)
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: currentType == t,
                      onSelected: (_) => setDialogState(() => currentType = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = noteController.text.trim();
                final oldRel = rel;
                final newRel = rel.copyWith(
                  relationType: currentType,
                  note: Value(note.isEmpty ? null : note),
                );
                await ref.read(relationActionsProvider).update(newRel);
                ref.invalidate(relationsByWorldProvider(widget.worldId));
                _recordUpdateRelation(oldRel, newRel, '$fromName 与 $toName 关系');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToImage(
    List<Character> characters,
    List<Relation> relations,
  ) async {
    if (_positions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画布上暂无人物，无法导出')));
      return;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final pos in _positions.values) {
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx);
      maxY = max(maxY, pos.dy);
    }

    const margin = 120.0;
    final exportRect = Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    );

    final width = exportRect.width;
    final height = exportRect.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    canvas.translate(-exportRect.left, -exportRect.top);

    final relPainter = RelationPainter(
      relations: relations,
      positions: _positions,
      characters: characters,
      revision: _graphRevision,
      isDark: isDark,
    );
    relPainter.paint(canvas, Size(maxX + margin, maxY + margin));

    for (final c in characters) {
      if (!_positions.containsKey(c.id)) continue;
      final pos = _positions[c.id]!;
      final color = c.status == 1 ? Colors.grey : AppColors.brand;
      _drawNodeOnCanvas(canvas, c, pos, color, isDark);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'relation_graph_$dateStr.png';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出图片保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (result == null) return;

    var savePath = result;
    if (!savePath.toLowerCase().endsWith('.png')) {
      savePath += '.png';
    }

    await File(savePath).writeAsBytes(pngBytes);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('关系图已成功导出至: $savePath')));
    }
  }

  Future<void> _exportToSvg(
    List<Character> characters,
    List<Relation> relations,
  ) async {
    if (_positions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画布上暂无人物，无法导出')));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgString = GraphSvgExporter.exportToSvg(
      characters: characters,
      relations: relations,
      positions: _positions,
      isDark: isDark,
    );

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'relation_graph_$dateStr.svg';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出矢量图保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );

    if (result == null) return;

    var savePath = result;
    if (!savePath.toLowerCase().endsWith('.svg')) {
      savePath += '.svg';
    }

    await File(savePath).writeAsString(svgString);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('矢量关系图已成功导出至: $savePath')));
    }
  }

  void _drawNodeOnCanvas(
    Canvas canvas,
    Character c,
    Offset pos,
    Color color,
    bool isDark,
  ) {
    final shapePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const half = 24.0;
    final initial = c.name.isNotEmpty ? c.name[0] : '?';

    if (c.gender == '男') {
      final rect = Rect.fromCenter(
        center: pos,
        width: half * 2,
        height: half * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        shapePaint,
      );
    } else if (c.gender == '女') {
      canvas.drawCircle(pos, half, shapePaint);
    } else {
      final path = Path()
        ..moveTo(pos.dx, pos.dy - half * 1.13)
        ..lineTo(pos.dx + half * 1.13, pos.dy)
        ..lineTo(pos.dx, pos.dy + half * 1.13)
        ..lineTo(pos.dx - half * 1.13, pos.dy)
        ..close();
      canvas.drawPath(path, shapePaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: AppFonts.textStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    final nameTp = TextPainter(
      text: TextSpan(
        text: c.name,
        style: AppFonts.textStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    nameTp.paint(canvas, Offset(pos.dx - nameTp.width / 2, pos.dy + half + 4));
  }

  static Widget? _genderIcon(String gender) {
    if (gender == '男') return const Text('♂', style: TextStyle(fontSize: 14));
    if (gender == '女') return const Text('♀', style: TextStyle(fontSize: 14));
    if (gender.isNotEmpty) {
      return const Text('⚥', style: TextStyle(fontSize: 14));
    }
    return null;
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
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建命名画布'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '画布名称',
                hintText: '如：主角团羁绊、主要势力派系、家族谱系...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '画布描述 (可选)',
                hintText: '简要说明该画布的用途与视角',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    final desc = descController.text.trim().isEmpty
        ? null
        : descController.text.trim();
    controller.dispose();
    descController.dispose();

    if (result == true && name.isNotEmpty && mounted) {
      final newCanvas = await ref
          .read(canvasActionsProvider)
          .create(widget.worldId, name, description: desc);
      if (mounted) {
        await _switchToCanvas(newCanvas);
        messenger.showSnackBar(SnackBar(content: Text('已创建并切换至画布【$name】')));
      }
    }
  }

  Future<void> _showDuplicateCanvasDialog(GraphCanvas currentCanvas) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(
      text: '${currentCanvas.name} (副本)',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复制当前画布'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '新画布名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (result == true && name.isNotEmpty && mounted) {
      final matrix = _transformController.value;
      await ref
          .read(canvasActionsProvider)
          .saveViewport(
            currentCanvas.id,
            matrix.getTranslation().x,
            matrix.getTranslation().y,
            matrix.getMaxScaleOnAxis(),
          );
      final newCanvas = await ref
          .read(canvasActionsProvider)
          .duplicate(currentCanvas.id, name);
      if (mounted) {
        await _switchToCanvas(newCanvas);
        messenger.showSnackBar(
          SnackBar(content: Text('已成功复制画布【$name】，节点位置与视口已完整继承')),
        );
      }
    }
  }

  Future<void> _showRenameCanvasDialog(GraphCanvas currentCanvas) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentCanvas.name);
    final descController = TextEditingController(
      text: currentCanvas.description ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名画布'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: '画布名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述 (可选)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    final newName = controller.text.trim();
    final newDesc = descController.text.trim().isEmpty
        ? null
        : descController.text.trim();
    controller.dispose();
    descController.dispose();

    if (result == true && newName.isNotEmpty && mounted) {
      await ref
          .read(canvasActionsProvider)
          .rename(currentCanvas.id, newName, newDesc: newDesc);
      if (mounted) {
        setState(() => _graphRevision++);
        messenger.showSnackBar(SnackBar(content: Text('画布已重命名为【$newName】')));
      }
    }
  }

  Future<void> _setDefaultCanvas(GraphCanvas canvas) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(canvasActionsProvider).setDefault(widget.worldId, canvas.id);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('已将【${canvas.name}】设为默认画布')),
      );
    }
  }

  Future<void> _showDeleteCanvasDialog(
    GraphCanvas canvas,
    List<GraphCanvas> allCanvases,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (allCanvases.length <= 1) {
      messenger.showSnackBar(const SnackBar(content: Text('不能删除唯一的画布')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除画布【${canvas.name}】？'),
        content: const Text(
          '此操作将移除该画布下的节点位置与视口排版，但绝不会删除世界观中的任何人物档案和角色关系数据。\n\n确认删除吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final remaining = allCanvases.where((c) => c.id != canvas.id).toList();
      final nextCanvas = remaining.firstWhere(
        (c) => c.isDefault,
        orElse: () => remaining.first,
      );

      await ref.read(canvasActionsProvider).delete(canvas.id);

      if (mounted) {
        await _switchToCanvas(nextCanvas);
        messenger.showSnackBar(
          SnackBar(content: Text('画布【${canvas.name}】已安全删除，人物与关系数据已保留')),
        );
      }
    }
  }

  Widget _buildCanvasSelector(List<GraphCanvas> canvases, bool isDark) {
    if (canvases.isEmpty) {
      return const Text('关系图');
    }

    final currentCanvas = canvases.firstWhere(
      (c) => c.id == _selectedCanvasId,
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
            _switchToCanvas(target);
          }
        } else if (val == 'action_new') {
          _showNewCanvasDialog();
        } else if (val == 'action_duplicate') {
          _showDuplicateCanvasDialog(currentCanvas);
        } else if (val == 'action_rename') {
          _showRenameCanvasDialog(currentCanvas);
        } else if (val == 'action_set_default') {
          _setDefaultCanvas(currentCanvas);
        } else if (val == 'action_delete') {
          _showDeleteCanvasDialog(currentCanvas, canvases);
        }
      },
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
          ListenableBuilder(
            listenable: _historyManager,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: _historyManager.canUndo
                        ? '撤销: ${_historyManager.undoDescription} (Ctrl+Z)'
                        : '撤销 (Ctrl+Z)',
                    onPressed: _historyManager.canUndo
                        ? () => _historyManager.undo()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded),
                    tooltip: _historyManager.canRedo
                        ? '重做: ${_historyManager.redoDescription} (Ctrl+Y)'
                        : '重做 (Ctrl+Y)',
                    onPressed: _historyManager.canRedo
                        ? () => _historyManager.redo()
                        : null,
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: '添加人物关系',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showAddRelationDialog(chars);
            },
          ),
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: '添加家谱关系',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showFamilyRelationDialog(chars);
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop_free),
            tooltip: '适应画布 / 查看全部',
            onPressed: () {
              final size = MediaQuery.of(context).size;
              _fitCanvasToNodes(size);
            },
          ),
          IconButton(
            icon: const Icon(Icons.route_rounded),
            tooltip: '人脉寻径 (最短关系链路分析)',
            onPressed: () {
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
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome_mosaic_rounded),
            tooltip: '智能排版算法与布局',
            onSelected: (modeStr) {
              if (modeStr == 'undo') {
                _undoAutoLayout();
                return;
              }
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              final mode = AutoLayoutMode.values.firstWhere(
                (m) => m.name == modeStr,
              );
              _applyAutoLayout(mode, chars, rels);
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
              if (_layoutSnapshotBeforeAuto != null) ...[
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
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              if (value == 'png') {
                _exportToImage(chars, rels);
              } else if (value == 'svg') {
                _exportToSvg(chars, rels);
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
            onPressed: () => _transformController.value = Matrix4.identity(),
          ),
          IconButton(
            icon: Icon(_showSidebar ? Icons.chevron_left : Icons.chevron_right),
            tooltip: _showSidebar ? '隐藏侧栏' : '显示侧栏',
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
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
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.centerLeft,
                  heightFactor: 1.0,
                  widthFactor: _showSidebar ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: ExcludeFocus(
                    excluding: !_showSidebar,
                    child: IgnorePointer(
                      ignoring: !_showSidebar,
                      child: SizedBox(
                        width: 120,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            border: Border(
                              right: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '人物列表',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: characters.length,
                                  itemBuilder: (context, index) {
                                    final c = characters[index];
                                    final placed = _positions.containsKey(c.id);
                                    final color = c.status == 1
                                        ? Colors.grey
                                        : theme.colorScheme.primary;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Draggable<int>(
                                        data: c.id,
                                        feedback: Material(
                                          elevation: 6,
                                          child: buildGenderShape(
                                            c.gender,
                                            28,
                                            color,
                                            c.name,
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: RelationSidebarItem(
                                            character: c,
                                            placed: placed,
                                          ),
                                        ),
                                        child: RelationSidebarItem(
                                          character: c,
                                          placed: placed,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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

const _relationTypes = ['亲属', '朋友', '恋人', '师徒', '敌对', '宿敌', '同事', '其他'];
