import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/group_provider.dart';
import '../../data/database/app_database.dart';
import '../character/character_dialog.dart';

class WorldDetailPage extends ConsumerWidget {
  final int worldId;
  final int? selectedGroupId;
  final void Function(int characterId)? onCharacterSelected;

  const WorldDetailPage({
    super.key,
    required this.worldId,
    this.selectedGroupId,
    this.onCharacterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldAsync = ref.watch(worldByIdProvider(worldId));
    final charactersAsync = ref.watch(charactersByWorldProvider(worldId));
    final groupsAsync = ref.watch(groupsByWorldProvider(worldId));

    // 根据选中的分组过滤人物
    final filteredCharactersAsync = selectedGroupId != null
        ? ref.watch(charactersByGroupProvider(selectedGroupId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (world) => Text(world.name),
          loading: () => const Text('加载中'),
          error: (_, __) => const Text('错误'),
        ),
      ),
      body: selectedGroupId != null
          ? _buildGroupCharacters(context, ref, filteredCharactersAsync)
          : _buildAllCharacters(context, ref, charactersAsync, groupsAsync),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 显示分组下的人物
  Widget _buildGroupCharacters(BuildContext context, WidgetRef ref, AsyncValue<List<Character>>? charactersAsync) {
    if (charactersAsync == null) return const SizedBox.shrink();

    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('该分组下暂无人物', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('从左侧拖拽人物到此分组', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: characters.map((c) => _CharacterCard(
            character: c,
            onTap: () => onCharacterSelected?.call(c.id),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('错误: $error')),
    );
  }

  // 显示所有人物（世界观视图）
  Widget _buildAllCharacters(BuildContext context, WidgetRef ref, AsyncValue<List<Character>> charactersAsync, AsyncValue<List<Group>> groupsAsync) {
    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('还没有人物', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('点击右下角按钮创建第一个人物', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final pinned = characters.where((c) => c.isPinned).toList();
        final normal = characters.where((c) => !c.isPinned && c.status == 0).toList();
        final drafts = characters.where((c) => c.status == 1).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pinned.isNotEmpty) ...[
              const Text('置顶', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              ...pinned.map((c) => _CharacterCard(
                character: c,
                onTap: () => onCharacterSelected?.call(c.id),
              )),
              const SizedBox(height: 16),
            ],
            if (normal.isNotEmpty) ...[
              const Text('人物', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              ...normal.map((c) => _CharacterCard(
                character: c,
                onTap: () => onCharacterSelected?.call(c.id),
              )),
            ],
            if (drafts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('草稿', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              ...drafts.map((c) => _CharacterCard(
                character: c,
                onTap: () => onCharacterSelected?.call(c.id),
              )),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('错误: $error')),
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
  final VoidCallback? onTap;

  const _CharacterCard({required this.character, this.onTap});

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
                ref.read(characterActionsProvider).toggleFavorite(character);
              },
            ),
            IconButton(
              icon: Icon(
                character.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () {
                ref.read(characterActionsProvider).togglePin(character);
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
