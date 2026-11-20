import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/lore_provider.dart';
import '../../providers/revision_provider.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../core/util/wiki_link_parser.dart';
import 'lore_cover_image.dart';
import 'lore_entity_dialog.dart';
import 'revision_history_dialog.dart';

class LoreEntityDetailDialog extends ConsumerWidget {
  final LoreEntity entity;
  final void Function(Character character)? onCharacterTap;
  final void Function(LoreEntity loreEntity)? onLoreEntityTap;

  const LoreEntityDetailDialog({
    super.key,
    required this.entity,
    this.onCharacterTap,
    this.onLoreEntityTap,
  });

  static Future<void> show(
    BuildContext context, {
    required LoreEntity entity,
    void Function(Character character)? onCharacterTap,
    void Function(LoreEntity loreEntity)? onLoreEntityTap,
  }) {
    return showDialog(
      context: context,
      builder: (_) => LoreEntityDetailDialog(
        entity: entity,
        onCharacterTap: onCharacterTap,
        onLoreEntityTap: onLoreEntityTap,
      ),
    );
  }

  static bool _isLeaderOrOwnerRole(String role) {
    final lower = role.toLowerCase();
    return role.contains('领袖') ||
        role.contains('会长') ||
        role.contains('团长') ||
        role.contains('首领') ||
        role.contains('宗主') ||
        role.contains('掌门') ||
        role.contains('元首') ||
        role.contains('司令') ||
        role.contains('持有') ||
        role.contains('佩戴') ||
        role.contains('契约') ||
        role.contains('主人') ||
        role.contains('锻造') ||
        role.contains('制造') ||
        role.contains('始祖') ||
        role.contains('先祖') ||
        role.contains('纯血') ||
        role.contains('皇室') ||
        role.contains('宗师') ||
        role.contains('大成') ||
        role.contains('巅峰') ||
        lower.contains('ancestor') ||
        lower.contains('pureblood') ||
        lower.contains('master') ||
        lower.contains('leader') ||
        lower.contains('owner') ||
        lower.contains('wielder') ||
        lower.contains('creator') ||
        lower.contains('chief') ||
        lower.contains('boss');
  }

  static Color _getRelationColor(String relationType) {
    if (relationType.contains('同盟') || relationType.contains('盟友')) {
      return const Color(0xFF10B981);
    }
    if (relationType.contains('敌对') ||
        relationType.contains('交战') ||
        relationType.contains('宿敌') ||
        relationType.contains('克制')) {
      return const Color(0xFFEF4444);
    }
    if (relationType.contains('从属') ||
        relationType.contains('附属') ||
        relationType.contains('宗主') ||
        relationType.contains('归属') ||
        relationType.contains('圣物')) {
      return const Color(0xFF3B82F6);
    }
    if (relationType.contains('贸易') ||
        relationType.contains('商业') ||
        relationType.contains('合作')) {
      return const Color(0xFFF59E0B);
    }
    if (relationType.contains('发源') ||
        relationType.contains('栖息') ||
        relationType.contains('故土') ||
        relationType.contains('起源')) {
      return const Color(0xFF10B981);
    }
    if (relationType.contains('载体') ||
        relationType.contains('附魔') ||
        relationType.contains('衍生') ||
        relationType.contains('进阶') ||
        relationType.contains('相生')) {
      return const Color(0xFF8B5CF6);
    }
    if (relationType.contains('存放') ||
        relationType.contains('封印') ||
        relationType.contains('埋藏')) {
      return const Color(0xFF059669);
    }
    if (relationType.contains('共鸣') ||
        relationType.contains('套装') ||
        relationType.contains('羁绊')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF64748B);
  }

  static IconData _getRelationIcon(String relationType) {
    if (relationType.contains('同盟') || relationType.contains('盟友')) {
      return Icons.handshake_outlined;
    }
    if (relationType.contains('敌对') ||
        relationType.contains('交战') ||
        relationType.contains('宿敌') ||
        relationType.contains('克制')) {
      return Icons.sports_kabaddi_outlined;
    }
    if (relationType.contains('从属') ||
        relationType.contains('附属') ||
        relationType.contains('宗主') ||
        relationType.contains('归属') ||
        relationType.contains('圣物')) {
      return Icons.account_tree_outlined;
    }
    if (relationType.contains('贸易') ||
        relationType.contains('商业') ||
        relationType.contains('合作')) {
      return Icons.store_mall_directory_outlined;
    }
    if (relationType.contains('发源') ||
        relationType.contains('栖息') ||
        relationType.contains('故土') ||
        relationType.contains('起源')) {
      return Icons.park_outlined;
    }
    if (relationType.contains('载体') ||
        relationType.contains('附魔') ||
        relationType.contains('衍生') ||
        relationType.contains('进阶') ||
        relationType.contains('相生')) {
      return Icons.auto_fix_high_rounded;
    }
    if (relationType.contains('存放') ||
        relationType.contains('封印') ||
        relationType.contains('埋藏')) {
      return Icons.location_on_outlined;
    }
    if (relationType.contains('共鸣') ||
        relationType.contains('套装') ||
        relationType.contains('羁绊')) {
      return Icons.auto_awesome;
    }
    return Icons.balance_outlined;
  }

  /// 弹出添加关联人物弹窗 (LORE-002 & LORE-003)
  void _showAddCharacterDialog(
    BuildContext context,
    WidgetRef ref,
    List<Character> availableCharacters,
  ) {
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
                          await ref
                              .read(loreActionsProvider)
                              .linkCharacter(
                                worldId: entity.worldId,
                                loreId: entity.id,
                                characterId: selectedCharId!,
                                role: role,
                              );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        },
                  child: const Text('添加关联'),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 弹出建立外交/地缘关系弹窗 (LORE-003: 势力间同盟/敌对/从属/贸易)
  void _showAddEntityRelationDialog(
    BuildContext context,
    WidgetRef ref,
    List<LoreEntity> availableEntities,
  ) {
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
                },
                child: const Text('确定建立'),
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
    final typeConfig = LoreEntityType.fromKey(entity.entityType);

    // Characters for wiki links
    final charsAsync = ref.watch(charactersByWorldProvider(entity.worldId));
    final allChars = charsAsync.valueOrNull ?? [];
    final charMap = {for (final c in allChars) c.name: c};

    // Lore entities for wiki links
    final loreAsync = ref.watch(loreEntitiesByWorldProvider(entity.worldId));
    final allLores = loreAsync.valueOrNull ?? [];
    final loreMap = {for (final l in allLores) l.name: l};

    // Ancestor breadcrumbs (LORE-002: 层级地理回溯)
    final ancestorsAsync = ref.watch(loreAncestorsProvider(entity.id));
    final ancestors = ancestorsAsync.valueOrNull ?? [];

    // Child entities (LORE-002: 下级地理与分支组织)
    final childrenAsync = ref.watch(loreChildEntitiesProvider(entity.id));
    final children = childrenAsync.valueOrNull ?? [];

    // Linked characters (LORE-002 & LORE-003: 稳定 ID 关联人物)
    final membersAsync = ref.watch(loreCharactersProvider(entity.id));
    final members = membersAsync.valueOrNull ?? [];
    final linkedCharIds = members.map((m) => m.character.id).toSet();
    final unlinkedChars = allChars
        .where((c) => !linkedCharIds.contains(c.id))
        .toList();

    // Entity relations (LORE-003: 势力间同盟/敌对/从属/贸易关系)
    final relationsAsync = ref.watch(loreEntityRelationsProvider(entity.id));
    final relations = relationsAsync.valueOrNull ?? [];
    final availableFactions = allLores.where((l) => l.id != entity.id).toList();

    // Parse custom fields
    Map<String, dynamic> customFields = {};
    if (entity.customFields.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.customFields);
        if (decoded is Map<String, dynamic>) {
          customFields = decoded;
        }
      } catch (_) {}
    }

    final factionStatus = customFields['势力现状']?.toString();
    final factionCreed =
        (customFields['核心宗旨'] ?? customFields['组织信条'] ?? customFields['宗旨'])
            ?.toString();

    final itemRarity =
        (customFields['品阶稀有度'] ??
                customFields['品阶'] ??
                customFields['品质'] ??
                customFields['稀有度'])
            ?.toString();
    final itemStatus =
        (customFields['持有状态'] ?? customFields['装备状态'] ?? customFields['状态'])
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

    final raceCategory =
        (customFields['种族分类'] ?? customFields['族系'] ?? customFields['类别'])
            ?.toString();
    final raceLifespan = (customFields['平均寿命'] ?? customFields['寿命'])
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

    final tags = entity.tags
        .split(RegExp(r'[,，]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 祖先层级面包屑 (LORE-002 面包屑导航)
              if (ancestors.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      for (int i = 0; i < ancestors.length; i++) ...[
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            show(context, entity: ancestors[i]);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              ancestors[i].name,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                      Text(
                        entity.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 头部：类型徽章、名称、编辑/删除
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeConfig.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: typeConfig.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeConfig.icon,
                          size: 16,
                          color: typeConfig.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          typeConfig.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: typeConfig.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            entity.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (factionStatus != null &&
                            factionStatus.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEC4899,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFEC4899,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.diamond,
                                  size: 11,
                                  color: Color(0xFFDB2777),
                                ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
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
                        if (raceCategory != null &&
                            raceCategory.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFD97706,
                                ).withValues(alpha: 0.4),
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
                        if (raceLifespan != null &&
                            raceLifespan.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.4),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
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
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, size: 20),
                    tooltip: '版本历史与快照恢复',
                    onPressed: () {
                      RevisionHistoryDialog.show(
                        context,
                        worldId: entity.worldId,
                        entityType: 'lore',
                        entityId: entity.id,
                        entityName: entity.name,
                        currentContent: entity.content,
                        onRestore: (rev) async {
                          await ref
                              .read(revisionActionsProvider)
                              .restoreLoreContent(
                                revisionId: rev.id,
                                lore: entity,
                              );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: '编辑词条',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      await LoreEntityDialog.show(
                        navigator.context,
                        worldId: entity.worldId,
                        entity: entity,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: '删除词条',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认删除词条？'),
                          content: Text(
                            '确认永久删除百科实体 “${entity.name}” 吗？此操作无法撤销。其下属子实体的父级归属将自动安全解绑。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(loreActionsProvider)
                            .deleteEntity(entity.id, worldId: entity.worldId);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 封面图与摘要
                      if (entity.coverImagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            width: double.infinity,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: LoreCoverImage(
                              imagePath: entity.coverImagePath,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (entity.summary.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: typeConfig.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: typeConfig.color,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            entity.summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (factionCreed != null &&
                          factionCreed.trim().isNotEmpty) ...[
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

                      if (itemEffect != null &&
                          itemEffect.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEC4899,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFEC4899,
                              ).withValues(alpha: 0.3),
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

                      if (itemCost != null && itemCost.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
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

                      // LORE-005 种族专属特征与生活习性卡片
                      if (raceTraits != null &&
                          raceTraits.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D9488,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFF0D9488,
                              ).withValues(alpha: 0.3),
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

                      if ((raceHabits != null &&
                              raceHabits.trim().isNotEmpty) ||
                          (raceFaith != null &&
                              raceFaith.trim().isNotEmpty)) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD97706,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: 0.3),
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

                      // LORE-006 能力专属威能与修行代价卡片
                      if (abilityEffect != null &&
                          abilityEffect.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
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

                      if ((abilityRequirements != null &&
                              abilityRequirements.trim().isNotEmpty) ||
                          (abilityCost != null &&
                              abilityCost.trim().isNotEmpty)) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFDC2626,
                              ).withValues(alpha: 0.3),
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

                      // 标签
                      if (tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((t) {
                            return Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ==========================================
                      // LORE-002: 下级地理空间 / 分支组织 (Children)
                      // ==========================================
                      if (children.isNotEmpty) ...[
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
                              avatar: Icon(
                                typeConfig.icon,
                                size: 14,
                                color: typeConfig.color,
                              ),
                              label: Text(child.name),
                              onPressed: () {
                                Navigator.pop(context);
                                show(context, entity: child);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ========================================================
                      // LORE-002, LORE-003, LORE-004, LORE-005, LORE-006: 稳定 ID 关联人物 (Linked Characters)
                      // ========================================================
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
                            onPressed: () => _showAddCharacterDialog(
                              context,
                              ref,
                              unlinkedChars,
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 14,
                            ),
                            label: const Text('关联人物'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
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
                          builder: (context) {
                            final sortedMembers = [...members]
                              ..sort((a, b) {
                                final isLeaderA = _isLeaderOrOwnerRole(
                                  a.relation.role,
                                );
                                final isLeaderB = _isLeaderOrOwnerRole(
                                  b.relation.role,
                                );
                                if (isLeaderA && !isLeaderB) return -1;
                                if (!isLeaderA && isLeaderB) return 1;
                                return a.relation.id.compareTo(b.relation.id);
                              });

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sortedMembers.map((m) {
                                final char = m.character;
                                final role = m.relation.role;
                                final isLeader = _isLeaderOrOwnerRole(role);

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
                                              ? theme
                                                    .colorScheme
                                                    .primaryContainer
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: isLeader
                                              ? Border.all(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
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
                                                    : entity.entityType ==
                                                          'race'
                                                    ? Icons.diversity_1_rounded
                                                    : entity.entityType ==
                                                          'ability'
                                                    ? Icons
                                                          .military_tech_rounded
                                                    : Icons
                                                          .workspace_premium_rounded,
                                                size: 11,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 2),
                                            ],
                                            Text(
                                              role,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isLeader
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    if (onCharacterTap != null) {
                                      Navigator.pop(context);
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
                        ),
                      const SizedBox(height: 16),

                      // ========================================================
                      // LORE-003, LORE-004, LORE-005, LORE-006: 实体间外交/地缘/相生相克关系
                      // ========================================================
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
                            onPressed: () => _showAddEntityRelationDialog(
                              context,
                              ref,
                              availableFactions,
                            ),
                            icon: const Icon(Icons.add_link_rounded, size: 14),
                            label: const Text('建立关系'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: relations.map((relItem) {
                            final other = relItem.otherEntity;
                            final rel = relItem.relation;
                            final relColor = _getRelationColor(
                              rel.relationType,
                            );
                            final relIcon = _getRelationIcon(rel.relationType);

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
                              onPressed: () {
                                Navigator.pop(context);
                                show(context, entity: other);
                              },
                              onDeleted: () async {
                                await ref
                                    .read(loreActionsProvider)
                                    .unlinkEntityRelation(rel.id);
                              },
                              deleteIconColor: theme.colorScheme.outline,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // 专有结构化属性
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
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: customFields.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
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

                      // 正文设定与双链
                      Text(
                        '百科设定详述',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entity.content.trim().isEmpty)
                        Text(
                          '（暂无详细正文设定）',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: WikiLinkParser.buildWikiSpans(
                              text: entity.content,
                              nameToCharacterMap: charMap,
                              nameToLoreEntityMap: loreMap,
                              onCharacterTap: onCharacterTap ?? (_) {},
                              onLoreEntityTap:
                                  onLoreEntityTap ??
                                  (target) {
                                    Navigator.pop(context);
                                    show(context, entity: target);
                                  },
                              context: context,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
