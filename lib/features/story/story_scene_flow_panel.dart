import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/story_provider.dart';
import '../../providers/character_provider.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/confirmation_dialog.dart';
import '../../core/design/components/oc_avatar.dart';
import 'story_scene_dialog.dart';

class StorySceneFlowPanel extends ConsumerWidget {
  final int worldId;
  final int workId;
  final int? chapterId;
  final bool isWide;
  final VoidCallback onBackToOutline;

  const StorySceneFlowPanel({
    super.key,
    required this.worldId,
    required this.workId,
    required this.chapterId,
    required this.isWide,
    required this.onBackToOutline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (chapterId == null) {
      return Center(
        child: Text(
          '请在左侧大纲中选择一个章节以查看场景分镜',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final activeChapterId = chapterId!;
    final chapterAsync = ref.watch(chaptersByWorkProvider(workId));
    final scenesDetailsAsync = ref.watch(
      sceneDetailsByChapterProvider(activeChapterId),
    );
    final allCharacters =
        ref.watch(charactersByWorldProvider(worldId)).valueOrNull ?? [];

    // Find current chapter
    final chapters = chapterAsync.valueOrNull ?? [];
    final currentChapter = chapters.any((c) => c.id == activeChapterId)
        ? chapters.firstWhere((c) => c.id == activeChapterId)
        : null;

    if (currentChapter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Chapter Banner Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isWide) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '返回章节列表',
                      onPressed: () {
                        onBackToOutline();
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentChapter.arcName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '第 ${currentChapter.sortOrder + 1} 章',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentChapter.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加分镜场景'),
                    onPressed: () async {
                      final details = scenesDetailsAsync.valueOrNull ?? [];
                      final nextOrder = details.length;
                      await StorySceneDialog.show(
                        context,
                        worldId: worldId,
                        chapterId: activeChapterId,
                        nextSortOrder: nextOrder,
                      );
                    },
                  ),
                ],
              ),
              if (currentChapter.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentChapter.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // Scenes Flow List
        Expanded(
          child: scenesDetailsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('加载场景失败: $err')),
            data: (details) {
              if (details.isEmpty) {
                return EmptyStateView(
                  icon: Icons.movie_creation_outlined,
                  title: '本章暂无分镜场景',
                  description: '将章节拆解为连续发生的场景、视点与冲突脉络。\n点击上方『添加分镜场景』开始细化分镜！',
                  primaryActionLabel: '添加场景分镜',
                  onPrimaryAction: () {
                    StorySceneDialog.show(
                      context,
                      worldId: worldId,
                      chapterId: activeChapterId,
                    );
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final detail = details[index];
                  return _buildSceneCard(
                    context,
                    ref,
                    detail: detail,
                    index: index,
                    chapterId: activeChapterId,
                    allCharacters: allCharacters,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSceneCard(
    BuildContext context,
    WidgetRef ref, {
    required StorySceneDetail detail,
    required int index,
    required int chapterId,
    required List<Character> allCharacters,
  }) {
    final theme = Theme.of(context);
    final scene = detail.scene;

    // Resolve cast characters for chips
    final castCharacters = allCharacters
        .where((c) => detail.characterIds.contains(c.id))
        .toList();

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Scene Index & Title & Mood & Actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '场景 #${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scene.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (scene.mood.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 14,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scene.mood,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: '编辑场景',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      StorySceneDialog.show(
                        context,
                        worldId: worldId,
                        chapterId: chapterId,
                        scene: scene,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: '删除场景',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: '删除场景确认',
                        content: '确定要删除场景《${scene.title}》吗？',
                        confirmLabel: '删除',
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(storyActionsProvider)
                            .deleteScene(scene.id, chapterId);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metadata Row: POV, Location, Time
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // POV Person
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'POV 视点: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (detail.povCharacter != null) ...[
                        OcAvatar(
                          avatarPath: detail.povCharacter!.avatarPath,
                          name: detail.povCharacter!.name,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detail.povCharacter!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ] else
                        const Text(
                          '全知视角',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),

                  // Location
                  if (detail.location != null || scene.locationName.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detail.location?.name ?? scene.locationName,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),

                  // Timeline Time
                  if (scene.timelineTime.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scene.timelineTime,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),

              // Scene Summary
              if (scene.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scene.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Content / Storyboard Beats
              if (scene.content.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  scene.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Cast / Characters who appear in this scene
              if (castCharacters.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '出场角色 (${castCharacters.length}):',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: castCharacters.map((c) {
                          final isPov = c.id == scene.povCharacterId;
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.only(right: 6),
                            avatar: OcAvatar(
                              avatarPath: c.avatarPath,
                              name: c.name,
                              size: 18,
                            ),
                            label: Text(
                              c.name + (isPov ? ' (POV)' : ''),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isPov
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
