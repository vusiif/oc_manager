import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/lore_provider.dart';
import 'lore_detail_utils.dart';

/// 百科实体间外交、地缘与克制关系展示与管理组件 (LORE-003 ~ LORE-006)
class LoreEntityRelationsSection extends StatelessWidget {
  final LoreEntity entity;
  final List<LoreEntityRelationItem> relations;
  final void Function(LoreEntity targetEntity) onEntityTap;
  final VoidCallback onAddRelationPressed;

  const LoreEntityRelationsSection({
    super.key,
    required this.entity,
    required this.relations,
    required this.onEntityTap,
    required this.onAddRelationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  entity.entityType == 'item'
                      ? Icons.hub_outlined
                      : entity.entityType == 'race'
                      ? Icons.share_location_rounded
                      : entity.entityType == 'ability'
                      ? Icons.alt_route_rounded
                      : Icons.handshake_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  entity.entityType == 'faction'
                      ? '势力外交与地缘关系 (${relations.length})'
                      : entity.entityType == 'item'
                      ? '归属势力与存放地缘 (${relations.length})'
                      : entity.entityType == 'race'
                      ? '发源故土、宿敌与同盟关系 (${relations.length})'
                      : entity.entityType == 'ability'
                      ? '能力载体、衍生与克制关系 (${relations.length})'
                      : '地缘关联与连接 (${relations.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onAddRelationPressed,
              icon: const Icon(Icons.add_link_rounded, size: 14),
              label: const Text('建立关系'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (relations.isEmpty)
          Text(
            entity.entityType == 'faction'
                ? '（暂未与其他势力建立外交关系，如盟友、敌对或附属）'
                : entity.entityType == 'item'
                ? '（暂未设置存放地或所属组织，如：存放于某圣殿、归属于某教廷）'
                : entity.entityType == 'race'
                ? '（暂未设置发源故土、聚居地或宿敌同盟，如：发源于某森林、世仇某帝国）'
                : entity.entityType == 'ability'
                ? '（暂未设置能力载体或相生相克，如：附魔于某圣剑、克制暗影魔法）'
                : '（暂无实体地缘关联）',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Consumer(
            builder: (context, ref, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: relations.map((relItem) {
                  final other = relItem.otherEntity;
                  final rel = relItem.relation;
                  final relColor = LoreDetailUtils.getRelationColor(
                    rel.relationType,
                  );
                  final relIcon = LoreDetailUtils.getRelationIcon(
                    rel.relationType,
                  );

                  return InputChip(
                    avatar: Icon(relIcon, size: 16, color: relColor),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(other.name),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: relColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: relColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            rel.relationType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: relColor,
                            ),
                          ),
                        ),
                        if (rel.note.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: rel.note,
                            child: Icon(
                              Icons.info_outline,
                              size: 13,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onPressed: () => onEntityTap(other),
                    onDeleted: () async {
                      await ref
                          .read(loreActionsProvider)
                          .unlinkEntityRelation(rel.id);
                    },
                    deleteIconColor: theme.colorScheme.outline,
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
