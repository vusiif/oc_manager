import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/character_provider.dart';
import '../../../providers/group_provider.dart';
import '../group_dialog.dart';
import 'group_tree_node.dart';

/// Tree node representing a world, rendering child groups and ungrouped characters.
class WorldTreeNode extends ConsumerStatefulWidget {
  final World world;
  final bool isExpanded;
  final bool isSelected;
  final int? selectedGroupId;
  final int? selectedCharacterId;
  final VoidCallback onToggle;
  final VoidCallback onWorldTap;
  final ValueChanged<int?> onGroupSelected;
  final void Function(int characterId, int? groupId) onCharacterSelected;

  const WorldTreeNode({
    super.key,
    required this.world,
    required this.isExpanded,
    required this.isSelected,
    required this.selectedGroupId,
    required this.selectedCharacterId,
    required this.onToggle,
    required this.onWorldTap,
    required this.onGroupSelected,
    required this.onCharacterSelected,
  });

  @override
  ConsumerState<WorldTreeNode> createState() => _WorldTreeNodeState();
}

class _WorldTreeNodeState extends ConsumerState<WorldTreeNode> {
  final Set<int> _expandedGroups = {};
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.world.id));
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.world.id),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        // 从所有分组中移除该人物
        groupsAsync.whenData((groups) {
          for (final group in groups) {
            ref
                .read(groupActionsProvider)
                .removeCharacterFromGroup(details.data, group.id);
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onWorldTap,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: _isDragOver
                    ? Colors.green.withValues(alpha: 0.2)
                    : widget.isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.public,
                      size: 16,
                      color: _isDragOver ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.world.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      tooltip: '新建分组',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () => _showCreateGroupDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isExpanded)
              groupsAsync.when(
                data: (groups) {
                  return charactersAsync.when(
                    data: (characters) {
                      final widgets = <Widget>[];

                      // 用户创建的分组
                      for (final group in groups) {
                        widgets.add(
                          GroupTreeNode(
                            group: group,
                            worldId: widget.world.id,
                            allCharacters: characters,
                            isSelected:
                                widget.selectedGroupId == group.id &&
                                widget.selectedCharacterId == null,
                            selectedCharacterId: widget.selectedCharacterId,
                            isExpanded: _expandedGroups.contains(group.id),
                            onToggle: () {
                              setState(() {
                                if (_expandedGroups.contains(group.id)) {
                                  _expandedGroups.remove(group.id);
                                } else {
                                  _expandedGroups.add(group.id);
                                }
                              });
                            },
                            onGroupTap: () => widget.onGroupSelected(group.id),
                            onCharacterSelected: widget.onCharacterSelected,
                          ),
                        );
                      }

                      // 获取所有已分组的人物 ID
                      final groupedCharacterIds = <int>{};
                      for (final group in groups) {
                        final groupChars = ref.watch(
                          charactersByGroupProvider(group.id),
                        );
                        groupChars.whenData((chars) {
                          for (final c in chars) {
                            groupedCharacterIds.add(c.id);
                          }
                        });
                      }

                      // 未分组的人物显示在分组下面
                      final ungrouped = characters
                          .where((c) => !groupedCharacterIds.contains(c.id))
                          .toList();
                      for (final character in ungrouped) {
                        final isCharSelected =
                            widget.selectedCharacterId == character.id;
                        widgets.add(
                          Draggable<int>(
                            data: character.id,
                            feedback: Material(
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Text(
                                  character.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => widget.onCharacterSelected(
                                character.id,
                                null,
                              ),
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  right: 8,
                                ),
                                color: isCharSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3)
                                    : null,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      child: Text(
                                        character.name.isNotEmpty
                                            ? character.name[0]
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        character.name,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widgets,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('错误: $e'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('错误: $e'),
              ),
          ],
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GroupDialog(worldId: widget.world.id),
    );
  }
}
