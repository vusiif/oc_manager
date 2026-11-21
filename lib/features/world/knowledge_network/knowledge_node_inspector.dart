import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import 'knowledge_network_models.dart';

class KnowledgeNodeAvatar extends StatelessWidget {
  final NetworkNode node;
  final Color typeColor;

  const KnowledgeNodeAvatar({
    super.key,
    required this.node,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
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
}

class KnowledgeNodeInspectorCard extends StatelessWidget {
  final NetworkNode node;
  final KnowledgeNetworkGraphData graphData;
  final bool isDark;
  final bool isFocused;
  final VoidCallback onToggleFocus;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final ValueChanged<String> onSelectTargetNode;

  const KnowledgeNodeInspectorCard({
    super.key,
    required this.node,
    required this.graphData,
    required this.isDark,
    required this.isFocused,
    required this.onToggleFocus,
    required this.onClose,
    required this.onOpenDetail,
    required this.onSelectTargetNode,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = node.type.color;
    // isFocused passed via param

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
                child: ClipOval(
                  child: KnowledgeNodeAvatar(node: node, typeColor: typeColor),
                ),
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
                onPressed: () => onClose(),
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
                  onPressed: onToggleFocus,
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
                  onPressed: () => onOpenDetail(),
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
                    onSelectTargetNode(targetId);
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
}
