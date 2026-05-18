import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/world_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/character_provider.dart';
import '../../data/database/app_database.dart';
import 'group_dialog.dart';

class TreeSidebar extends ConsumerStatefulWidget {
  final int? selectedWorldId;
  final int? selectedGroupId;
  final int? selectedCharacterId;
  final ValueChanged<int?> onWorldSelected;
  final ValueChanged<int?> onGroupSelected;
  final ValueChanged<int?> onCharacterSelected;

  const TreeSidebar({
    super.key,
    this.selectedWorldId,
    this.selectedGroupId,
    this.selectedCharacterId,
    required this.onWorldSelected,
    required this.onGroupSelected,
    required this.onCharacterSelected,
  });

  @override
  ConsumerState<TreeSidebar> createState() => _TreeSidebarState();
}

class _TreeSidebarState extends ConsumerState<TreeSidebar> {
  final Set<int> _expandedWorlds = {};

  @override
  Widget build(BuildContext context) {
    final worldsAsync = ref.watch(worldsProvider);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.account_tree, size: 20),
                const SizedBox(width: 8),
                const Text('导航', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: '新建世界观',
                  onPressed: () => _showCreateWorldDialog(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: worldsAsync.when(
              data: (worlds) {
                if (worlds.isEmpty) {
                  return const Center(
                    child: Text('还没有世界观\n点击上方 + 创建', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: worlds.map((world) {
                    return _WorldTreeNode(
                      world: world,
                      isExpanded: _expandedWorlds.contains(world.id),
                      isSelected: widget.selectedWorldId == world.id && widget.selectedGroupId == null && widget.selectedCharacterId == null,
                      selectedGroupId: widget.selectedGroupId,
                      selectedCharacterId: widget.selectedCharacterId,
                      onToggle: () {
                        setState(() {
                          if (_expandedWorlds.contains(world.id)) {
                            _expandedWorlds.remove(world.id);
                          } else {
                            _expandedWorlds.add(world.id);
                          }
                        });
                      },
                      onWorldTap: () {
                        widget.onWorldSelected(world.id);
                        widget.onGroupSelected(null);
                        widget.onCharacterSelected(null);
                      },
                      onGroupSelected: (groupId) {
                        widget.onWorldSelected(world.id);
                        widget.onGroupSelected(groupId);
                        widget.onCharacterSelected(null);
                      },
                      onCharacterSelected: (characterId, groupId) {
                        widget.onWorldSelected(world.id);
                        widget.onGroupSelected(groupId);
                        widget.onCharacterSelected(characterId);
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateWorldDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建世界观'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '世界观名称', hintText: '例如：魔法大陆'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(worldActionsProvider).create(name);
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _WorldTreeNode extends ConsumerStatefulWidget {
  final World world;
  final bool isExpanded;
  final bool isSelected;
  final int? selectedGroupId;
  final int? selectedCharacterId;
  final VoidCallback onToggle;
  final VoidCallback onWorldTap;
  final ValueChanged<int?> onGroupSelected;
  final void Function(int characterId, int? groupId) onCharacterSelected;

  const _WorldTreeNode({
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
  ConsumerState<_WorldTreeNode> createState() => _WorldTreeNodeState();
}

class _WorldTreeNodeState extends ConsumerState<_WorldTreeNode> {
  final Set<int> _expandedGroups = {};
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.world.id));
    final charactersAsync = ref.watch(charactersByWorldProvider(widget.world.id));

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
            ref.read(groupActionsProvider).removeCharacterFromGroup(details.data, group.id);
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
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : null,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Icon(
                        widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.public, size: 16, color: _isDragOver ? Colors.green : Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.world.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      tooltip: '新建分组',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                      _GroupTreeNode(
                        group: group,
                        worldId: widget.world.id,
                        allCharacters: characters,
                        isSelected: widget.selectedGroupId == group.id && widget.selectedCharacterId == null,
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
                    final groupChars = ref.watch(charactersByGroupProvider(group.id));
                    groupChars.whenData((chars) {
                      for (final c in chars) {
                        groupedCharacterIds.add(c.id);
                      }
                    });
                  }

                  // 未分组的人物显示在分组下面
                  final ungrouped = characters.where((c) => !groupedCharacterIds.contains(c.id)).toList();
                  for (final character in ungrouped) {
                    final isCharSelected = widget.selectedCharacterId == character.id;
                    widgets.add(
                      Draggable<int>(
                        data: character.id,
                        feedback: Material(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(character.name, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => widget.onCharacterSelected(character.id, null),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.only(left: 32, right: 8),
                            color: isCharSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(character.name.isNotEmpty ? character.name[0] : '?', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(character.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
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
    showDialog(context: context, builder: (_) => GroupDialog(worldId: widget.world.id));
  }
}

// 分组节点
class _GroupTreeNode extends ConsumerStatefulWidget {
  final Group group;
  final int worldId;
  final List<Character> allCharacters;
  final bool isSelected;
  final int? selectedCharacterId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onGroupTap;
  final void Function(int characterId, int? groupId) onCharacterSelected;

  const _GroupTreeNode({
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
  ConsumerState<_GroupTreeNode> createState() => _GroupTreeNodeState();
}

class _GroupTreeNodeState extends ConsumerState<_GroupTreeNode> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final groupCharsAsync = ref.watch(charactersByGroupProvider(widget.group.id));

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
        ref.read(groupActionsProvider).addCharacterToGroup(details.data, widget.group.id);
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
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : null,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Icon(
                        widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(Icons.folder, size: 16, color: _isDragOver ? Colors.green : Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.group.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    ),
                    // 右键菜单
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑分组')),
                        const PopupMenuItem(value: 'delete', child: Text('删除分组', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(context: context, builder: (_) => GroupDialog(worldId: widget.worldId, group: widget.group));
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
                      final isSelected = widget.selectedCharacterId == character.id;
                      return Draggable<int>(
                        data: character.id,
                        feedback: Material(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(character.name, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => widget.onCharacterSelected(character.id, widget.group.id),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.only(left: 56, right: 8),
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(character.name.isNotEmpty ? character.name[0] : '?', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(character.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                // 从分组移除
                                GestureDetector(
                                  onTap: () {
                                    ref.read(groupActionsProvider).removeCharacterFromGroup(character.id, widget.group.id);
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
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
