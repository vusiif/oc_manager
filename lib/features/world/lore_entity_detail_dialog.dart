import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/lore_provider.dart';
import '../../providers/revision_provider.dart';
import '../../core/util/wiki_link_parser.dart';
import 'lore_cover_image.dart';
import 'lore_entity_dialog.dart';
import 'revision_history_dialog.dart';
import 'lore_details/lore_header_badges.dart';
import 'lore_details/lore_traits_section.dart';
import 'lore_details/lore_children_section.dart';
import 'lore_details/lore_linked_characters_section.dart';
import 'lore_details/lore_entity_relations_section.dart';
import 'lore_details/lore_relation_dialogs.dart';

/// 百科实体详情对话框 (LORE-001 ~ LORE-007)
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
                        LoreHeaderBadges(customFields: customFields),
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
                        lore: entity,
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

                      // 专有设定特征卡片组 (LORE-002 ~ LORE-006)
                      LoreTraitsSection(
                        typeConfig: typeConfig,
                        customFields: customFields,
                      ),

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

                      // 下级地理空间 / 分支组织 (Children)
                      LoreChildrenSection(
                        entity: entity,
                        typeConfig: typeConfig,
                        children: children,
                        onChildTap: (child) {
                          Navigator.pop(context);
                          show(context, entity: child);
                        },
                      ),

                      // 稳定 ID 关联人物 (Linked Characters)
                      LoreLinkedCharactersSection(
                        entity: entity,
                        members: members,
                        unlinkedChars: unlinkedChars,
                        onCharacterTap: (char) {
                          if (onCharacterTap != null) {
                            Navigator.pop(context);
                            onCharacterTap!(char);
                          }
                        },
                        onAddPressed: () =>
                            LoreRelationDialogs.showAddCharacterDialog(
                              context,
                              ref,
                              entity: entity,
                              availableCharacters: unlinkedChars,
                            ),
                      ),

                      // 实体间外交/地缘/相生相克关系 (Entity Relations)
                      LoreEntityRelationsSection(
                        entity: entity,
                        relations: relations,
                        onEntityTap: (other) {
                          Navigator.pop(context);
                          show(context, entity: other);
                        },
                        onAddRelationPressed: () =>
                            LoreRelationDialogs.showAddEntityRelationDialog(
                              context,
                              ref,
                              entity: entity,
                              availableEntities: availableFactions,
                            ),
                      ),

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
