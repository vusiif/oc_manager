import 'package:flutter/material.dart';

/// 百科实体标题栏附属类型徽章组件 (LORE-002 ~ LORE-006)
class LoreHeaderBadges extends StatelessWidget {
  final Map<String, dynamic> customFields;

  const LoreHeaderBadges({super.key, required this.customFields});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final factionStatus = customFields['势力现状']?.toString();
    final itemRarity =
        (customFields['品阶稀有度'] ??
                customFields['品阶'] ??
                customFields['品质'] ??
                customFields['稀有度'])
            ?.toString();
    final itemStatus =
        (customFields['持有状态'] ?? customFields['装备状态'] ?? customFields['状态'])
            ?.toString();

    final raceCategory =
        (customFields['种族分类'] ?? customFields['族系'] ?? customFields['类别'])
            ?.toString();
    final raceLifespan = (customFields['平均寿命'] ?? customFields['寿命'])
        ?.toString();

    final abilityRank =
        (customFields['威能阶位'] ??
                customFields['阶位'] ??
                customFields['等级'] ??
                customFields['品质'])
            ?.toString();
    final abilityType =
        (customFields['能力分类'] ??
                customFields['法系分类'] ??
                customFields['派系'] ??
                customFields['分类'])
            ?.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (factionStatus != null && factionStatus.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              factionStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (itemRarity != null && itemRarity.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEC4899).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, size: 11, color: Color(0xFFDB2777)),
                const SizedBox(width: 3),
                Text(
                  itemRarity,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB2777),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (itemStatus != null && itemStatus.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              itemStatus,
              style: TextStyle(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        // LORE-005 种族专属徽章
        if (raceCategory != null && raceCategory.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 11,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 3),
                Text(
                  raceCategory,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (raceLifespan != null && raceLifespan.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '寿命: $raceLifespan',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        // LORE-006 能力专属徽章
        if (abilityRank != null && abilityRank.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 11,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 3),
                Text(
                  abilityRank,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (abilityType != null && abilityType.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              abilityType,
              style: TextStyle(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
