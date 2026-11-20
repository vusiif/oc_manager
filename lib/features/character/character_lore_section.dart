import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/lore_provider.dart';
import '../world/lore_entity_detail_dialog.dart';

/// 角色所属势力、地点归属、随身装备、种族与能力展示区块 (LORE-002 ~ LORE-006)
class CharacterLoreSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterLoreSection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  void _showLinkLoreDialog(
    BuildContext context,
    WidgetRef ref,
    List<LoreEntity> allLores,
    Set<int> alreadyLinkedLoreIds,
  ) {
    final available = allLores
        .where((l) => !alreadyLinkedLoreIds.contains(l.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前世界观暂无未关联的百科条目或势力。')));
      return;
    }

    int selectedLoreId = available.first.id;
    final roleController = TextEditingController(text: '成员');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedLore = available.firstWhere(
            (l) => l.id == selectedLoreId,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text('关联百科设定 (势力 / 地点 / 装备 / 种族 / 能力)'),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedLoreId,
                      decoration: const InputDecoration(
                        labelText: '选择百科实体 / 组织 / 装备 / 种族 / 能力 *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: available.map((l) {
                        final typeConfig = LoreEntityType.fromKey(l.entityType);
                        return DropdownMenuItem<int>(
                          value: l.id,
                          child: Row(
                            children: [
                              Icon(
                                typeConfig.icon,
                                size: 16,
                                color: typeConfig.color,
                              ),
                              const SizedBox(width: 6),
                              Text('${l.name} (${typeConfig.label})'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedLoreId = val;
                            final newLore = available.firstWhere(
                              (l) => l.id == val,
                            );
                            if (newLore.entityType == 'faction' &&
                                (roleController.text == '常驻' ||
                                    roleController.text == '持有者' ||
                                    roleController.text == '纯血统' ||
                                    roleController.text == '精通修习')) {
                              roleController.text = '成员';
                            } else if (newLore.entityType == 'location' &&
                                (roleController.text == '成员' ||
                                    roleController.text == '持有者' ||
                                    roleController.text == '纯血统' ||
                                    roleController.text == '精通修习')) {
                              roleController.text = '常驻';
                            } else if (newLore.entityType == 'item' &&
                                (roleController.text == '成员' ||
                                    roleController.text == '常驻' ||
                                    roleController.text == '纯血统' ||
                                    roleController.text == '精通修习')) {
                              roleController.text = '持有者';
                            } else if (newLore.entityType == 'race' &&
                                (roleController.text == '成员' ||
                                    roleController.text == '常驻' ||
                                    roleController.text == '持有者' ||
                                    roleController.text == '精通修习')) {
                              roleController.text = '纯血统';
                            } else if (newLore.entityType == 'ability' &&
                                (roleController.text == '成员' ||
                                    roleController.text == '常驻' ||
                                    roleController.text == '持有者' ||
                                    roleController.text == '纯血统')) {
                              roleController.text = '精通修习';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: roleController,
                      decoration: InputDecoration(
                        labelText: selectedLore.entityType == 'faction'
                            ? '组织身份 / 职务'
                            : selectedLore.entityType == 'item'
                            ? '佩戴角色 / 身份'
                            : selectedLore.entityType == 'race'
                            ? '种族血脉 / 身份'
                            : selectedLore.entityType == 'ability'
                            ? '能力掌握 / 境界'
                            : '地理关联 / 身份',
                        hintText: selectedLore.entityType == 'faction'
                            ? '如：领袖、副会长、军团长、成员'
                            : selectedLore.entityType == 'item'
                            ? '如：持有者、锻造工匠、守护使者'
                            : selectedLore.entityType == 'race'
                            ? '如：纯血统、混血后裔、始祖、王室血脉'
                            : selectedLore.entityType == 'ability'
                            ? '如：创造宗师、大成境界、精通修习、血脉传承'
                            : '如：出生地、常驻、领主、隐士',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final role = roleController.text.trim().isEmpty
                      ? (selectedLore.entityType == 'faction'
                            ? '成员'
                            : selectedLore.entityType == 'item'
                            ? '持有者'
                            : selectedLore.entityType == 'race'
                            ? '纯血统'
                            : selectedLore.entityType == 'ability'
                            ? '精通修习'
                            : '常驻')
                      : roleController.text.trim();
                  await ref
                      .read(loreActionsProvider)
                      .linkCharacter(
                        worldId: worldId,
                        loreId: selectedLoreId,
                        characterId: characterId,
                        role: role,
                      );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                },
                child: const Text('关联'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final affiliationsAsync = ref.watch(characterLoresProvider(characterId));
    final affiliations = affiliationsAsync.valueOrNull ?? [];

    final allLoresAsync = ref.watch(loreEntitiesByWorldProvider(worldId));
    final allLores = allLoresAsync.valueOrNull ?? [];
    final alreadyLinkedIds = affiliations.map((a) => a.lore.id).toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '所属势力与地点归属 / 随身装备 / 种族与能力 (${affiliations.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showLinkLoreDialog(
                    context,
                    ref,
                    allLores,
                    alreadyLinkedIds,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('关联'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (affiliations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    '尚未归属任何势力、种族、地点、装备或能力，点击右上角快速关联。',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: affiliations.map((aff) {
                  final lore = aff.lore;
                  final rel = aff.relation;
                  final typeConfig = LoreEntityType.fromKey(lore.entityType);

                  return InputChip(
                    avatar: Icon(
                      typeConfig.icon,
                      size: 16,
                      color: typeConfig.color,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lore.name),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: typeConfig.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rel.role,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeConfig.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      LoreEntityDetailDialog.show(context, entity: lore);
                    },
                    onDeleted: () async {
                      await ref
                          .read(loreActionsProvider)
                          .unlinkCharacter(
                            loreId: lore.id,
                            characterId: characterId,
                          );
                    },
                    deleteIconColor: theme.colorScheme.outline,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
