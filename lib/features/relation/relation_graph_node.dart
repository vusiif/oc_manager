import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/util/graph_viewport_culling.dart';
import '../../data/database/app_database.dart';
import 'widgets/relation_node_avatar.dart';

export 'widgets/relation_node_avatar.dart';

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
  final bool isSelected;
  final bool isDimmed;
  final bool isConnectTarget;
  final VoidCallback? onTap;
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
    this.isSelected = false,
    this.isDimmed = false,
    this.isConnectTarget = false,
    this.onTap,
    this.lodLevel = GraphLodLevel.full,
  });

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  late Offset _pos;
  bool _isHovered = false;
  bool _isConnecting = false;

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

    final isHighlighted = widget.isPathHighlighted || widget.isSelected;

    // Overview LOD: ultra-lightweight micro-dot for massive graph rendering (PERF-001)
    if (widget.lodLevel == GraphLodLevel.overview) {
      return Positioned(
        left: _pos.dx - 10,
        top: _pos.dy - 10,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
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
                  color: isHighlighted ? AppColors.brand : Colors.white70,
                  width: isHighlighted ? 2.5 : 1.0,
                ),
                boxShadow: isHighlighted
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
            onTap: widget.onTap,
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
              setState(() => _pos = nextPos);
              widget.onDragUpdate(nextPos);
            },
            onPanEnd: (_) => widget.onDragEnd(_pos),
            onPanCancel: () => widget.onDragEnd(_pos),
            child: Opacity(
              opacity: widget.isDimmed ? 0.25 : 1.0,
              child: buildCharacterAvatar(
                character: widget.character,
                size: 40,
                color: color,
                isHighlighted: isHighlighted,
              ),
            ),
          ),
        ),
      );
    }

    final showHandle = _isHovered || _isConnecting;
    return Positioned(
      left: _pos.dx - 42,
      top: _pos.dy - 24,
      child: RepaintBoundary(
        child: MouseRegion(
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) {
            if (!_isConnecting) {
              setState(() => _isHovered = false);
            }
          },
          child: SizedBox(
            width: 86,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 10,
                  top: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTap,
                    onSecondaryTapDown: _showContextMenu,
                    onLongPressStart: (details) => _showContextMenu(
                      TapDownDetails(
                        globalPosition: details.globalPosition,
                        localPosition: details.localPosition,
                      ),
                    ),
                    onPanStart: (_) {
                      if (_isConnecting) return;
                      widget.onDragStart?.call(_pos);
                    },
                    onPanUpdate: (details) {
                      if (_isConnecting) return;
                      final newX = max(40.0, _pos.dx + details.delta.dx);
                      final newY = max(40.0, _pos.dy + details.delta.dy);
                      final nextPos = Offset(newX, newY);
                      setState(() {
                        _pos = nextPos;
                      });
                      widget.onDragUpdate(nextPos);
                    },
                    onPanEnd: (_) {
                      if (!_isConnecting) {
                        widget.onDragEnd(_pos);
                      }
                    },
                    onPanCancel: () {
                      if (!_isConnecting) {
                        widget.onDragEnd(_pos);
                      }
                    },
                    child: Opacity(
                      opacity: widget.isDimmed ? 0.25 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // 磁吸吸附高亮光圈（使用Positioned渲染在外层，绝不撑大48x48布局尺寸）
                                if (widget.isConnectTarget)
                                  Positioned(
                                    left: -7,
                                    top: -7,
                                    width: 62,
                                    height: 62,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.brand.withValues(
                                              alpha: 0.85,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isHighlighted)
                                  Positioned(
                                    left: -5,
                                    top: -5,
                                    width: 58,
                                    height: 58,
                                    child: Container(
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
                                  ),
                                buildCharacterAvatar(
                                  character: widget.character,
                                  size: 48,
                                  color: color,
                                  isHighlighted: isHighlighted,
                                  isConnectTarget: widget.isConnectTarget,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 64,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.88)
                                  : Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isHighlighted || widget.isConnectTarget)
                                    ? AppColors.brand.withValues(alpha: 0.85)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white12
                                          : Colors.black12),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    (isHighlighted || widget.isConnectTarget)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: (isHighlighted || widget.isConnectTarget)
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
                ),
                // 节点连接手柄：完全置于 SizedBox(width: 86) 内部，鼠标靠近绝对不缩回！
                if (showHandle)
                  Positioned(
                    right: 0,
                    top: 12,
                    child: Tooltip(
                      message: '拖拽到另一人物创建关系',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          setState(() => _isConnecting = true);
                          widget.onConnectStart?.call(_pos);
                        },
                        onPanUpdate: (details) {
                          widget.onConnectUpdate?.call(details.globalPosition);
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _isConnecting = false;
                            _isHovered = false;
                          });
                          widget.onConnectEnd?.call();
                        },
                        onPanCancel: () {
                          setState(() {
                            _isConnecting = false;
                            _isHovered = false;
                          });
                          widget.onConnectEnd?.call();
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
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
      ),
    );
  }
}
