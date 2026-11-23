import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';

Widget buildGenderShape(String gender, double size, Color color, String label) {
  final half = size;
  final text = label.isNotEmpty ? label[0] : '?';

  if (gender == '男') {
    // 方形
    return Container(
      width: half * 2,
      height: half * 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: half * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  } else if (gender == '女') {
    // 圆形
    return CircleAvatar(
      radius: half,
      backgroundColor: color,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: half * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
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
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: half * 0.65,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// --- 侧边栏条目 ---

class RelationSidebarItem extends StatelessWidget {
  final Character character;
  final bool placed;

  const RelationSidebarItem({
    super.key,
    required this.character,
    required this.placed,
  });

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
          buildGenderShape(character.gender, 22, color, character.name),
          const SizedBox(height: 4),
          Text(
            character.name,
            style: TextStyle(
              fontSize: 11,
              color: placed ? theme.colorScheme.onSurfaceVariant : null,
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

class DraggableNode extends StatefulWidget {
  final Character character;
  final Offset position;
  final List<Character> allCharacters;
  final List<Relation> relations;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final ValueChanged<Offset>? onConnectStart;
  final ValueChanged<Offset>? onConnectUpdate;
  final VoidCallback? onConnectEnd;
  final VoidCallback onRemove;
  final VoidCallback onManageRelations;
  final VoidCallback onEdit;
  final bool isPathHighlighted;
  final bool isDimmed;
  final GraphLodLevel lodLevel;

  const DraggableNode({
    super.key,
    required this.character,
    required this.position,
    required this.allCharacters,
    required this.relations,
    this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onConnectStart,
    this.onConnectUpdate,
    this.onConnectEnd,
    required this.onRemove,
    required this.onManageRelations,
    required this.onEdit,
    this.isPathHighlighted = false,
    this.isDimmed = false,
    this.lodLevel = GraphLodLevel.full,
  });

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  late Offset _pos;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.position;
  }

  @override
  void didUpdateWidget(DraggableNode old) {
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
          onTap: widget.onEdit,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('编辑人物'),
            ],
          ),
        ),
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
              Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
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

    // Overview LOD: ultra-lightweight micro-dot for massive graph rendering (PERF-001)
    if (widget.lodLevel == GraphLodLevel.overview) {
      return Positioned(
        left: _pos.dx - 10,
        top: _pos.dy - 10,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: _showContextMenu,
            onPanStart: (_) => widget.onDragStart?.call(_pos),
            onPanUpdate: (details) {
              final newX = max(40.0, _pos.dx + details.delta.dx);
              final newY = max(40.0, _pos.dy + details.delta.dy);
              final nextPos = Offset(newX, newY);
              setState(() => _pos = nextPos);
              widget.onDragUpdate(nextPos);
            },
            onPanEnd: (_) => widget.onDragEnd(_pos),
            onPanCancel: () => widget.onDragEnd(_pos),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: widget.character.gender == '男'
                    ? BoxShape.rectangle
                    : BoxShape.circle,
                borderRadius: widget.character.gender == '男'
                    ? BorderRadius.circular(3)
                    : null,
                border: Border.all(
                  color: widget.isPathHighlighted
                      ? AppColors.brand
                      : Colors.white70,
                  width: widget.isPathHighlighted ? 2.5 : 1.0,
                ),
                boxShadow: widget.isPathHighlighted
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    // Medium LOD: render shape with drag/context interaction, omit text below (PERF-001)
    if (widget.lodLevel == GraphLodLevel.medium) {
      return Positioned(
        left: _pos.dx - 22,
        top: _pos.dy - 22,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: _showContextMenu,
            onPanStart: (_) => widget.onDragStart?.call(_pos),
            onPanUpdate: (details) {
              final newX = max(40.0, _pos.dx + details.delta.dx);
              final newY = max(40.0, _pos.dy + details.delta.dy);
              final nextPos = Offset(newX, newY);
              setState(() => _pos = nextPos);
              widget.onDragUpdate(nextPos);
            },
            onPanEnd: (_) => widget.onDragEnd(_pos),
            onPanCancel: () => widget.onDragEnd(_pos),
            child: Opacity(
              opacity: widget.isDimmed ? 0.25 : 1.0,
              child: buildGenderShape(widget.character.gender, 20, color, name),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: _pos.dx - 30,
      top: _pos.dy - 30,
      child: RepaintBoundary(
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: _showContextMenu,
                onLongPressStart: (details) => _showContextMenu(
                  TapDownDetails(
                    globalPosition: details.globalPosition,
                    localPosition: details.localPosition,
                  ),
                ),
                onPanStart: (_) => widget.onDragStart?.call(_pos),
                onPanUpdate: (details) {
                  final newX = max(40.0, _pos.dx + details.delta.dx);
                  final newY = max(40.0, _pos.dy + details.delta.dy);
                  final nextPos = Offset(newX, newY);
                  setState(() {
                    _pos = nextPos;
                  });
                  widget.onDragUpdate(nextPos);
                },
                onPanEnd: (_) {
                  widget.onDragEnd(_pos);
                },
                onPanCancel: () {
                  widget.onDragEnd(_pos);
                },
                child: Opacity(
                  opacity: widget.isDimmed ? 0.25 : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.isPathHighlighted)
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brand.withValues(
                                      alpha: 0.7,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          buildGenderShape(
                            widget.character.gender,
                            24,
                            color,
                            name,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 64,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: widget.isPathHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: widget.isPathHighlighted
                                ? AppColors.brand
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 节点连接手柄：鼠标悬停在节点上时浮现
              if (_isHovered)
                Positioned(
                  right: -6,
                  top: 15,
                  child: Tooltip(
                    message: '拖拽到另一人物创建关系',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        widget.onConnectStart?.call(_pos);
                      },
                      onPanUpdate: (details) {
                        widget.onConnectUpdate?.call(details.delta);
                      },
                      onPanEnd: (_) {
                        widget.onConnectEnd?.call();
                      },
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
