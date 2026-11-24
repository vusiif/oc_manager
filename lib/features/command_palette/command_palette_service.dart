import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/world_provider.dart';
import '../../providers/settings_provider.dart';
import '../world/world_dialog.dart';
import '../character/character_dialog.dart';
import '../world/world_analytics_dialog.dart';
import '../world/consistency_checker_dialog.dart';
import '../world/booklet_export_dialog.dart';
import '../world/oc_package_dialogs.dart';
import 'command_palette_model.dart';

class CommandPaletteService {
  /// Builds all static action commands available in the application.
  static List<CommandPaletteItem> getStaticCommands() {
    return [
      CommandPaletteItem(
        id: 'cmd_new_world',
        title: '新建世界观',
        subtitle: '创建全新的设定宇宙或故事舞台',
        category: CommandPaletteCategory.command,
        icon: Icons.add_circle_outline_rounded,
        iconColor: const Color(0xFF4F46E5),
        keywords: ['world', 'create', 'new', 'add', 'chuanjian', 'shijieguan'],
        onExecute: (context, ref) {
          showDialog(context: context, builder: (_) => const WorldDialog());
        },
      ),
      CommandPaletteItem(
        id: 'cmd_new_character',
        title: '新建人物角色',
        subtitle: '在世界观中建立新的人物档案卡片',
        category: CommandPaletteCategory.command,
        icon: Icons.person_add_alt_1_rounded,
        iconColor: const Color(0xFF10B981),
        keywords: ['character', 'oc', 'renwu', 'juese', 'new', 'add'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          showDialog(
            context: context,
            builder: (_) => CharacterDialog(worldId: w.id),
          );
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_open_chronicle',
        title: '世界编年史 (Timeline)',
        subtitle: '纵览宏大纪元与角色生平时间线',
        category: CommandPaletteCategory.command,
        icon: Icons.history_edu_rounded,
        iconColor: const Color(0xFFF59E0B),
        keywords: [
          'chronicle',
          'timeline',
          'biannianshi',
          'shijianxian',
          'jiyuan',
        ],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          context.push('/world/${w.id}/chronicle');
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_open_graph',
        title: '角色关系图谱 (Canvas)',
        subtitle: '力导向与自动排布图谱，推演人物羁绊',
        category: CommandPaletteCategory.command,
        icon: Icons.hub_rounded,
        iconColor: const Color(0xFF8B5CF6),
        keywords: ['relation', 'graph', 'canvas', 'guanxitu', 'tupu'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          context.push('/world/${w.id}/graph');
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_open_lore',
        title: '世界观百科 (Encyclopedia)',
        subtitle: '地点、组织、种族、物品与规则设定库',
        category: CommandPaletteCategory.command,
        icon: Icons.auto_stories_rounded,
        iconColor: const Color(0xFF06B6D4),
        keywords: ['lore', 'wiki', 'encyclopedia', 'baike', 'didian', 'zuzhi'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          context.push('/world/${w.id}/lore');
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_open_analytics',
        title: '全景数据大盘与网络分析',
        subtitle: '世界观统计总览、性别比例与六维分布',
        category: CommandPaletteCategory.command,
        icon: Icons.insights_rounded,
        iconColor: const Color(0xFF3B82F6),
        keywords: ['analytics', 'stats', 'dapan', 'shuju', 'fenxi'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          showDialog(
            context: context,
            builder: (_) =>
                WorldAnalyticsDialog(worldId: w.id, worldName: w.name),
          );
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_consistency_check',
        title: '设定一致性检查 (Consistency)',
        subtitle: '诊断时间线冲突、生卒年悖论与引用失效',
        category: CommandPaletteCategory.command,
        icon: Icons.fact_check_rounded,
        iconColor: const Color(0xFFEC4899),
        keywords: ['consistency', 'check', 'yizhixing', 'jiancha', 'chongtu'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          ConsistencyCheckerDialog.show(
            context,
            worldId: w.id,
            worldName: w.name,
          );
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_booklet_export',
        title: '导出出版级设定集 (Booklet)',
        subtitle: '生成脱机单文件 HTML 或 Markdown 设定集',
        category: CommandPaletteCategory.command,
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFFF97316),
        keywords: ['booklet', 'export', 'html', 'daochu', 'shedingji'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          BookletExportDialog.show(context, w);
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_ocpkg_export',
        title: '导出便携数据包 (.ocpkg)',
        subtitle: '打包角色、图谱与画廊立绘为便携包',
        category: CommandPaletteCategory.command,
        icon: Icons.archive_outlined,
        iconColor: const Color(0xFF6366F1),
        keywords: ['ocpkg', 'package', 'export', 'daochu', 'dabao'],
        onExecute: (context, ref) => _runWithWorld(context, ref, (w) async {
          OcPackageExportDialog.show(context, w);
        }),
      ),
      CommandPaletteItem(
        id: 'cmd_ocpkg_import',
        title: '导入便携数据包 (.ocpkg)',
        subtitle: '从外界载入并安全合并角色或世界观数据包',
        category: CommandPaletteCategory.command,
        icon: Icons.unarchive_outlined,
        iconColor: const Color(0xFF14B8A6),
        keywords: ['import', 'daoru', 'ocpkg', 'load'],
        onExecute: (context, ref) {
          OcPackageImportDialog.show(context);
        },
      ),
      CommandPaletteItem(
        id: 'cmd_deep_search',
        title: '全局深度搜索 (Deep Search)',
        subtitle: '跨字段多维检索人物姓名、描述与标签',
        category: CommandPaletteCategory.command,
        icon: Icons.search_rounded,
        iconColor: const Color(0xFF3B82F6),
        keywords: ['search', 'sousuo', 'find', 'chazhao'],
        onExecute: (context, ref) {
          context.push('/search');
        },
      ),
      CommandPaletteItem(
        id: 'cmd_toggle_theme',
        title: '切换深色 / 浅色模式',
        subtitle: '快捷切换应用的明亮或暗黑外观风格',
        category: CommandPaletteCategory.command,
        icon: Icons.brightness_medium_rounded,
        iconColor: const Color(0xFFEAB308),
        keywords: ['theme', 'dark', 'light', 'zhuti', 'qiehuan'],
        onExecute: (context, ref) async {
          final currentMode =
              ref.read(themeModeProvider).valueOrNull ?? ThemeMode.system;
          final nextMode = currentMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;
          await ref.read(themeModeProvider.notifier).setThemeMode(nextMode);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '已切换为 ${nextMode == ThemeMode.dark ? "深色暗黑" : "浅色明亮"} 模式',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
      CommandPaletteItem(
        id: 'cmd_tag_management',
        title: '标签管理 (Tags)',
        subtitle: '管理全局角色与词条标签',
        category: CommandPaletteCategory.command,
        icon: Icons.label_outline_rounded,
        iconColor: const Color(0xFF64748B),
        keywords: ['tag', 'biaoqian', 'manage'],
        onExecute: (context, ref) {
          context.push('/tags');
        },
      ),
      CommandPaletteItem(
        id: 'cmd_template_management',
        title: '模板管理 (Templates)',
        subtitle: '自定义人物属性模板与专属字段结构',
        category: CommandPaletteCategory.command,
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF64748B),
        keywords: ['template', 'moban', 'fields'],
        onExecute: (context, ref) {
          context.push('/templates');
        },
      ),
      CommandPaletteItem(
        id: 'cmd_drafts',
        title: '草稿箱 (Drafts)',
        subtitle: '快速回顾与整理未定稿角色',
        category: CommandPaletteCategory.command,
        icon: Icons.drafts_outlined,
        iconColor: const Color(0xFF94A3B8),
        keywords: ['draft', 'caogao', 'sketch'],
        onExecute: (context, ref) {
          context.push('/drafts');
        },
      ),
      CommandPaletteItem(
        id: 'cmd_trash',
        title: '回收站 (Trash)',
        subtitle: '查看、还原或彻底清除已删除世界观与角色',
        category: CommandPaletteCategory.command,
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFEF4444),
        keywords: ['trash', 'huishouzhan', 'delete', 'restore'],
        onExecute: (context, ref) {
          context.push('/trash');
        },
      ),
      CommandPaletteItem(
        id: 'cmd_settings',
        title: '系统设置 (Settings)',
        subtitle: '偏好配置、数据库双轨备份与安全灾备还原',
        category: CommandPaletteCategory.command,
        icon: Icons.settings_outlined,
        iconColor: const Color(0xFF475569),
        keywords: ['settings', 'shezhi', 'backup', 'beifen', 'config'],
        onExecute: (context, ref) {
          context.push('/settings');
        },
      ),
    ];
  }

  /// Searches and aggregates commands, worlds, characters, and lore entities.
  static Future<List<CommandPaletteItem>> searchItems(
    WidgetRef ref,
    String query, {
    int? activeWorldId,
  }) async {
    final db = ref.read(databaseProvider);
    final staticCmds = getStaticCommands();
    final q = query.trim();

    // 1. Fetch worlds
    final allWorlds = await db.worldDao.getAllWorlds();
    final worldMap = {for (final w in allWorlds) w.id: w.name};

    // If query is empty: Return static commands + existing worlds + top recent characters
    if (q.isEmpty) {
      final items = <CommandPaletteItem>[...staticCmds];

      // Add worlds as quick access
      for (final w in allWorlds) {
        items.add(
          CommandPaletteItem(
            id: 'world_${w.id}',
            title: w.name,
            subtitle: w.description?.isNotEmpty == true
                ? w.description!
                : '世界观 · 快速切换进入',
            category: CommandPaletteCategory.world,
            icon: Icons.public_rounded,
            iconColor: const Color(0xFF4F46E5),
            keywords: ['world', w.name],
            onExecute: (context, r) {
              r.read(activeWorldIdProvider.notifier).state = w.id;
              context.go('/');
            },
          ),
        );
      }

      // Add top recent characters
      try {
        final recentChars =
            await (db.select(db.characters)
                  ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
                  ..limit(6))
                .get();

        for (final c in recentChars) {
          final wName = worldMap[c.worldId] ?? '世界观';
          items.add(
            CommandPaletteItem(
              id: 'character_${c.id}',
              title: c.name,
              subtitle: '角色 · 所属 [$wName] · ${c.description}',
              category: CommandPaletteCategory.character,
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF10B981),
              keywords: ['character', c.name],
              onExecute: (context, r) {
                r.read(activeWorldIdProvider.notifier).state = c.worldId;
                context.push('/world/${c.worldId}/character/${c.id}');
              },
            ),
          );
        }
      } catch (_) {}

      return items;
    }

    // When query is non-empty: Perform deep scored search across all categories
    final scoredItems = <({CommandPaletteItem item, int score})>[];

    // Score static commands
    for (final cmd in staticCmds) {
      final score = cmd.matchScore(q);
      if (score > 0) {
        scoredItems.add((item: cmd, score: score));
      }
    }

    // Match worlds
    for (final w in allWorlds) {
      final item = CommandPaletteItem(
        id: 'world_${w.id}',
        title: w.name,
        subtitle: w.description?.isNotEmpty == true ? w.description! : '世界观',
        category: CommandPaletteCategory.world,
        icon: Icons.public_rounded,
        iconColor: const Color(0xFF4F46E5),
        keywords: ['world', w.name],
        onExecute: (context, r) {
          r.read(activeWorldIdProvider.notifier).state = w.id;
          context.go('/');
        },
      );
      final score = item.matchScore(q);
      if (score > 0) {
        scoredItems.add((
          item: item,
          score: score + 10,
        )); // Boost entity matches
      }
    }

    // Search characters deep
    try {
      final charResults = await db.characterDao.searchCharactersDeep(q);
      for (final res in charResults) {
        final c = res.character;
        final wName = worldMap[c.worldId] ?? '世界观';
        final item = CommandPaletteItem(
          id: 'character_${c.id}',
          title: c.name,
          subtitle:
              '角色 · 所属 [$wName] · 匹配: ${res.matchedField} (${res.matchedSnippet})',
          category: CommandPaletteCategory.character,
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF10B981),
          keywords: ['character', c.name],
          onExecute: (context, r) {
            r.read(activeWorldIdProvider.notifier).state = c.worldId;
            context.push('/world/${c.worldId}/character/${c.id}');
          },
        );
        final score = item.matchScore(q);
        scoredItems.add((item: item, score: score > 0 ? score + 15 : 45));
      }
    } catch (_) {}

    // Search lore entities
    try {
      final pattern = '%$q%';
      final lores =
          await (db.select(db.loreEntities)
                ..where((t) => t.name.like(pattern) | t.summary.like(pattern))
                ..limit(10))
              .get();

      for (final l in lores) {
        final wName = worldMap[l.worldId] ?? '世界观';
        final item = CommandPaletteItem(
          id: 'lore_${l.id}',
          title: l.name,
          subtitle: '词条 [${l.entityType}] · 所属 [$wName] · ${l.summary}',
          category: CommandPaletteCategory.lore,
          icon: Icons.auto_stories_rounded,
          iconColor: const Color(0xFF06B6D4),
          keywords: ['lore', l.name, l.entityType],
          onExecute: (context, r) {
            r.read(activeWorldIdProvider.notifier).state = l.worldId;
            context.push('/world/${l.worldId}/lore');
          },
        );
        final score = item.matchScore(q);
        scoredItems.add((item: item, score: score > 0 ? score + 10 : 40));
      }
    } catch (_) {}

    // Sort by descending score
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    return scoredItems.map((e) => e.item).toList();
  }

  /// Helper to pick or confirm target world when a command requires one.
  static Future<World?> _resolveTargetWorld(
    BuildContext context,
    List<World> worlds,
    int? activeWorldId,
  ) async {
    if (worlds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('尚未创建世界观，请先新建世界观')));
      return null;
    }

    if (activeWorldId != null) {
      final matched = worlds.where((w) => w.id == activeWorldId).toList();
      if (matched.isNotEmpty) return matched.first;
    }

    if (worlds.length == 1) return worlds.first;

    // Show selection dialog
    return showDialog<World>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择目标世界观'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: worlds.length,
            itemBuilder: (_, index) {
              final w = worlds[index];
              return ListTile(
                leading: const Icon(Icons.public_rounded),
                title: Text(w.name),
                subtitle: Text(
                  w.description ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(ctx).pop(w),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Helper to ensure a target world is resolved before executing a command.
  static Future<void> _runWithWorld(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(World world) action,
  ) async {
    final worlds = await ref.read(databaseProvider).worldDao.getAllWorlds();
    if (!context.mounted) return;
    final activeId = ref.read(activeWorldIdProvider);
    final targetWorld = await _resolveTargetWorld(context, worlds, activeId);
    if (targetWorld != null && context.mounted) {
      await action(targetWorld);
    }
  }
}
