import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/world_provider.dart';
import 'world_dialog.dart';

class WorldListPage extends ConsumerWidget {
  const WorldListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(worldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('世界观'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label),
                  title: Text('标签管理'),
                ),
              ),
              const PopupMenuItem(
                value: 'drafts',
                child: ListTile(
                  leading: Icon(Icons.drafts),
                  title: Text('草稿箱'),
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('回收站'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('设置'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'tags') {
                context.push('/tags');
              } else if (value == 'drafts') {
                context.push('/drafts');
              } else if (value == 'trash') {
                context.push('/trash');
              } else if (value == 'settings') {
                // TODO: 设置页面
              }
            },
          ),
        ],
      ),
      body: worldsAsync.when(
        data: (worlds) {
          if (worlds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '还没有世界观',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角按钮创建第一个世界观',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: worlds.length,
            itemBuilder: (context, index) {
              final world = worlds[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.public),
                  ),
                  title: Text(
                    world.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: world.description != null
                      ? Text(
                          world.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (world.isLocked)
                        const Icon(Icons.lock, color: Colors.orange),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context, ref, world),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, ref, world),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/world/${world.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const WorldDialog(),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, dynamic world) {
    showDialog(
      context: context,
      builder: (context) => WorldDialog(world: world),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, dynamic world) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除世界观'),
        content: Text('确定要删除"${world.name}"吗？\n该世界观下的所有人物也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(worldActionsProvider).delete(world.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
