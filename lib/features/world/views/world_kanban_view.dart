import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../core/constants/character_status.dart';
import '../../../core/design/components/oc_avatar.dart';
import '../../../providers/character_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/database_provider.dart';

enum KanbanGroupBy {
  status, // 按创作状态
  group, // 按所属分组
}

/// 世界观泳道看板视图 (Kanban Board)
class WorldKanbanView extends ConsumerStatefulWidget {
  final int worldId;
  final List<Character> characters;
  final List<Group> groups;
  final void Function(int characterId)? onCharacterSelected;

  const WorldKanbanView({
    super.key,
    required this.worldId,
    required this.characters,
    required this.groups,
    this.onCharacterSelected,
  });

  @override
  ConsumerState<WorldKanbanView> createState() => _WorldKanbanViewState();
}

class _WorldKanbanViewState extends ConsumerState<WorldKanbanView> {
  KanbanGroupBy _groupBy = KanbanGroupBy.status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 顶部控制条：分列维度切换与统计
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '看板维度: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<KanbanGroupBy>(
                segments: const [
                  ButtonSegment(
                    value: KanbanGroupBy.status,
                    label: Text('按创作状态'),
                    icon: Icon(Icons.tune_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: KanbanGroupBy.group,
                    label: Text('按阵营组织'),
                    icon: Icon(Icons.groups_rounded, size: 16),
                  ),
                ],
                selected: {_groupBy},
                onSelectionChanged: (set) {
                  setState(() => _groupBy = set.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${widget.characters.length} 位人物 · 支持卡片拖拽跨列流转',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 泳道卡片横向滚动区域
        Expanded(
          child: _groupBy == KanbanGroupBy.status
              ? _buildStatusKanban(context)
              : _buildGroupKanban(context),
        ),
      ],
    );
  }

  /// 按创作状态分列
  Widget _buildStatusKanban(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: CharacterCreationStatus.all.length,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final status = CharacterCreationStatus.all[index];
        final columnChars = widget.characters
            .where((c) => c.status == status.code)
            .toList();

        return _KanbanColumn(
          title: status.label,
          icon: status.icon,
          color: status.color,
          count: columnChars.length,
          characters: columnChars,
          onCharacterSelected: widget.onCharacterSelected,
          onAcceptCharacter: (char) async {
            if (char.status != status.code) {
              await ref
                  .read(characterActionsProvider)
                  .updateStatus(char.id, status.code);
            }
          },
        );
      },
    );
  }

  /// 按阵营/分组分列
  Widget _buildGroupKanban(BuildContext context) {
    // 异步监听各个分组的人物 ID 映射
    final columns = <_GroupColumnData>[];

    for (final g in widget.groups) {
      columns.add(_GroupColumnData(
        groupId: g.id,
        title: g.name,
      ));
    }

    // 未分组列
    columns.add(const _GroupColumnData(
      groupId: null,
      title: '未归属阵营',
    ));

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: columns.length,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final col = columns[index];
        return _GroupKanbanColumnWrapper(
          worldId: widget.worldId,
          col: col,
          allCharacters: widget.characters,
          onCharacterSelected: widget.onCharacterSelected,
        );
      },
    );
  }
}

class _GroupColumnData {
  final int? groupId;
  final String title;

  const _GroupColumnData({
    required this.groupId,
    required this.title,
  });
}

class _GroupKanbanColumnWrapper extends ConsumerWidget {
  final int worldId;
  final _GroupColumnData col;
  final List<Character> allCharacters;
  final void Function(int characterId)? onCharacterSelected;

  const _GroupKanbanColumnWrapper({
    required this.worldId,
    required this.col,
    required this.allCharacters,
    this.onCharacterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (col.groupId != null) {
      final charsAsync = ref.watch(charactersByGroupProvider(col.groupId!));
      final chars = charsAsync.valueOrNull ?? [];

      return _KanbanColumn(
        title: col.title,
        icon: Icons.shield_outlined,
        color: Theme.of(context).colorScheme.primary,
        count: chars.length,
        characters: chars,
        onCharacterSelected: onCharacterSelected,
        onAcceptCharacter: (char) async {
          final groupDao = ref.read(groupDaoProvider);
          final currentGroupIds =
              await groupDao.getGroupIdsByCharacter(char.id);
          if (!currentGroupIds.contains(col.groupId!)) {
            await groupDao.setCharacterGroups(char.id, [col.groupId!]);
            ref.invalidate(charactersByGroupProvider);
            ref.invalidate(unassignedCharactersByWorldProvider(worldId));
          }
        },
      );
    } else {
      // 未分组人物筛选与响应式展示
      final unassignedAsync = ref.watch(unassignedCharactersByWorldProvider(worldId));
      final unassignedChars = unassignedAsync.valueOrNull ?? [];

      return _KanbanColumn(
        title: col.title,
        icon: Icons.help_outline_rounded,
        color: Colors.grey,
        count: unassignedChars.length,
        characters: unassignedChars,
        onCharacterSelected: onCharacterSelected,
        onAcceptCharacter: (char) async {
          final groupDao = ref.read(groupDaoProvider);
          await groupDao.setCharacterGroups(char.id, []);
          ref.invalidate(charactersByGroupProvider);
          ref.invalidate(unassignedCharactersByWorldProvider(worldId));
        },
      );
    }
  }
}

/// 单个看板列 (Column)
class _KanbanColumn extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<Character> characters;
  final void Function(int characterId)? onCharacterSelected;
  final Future<void> Function(Character character) onAcceptCharacter;

  const _KanbanColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.characters,
    this.onCharacterSelected,
    required this.onAcceptCharacter,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragOver
              ? widget.color
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: _isDragOver ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 列标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 17, color: widget.color),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 拖拽放入区域与卡片列表
          Expanded(
            child: DragTarget<Character>(
              onWillAcceptWithDetails: (details) {
                setState(() => _isDragOver = true);
                return true;
              },
              onLeave: (_) {
                setState(() => _isDragOver = false);
              },
              onAcceptWithDetails: (details) async {
                setState(() => _isDragOver = false);
                await widget.onAcceptCharacter(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                if (widget.characters.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _isDragOver ? '松开以移动至此列' : '暂无人物\n拖拽卡片至此',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _isDragOver
                              ? widget.color
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: widget.characters.length,
                  itemBuilder: (context, index) {
                    final char = widget.characters[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DraggableKanbanCard(
                        character: char,
                        onTap: () => widget.onCharacterSelected?.call(char.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 看板中的可拖拽角色卡片
class _DraggableKanbanCard extends ConsumerWidget {
  final Character character;
  final VoidCallback onTap;

  const _DraggableKanbanCard({
    required this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusConfig = CharacterCreationStatus.find(character.status);

    final cardContent = Container(
      width: 258,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: character.isPinned
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: character.isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 姓名 + 置顶/收藏图标
          Row(
            children: [
              OcAvatar(
                avatarPath: character.avatarPath,
                name: character.name,
                gender: character.gender,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (character.gender.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        character.gender,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (character.isPinned)
                Icon(
                  Icons.push_pin_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              if (character.isFavorite) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 底部状态微标与描述切片
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusConfig.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusConfig.icon, size: 11, color: statusConfig.color),
                    const SizedBox(width: 3),
                    Text(
                      statusConfig.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: statusConfig.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_horiz_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: '修改状态',
                itemBuilder: (context) => [
                  for (final s in CharacterCreationStatus.all)
                    PopupMenuItem(
                      value: s.code,
                      child: Row(
                        children: [
                          Icon(s.icon, size: 16, color: s.color),
                          const SizedBox(width: 8),
                          Text(s.label),
                        ],
                      ),
                    ),
                ],
                onSelected: (newCode) {
                  ref
                      .read(characterActionsProvider)
                      .updateStatus(character.id, newCode);
                },
              ),
            ],
          ),
        ],
      ),
    );

    return Draggable<Character>(
      data: character,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(opacity: 0.9, child: cardContent),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: cardContent,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: cardContent,
      ),
    );
  }
}
