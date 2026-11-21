import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/components/confirmation_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../data/database/app_database.dart';
import '../../providers/story_provider.dart';
import '../../providers/world_provider.dart';
import 'story_chapter_outline_panel.dart';
import 'story_scene_flow_panel.dart';
import 'story_work_dialog.dart';
import 'story_cast_dialog.dart';
import 'story_export_dialog.dart';

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
                            child: StoryChapterOutlinePanel(
                              worldId: widget.worldId,
                              workId: activeWorkId,
                              isWide: true,
                              selectedChapterId: _selectedChapterId,
                              onSelectChapter: (id) {
                                setState(() => _selectedChapterId = id);
                              },
                            ),
                          ),
                          const VerticalDivider(width: 1),

                          // Right Scene Flow Panel
                          Expanded(
                            child: StorySceneFlowPanel(
                              worldId: widget.worldId,
                              workId: activeWorkId,
                              chapterId: _selectedChapterId,
                              isWide: true,
                              onBackToOutline: () {
                                setState(() => _narrowShowScenes = false);
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Narrow / Mobile screen navigation
                      if (_narrowShowScenes && _selectedChapterId != null) {
                        return StorySceneFlowPanel(
                          worldId: widget.worldId,
                          workId: activeWorkId,
                          chapterId: _selectedChapterId,
                          isWide: false,
                          onBackToOutline: () {
                            setState(() => _narrowShowScenes = false);
                          },
                        );
                      } else {
                        return StoryChapterOutlinePanel(
                          worldId: widget.worldId,
                          workId: activeWorkId,
                          isWide: false,
                          selectedChapterId: _selectedChapterId,
                          onSelectChapter: (id) {
                            setState(() {
                              _selectedChapterId = id;
                              if (id != null) _narrowShowScenes = true;
                            });
                          },
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

          // Export Script & Outline (EXPORT-002)
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 20),
            tooltip: '导出剧本与大纲',
            onPressed: () {
              StoryExportDialog.show(context, currentWork);
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
}
