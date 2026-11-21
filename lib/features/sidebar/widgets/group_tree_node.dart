import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/group_provider.dart';
import '../group_dialog.dart';

/// Tree node representing a group under a world, with drag-and-drop character assignment.
class GroupTreeNode extends ConsumerStatefulWidget {
  final Group group;
  final int worldId;
  final List<Character> allCharacters;
  final bool isSelected;
  final int? selectedCharacterId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onGroupTap;
  final void Function(int characterId, int? groupId) onCharacterSelected;

  const GroupTreeNode({
    super.key,
    required this.group,
    required this.worldId,
    required this.allCharacters,
    required this.isSelected,
    required this.selectedCharacterId,
    required this.isExpanded,
    required this.onToggle,
    required this.onGroupTap,
    required this.onCharacterSelected,
  });

  @override
  ConsumerState<GroupTreeNode> createState() => _GroupTreeNodeState();
}

class _GroupTreeNodeState extends ConsumerState<GroupTreeNode> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final groupCharsAsync = ref.watch(
      charactersByGroupProvider(widget.group.id),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _isDragOver = false);
        try {
          await ref
              .read(groupActionsProvider)
              .addCharacterToGroup(details.data, widget.group.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$e')));
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onGroupTap,
              child: Container(
                height: 32,
                padding: const EdgeInsets.only(left: 32, right: 8),
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
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: _isDragOver ? Colors.green : Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.group.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 右键菜单
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑分组')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            '删除分组',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => GroupDialog(
                              worldId: widget.worldId,
                              group: widget.group,
                            ),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isExpanded)
              groupCharsAsync.when(
                data: (characters) {
                  return Column(
                    children: characters.map((character) {
                      final isSelected =
                          widget.selectedCharacterId == character.id;
                      return Draggable<int>(
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
                            widget.group.id,
                          ),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.only(left: 56, right: 8),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
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
                                // 从分组移除
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(groupActionsProvider)
                                        .removeCharacterFromGroup(
                                          character.id,
                                          widget.group.id,
                                        );
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除"${widget.group.name}"吗？\n分组下的人物不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(groupActionsProvider).delete(widget.group.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
