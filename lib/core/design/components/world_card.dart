import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../design_tokens.dart';

/// Unified AppFlowy-inspired card component for world overview hubs.
class WorldCard extends StatefulWidget {
  final World world;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorldCard({
    super.key,
    required this.world,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<WorldCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final world = widget.world;

    final cardBg = isDark
        ? (_isHovered ? AppColors.darkBorder : AppColors.darkSurface)
        : (_isHovered
              ? AppColors.brandLight.withValues(alpha: 0.3)
              : AppColors.lightSurface);

    final borderColor = isDark
        ? (_isHovered
              ? AppColors.brand.withValues(alpha: 0.55)
              : AppColors.darkBorder)
        : (_isHovered
              ? AppColors.brand.withValues(alpha: 0.4)
              : AppColors.lightBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: borderColor, width: _isHovered ? 1.2 : 1.0),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: AppRadius.radiusLg,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              world.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (world.isLocked) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: '已锁定',
                              child: Icon(
                                Icons.lock_rounded,
                                size: 15,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: '编辑世界观',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: '删除世界观',
                      icon: Icon(
                        Icons.delete_outline,
                        color: _isHovered ? AppColors.danger : null,
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    (world.description != null &&
                            world.description!.trim().isNotEmpty)
                        ? world.description!
                        : '暂无世界观简介，点击进入编辑人物、百科与关系图谱。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                          (world.description != null &&
                              world.description!.trim().isNotEmpty)
                          ? (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)
                          : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
