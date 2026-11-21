import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/util/graph_viewport_culling.dart';
import 'knowledge_network_models.dart';

/// 知识网络单个节点 Widget，支持 LOD 三级分级渲染 (PERF-001)
class KnowledgeNetworkNodeWidget extends StatelessWidget {
  final NetworkNode node;
  final Offset pos;
  final bool isFocused;
  final bool isSelected;
  final bool isDimmed;
  final bool isDark;
  final double currentScale;
  final GraphLodLevel lodLevel;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final void Function(Offset delta)? onPanUpdate;

  const KnowledgeNetworkNodeWidget({
    super.key,
    required this.node,
    required this.pos,
    required this.isFocused,
    required this.isSelected,
    required this.isDimmed,
    required this.isDark,
    required this.currentScale,
    this.lodLevel = GraphLodLevel.full,
    required this.onTap,
    this.onDoubleTap,
    this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = node.type.color;

    if (lodLevel == GraphLodLevel.overview) {
      return _buildOverviewDot(typeColor);
    }

    if (lodLevel == GraphLodLevel.medium) {
      return _buildMediumNode(typeColor);
    }

    return _buildFullNode(typeColor);
  }

  Widget _buildOverviewDot(Color typeColor) {
    const dotSize = 22.0;
    return Positioned(
      left: pos.dx - dotSize / 2,
      top: pos.dy - dotSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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

  Widget _buildMediumNode(Color typeColor) {
    const mediumSize = 42.0;
    return Positioned(
      left: pos.dx - mediumSize / 2,
      top: pos.dy - mediumSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate != null
            ? (details) => onPanUpdate!(details.delta / currentScale)
            : null,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
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
            child: ClipOval(child: _buildNodeAvatar(typeColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildFullNode(Color typeColor) {
    const nodeSize = 64.0;
    return Positioned(
      left: pos.dx - nodeSize / 2,
      top: pos.dy - nodeSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate != null
            ? (details) => onPanUpdate!(details.delta / currentScale)
            : null,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
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
                    child: ClipOval(child: _buildNodeAvatar(typeColor)),
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

  Widget _buildNodeAvatar(Color typeColor) {
    if (node.imagePath != null &&
        node.imagePath!.isNotEmpty &&
        File(node.imagePath!).existsSync()) {
      return Image.file(
        File(node.imagePath!),
        fit: BoxFit.cover,
        cacheWidth: 120,
        cacheHeight: 120,
        errorBuilder: (_, _, _) =>
            Icon(node.type.icon, color: typeColor, size: 28),
      );
    }
    return Icon(node.type.icon, color: typeColor, size: 28);
  }
}
