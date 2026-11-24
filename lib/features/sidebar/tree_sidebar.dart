import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/world_provider.dart';
import 'widgets/world_tree_node.dart';

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
          right: BorderSide(color: Theme.of(context).dividerColor),
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
                const Text(
                  '导航',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
                    child: Text(
                      '还没有世界观\n点击上方 + 创建',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: worlds.map((world) {
                    return WorldTreeNode(
                      world: world,
                      isExpanded: _expandedWorlds.contains(world.id),
                      isSelected:
                          widget.selectedWorldId == world.id &&
                          widget.selectedGroupId == null &&
                          widget.selectedCharacterId == null,
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
          decoration: const InputDecoration(
            labelText: '世界观名称',
            hintText: '例如：魔法大陆',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
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
    ).then((_) => controller.dispose());
  }
}
