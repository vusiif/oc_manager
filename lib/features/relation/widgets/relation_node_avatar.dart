import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/design/components/oc_avatar.dart';
import '../../../core/design/design_tokens.dart';
import '../../../data/database/app_database.dart';

/// Builds a Milanote-inspired character card avatar for graph nodes and sidebars.
/// Supports high-res user-uploaded portraits via [OcAvatar] with smooth clipping,
/// crisp semantic border rings, and rich gradient initial fallbacks.
Widget buildCharacterAvatar({
  required Character character,
  required double size,
  required Color color,
  bool isHighlighted = false,
  bool isConnectTarget = false,
}) {
  final genderColor = character.status == 1
      ? Colors.grey
      : (character.gender == '男'
            ? AppColors.genderMale
            : (character.gender == '女'
                  ? AppColors.genderFemale
                  : AppColors.genderOther));

  final activeColor = (isHighlighted || isConnectTarget)
      ? AppColors.brand
      : (character.status == 1 ? Colors.grey : genderColor);

  final isMale = character.gender == '男';
  final shape = isMale ? BoxShape.rectangle : BoxShape.circle;

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: shape,
      borderRadius: isMale ? BorderRadius.circular(8) : null,
      border: Border.all(
        color: activeColor,
        width: (isHighlighted || isConnectTarget) ? 2.5 : 2.0,
      ),
      boxShadow: [
        BoxShadow(
          color:
              (isHighlighted || isConnectTarget
                      ? AppColors.brand
                      : Colors.black)
                  .withValues(
                    alpha: isHighlighted || isConnectTarget ? 0.35 : 0.16,
                  ),
          blurRadius: (isHighlighted || isConnectTarget) ? 8 : 4,
          offset: const Offset(0, 1.5),
        ),
      ],
    ),
    child: OcAvatar(
      avatarPath: character.avatarPath,
      name: character.name,
      gender: character.gender,
      size: size - 4, // 扣除两侧 2px 边框
      shape: shape,
      borderRadius: isMale ? 6.0 : 0.0,
      isDraft: character.status == 1,
      solidFallback: true,
    ),
  );
}

/// Fallback / legacy shape builder preserving geometric shape signatures
/// while supporting avatarPath when present.
Widget buildGenderShape(
  String gender,
  double size,
  Color color,
  String label, {
  String? avatarPath,
}) {
  final half = size;
  final text = label.isNotEmpty ? label[0] : '?';
  final isMale = gender == '男';
  final shape = isMale ? BoxShape.rectangle : BoxShape.circle;

  if (avatarPath != null && avatarPath.trim().isNotEmpty) {
    return Container(
      width: half * 2,
      height: half * 2,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: isMale ? BorderRadius.circular(8) : null,
        border: Border.all(color: color, width: 2.0),
      ),
      child: OcAvatar(
        avatarPath: avatarPath,
        name: label,
        gender: gender,
        size: half * 2 - 4,
        shape: shape,
        borderRadius: isMale ? 6.0 : 0.0,
        solidFallback: true,
      ),
    );
  }

  if (gender == '男') {
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

/// 侧边栏条目 (Milanote / AppFlowy 风格卡片)
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
    final isDark = theme.brightness == Brightness.dark;
    final color = character.status == 1
        ? Colors.grey
        : theme.colorScheme.primary;

    return Opacity(
      opacity: placed ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            buildCharacterAvatar(character: character, size: 32, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    character.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: placed ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (character.gender.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      character.gender,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (placed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '已放置',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              )
            else
              const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
