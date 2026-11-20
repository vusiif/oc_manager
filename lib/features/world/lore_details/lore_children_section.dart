import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/lore_provider.dart';

/// 百科实体下级空间、组织分支或衍生体系卡片组 (LORE-002 ~ LORE-006)
class LoreChildrenSection extends StatelessWidget {
  final LoreEntity entity;
  final LoreEntityType typeConfig;
  final List<LoreEntity> children;
  final void Function(LoreEntity child) onChildTap;

  const LoreChildrenSection({
    super.key,
    required this.entity,
    required this.typeConfig,
    required this.children,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 16,
              color: typeConfig.color,
            ),
            const SizedBox(width: 6),
            Text(
              entity.entityType == 'faction'
                  ? '下属分支 / 派系组织 (${children.length})'
                  : entity.entityType == 'race'
                  ? '衍生亚种 / 枝族分支 (${children.length})'
                  : entity.entityType == 'ability'
                  ? '进阶法系 / 衍生体系 (${children.length})'
                  : '下级地理空间 / 辖区建筑 (${children.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children.map((child) {
            return ActionChip(
              avatar: Icon(typeConfig.icon, size: 14, color: typeConfig.color),
              label: Text(child.name),
              onPressed: () => onChildTap(child),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
