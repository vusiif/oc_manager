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

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _initPositions(List<Character> characters, List<GraphLayout> layouts) {
    if (_initialized) return;
    _initialized = true;

    final saved = {for (var l in layouts) l.characterId: Offset(l.x, l.y)};
    final canvasSize = _canvasSizeFor(characters.length);
    final radius = min(canvasSize.width, canvasSize.height) / 2 - 80;

    for (var i = 0; i < characters.length; i++) {
      final c = characters[i];
      if (saved.containsKey(c.id)) {
        _positions[c.id] = saved[c.id]!;
      } else {
        final angle = 2 * pi * i / characters.length - pi / 2;
        _positions[c.id] = Offset(
          canvasSize.width / 2 + radius * cos(angle),
          canvasSize.height / 2 + radius * sin(angle),
        );
      }
    }
  }

  Size _canvasSizeFor(int count) {
    final side = max(800.0, count * 120.0);
    return Size(side, side);
  }

  void _savePosition(int characterId, Offset pos) {
    ref.read(graphLayoutActionsProvider).savePosition(
          widget.worldId,
          characterId,
          pos.dx,
          pos.dy,
        );
  }

  void _showAddRelationDialog(List<Character> characters) {
    final others = characters.toList();
    if (others.length < 2) return;

    int? fromId = others[0].id;
    int? toId = others.length > 1 ? others[1].id : others[0].id;
    String selectedType = '朋友';
    bool isBidirectional = true;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加关系'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: fromId,
                decoration: const InputDecoration(labelText: '起始人物'),
                items: others
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => fromId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: toId,
                decoration: const InputDecoration(labelText: '目标人物'),
                items: others
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => toId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '关系类型'),
                items: _relationTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedType = v);
                },
              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fromId != null && toId != null && fromId != toId) {
                  await ref.read(relationActionsProvider).create(
                        fromCharacterId: fromId!,
                        toCharacterId: toId!,
                        relationType: selectedType,
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

  @override
  Widget build(BuildContext context) {
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));
    final relationsAsync =
        ref.watch(relationsByWorldProvider(widget.worldId));
    final layoutsAsync =
        ref.watch(graphLayoutsProvider(widget.worldId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('关系图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '重置视图',
            onPressed: () => _transformController.value = Matrix4.identity(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final chars = charactersAsync.valueOrNull ?? [];
          _showAddRelationDialog(chars);
        },
        child: const Icon(Icons.add),
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
          final canvasSize = _canvasSizeFor(characters.length);

          return InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.3,
            maxScale: 3.0,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  // 绘制连线
                  CustomPaint(
                    size: canvasSize,
                    painter: _RelationPainter(
                      relations: relations,
                      positions: _positions,
                      characters: characters,
                    ),
                  ),
                  // 人物节点
                  for (var character in characters)
                    if (_positions.containsKey(character.id))
                      _DraggableNode(
                        character: character,
                        position: _positions[character.id]!,
                        onDragUpdate: (newPos) {
                          setState(() {
                            _positions[character.id] = newPos;
                          });
                        },
                        onDragEnd: (newPos) {
                          _savePosition(character.id, newPos);
                        },
                      ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('错误: $error')),
      ),
    );
  }
}

// --- 可拖拽节点 ---

class _DraggableNode extends StatefulWidget {
  final Character character;
  final Offset position;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;

  const _DraggableNode({
    required this.character,
    required this.position,
    required this.onDragUpdate,
    required this.onDragEnd,
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
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
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

    for (final rel in relations) {
      final from = positions[rel.fromCharacterId];
      final to = positions[rel.toCharacterId];
      if (from == null || to == null) continue;

      // 画线
      linePaint.color = rel.isBidirectional
          ? Colors.blue.shade300
          : Colors.orange.shade300;
      canvas.drawLine(from, to, linePaint);

      // 箭头（非双向时画在目标端）
      if (!rel.isBidirectional) {
        _drawArrow(canvas, from, to, linePaint.color);
      }

      // 关系类型标签
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      textPainter.text = TextSpan(
        text: rel.relationType,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 11,
          backgroundColor: Colors.white.withValues(alpha: 0.8),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2));
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final direction = (to - from).direction;
    final arrowSize = 10.0;
    final arrowAngle = 0.5; // radians

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * cos(direction - arrowAngle),
        to.dy - arrowSize * sin(direction - arrowAngle),
      )
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * cos(direction + arrowAngle),
        to.dy - arrowSize * sin(direction + arrowAngle),
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
