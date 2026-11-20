import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/story_provider.dart';
import '../../core/design/components/confirmation_dialog.dart';
import 'story_chapter_dialog.dart';

class StoryChapterOutlinePanel extends ConsumerWidget {
  final int worldId;
  final int workId;
  final bool isWide;
  final int? selectedChapterId;
  final ValueChanged<int?> onSelectChapter;

  const StoryChapterOutlinePanel({
    super.key,
    required this.worldId,
    required this.workId,
    required this.isWide,
    required this.selectedChapterId,
    required this.onSelectChapter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  if (newId != null) {
                    onSelectChapter(newId);
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
                            if (newId != null) {
                              onSelectChapter(newId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Auto-select first chapter if none selected or invalid
              if (selectedChapterId == null ||
                  !chapters.any((c) => c.id == selectedChapterId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chapters.isNotEmpty) {
                    onSelectChapter(chapters.first.id);
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
                        final isSelected = c.id == selectedChapterId;
                        return _buildChapterListItem(
                          context,
                          ref,
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
    BuildContext context,
    WidgetRef ref, {
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
                if (confirmed) {
                  await ref
                      .read(storyActionsProvider)
                      .deleteChapter(chapter.id, workId);
                  if (selectedChapterId == chapter.id) {
                    onSelectChapter(null);
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
            onSelectChapter(chapter.id);
          },
        ),
      ),
    );
  }
}
