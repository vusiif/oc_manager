import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/world_provider.dart';
import '../lore_entity_detail_dialog.dart';
import 'knowledge_network_layout_engine.dart';
import 'knowledge_network_painter.dart';
import 'knowledge_network_provider.dart';

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
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
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
                              center: canvasCenter,
                              showOrbitGuides:
                                  _currentLayoutMode ==
                                  NetworkLayoutMode.galaxy,
                            ),
                          ),
                        ),
                      ),

                      // 实体节点 Widget 交互层
                      for (final node in visibleNodes.values)
                        if (_positions.containsKey(node.id))
                          _buildNodeWidget(
                            node: node,
                            pos: _positions[node.id]!,
                            isFocused: _filterState.focusedNodeId == node.id,
                            isSelected: _selectedNodeId == node.id,
                            isDimmed:
                                _filterState.focusedNodeId != null &&
                                !neighborNodeIds.contains(node.id),
                            isDark: isDark,
                            allEdges: visibleEdges,
                          ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. 顶部浮动控制工具栏 (AppBar & Tools)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopToolbar(isDark, worldAsync.valueOrNull?.name),
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
                  child: _buildNodeInspectorCard(
                    node: node,
                    graphData: graphData,
                    isDark: isDark,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  /// 构建节点 Widget
  Widget _buildNodeWidget({
    required NetworkNode node,
    required Offset pos,
    required bool isFocused,
    required bool isSelected,
    required bool isDimmed,
    required bool isDark,
    required List<NetworkEdge> allEdges,
  }) {
    const nodeSize = 64.0;
    final typeColor = node.type.color;

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

  /// 顶部控制工具栏
  Widget _buildTopToolbar(bool isDark, String? worldName) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: '返回',
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),

          // 标题与世界观名称
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    '知识网络 · 全景图谱',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      worldName ?? 'World',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'LORE-007 实体全息图与多维关联拓扑',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),

          // 搜索框
          SizedBox(
            width: 180,
            height: 36,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索实体...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filterState = _filterState.copyWith(
                              searchQuery: '',
                            );
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                setState(() {
                  _filterState = _filterState.copyWith(searchQuery: val.trim());
                });
              },
            ),
          ),
          const SizedBox(width: 10),

          // 布局算法选择
          PopupMenuButton<NetworkLayoutMode>(
            initialValue: _currentLayoutMode,
            tooltip: '排布模式',
            icon: Icon(_currentLayoutMode.icon, color: AppColors.brand),
            onSelected: (mode) {
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
            itemBuilder: (context) => [
              for (final mode in NetworkLayoutMode.values)
                PopupMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(mode.icon, size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Text(mode.label),
                    ],
                  ),
                ),
            ],
          ),

          // 过滤器弹窗按钮
          IconButton(
            icon: Badge(
              isLabelVisible:
                  _filterState.enabledNodeTypes.length <
                      NetworkNodeType.values.length ||
                  _filterState.enabledEdgeTypes.length <
                      NetworkEdgeType.values.length,
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: '图谱维度过滤',
            onPressed: () => _showFilterDialog(context, isDark),
          ),

          // 视口居中重置按钮
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: '视口重置居中',
            onPressed: _centerViewport,
          ),
        ],
      ),
    );
  }

  /// 节点详情卡片 (Inspector Card)
  Widget _buildNodeInspectorCard({
    required NetworkNode node,
    required KnowledgeNetworkGraphData graphData,
    required bool isDark,
  }) {
    final typeColor = node.type.color;
    final isFocused = _filterState.focusedNodeId == node.id;

    // 查找与该节点相连的所有边
    final connectedEdges = graphData.edges
        .where((e) => e.fromId == node.id || e.toId == node.id)
        .toList();

    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：类型图标、名称、关闭按钮
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor.withValues(alpha: 0.15),
                  border: Border.all(color: typeColor, width: 2),
                ),
                child: ClipOval(child: _buildNodeAvatar(node, typeColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            node.type.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${node.degree} 个关联',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedNodeId = null),
              ),
            ],
          ),

          if (node.subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              node.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 20),

          // 操作按钮组
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isFocused
                        ? Icons.filter_center_focus
                        : Icons.center_focus_weak,
                    size: 16,
                  ),
                  label: Text(isFocused ? '取消聚焦' : '聚焦网络'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isFocused) {
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('详情卡片'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.brand,
                  ),
                  onPressed: () => _openEntityDetail(node),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            '关联脉络 (${connectedEdges.length})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // 连线列表
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: connectedEdges.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
              itemBuilder: (context, index) {
                final edge = connectedEdges[index];
                final isOutgoing = edge.fromId == node.id;
                final targetId = isOutgoing ? edge.toId : edge.fromId;
                final targetNode = graphData.nodes[targetId];

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _selectedNodeId = targetId;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOutgoing
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: 14,
                          color: edge.type.color,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: edge.type.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            edge.label.isNotEmpty
                                ? edge.label
                                : edge.type.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: edge.type.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            targetNode?.label ?? targetId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, color: AppColors.brand),
                  const SizedBox(width: 8),
                  const Text('网络维度过滤'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 节点类型过滤
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '实体类型 (Nodes)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                final all = Set<NetworkNodeType>.from(
                                  NetworkNodeType.values,
                                );
                                final isAll =
                                    _filterState.enabledNodeTypes.length ==
                                    all.length;
                                setState(() {
                                  _filterState = _filterState.copyWith(
                                    enabledNodeTypes: isAll ? {} : all,
                                  );
                                });
                              });
                            },
                            child: Text(
                              _filterState.enabledNodeTypes.length ==
                                      NetworkNodeType.values.length
                                  ? '取消全选'
                                  : '全选',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final t in NetworkNodeType.values)
                            FilterChip(
                              avatar: Icon(t.icon, size: 14, color: t.color),
                              label: Text(t.label),
                              selected: _filterState.enabledNodeTypes.contains(
                                t,
                              ),
                              selectedColor: t.color.withValues(alpha: 0.2),
                              onSelected: (selected) {
                                setDialogState(() {
                                  final newSet = Set<NetworkNodeType>.from(
                                    _filterState.enabledNodeTypes,
                                  );
                                  if (selected) {
                                    newSet.add(t);
                                  } else {
                                    newSet.remove(t);
                                  }
                                  setState(() {
                                    _filterState = _filterState.copyWith(
                                      enabledNodeTypes: newSet,
                                    );
                                  });
                                });
                              },
                            ),
                        ],
                      ),

                      const Divider(height: 24),

                      // 边类型过滤
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '关联类型 (Edges)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                final all = Set<NetworkEdgeType>.from(
                                  NetworkEdgeType.values,
                                );
                                final isAll =
                                    _filterState.enabledEdgeTypes.length ==
                                    all.length;
                                setState(() {
                                  _filterState = _filterState.copyWith(
                                    enabledEdgeTypes: isAll ? {} : all,
                                  );
                                });
                              });
                            },
                            child: Text(
                              _filterState.enabledEdgeTypes.length ==
                                      NetworkEdgeType.values.length
                                  ? '取消全选'
                                  : '全选',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final et in NetworkEdgeType.values)
                            FilterChip(
                              label: Text(et.label),
                              selected: _filterState.enabledEdgeTypes.contains(
                                et,
                              ),
                              selectedColor: et.color.withValues(alpha: 0.2),
                              onSelected: (selected) {
                                setDialogState(() {
                                  final newSet = Set<NetworkEdgeType>.from(
                                    _filterState.enabledEdgeTypes,
                                  );
                                  if (selected) {
                                    newSet.add(et);
                                  } else {
                                    newSet.remove(et);
                                  }
                                  setState(() {
                                    _filterState = _filterState.copyWith(
                                      enabledEdgeTypes: newSet,
                                    );
                                  });
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterState = const KnowledgeNetworkFilterState();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('重置全部'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('完成'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
