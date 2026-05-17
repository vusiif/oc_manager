import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';
import '../character/character_dialog.dart';

class WorldDetailPage extends ConsumerWidget {
  final int worldId;

  const WorldDetailPage({super.key, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldAsync = ref.watch(worldByIdProvider(worldId));
    final charactersAsync = ref.watch(charactersByWorldProvider(worldId));

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (world) => Text(world.name),
          loading: () => const Text('加载中'),
          error: (_, __) => const Text('错误'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: '关系图',
            onPressed: () => context.push('/world/$worldId/graph'),
          ),
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: '标签管理',
            onPressed: () => context.push('/tags'),
          ),
        ],
      ),
      body: charactersAsync.when(
        data: (characters) {
          if (characters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '还没有人物',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角按钮创建第一个人物',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final pinned =
              characters.where((c) => c.isPinned).toList();
          final normal = characters
              .where((c) => !c.isPinned && c.status == 0)
              .toList();
          final drafts =
              characters.where((c) => c.status == 1).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pinned.isNotEmpty) ...[
                const Text('置顶',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                ...pinned.map((c) => _CharacterCard(
                      character: c,
                      worldId: worldId,
                    )),
                const SizedBox(height: 16),
              ],
              if (normal.isNotEmpty) ...[
                const Text('人物',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                ...normal.map((c) => _CharacterCard(
                      character: c,
                      worldId: worldId,
                    )),
              ],
              if (drafts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('草稿',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                ...drafts.map((c) => _CharacterCard(
                      character: c,
                      worldId: worldId,
                    )),
              ],
            ],
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
      builder: (context) => CharacterDialog(worldId: worldId),
    );
  }
}

class _CharacterCard extends ConsumerWidget {
  final dynamic character;
  final int worldId;

  const _CharacterCard({required this.character, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: character.status == 1
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            character.name.isNotEmpty ? character.name[0] : '?',
            style: TextStyle(
              color: character.status == 1
                  ? Colors.grey
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(character.name),
        subtitle: character.status == 1 ? const Text('草稿') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                character.isFavorite ? Icons.star : Icons.star_border,
                color: character.isFavorite ? Colors.amber : null,
              ),
              onPressed: () {
                ref
                    .read(characterActionsProvider)
                    .toggleFavorite(character);
              },
            ),
            IconButton(
              icon: Icon(
                character.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              onPressed: () {
                ref.read(characterActionsProvider).togglePin(character);
              },
            ),
          ],
        ),
        onTap: () => context.push('/world/$worldId/character/${character.id}'),
      ),
    );
  }
}
