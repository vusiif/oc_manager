import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/trash_provider.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'empty',
                child: Text('清空回收站',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'empty') {
                _confirmEmpty(context, ref);
              }
            },
          ),
        ],
      ),
      body: trashAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('回收站是空的',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('删除的人物和世界观会出现在这里',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data =
                  jsonDecode(item.itemData) as Map<String, dynamic>;
              final name = data['name'] as String? ?? '未知';
              final isCharacter = item.itemType == 'character';
              final deletedAt = item.deletedAt;
              final daysLeft =
                  30 - DateTime.now().difference(deletedAt).inDays;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    isCharacter ? Icons.person : Icons.public,
                    color: Colors.grey,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    '${isCharacter ? "人物" : "世界观"} · '
                    '删除于 ${_formatDate(deletedAt)}'
                    '${daysLeft > 0 ? " · $daysLeft天后自动清理" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, size: 20),
                        tooltip: '恢复',
                        onPressed: () =>
                            _restore(context, ref, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            size: 20, color: Colors.red),
                        tooltip: '永久删除',
                        onPressed: () =>
                            _confirmPermanentDelete(context, ref, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('错误: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _restore(
      BuildContext context, WidgetRef ref, dynamic item) async {
    final actions = ref.read(trashActionsProvider);
    if (item.itemType == 'character') {
      await actions.restoreCharacter(item);
    } else {
      await actions.restoreWorld(item);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复')),
      );
    }
  }

  void _confirmPermanentDelete(
      BuildContext context, WidgetRef ref, dynamic item) {
    final data = jsonDecode(item.itemData) as Map<String, dynamic>;
    final name = data['name'] as String? ?? '未知';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除'),
        content: Text('确定要永久删除"$name"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(trashActionsProvider)
                  .permanentDelete(item.id);
              if (context.mounted) Navigator.pop(context);
            },
            child:
                const Text('永久删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmEmpty(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要永久删除所有回收站中的内容吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(trashActionsProvider).emptyTrash();
              if (context.mounted) Navigator.pop(context);
            },
            child:
                const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
