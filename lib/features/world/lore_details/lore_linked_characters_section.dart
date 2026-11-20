import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../core/design/components/oc_avatar.dart';
import '../../../providers/lore_provider.dart';
import 'lore_detail_utils.dart';

/// 百科实体关联角色展示与管理组件 (LORE-002 ~ LORE-006)
class LoreLinkedCharactersSection extends StatelessWidget {
  final LoreEntity entity;
  final List<LoreCharacterMember> members;
  final List<Character> unlinkedChars;
  final void Function(Character character)? onCharacterTap;
  final VoidCallback onAddPressed;

  const LoreLinkedCharactersSection({
    super.key,
    required this.entity,
    required this.members,
    required this.unlinkedChars,
    this.onCharacterTap,
    required this.onAddPressed,
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
                      ? Icons.person_pin_circle_outlined
                      : entity.entityType == 'race'
                      ? Icons.family_restroom_rounded
                      : entity.entityType == 'ability'
                      ? Icons.auto_awesome_rounded
                      : Icons.group_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  entity.entityType == 'faction'
                      ? '组织成员 / 领导层 (${members.length})'
                      : entity.entityType == 'item'
                      ? '持有者与制造传承 (${members.length})'
                      : entity.entityType == 'race'
                      ? '族系角色与血脉成员 (${members.length})'
                      : entity.entityType == 'ability'
                      ? '创造宗师与修习掌握者 (${members.length})'
                      : '关联人物 / 常驻居民 (${members.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
              label: const Text('关联人物'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (members.isEmpty)
          Text(
            entity.entityType == 'faction'
                ? '（暂未关联任何组织成员，点击右上角快速添加）'
                : entity.entityType == 'item'
                ? '（暂无持有者或制造者，点击右上角快速添加）'
                : entity.entityType == 'race'
                ? '（暂未关联族系成员或血脉角色，点击右上角快速添加）'
                : entity.entityType == 'ability'
                ? '（暂无掌握或修习该能力的角色，点击右上角快速添加）'
                : '（暂无常驻或关联人物，点击右上角快速添加）',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Builder(
            builder: (ctx) {
              final sortedMembers = [...members]
                ..sort((a, b) {
                  final isLeaderA = LoreDetailUtils.isLeaderOrOwnerRole(
                    a.relation.role,
                  );
                  final isLeaderB = LoreDetailUtils.isLeaderOrOwnerRole(
                    b.relation.role,
                  );
                  if (isLeaderA && !isLeaderB) return -1;
                  if (!isLeaderA && isLeaderB) return 1;
                  return a.relation.id.compareTo(b.relation.id);
                });

              return Consumer(
                builder: (context, ref, _) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedMembers.map((m) {
                      final char = m.character;
                      final role = m.relation.role;
                      final isLeader = LoreDetailUtils.isLeaderOrOwnerRole(
                        role,
                      );

                      return InputChip(
                        avatar: OcAvatar(
                          avatarPath: char.avatarPath,
                          name: char.name,
                          gender: char.gender,
                          size: 18,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(char.name),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isLeader
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: isLeader
                                    ? Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLeader) ...[
                                    Icon(
                                      entity.entityType == 'item'
                                          ? Icons.diamond_outlined
                                          : entity.entityType == 'race'
                                          ? Icons.diversity_1_rounded
                                          : entity.entityType == 'ability'
                                          ? Icons.military_tech_rounded
                                          : Icons.workspace_premium_rounded,
                                      size: 11,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 2),
                                  ],
                                  Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isLeader
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          if (onCharacterTap != null) {
                            onCharacterTap!(char);
                          }
                        },
                        onDeleted: () async {
                          await ref
                              .read(loreActionsProvider)
                              .unlinkCharacter(
                                loreId: entity.id,
                                characterId: char.id,
                              );
                        },
                        deleteIconColor: theme.colorScheme.outline,
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
