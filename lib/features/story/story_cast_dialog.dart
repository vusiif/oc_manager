import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../providers/story_provider.dart';

class StoryCastDialog extends ConsumerStatefulWidget {
  final int workId;
  final String workTitle;
  final int worldId;

  const StoryCastDialog({
    super.key,
    required this.workId,
    required this.workTitle,
    required this.worldId,
  });

  static Future<void> show(
    BuildContext context, {
    required int workId,
    required String workTitle,
    required int worldId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => StoryCastDialog(
        workId: workId,
        workTitle: workTitle,
        worldId: worldId,
      ),
    );
  }

  @override
  ConsumerState<StoryCastDialog> createState() => _StoryCastDialogState();
}

class _StoryCastDialogState extends ConsumerState<StoryCastDialog> {
  String _searchQuery = '';
  final Set<int> _expandedCharacterIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final castStatsAsync = ref.watch(workCastStatsProvider(widget.workId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.groups_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '《${widget.workTitle}》登场角色表',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '汇总统计全部登场角色的戏份频次、覆盖章节与首次登场',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索登场角色名称...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),

            // Cast List
            Expanded(
              child: castStatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('加载出场角色失败: $err')),
                data: (allStats) {
                  final filteredStats = allStats.where((s) {
                    if (_searchQuery.isEmpty) return true;
                    return s.character.name.toLowerCase().contains(
                      _searchQuery,
                    );
                  }).toList();

                  if (filteredStats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? '当前作品尚未在任何场景中分配出场角色'
                                : '未找到匹配的登场角色',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredStats.length,
                    itemBuilder: (context, index) {
                      final member = filteredStats[index];
                      final isExpanded = _expandedCharacterIds.contains(
                        member.character.id,
                      );

                      return _buildMemberCard(
                        context,
                        member: member,
                        rank: index + 1,
                        isExpanded: isExpanded,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required WorkCastMemberStats member,
    required int rank,
    required bool isExpanded,
  }) {
    final theme = Theme.of(context);
    final c = member.character;

    // Rank styling
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFEAB308); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFD97706); // Bronze
    } else {
      rankColor = theme.colorScheme.outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                OcAvatar(
                  avatarPath: c.avatarPath,
                  name: c.name,
                  gender: c.gender,
                  size: 40,
                ),
                const SizedBox(width: 10),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.gender.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${c.gender})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Badges Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            theme,
                            '出场 ${member.sceneCount} 场',
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.onPrimaryContainer,
                          ),
                          _buildBadge(
                            theme,
                            '覆盖 ${member.chapterCount} 章',
                            theme.colorScheme.secondaryContainer,
                            theme.colorScheme.onSecondaryContainer,
                          ),
                          if (member.povCount > 0)
                            _buildBadge(
                              theme,
                              'POV ${member.povCount} 场',
                              theme.colorScheme.tertiaryContainer,
                              theme.colorScheme.onTertiaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // View Character Profile Button
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  tooltip: '查看角色档案详情',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/world/${widget.worldId}/character/${c.id}');
                  },
                ),
              ],
            ),

            // First Appearance Note
            if (member.firstAppearance != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '首次登场：第 ${member.firstAppearance!.chapter.sortOrder + 1} 章《${member.firstAppearance!.chapter.title}》· ${member.firstAppearance!.scene.title}${member.firstAppearance!.scene.timelineTime.isNotEmpty ? ' (${member.firstAppearance!.scene.timelineTime})' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    ThemeData theme,
    String label,
    Color bgColor,
    Color fgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }
}
