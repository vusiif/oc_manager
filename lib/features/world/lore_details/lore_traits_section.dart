import 'package:flutter/material.dart';
import '../../../providers/lore_provider.dart';

/// 百科实体专有设定特征与属性卡片组 (LORE-002 ~ LORE-006)
class LoreTraitsSection extends StatelessWidget {
  final LoreEntityType typeConfig;
  final Map<String, dynamic> customFields;

  const LoreTraitsSection({
    super.key,
    required this.typeConfig,
    required this.customFields,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final factionCreed =
        (customFields['核心宗旨'] ?? customFields['组织信条'] ?? customFields['宗旨'])
            ?.toString();

    final itemEffect =
        (customFields['特殊效果'] ??
                customFields['特殊威能'] ??
                customFields['特效'] ??
                customFields['效果'])
            ?.toString();
    final itemCost =
        (customFields['使用代价'] ??
                customFields['负面效果'] ??
                customFields['诅咒代价'] ??
                customFields['代价'])
            ?.toString();

    final raceTraits =
        (customFields['生理特征'] ??
                customFields['外貌特征'] ??
                customFields['种族特征'] ??
                customFields['特征'])
            ?.toString();
    final raceHabits =
        (customFields['生活习性'] ?? customFields['社会文化'] ?? customFields['文化习俗'])
            ?.toString();
    final raceFaith =
        (customFields['信仰崇拜'] ?? customFields['信仰'] ?? customFields['图腾'])
            ?.toString();

    final abilityEffect =
        (customFields['生效方式'] ??
                customFields['能力效果'] ??
                customFields['效果'] ??
                customFields['威能'])
            ?.toString();
    final abilityRequirements =
        (customFields['前置条件'] ?? customFields['修行要求'] ?? customFields['前置'])
            ?.toString();
    final abilityCost =
        (customFields['反噬代价'] ??
                customFields['使用代价'] ??
                customFields['代价'] ??
                customFields['限制条件'])
            ?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 势力核心宗旨
        if (factionCreed != null && factionCreed.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeConfig.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: typeConfig.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: typeConfig.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '核心宗旨：$factionCreed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: typeConfig.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 装备特效与威能
        if (itemEffect != null && itemEffect.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '装备特效与威能：$itemEffect',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDB2777),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 装备使用代价与负面效果
        if (itemCost != null && itemCost.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '使用代价与限制：$itemCost',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 种族生理与外貌特征
        if (raceTraits != null && raceTraits.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '生理与外貌特征：$raceTraits',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 种族文化与信仰崇拜
        if ((raceHabits != null && raceHabits.trim().isNotEmpty) ||
            (raceFaith != null && raceFaith.trim().isNotEmpty)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '文化习俗与信仰：${raceHabits ?? ''}${raceHabits != null && raceFaith != null ? ' | 信仰崇拜：' : ''}${raceFaith ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 能力生效方式与威能表现
        if (abilityEffect != null && abilityEffect.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.flash_on_rounded,
                  size: 18,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '生效方式与威能表现：$abilityEffect',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 能力修习前置与反噬代价
        if ((abilityRequirements != null &&
                abilityRequirements.trim().isNotEmpty) ||
            (abilityCost != null && abilityCost.trim().isNotEmpty)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '修习前置与限制代价：${abilityRequirements != null && abilityRequirements.isNotEmpty ? '前置要求: $abilityRequirements' : ''}${abilityRequirements != null && abilityRequirements.isNotEmpty && abilityCost != null && abilityCost.isNotEmpty ? ' | ' : ''}${abilityCost != null && abilityCost.isNotEmpty ? '代价限制: $abilityCost' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 专有结构化键值属性表格
        if (customFields.isNotEmpty) ...[
          Text(
            '专有属性',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: customFields.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
