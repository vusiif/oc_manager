import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/lore_provider.dart';

/// 百科实体关联人物与关联实体弹窗交互 (LORE-002 ~ LORE-006)
class LoreRelationDialogs {
  /// 弹出添加关联人物弹窗 (LORE-002 & LORE-003)
  static void showAddCharacterDialog(
    BuildContext context,
    WidgetRef ref, {
    required LoreEntity entity,
    required List<Character> availableCharacters,
  }) {
    int? selectedCharId = availableCharacters.isNotEmpty
        ? availableCharacters.first.id
        : null;
    final roleController = TextEditingController(
      text: entity.entityType == 'faction'
          ? '成员'
          : entity.entityType == 'item'
          ? '持有者'
          : entity.entityType == 'race'
          ? '纯血统'
          : entity.entityType == 'ability'
          ? '精通修习'
          : '常驻',
    );

    final suggestedRoles = entity.entityType == 'faction'
        ? const ['领袖', '副会长', '元老', '军团长', '核心精英', '正式成员', '见习生', '情报特工']
        : entity.entityType == 'item'
        ? const ['当前持有者', '制造锻造者', '初代佩戴者', '守护使者', '契约者', '历史持有者']
        : entity.entityType == 'race'
        ? const ['纯血统', '混血后裔', '先祖始祖', '皇室血脉', '异化变种', '流亡者']
        : entity.entityType == 'ability'
        ? const ['创造者/宗师', '巅峰大成者', '核心修习者', '初窥门径', '血脉传承者', '失传封印']
        : const ['统治者', '城主', '常驻居民', '出生地', '守护者', '隐居者', '流浪过客'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text('关联人物到【${entity.name}】'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: availableCharacters.isEmpty
                  ? const Text('当前世界观暂无未关联角色，请先创建角色。')
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedCharId,
                            decoration: const InputDecoration(
                              labelText: '选择人物 *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: availableCharacters.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedCharId = val);
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: roleController,
                            maxLength: 50,
                            decoration: InputDecoration(
                              labelText: entity.entityType == 'faction'
                                  ? '组织身份 / 职务'
                                  : entity.entityType == 'item'
                                  ? '装备角色 / 身份'
                                  : '地理关联 / 身份',
                              hintText: entity.entityType == 'faction'
                                  ? '如：领袖、副会长、军团长、成员'
                                  : entity.entityType == 'item'
                                  ? '如：当前持有者、锻造工匠、守护者'
                                  : '如：出生地、统治者、常驻居民、隐居者',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '常用职务推荐：',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: suggestedRoles.map((role) {
                              return ActionChip(
                                label: Text(
                                  role,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  roleController.text = role;
                                },
                              );
                            }).toList(),
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
              if (availableCharacters.isNotEmpty)
                FilledButton(
                  onPressed: selectedCharId == null
                      ? null
                      : () async {
                          final role = roleController.text.trim().isEmpty
                              ? (entity.entityType == 'faction' ? '成员' : '常驻')
                              : roleController.text.trim();
                          try {
                            await ref
                                .read(loreActionsProvider)
                                .linkCharacter(
                                  worldId: entity.worldId,
                                  loreId: entity.id,
                                  characterId: selectedCharId!,
                                  role: role,
                                );
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(
                                  content: Text('关联人物失败: $e'),
                                  backgroundColor: Theme.of(
                                    dialogCtx,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('添加关联'),
                ),
            ],
          );
        },
      ),
    ).then((_) => roleController.dispose());
  }

  /// 弹出建立外交/地缘关系弹窗 (LORE-003: 势力间同盟/敌对/从属/贸易)
  static void showAddEntityRelationDialog(
    BuildContext context,
    WidgetRef ref, {
    required LoreEntity entity,
    required List<LoreEntity> availableEntities,
  }) {
    if (availableEntities.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前世界观暂无其他可建立关系的百科实体/组织。')));
      return;
    }

    int selectedTargetId = availableEntities.first.id;
    final isItem = entity.entityType == 'item';
    final isRace = entity.entityType == 'race';
    final isAbility = entity.entityType == 'ability';

    String selectedRelationType = isItem
        ? '存放于/封印地'
        : isRace
        ? '发源故土/栖息地'
        : isAbility
        ? '附魔载体/专属法宝'
        : '同盟';
    bool isBidirectional = true;
    final noteController = TextEditingController();

    final relationTypes = isItem
        ? const ['存放于/封印地', '归属于/宗派圣物', '共鸣套装/羁绊', '制造材料/源石', '克制对立', '同盟']
        : isRace
        ? const ['发源故土/栖息地', '主要聚居地', '同盟友好', '世代宿敌', '附庸朝贡', '起源分支']
        : isAbility
        ? const ['附魔载体/专属法宝', '相生衍生', '相克克制', '前置进阶体系', '宗派独占秘传', '克制对立']
        : const ['同盟', '敌对', '从属/附属', '贸易伙伴', '休战/中立', '宗主国'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isItem
                      ? Icons.hub_outlined
                      : isRace
                      ? Icons.diversity_3_outlined
                      : isAbility
                      ? Icons.auto_awesome
                      : Icons.share_arrival_time_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isItem
                      ? '建立归属与地缘关联【${entity.name}】'
                      : isRace
                      ? '建立种族关系【${entity.name}】'
                      : isAbility
                      ? '建立能力羁绊与克制【${entity.name}】'
                      : '建立外交关系【${entity.name}】',
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedTargetId,
                      decoration: InputDecoration(
                        labelText: isItem || isRace || isAbility
                            ? '目标百科实体 (组织/地点/装备/种族/能力) *'
                            : '目标组织 / 势力 *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: availableEntities.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.id,
                          child: Text(e.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTargetId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRelationType,
                      decoration: const InputDecoration(
                        labelText: '关系类型 *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: relationTypes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRelationType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: const Text('双向关系 (相互生效)'),
                      subtitle: const Text('开启后在双方主页均会显示此关系'),
                      value: isBidirectional,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => isBidirectional = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: noteController,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: '外交条约 / 背景备注',
                        hintText: '如：签署《百年互不侵犯条约》、争夺圣遗物引发宿怨',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
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
                  try {
                    await ref
                        .read(loreActionsProvider)
                        .linkEntityRelation(
                          worldId: entity.worldId,
                          fromLoreId: entity.id,
                          toLoreId: selectedTargetId,
                          relationType: selectedRelationType,
                          isBidirectional: isBidirectional,
                          note: noteController.text.trim(),
                        );
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  } catch (e) {
                    if (dialogCtx.mounted) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(
                          content: Text('建立实体关系失败: $e'),
                          backgroundColor: Theme.of(
                            dialogCtx,
                          ).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('确定建立'),
              ),
            ],
          );
        },
      ),
    ).then((_) => noteController.dispose());
  }
}
