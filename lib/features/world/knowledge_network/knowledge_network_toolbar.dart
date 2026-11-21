import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import 'knowledge_network_layout_engine.dart';
import 'knowledge_network_models.dart';

class KnowledgeNetworkToolbar extends StatelessWidget {
  final bool isDark;
  final String? worldName;
  final double currentScale;
  final NetworkLayoutMode currentLayout;
  final KnowledgeNetworkFilterState filterState;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<NetworkLayoutMode> onLayoutChanged;
  final VoidCallback onResetViewport;
  final VoidCallback onOpenFilter;
  final VoidCallback onClearFilter;

  const KnowledgeNetworkToolbar({
    super.key,
    required this.isDark,
    required this.worldName,
    required this.currentScale,
    required this.currentLayout,
    required this.filterState,
    required this.searchController,
    required this.onSearchChanged,
    required this.onLayoutChanged,
    required this.onResetViewport,
    required this.onOpenFilter,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 2),
              Text(
                '多维度实体知识图谱 (缩放: ${(currentScale * 100).toInt()}%)',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          // 快速搜索输入框
          SizedBox(
            width: 180,
            height: 36,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜索实体...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 16),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
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
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 10),

          // 布局算法选择
          PopupMenuButton<NetworkLayoutMode>(
            initialValue: currentLayout,
            tooltip: '排布模式',
            icon: Icon(currentLayout.icon, color: AppColors.brand),
            onSelected: onLayoutChanged,
            itemBuilder: (context) => [
              for (final mode in NetworkLayoutMode.values)
                PopupMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        mode.icon,
                        size: 18,
                        color: mode == currentLayout ? AppColors.brand : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: mode == currentLayout ? AppColors.brand : null,
                          fontWeight: mode == currentLayout
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // 过滤器按钮
          IconButton(
            icon: Badge(
              isLabelVisible:
                  filterState.searchQuery.isNotEmpty ||
                  filterState.focusedNodeId != null ||
                  filterState.enabledNodeTypes.length <
                      NetworkNodeType.values.length ||
                  filterState.enabledEdgeTypes.length <
                      NetworkEdgeType.values.length,
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: '图谱维度过滤',
            onPressed: onOpenFilter,
          ),

          // 视口居中重置按钮
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: '视口重置居中',
            onPressed: onResetViewport,
          ),
        ],
      ),
    );
  }
}
