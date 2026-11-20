import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/story_provider.dart';

/// 角色详情页中的故事线出场记录卡片 (STORY-003)
class CharacterStoryAppearanceSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterStoryAppearanceSection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(
      characterAppearanceSummaryProvider((
        characterId: characterId,
        worldId: worldId,
      )),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '故事线出场记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                summaryAsync.when(
                  data: (summary) => summary.totalScenes == 0
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${summary.totalScenes} 场次',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text('故事工作台', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    context.push('/world/$worldId/story');
                  },
                ),
              ],
            ),
            const Divider(height: 16),

            // 2. Body
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '加载出场记录失败: $err',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
              data: (summary) {
                if (summary.totalScenes == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 36,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '该角色暂无故事作品出场记录',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '在故事创作工作台的场景分镜中将该角色标记为 POV 或出场角色，系统将在此自动汇总其戏份轨迹。',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetricPill(
                          theme,
                          '出场 ${summary.totalScenes} 场景',
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.onPrimaryContainer,
                        ),
                        _buildMetricPill(
                          theme,
                          '覆盖 ${summary.totalChapters} 章节',
                          theme.colorScheme.secondaryContainer,
                          theme.colorScheme.onSecondaryContainer,
                        ),
                        if (summary.totalPovScenes > 0)
                          _buildMetricPill(
                            theme,
                            'POV 视点 ${summary.totalPovScenes} 场',
                            theme.colorScheme.tertiaryContainer,
                            theme.colorScheme.onTertiaryContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // First & Last Appearance Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 500;
                        final firstCard = _buildAppearanceHighlightCard(
                          context,
                          title: '首次登场',
                          icon: Icons.flag_outlined,
                          item: summary.firstAppearance,
                          accentColor: theme.colorScheme.primary,
                        );
                        final lastCard = _buildAppearanceHighlightCard(
                          context,
                          title: '最近登场',
                          icon: Icons.update_rounded,
                          item: summary.lastAppearance,
                          accentColor: theme.colorScheme.tertiary,
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: firstCard),
                              const SizedBox(width: 10),
                              Expanded(child: lastCard),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              firstCard,
                              const SizedBox(height: 8),
                              lastCard,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Scene Appearance Timeline by Work
                    Text(
                      '出场作品与场景轨迹',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAppearancesByWork(context, summary.appearances),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(
    ThemeData theme,
    String label,
    Color bgColor,
    Color fgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }

  Widget _buildAppearanceHighlightCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required CharacterAppearanceItem? item,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    if (item == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              if (item.isPov) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'POV',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '《${item.work.title}》',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '第 ${item.chapter.sortOrder + 1} 章《${item.chapter.title}》· ${item.scene.title}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.scene.timelineTime.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.scene.timelineTime,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppearancesByWork(
    BuildContext context,
    List<CharacterAppearanceItem> appearances,
  ) {
    final theme = Theme.of(context);

    // Group appearances by Work
    final Map<int, List<CharacterAppearanceItem>> workMap = {};
    for (final a in appearances) {
      workMap.putIfAbsent(a.work.id, () => []).add(a);
    }

    return Column(
      children: workMap.entries.map((entry) {
        final workAppearances = entry.value;
        final work = workAppearances.first.work;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ExpansionTile(
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            leading: Icon(
              Icons.menu_book_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              work.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${work.type} · 登场 ${workAppearances.length} 场景',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
            ),
            children: workAppearances.map((a) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: a.isPov
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '第 ${a.chapter.sortOrder + 1} 章《${a.chapter.title}》· ${a.scene.title}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: a.isPov
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (a.isPov) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'POV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (a.scene.timelineTime.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        a.scene.timelineTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
