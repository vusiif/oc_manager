import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../design_tokens.dart';
import 'oc_avatar.dart';

/// 统一 OC 人设卡片组件
class OcCard extends StatefulWidget {
  final Character character;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onPinToggle;

  const OcCard({
    super.key,
    required this.character,
    this.onTap,
    this.onFavoriteToggle,
    this.onPinToggle,
  });

  @override
  State<OcCard> createState() => _OcCardState();
}

class _OcCardState extends State<OcCard> {
  bool _isHovered = false;

  Color _getGenderColor(String gender) {
    if (gender == '男') return AppColors.genderMale;
    if (gender == '女') return AppColors.genderFemale;
    if (gender.isNotEmpty) return AppColors.genderOther;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final character = widget.character;
    final isDraft = character.status == 1;

    final cardBg = isDark
        ? (_isHovered ? AppColors.darkBorder : AppColors.darkSurface)
        : (_isHovered ? AppColors.brandLight.withValues(alpha: 0.3) : AppColors.lightSurface);

    final borderColor = isDark
        ? (_isHovered ? AppColors.brand.withValues(alpha: 0.5) : AppColors.darkBorder)
        : (_isHovered ? AppColors.brand.withValues(alpha: 0.35) : AppColors.lightBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: borderColor, width: _isHovered ? 1.2 : 1.0),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: AppRadius.radiusMd,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                // 头像徽章
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OcAvatar(
                      avatarPath: character.avatarPath,
                      name: character.name,
                      gender: character.gender,
                      size: 40,
                      isDraft: isDraft,
                    ),
                    if (character.gender.isNotEmpty)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            character.gender == '男'
                                ? Icons.male
                                : (character.gender == '女'
                                    ? Icons.female
                                    : Icons.transgender),
                            size: 13,
                            color: _getGenderColor(character.gender),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),

                // 核心信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              character.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDraft) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: AppRadius.radiusSm,
                              ),
                              child: const Text(
                                '草稿',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (character.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          character.description.replaceAll('\n', ' '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 操作按钮组
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onFavoriteToggle != null)
                      IconButton(
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          character.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: character.isFavorite ? Colors.amber : Colors.grey,
                        ),
                        tooltip: character.isFavorite ? '取消收藏' : '收藏',
                        onPressed: widget.onFavoriteToggle,
                      ),
                    if (widget.onPinToggle != null)
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          character.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          color: character.isPinned ? AppColors.brand : Colors.grey,
                        ),
                        tooltip: character.isPinned ? '取消置顶' : '置顶',
                        onPressed: widget.onPinToggle,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
