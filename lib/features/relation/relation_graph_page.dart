import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';

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
  bool _initialized = false;
  bool _showSidebar = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _initPositions(List<Character> characters, List<GraphLayout> layouts) {
    if (_initialized) return;
    _initialized = true;

    final saved = {for (var l in layouts) l.characterId: Offset(l.x, l.y)};
    for (final c in characters) {
      if (saved.containsKey(c.id)) {
        _positions[c.id] = saved[c.id]!;
      }
    }
  }

  void _savePosition(int characterId, Offset pos) {
    ref.read(graphLayoutActionsProvider).savePosition(
          widget.worldId,
          characterId,
          pos.dx,
          pos.dy,
        );
  }

  void _dropCharacter(int characterId, Offset screenDropPos) {
    final inverse = Matrix4.inverted(_transformController.value);
    final canvasPos = MatrixUtils.transformPoint(inverse, screenDropPos);
    setState(() {
      _positions[characterId] = canvasPos;
    });
    _savePosition(characterId, canvasPos);
  }

  void _removeFromCanvas(int characterId) {
    setState(() {
      _positions.remove(characterId);
    });
    ref.read(graphLayoutActionsProvider).removePosition(
          widget.worldId,
          characterId,
        );
  }

  // --- 添加关系对话框 ---

  void _showAddRelationDialog(List<Character> characters, {int? fromId}) {
    if (characters.length < 2) return;

    int? selectedFrom = fromId ?? characters[0].id;
    int? selectedTo = characters.firstWhere(
      (c) => c.id != selectedFrom,
      orElse: () => characters[0],
    ).id;
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
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedFrom = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTo,
                  decoration: const InputDecoration(labelText: '目标人物'),
                  items: characters
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedTo = v),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('关系类型',
                      style: Theme.of(context).textTheme.bodySmall),
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
                      label: const Text('自定义…',
                          style: TextStyle(fontSize: 12)),
                      selected: isCustomType,
                      onSelected: (_) =>
                          setState(() => isCustomType = true),
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
                  await ref.read(relationActionsProvider).create(
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(
                      relationsByWorldProvider(widget.worldId));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 管理人物关系对话框 ---

  void _showRelationManager(
      Character character, List<Character> allCharacters, List<Relation> relations) {
    String nameOf(int id) =>
        allCharacters
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull ??
        '?';

    showDialog(
      context: context,
      builder: (context) {
        List<Relation> localRelations = List.of(relations);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final myRelations = localRelations
                .where((r) =>
                    r.fromCharacterId == character.id ||
                    r.toCharacterId == character.id)
                .toList();

            return AlertDialog(
              title: Text('${character.name} 的关系'),
              content: SizedBox(
                width: 360,
                child: myRelations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('暂无关系',
                              style: TextStyle(color: Colors.grey)),
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
                          final direction =
                              rel.fromCharacterId == character.id
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
                                ? Text(rel.note!,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20,
                                  color:
                                      Theme.of(context).colorScheme.error),
                              onPressed: () async {
                                await ref
                                    .read(relationActionsProvider)
                                    .delete(rel.id);
                                setDialogState(() {
                                  localRelations.removeWhere(
                                      (r) => r.id == rel.id);
                                });
                                ref.invalidate(
                                    relationsByWorldProvider(
                                        widget.worldId));
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
                    _showAddRelationDialog(allCharacters,
                        fromId: character.id);
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
                  Text('父母（可多选）',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(c.name,
                              style: const TextStyle(fontSize: 12)),
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
                  Text('子女（可多选）',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(c.name,
                              style: const TextStyle(fontSize: 12)),
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
                    decoration:
                        const InputDecoration(labelText: '备注（可选）'),
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
                  await ref
                      .read(relationActionsProvider)
                      .createFamilyRelation(
                        parentIds: parentIds,
                        childIds: childIds,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(
                      relationsByWorldProvider(widget.worldId));
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

  static Widget? _genderIcon(String gender) {
    if (gender == '男') return const Text('♂', style: TextStyle(fontSize: 14));
    if (gender == '女') return const Text('♀', style: TextStyle(fontSize: 14));
    if (gender.isNotEmpty) {
      return const Text('⚥', style: TextStyle(fontSize: 14));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));
    final relationsAsync =
        ref.watch(relationsByWorldProvider(widget.worldId));
    final layoutsAsync =
        ref.watch(graphLayoutsProvider(widget.worldId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关系图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: '添加家谱关系',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showFamilyRelationDialog(chars);
            },
          ),
          IconButton(
            icon: Icon(_showSidebar ? Icons.chevron_left : Icons.chevron_right),
            tooltip: _showSidebar ? '隐藏侧栏' : '显示侧栏',
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '重置视图',
            onPressed: () => _transformController.value = Matrix4.identity(),
          ),
        ],
      ),
      body: charactersAsync.when(
        data: (characters) {
          final relations = relationsAsync.valueOrNull ?? [];
          final layouts = layoutsAsync.valueOrNull ?? [];

          if (characters.isEmpty) {
            return const Center(
              child: Text('暂无人物', style: TextStyle(color: Colors.grey)),
            );
          }

          _initPositions(characters, layouts);

          return Row(
            children: [
              if (_showSidebar)
                Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: characters.length,
                          itemBuilder: (context, index) {
                            final c = characters[index];
                            final placed = _positions.containsKey(c.id);
                            final color = c.status == 1
                                ? Colors.grey
                                : theme.colorScheme.primary;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Draggable<int>(
                                data: c.id,
                                feedback: Material(
                                  elevation: 6,
                                  child: _buildShape(
                                    c.gender, 28, color, c.name),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _SidebarItem(
                                      character: c, placed: placed),
                                ),
                                child: _SidebarItem(
                                    character: c, placed: placed),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(
                        constraints.maxWidth, constraints.maxHeight);
                    final canvasSize = Size(
                      max(viewport.width, 2000),
                      max(viewport.height, 2000),
                    );

                    return DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final renderBox = context.findRenderObject()
                            as RenderBox;
                        final localPos =
                            renderBox.globalToLocal(details.offset);
                        _dropCharacter(details.data, localPos);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return InteractiveViewer(
                          transformationController: _transformController,
                          boundaryMargin: const EdgeInsets.all(500),
                          minScale: 0.1,
                          maxScale: 3.0,
                          child: Container(
                            width: canvasSize.width,
                            height: canvasSize.height,
                            color: theme
                                .colorScheme.surfaceContainerLowest,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GridPainter(
                                      color: theme
                                          .colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                CustomPaint(
                                  size: canvasSize,
                                  painter: _RelationPainter(
                                    relations: relations,
                                    positions: _positions,
                                    characters: characters,
                                  ),
                                ),
                                for (var character in characters)
                                  if (_positions.containsKey(character.id))
                                    _DraggableNode(
                                      character: character,
                                      position:
                                          _positions[character.id]!,
                                      allCharacters: characters,
                                      relations: relations,
                                      onDragUpdate: (newPos) {
                                        setState(() {
                                          _positions[character.id] =
                                              newPos;
                                        });
                                      },
                                      onDragEnd: (newPos) {
                                        _savePosition(
                                            character.id, newPos);
                                      },
                                      onRemove: () =>
                                          _removeFromCanvas(character.id),
                                      onManageRelations: () =>
                                          _showRelationManager(
                                              character,
                                              characters,
                                              relations),
                                    ),
                                if (candidateData.isNotEmpty)
                                  Center(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '松开放置人物',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
  }
}

// --- 性别形状 ---

Widget _buildShape(String gender, double size, Color color, String label) {
  final half = size;
  final text = label.isNotEmpty ? label[0] : '?';

  if (gender == '男') {
    // 圆形
    return CircleAvatar(
      radius: half,
      backgroundColor: color,
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: half * 0.75,
              fontWeight: FontWeight.bold)),
    );
  } else if (gender == '女') {
    // 方形
    return Container(
      width: half * 2,
      height: half * 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: half * 0.75,
              fontWeight: FontWeight.bold)),
    );
  } else {
    // 菱形
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: half * 1.6,
        height: half * 1.6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -pi / 4,
          child: Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: half * 0.65,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// --- 侧边栏条目 ---

class _SidebarItem extends StatelessWidget {
  final Character character;
  final bool placed;

  const _SidebarItem({required this.character, required this.placed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = character.status == 1
        ? Colors.grey
        : theme.colorScheme.primary;

    return Opacity(
      opacity: placed ? 0.4 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShape(character.gender, 22, color, character.name),
          const SizedBox(height: 4),
          Text(
            character.name,
            style: TextStyle(
              fontSize: 11,
              color: placed
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// --- 画布上可拖拽节点 ---

class _DraggableNode extends StatefulWidget {
  final Character character;
  final Offset position;
  final List<Character> allCharacters;
  final List<Relation> relations;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final VoidCallback onRemove;
  final VoidCallback onManageRelations;

  const _DraggableNode({
    required this.character,
    required this.position,
    required this.allCharacters,
    required this.relations,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onRemove,
    required this.onManageRelations,
  });

  @override
  State<_DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<_DraggableNode> {
  late Offset _pos;

  @override
  void initState() {
    super.initState();
    _pos = widget.position;
  }

  @override
  void didUpdateWidget(_DraggableNode old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) {
      _pos = widget.position;
    }
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          height: 36,
          onTap: widget.onManageRelations,
          child: const Row(
            children: [
              Icon(Icons.hub, size: 18),
              SizedBox(width: 8),
              Text('管理关系'),
            ],
          ),
        ),
        PopupMenuItem(
          height: 36,
          onTap: widget.onRemove,
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('移回侧栏'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.character.name;
    final color = widget.character.status == 1
        ? Colors.grey
        : Theme.of(context).colorScheme.primary;

    return Positioned(
      left: _pos.dx - 30,
      top: _pos.dy - 30,
      child: GestureDetector(
        onSecondaryTapDown: _showContextMenu,
        onLongPressStart: (details) => _showContextMenu(
          TapDownDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
          ),
        ),
        onPanUpdate: (details) {
          setState(() {
            _pos += details.delta;
          });
          widget.onDragUpdate(_pos);
        },
        onPanEnd: (_) {
          widget.onDragEnd(_pos);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShape(widget.character.gender, 24, color, name),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 网格背景 ---

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

// --- 关系连线绘制 ---

class _RelationPainter extends CustomPainter {
  final List<Relation> relations;
  final Map<int, Offset> positions;
  final List<Character> characters;

  _RelationPainter({
    required this.relations,
    required this.positions,
    required this.characters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const nodeRadius = 28.0;

    // 分离家谱组和普通组
    final familyGroups = <String, List<Relation>>{};
    final normalGroups = <String, List<Relation>>{};

    for (final rel in relations) {
      if (!positions.containsKey(rel.fromCharacterId) ||
          !positions.containsKey(rel.toCharacterId)) {
        continue;
      }
      final key = _pairKey(rel.fromCharacterId, rel.toCharacterId);
      if (rel.relationGroupId != null &&
          _familyTypes.contains(rel.relationType)) {
        familyGroups
            .putIfAbsent(rel.relationGroupId!, () => [])
            .add(rel);
      } else {
        normalGroups.putIfAbsent(key, () => []).add(rel);
      }
    }

    // 绘制家谱
    for (final entry in familyGroups.entries) {
      _drawFamilyGroup(canvas, textPainter, linePaint, entry.value, nodeRadius);
    }

    // 绘制普通关系
    for (final entry in normalGroups.entries) {
      _drawNormalGroup(canvas, textPainter, linePaint, entry.value, nodeRadius);
    }
  }

  // --- 家谱图：遗传图风格 ---

  void _drawFamilyGroup(Canvas canvas, TextPainter tp, Paint paint,
      List<Relation> group, double nodeRadius) {
    // 收集父母和子女
    final parentIds = <int>{};
    final childIds = <int>{};

    for (final rel in group) {
      // fromCharacterId = 父母, toCharacterId = 子女
      if (rel.fromCharacterId != rel.toCharacterId) {
        parentIds.add(rel.fromCharacterId);
        childIds.add(rel.toCharacterId);
      }
    }

    final parents = parentIds.map((id) => positions[id]).whereType<Offset>().toList();
    final children = childIds.map((id) => positions[id]).whereType<Offset>().toList();

    if (parents.isEmpty || children.isEmpty) return;

    final color = Colors.blue.shade300;
    paint.color = color;

    if (parents.length >= 2) {
      // 父母之间连线
      final p1 = parents[0];
      final p2 = parents[1];
      final dir = (p2 - p1).direction;
      final edge1 = Offset(
          p1.dx + nodeRadius * cos(dir), p1.dy + nodeRadius * sin(dir));
      final edge2 = Offset(
          p2.dx - nodeRadius * cos(dir), p2.dy - nodeRadius * sin(dir));
      canvas.drawLine(edge1, edge2, paint);

      // 父母中点
      final parentMid = Offset(
          (edge1.dx + edge2.dx) / 2, (edge1.dy + edge2.dy) / 2);

      // 如果有更多父母（罕见），都连到中点
      for (var i = 2; i < parents.length; i++) {
        final pi = parents[i];
        final d = (pi - parentMid).direction;
        canvas.drawLine(
            Offset(pi.dx - nodeRadius * cos(d),
                pi.dy - nodeRadius * sin(d)),
            parentMid,
            paint);
      }

      // 从父母中点向下画竖线
      const dropLen = 50.0;
      final busY = parentMid.dy + dropLen;
      final busStart = Offset(parentMid.dx, busY);
      canvas.drawLine(parentMid, busStart, paint);

      if (children.length == 1) {
        // 单个子女：直接连下去
        final child = children[0];
        final cEdge = Offset(child.dx, child.dy - nodeRadius);
        final busToChild = Offset(busStart.dx, cEdge.dy);
        canvas.drawLine(busStart, busToChild, paint);
        canvas.drawLine(busToChild, cEdge, paint);

        _drawArrowDir(canvas, cEdge, pi / 2, color);
      } else {
        // 多个子女：画横线再分叉
        final childXs =
            children.map((c) => c.dx).toList()..sort();
        final busLeft = Offset(childXs.first, busY);
        final busRight = Offset(childXs.last, busY);

        // 横线
        canvas.drawLine(
            Offset(min(busStart.dx, busLeft.dx), busY),
            Offset(max(busStart.dx, busRight.dx), busY),
            paint);

        // 每个子女
        for (final child in children) {
          final cEdge = Offset(child.dx, child.dy - nodeRadius);
          final junction = Offset(child.dx, busY);
          canvas.drawLine(junction, cEdge, paint);
          _drawArrowDir(canvas, cEdge, pi / 2, color);
        }
      }

      // 标签
      final relType = group.first.relationType;
      _drawLabel(canvas, tp, relType,
          Offset(parentMid.dx, parentMid.dy + 16));
    }
  }

  // --- 普通关系：弧线/直线 ---

  void _drawNormalGroup(Canvas canvas, TextPainter tp, Paint paint,
      List<Relation> group, double nodeRadius) {
    final from = positions[group.first.fromCharacterId]!;
    final to = positions[group.first.toCharacterId]!;
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final rel = group[i];
      final color = rel.isBidirectional
          ? Colors.blue.shade300
          : Colors.orange.shade300;
      paint.color = color;

      final offset = count == 1 ? 0.0 : (i - (count - 1) / 2) * 40.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;

      if (count == 1) {
        final dir = dist > 0 ? Offset(dx / dist, dy / dist) : Offset.zero;
        final p1 = Offset(
            from.dx + dir.dx * nodeRadius, from.dy + dir.dy * nodeRadius);
        final p2 = Offset(
            to.dx - dir.dx * nodeRadius, to.dy - dir.dy * nodeRadius);
        canvas.drawLine(p1, p2, paint);

        if (rel.isBidirectional) {
          _drawArrow(canvas, p1, p2, color);
          _drawArrow(canvas, p2, p1, color);
        } else {
          _drawArrow(canvas, p1, p2, color);
        }

        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        _drawLabel(canvas, tp, rel.relationType, mid);
      } else {
        final cp = Offset(
          (from.dx + to.dx) / 2 + nx * offset,
          (from.dy + to.dy) / 2 + ny * offset,
        );

        final tStart = Offset(cp.dx - from.dx, cp.dy - from.dy).direction;
        final tEnd = Offset(to.dx - cp.dx, to.dy - cp.dy).direction;

        final p1 = Offset(
            from.dx + nodeRadius * cos(tStart),
            from.dy + nodeRadius * sin(tStart));
        final p2 = Offset(
            to.dx - nodeRadius * cos(tEnd),
            to.dy - nodeRadius * sin(tEnd));

        final adjCp = Offset(
          (p1.dx + p2.dx) / 2 + nx * offset,
          (p1.dy + p2.dy) / 2 + ny * offset,
        );

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(adjCp.dx, adjCp.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);

        if (rel.isBidirectional) {
          _drawArrowDir(canvas, p2, tEnd, color);
          _drawArrowDir(canvas, p1, tStart + pi, color);
        } else {
          _drawArrowDir(canvas, p2, tEnd, color);
        }

        final t = 0.5;
        final labelX = (1 - t) * (1 - t) * p1.dx +
            2 * (1 - t) * t * adjCp.dx +
            t * t * p2.dx;
        final labelY = (1 - t) * (1 - t) * p1.dy +
            2 * (1 - t) * t * adjCp.dy +
            t * t * p2.dy;
        _drawLabel(canvas, tp, rel.relationType, Offset(labelX, labelY));
      }
    }
  }

  String _pairKey(int a, int b) {
    final minId = a < b ? a : b;
    final maxId = a < b ? b : a;
    return '$minId-$maxId';
  }

  void _drawLabel(Canvas canvas, TextPainter tp, String text, Offset center) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 11,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
      ),
    );
    tp.layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    _drawArrowDir(canvas, to, (to - from).direction, color);
  }

  void _drawArrowDir(
      Canvas canvas, Offset pos, double direction, Color color) {
    const arrowSize = 10.0;
    const arrowAngle = 0.5;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction - arrowAngle),
        pos.dy - arrowSize * sin(direction - arrowAngle),
      )
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction + arrowAngle),
        pos.dy - arrowSize * sin(direction + arrowAngle),
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RelationPainter old) =>
      old.relations != relations || old.positions != positions;
}

const _familyTypes = ['亲子', '父母', '父女', '父子', '母子', '母女', '家人'];

const _relationTypes = [
  '亲属',
  '朋友',
  '恋人',
  '师徒',
  '敌对',
  '宿敌',
  '同事',
  '其他',
];
