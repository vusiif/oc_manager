import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/util/graph_viewport_culling.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/world_provider.dart';
import '../lore_entity_detail_dialog.dart';
import 'knowledge_network_filter_dialog.dart';
import 'knowledge_network_layout_engine.dart';
import 'knowledge_network_painter.dart';
import 'knowledge_network_provider.dart';
import 'knowledge_network_toolbar.dart';
import 'knowledge_node_inspector.dart';

/// 知识网络全域大视图页面 (LORE-007)
class KnowledgeNetworkPage extends ConsumerStatefulWidget {
  final int worldId;

  const KnowledgeNetworkPage({super.key, required this.worldId});

  @override
  ConsumerState<KnowledgeNetworkPage> createState() =>
      _KnowledgeNetworkPageState();
}

class _KnowledgeNetworkPageState extends ConsumerState<KnowledgeNetworkPage> {
  static const double canvasWidth = 3600.0;
  static const double canvasHeight = 2600.0;
  static const Offset canvasCenter = Offset(canvasWidth / 2, canvasHeight / 2);

  final TransformationController _transformController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();

  Map<String, Offset> _positions = {};
  NetworkLayoutMode _currentLayoutMode = NetworkLayoutMode.galaxy;
  KnowledgeNetworkFilterState _filterState =
      const KnowledgeNetworkFilterState();

  String? _selectedNodeId;
  bool _hasInitialLayout = false;
  double _currentScale = 1.0;
  Rect? _visibleWorldRect;
  Size _currentViewport = const Size(1200, 800);

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    // 初始位置居中
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerViewport();
    });
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _centerViewport() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    const initialScale = 0.85;
    final tx = size.width / 2 - canvasCenter.dx * initialScale;
    final ty = size.height / 2 - canvasCenter.dy * initialScale;

    _transformController.value = Matrix4.identity()
      ..storage[0] = initialScale
      ..storage[5] = initialScale
      ..storage[12] = tx
      ..storage[13] = ty;
  }

  void _applyLayout(
    List<NetworkNode> nodes,
    List<NetworkEdge> edges,
    NetworkLayoutMode mode,
  ) {
    final newPositions = KnowledgeNetworkLayoutEngine.computeLayout(
      mode: mode,
      nodes: nodes,
      edges: edges,
      center: canvasCenter,
    );

    setState(() {
      _currentLayoutMode = mode;
      _positions = Map<String, Offset>.from(newPositions);
      _hasInitialLayout = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final graphAsync = ref.watch(knowledgeNetworkGraphProvider(widget.worldId));

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. 大画布交互层
          graphAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text('知识网络加载失败: $err'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.refresh(
                      knowledgeNetworkGraphProvider(widget.worldId),
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
            data: (graphData) {
              if (graphData.nodes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hub_outlined,
                        size: 64,
                        color: (isDark ? Colors.white38 : Colors.black26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '本世界观暂无实体或关联',
                        style: TextStyle(
                          fontSize: 16,
                          color: (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '在百科条目、人物设定或编年史中添加内容即可生成网络',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // 过滤计算
              final filtered = graphData.filter(_filterState);
              final visibleNodes = filtered.visibleNodes;
              final visibleEdges = filtered.visibleEdges;
              final neighborNodeIds = filtered.neighborNodeIds;

              // 初次加载排版
              if (!_hasInitialLayout || _positions.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && (!_hasInitialLayout || _positions.isEmpty)) {
                    _applyLayout(
                      visibleNodes.values.toList(),
                      visibleEdges,
                      _currentLayoutMode,
                    );
                  }
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  _currentViewport = viewport;
                  final visibleRect =
                      _visibleWorldRect ??
                      GraphViewportCulling.computeVisibleWorldRect(
                        transform: _transformController.value,
                        viewportSize: viewport,
                        bufferMargin: 160.0,
                      );
                  final lodLevel = GraphViewportCulling.getLodLevel(
                    _currentScale,
                  );

                  return InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.15,
                    maxScale: 2.5,
                    boundaryMargin: const EdgeInsets.all(2400),
                    constrained: false,
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 背景点击：点击画布空白处，清除聚焦与选中
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedNodeId = null;
                                  if (_filterState.focusedNodeId != null) {
                                    _filterState = _filterState.copyWith(
                                      clearFocusedNode: true,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                          // 背景连线与光晕绘制层
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: KnowledgeNetworkPainter(
                                  edges: visibleEdges,
                                  positions: _positions,
                                  nodes: visibleNodes,
                                  focusedNodeId: _filterState.focusedNodeId,
                                  neighborNodeIds: neighborNodeIds,
                                  isDark: isDark,
                                  scale: _currentScale,
                                  visibleRect: visibleRect,
                                  center: canvasCenter,
                                  showOrbitGuides:
                                      _currentLayoutMode ==
                                      NetworkLayoutMode.galaxy,
                                ),
                              ),
                            ),
                          ),

                          // 实体节点 Widget 交互层 (带视口裁剪与 LOD 过滤)
                          for (final node in visibleNodes.values)
                            if (_positions.containsKey(node.id) &&
                                (node.id == _selectedNodeId ||
                                    node.id == _filterState.focusedNodeId ||
                                    GraphViewportCulling.isNodeVisible(
                                      _positions[node.id]!,
                                      visibleRect,
                                      radius: 45.0,
                                    )))
                              _buildNodeWidget(
                                node: node,
                                pos: _positions[node.id]!,
                                isFocused:
                                    _filterState.focusedNodeId == node.id,
                                isSelected: _selectedNodeId == node.id,
                                isDimmed:
                                    _filterState.focusedNodeId != null &&
                                    !neighborNodeIds.contains(node.id),
                                isDark: isDark,
                                allEdges: visibleEdges,
                                lodLevel: lodLevel,
                              ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 2. 顶部浮动控制工具栏 (AppBar & Tools)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: KnowledgeNetworkToolbar(
              isDark: isDark,
              worldName: worldAsync.valueOrNull?.name,
              currentScale: _currentScale,
              currentLayout: _currentLayoutMode,
              filterState: _filterState,
              searchController: _searchController,
              onSearchChanged: (v) {
                setState(() {
                  _filterState = _filterState.copyWith(searchQuery: v.trim());
                });
              },
              onLayoutChanged: (mode) {
                final graphData = ref
                    .read(knowledgeNetworkGraphProvider(widget.worldId))
                    .valueOrNull;
                if (graphData != null) {
                  final filtered = graphData.filter(_filterState);
                  _applyLayout(
                    filtered.visibleNodes.values.toList(),
                    filtered.visibleEdges,
                    mode,
                  );
                }
              },
              onResetViewport: _centerViewport,
              onOpenFilter: () => _showFilterDialog(context, isDark),
              onClearFilter: () {
                setState(() {
                  _filterState = const KnowledgeNetworkFilterState();
                });
              },
            ),
          ),

          // 3. 底部/右侧实体详情抽屉 (Inspector Drawer)
          if (_selectedNodeId != null)
            graphAsync.maybeWhen(
              data: (graphData) {
                final node = graphData.nodes[_selectedNodeId];
                if (node == null) return const SizedBox.shrink();
                return Positioned(
                  right: 16,
                  bottom: 16,
                  child: KnowledgeNodeInspectorCard(
                    node: node,
                    graphData: graphData,
                    isDark: isDark,
                    isFocused: _filterState.focusedNodeId == node.id,
                    onToggleFocus: () {
                      setState(() {
                        if (_filterState.focusedNodeId == node.id) {
                          _filterState = _filterState.copyWith(
                            clearFocusedNode: true,
                          );
                        } else {
                          _filterState = _filterState.copyWith(
                            focusedNodeId: node.id,
                          );
                        }
                      });
                    },
                    onClose: () => setState(() => _selectedNodeId = null),
                    onOpenDetail: () => _openEntityDetail(node),
                    onSelectTargetNode: (targetId) {
                      setState(() => _selectedNodeId = targetId);
                    },
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  /// 构建节点 Widget (支持 LOD 分级渲染 - PERF-001)
  Widget _buildNodeWidget({
    required NetworkNode node,
    required Offset pos,
    required bool isFocused,
    required bool isSelected,
    required bool isDimmed,
    required bool isDark,
    required List<NetworkEdge> allEdges,
    GraphLodLevel lodLevel = GraphLodLevel.full,
  }) {
    final typeColor = node.type.color;

    // 1. Overview LOD: 轻量微点 (极简 22px，无文字/图片，大幅提升缩放帧率)
    if (lodLevel == GraphLodLevel.overview) {
      const dotSize = 22.0;
      return Positioned(
        left: pos.dx - dotSize / 2,
        top: pos.dy - dotSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _selectedNodeId = node.id;
            });
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDimmed ? 0.22 : 1.0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: typeColor,
                border: Border.all(
                  color: isSelected
                      ? AppColors.brand
                      : (isDark ? Colors.white70 : Colors.black45),
                  width: isSelected || isFocused ? 2.5 : 1.2,
                ),
                boxShadow: isFocused || isSelected
                    ? [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.6),
                          blurRadius: 8,
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

    // 2. Medium LOD: 中等大小几何头像 (42px，省略度数徽章与文本胶囊)
    if (lodLevel == GraphLodLevel.medium) {
      const mediumSize = 42.0;
      return Positioned(
        left: pos.dx - mediumSize / 2,
        top: pos.dy - mediumSize / 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            setState(() {
              _positions[node.id] =
                  (_positions[node.id] ?? pos) + details.delta / _currentScale;
            });
          },
          onTap: () {
            setState(() {
              _selectedNodeId = node.id;
            });
          },
          onDoubleTap: () {
            setState(() {
              if (_filterState.focusedNodeId == node.id) {
                _filterState = _filterState.copyWith(clearFocusedNode: true);
              } else {
                _filterState = _filterState.copyWith(focusedNodeId: node.id);
              }
            });
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDimmed ? 0.22 : 1.0,
            child: Container(
              width: mediumSize,
              height: mediumSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? AppColors.brand
                      : (isFocused
                            ? typeColor
                            : typeColor.withValues(alpha: 0.6)),
                  width: isSelected || isFocused ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFocused ? typeColor : Colors.black).withValues(
                      alpha: isFocused ? 0.35 : 0.12,
                    ),
                    blurRadius: isFocused ? 10 : 4,
                  ),
                ],
              ),
              child: ClipOval(child: _buildNodeAvatar(node, typeColor)),
            ),
          ),
        ),
      );
    }

    // 3. Full LOD: 全量卡片 (64px + 度数徽章 + 文本胶囊)
    const nodeSize = 64.0;

    return Positioned(
      left: pos.dx - nodeSize / 2,
      top: pos.dy - nodeSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            _positions[node.id] =
                (_positions[node.id] ?? pos) + details.delta / _currentScale;
          });
        },
        onTap: () {
          setState(() {
            _selectedNodeId = node.id;
          });
        },
        onDoubleTap: () {
          // 双击快速进入/退出聚焦模式
          setState(() {
            if (_filterState.focusedNodeId == node.id) {
              _filterState = _filterState.copyWith(clearFocusedNode: true);
            } else {
              _filterState = _filterState.copyWith(focusedNodeId: node.id);
            }
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDimmed ? 0.22 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 节点头像 / 图标卡片
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brand
                            : (isFocused
                                  ? typeColor
                                  : typeColor.withValues(alpha: 0.6)),
                        width: isSelected || isFocused ? 3.0 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isFocused ? typeColor : Colors.black)
                              .withValues(alpha: isFocused ? 0.35 : 0.12),
                          blurRadius: isFocused ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(child: _buildNodeAvatar(node, typeColor)),
                  ),

                  // 右上角度数徽章 (Degree Badge)
                  if (node.degree > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${node.degree}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // 节点名称胶囊
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? AppColors.brand
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeAvatar(NetworkNode node, Color typeColor) {
    if (node.imagePath != null &&
        node.imagePath!.isNotEmpty &&
        File(node.imagePath!).existsSync()) {
      return Image.file(
        File(node.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(node.type.icon, color: typeColor, size: 28),
      );
    }
    return Icon(node.type.icon, color: typeColor, size: 28);
  }

  /// 打开对应实体的详情弹窗或页面
  void _openEntityDetail(NetworkNode node) {
    if (node.type == NetworkNodeType.character && node.entity is Character) {
      context.push('/world/${widget.worldId}/character/${node.rawId}');
    } else if (node.entity is LoreEntity) {
      LoreEntityDetailDialog.show(
        context,
        entity: node.entity as LoreEntity,
        onCharacterTap: (c) {
          context.push('/world/${widget.worldId}/character/${c.id}');
        },
        onLoreEntityTap: (le) {
          setState(() {
            _selectedNodeId = 'l_${le.id}';
          });
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已选中【${node.label}】')));
    }
  }

  /// 过滤器配置弹窗
  void _showFilterDialog(BuildContext context, bool isDark) {
    KnowledgeNetworkFilterDialog.show(
      context: context,
      isDark: isDark,
      filterState: _filterState,
      onFilterChanged: (newFilter) {
        setState(() => _filterState = newFilter);
      },
    );
  }
}
