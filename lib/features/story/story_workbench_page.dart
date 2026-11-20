import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/components/confirmation_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/world_provider.dart';
import 'story_chapter_dialog.dart';
import 'story_scene_dialog.dart';
import 'story_work_dialog.dart';
import 'story_cast_dialog.dart';

class StoryWorkbenchPage extends ConsumerStatefulWidget {
  final int worldId;

  const StoryWorkbenchPage({super.key, required this.worldId});

  @override
  ConsumerState<StoryWorkbenchPage> createState() => _StoryWorkbenchPageState();
}

class _StoryWorkbenchPageState extends ConsumerState<StoryWorkbenchPage> {
  int? _selectedWorkId;
  int? _selectedChapterId;
  bool _narrowShowScenes = false;

  @override
  Widget build(BuildContext context) {
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final worksAsync = ref.watch(worksByWorldProvider(widget.worldId));

    final world = worldAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          world != null ? '${world.name} · 故事线与场景分镜' : '故事创作工作台',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded),
            tooltip: '新建作品',
            onPressed: () async {
              final newId = await StoryWorkDialog.show(
                context,
                worldId: widget.worldId,
              );
              if (newId != null && mounted) {
                setState(() {
                  _selectedWorkId = newId;
                  _selectedChapterId = null;
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: worksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载故事作品失败: $err')),
        data: (works) {
          if (works.isEmpty) {
            return EmptyStateView(
              icon: Icons.auto_stories_outlined,
              title: '暂无故事作品',
              description: '一个世界观可包含多部小说、漫画分镜、剧本或跑团企划。\n点击下方按钮开启你的第一部故事创作！',
              primaryActionLabel: '新建故事作品',
              onPrimaryAction: () async {
                final newId = await StoryWorkDialog.show(
                  context,
                  worldId: widget.worldId,
                );
                if (newId != null && mounted) {
                  setState(() => _selectedWorkId = newId);
                }
              },
            );
          }

          // Ensure valid selected work
          final currentWork = works.any((w) => w.id == _selectedWorkId)
              ? works.firstWhere((w) => w.id == _selectedWorkId)
              : works.first;
          final activeWorkId = currentWork.id;

          return Column(
            children: [
              // 1. Top Work Switcher & Info Bar
              _buildWorkHeader(context, works, currentWork),
              const Divider(height: 1),

              // 2. Main Workbench Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    if (isWide) {
                      return Row(
                        children: [
                          // Left Outline Panel
                          SizedBox(
                            width: 340,
                            child: _buildChapterOutlinePanel(
                              context,
                              activeWorkId,
                              isWide: true,
                            ),
                          ),
                          const VerticalDivider(width: 1),

                          // Right Scene Flow Panel
                          Expanded(
                            child: _buildSceneFlowPanel(
                              context,
                              activeWorkId,
                              isWide: true,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Narrow / Mobile screen navigation
                      if (_narrowShowScenes && _selectedChapterId != null) {
                        return _buildSceneFlowPanel(
                          context,
                          activeWorkId,
                          isWide: false,
                        );
                      } else {
                        return _buildChapterOutlinePanel(
                          context,
                          activeWorkId,
                          isWide: false,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================================
  // Top Work Header & Switcher
  // ========================================================
  Widget _buildWorkHeader(
    BuildContext context,
    List<StoryWork> works,
    StoryWork currentWork,
  ) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(workStatsProvider(currentWork.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          // Work Selector Dropdown
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentWork.id,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: works.map((w) {
                  return DropdownMenuItem<int>(
                    value: w.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            w.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedWorkId = id;
                      _selectedChapterId = null;
                      _narrowShowScenes = false;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Work Type Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentWork.type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Work Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentWork.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),

          const Spacer(),

          // Stats Badge
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${stats.chapterCount} 章节 · ${stats.sceneCount} 场景 · ${stats.totalWords} 字',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Cast & Character Appearances (STORY-003)
          IconButton(
            icon: const Icon(Icons.groups_outlined, size: 20),
            tooltip: '作品登场角色表 (Cast Index)',
            onPressed: () {
              StoryCastDialog.show(
                context,
                workId: currentWork.id,
                workTitle: currentWork.title,
                worldId: widget.worldId,
              );
            },
          ),

          // Edit Work
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: '编辑当前作品信息',
            onPressed: () {
              StoryWorkDialog.show(
                context,
                worldId: widget.worldId,
                work: currentWork,
              );
            },
          ),

          // Delete Work
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            tooltip: '删除当前作品',
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: '删除作品确认',
                content:
                    '确定要删除作品《${currentWork.title}》吗？\n删除作品将同时清理其下的所有章节与场景分镜，此操作不可恢复。',
                confirmLabel: '确认删除',
                isDestructive: true,
              );
              if (confirmed && mounted) {
                await ref
                    .read(storyActionsProvider)
                    .deleteWork(currentWork.id, widget.worldId);
                setState(() {
                  _selectedWorkId = null;
                  _selectedChapterId = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Left Panel: Chapters Outline & Arcs
  // ========================================================
  Widget _buildChapterOutlinePanel(
    BuildContext context,
    int workId, {
    required bool isWide,
  }) {
    final theme = Theme.of(context);
    final chaptersAsync = ref.watch(chaptersByWorkProvider(workId));

    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                '大纲与故事线',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加章节'),
                onPressed: () async {
                  final chapters = chaptersAsync.valueOrNull ?? [];
                  final nextOrder = chapters.length;
                  final newId = await StoryChapterDialog.show(
                    context,
                    workId: workId,
                    nextSortOrder: nextOrder,
                  );
                  if (newId != null && mounted) {
                    setState(() {
                      _selectedChapterId = newId;
                      if (!isWide) _narrowShowScenes = true;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Chapters List grouped by Arc
        Expanded(
          child: chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('加载章节失败: $err')),
            data: (chapters) {
              if (chapters.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '作品尚无章节大纲',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('新建第一章'),
                          onPressed: () async {
                            final newId = await StoryChapterDialog.show(
                              context,
                              workId: workId,
                            );
                            if (newId != null && mounted) {
                              setState(() {
                                _selectedChapterId = newId;
                                if (!isWide) _narrowShowScenes = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Auto-select first chapter if none selected or invalid
              if (_selectedChapterId == null ||
                  !chapters.any((c) => c.id == _selectedChapterId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && chapters.isNotEmpty) {
                    setState(() => _selectedChapterId = chapters.first.id);
                  }
                });
              }

              // Group chapters by Arc
              final Map<String, List<StoryChapter>> arcGroups = {};
              for (final c in chapters) {
                final arc = c.arcName.trim().isEmpty ? '正卷' : c.arcName.trim();
                arcGroups.putIfAbsent(arc, () => []).add(c);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: arcGroups.entries.map((entry) {
                  final arcName = entry.key;
                  final arcChapters = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arc Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_special_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              arcName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${arcChapters.length}章)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arc Chapters
                      ...arcChapters.map((c) {
                        final isSelected = c.id == _selectedChapterId;
                        return _buildChapterListItem(
                          context,
                          chapter: c,
                          isSelected: isSelected,
                          workId: workId,
                          isWide: isWide,
                        );
                      }),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChapterListItem(
    BuildContext context, {
    required StoryChapter chapter,
    required bool isSelected,
    required int workId,
    required bool isWide,
  }) {
    final theme = Theme.of(context);

    // Status color
    Color statusColor;
    switch (chapter.status) {
      case '撰写中':
        statusColor = Colors.blue;
        break;
      case '已定稿':
        statusColor = Colors.green;
        break;
      case '待重构':
        statusColor = Colors.orange;
        break;
      case '大纲':
      default:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary)
            : Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '${chapter.sortOrder + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            chapter.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  chapter.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (chapter.wordCount > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '${chapter.wordCount}字',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            padding: EdgeInsets.zero,
            tooltip: '章节操作',
            onSelected: (val) async {
              if (val == 'edit') {
                StoryChapterDialog.show(
                  context,
                  workId: workId,
                  chapter: chapter,
                );
              } else if (val == 'delete') {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: '删除章节确认',
                  content: '确定要删除章节《${chapter.title}》吗？\n删除章节将同时清理其下的所有场景分镜。',
                  confirmLabel: '删除',
                  isDestructive: true,
                );
                if (confirmed && mounted) {
                  await ref
                      .read(storyActionsProvider)
                      .deleteChapter(chapter.id, workId);
                  if (_selectedChapterId == chapter.id) {
                    setState(() => _selectedChapterId = null);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('编辑章节'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除章节', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _selectedChapterId = chapter.id;
              if (!isWide) _narrowShowScenes = true;
            });
          },
        ),
      ),
    );
  }

  // ========================================================
  // Right Panel: Scenes Timeline & Storyboard
  // ========================================================
  Widget _buildSceneFlowPanel(
    BuildContext context,
    int workId, {
    required bool isWide,
  }) {
    final theme = Theme.of(context);

    if (_selectedChapterId == null) {
      return Center(
        child: Text(
          '请在左侧大纲中选择一个章节以查看场景分镜',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final chapterId = _selectedChapterId!;
    final chapterAsync = ref.watch(chaptersByWorkProvider(workId));
    final scenesDetailsAsync = ref.watch(
      sceneDetailsByChapterProvider(chapterId),
    );

    // Find current chapter
    final chapters = chapterAsync.valueOrNull ?? [];
    final currentChapter = chapters.any((c) => c.id == chapterId)
        ? chapters.firstWhere((c) => c.id == chapterId)
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
                        setState(() => _narrowShowScenes = false);
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
                        worldId: widget.worldId,
                        chapterId: chapterId,
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
                      worldId: widget.worldId,
                      chapterId: chapterId,
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
                    detail: detail,
                    index: index,
                    chapterId: chapterId,
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
    BuildContext context, {
    required StorySceneDetail detail,
    required int index,
    required int chapterId,
  }) {
    final theme = Theme.of(context);
    final scene = detail.scene;

    // Resolve cast characters for chips
    final allCharacters =
        ref.watch(charactersByWorldProvider(widget.worldId)).valueOrNull ?? [];
    final castCharacters = allCharacters
        .where((c) => detail.characterIds.contains(c.id))
        .toList();

    return Card(
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
                      worldId: widget.worldId,
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
                    if (confirmed && mounted) {
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
    );
  }
}
