import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../providers/database_provider.dart';
import '../../data/database/app_database.dart';

class DraftsPage extends ConsumerWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('草稿箱'),
      ),
      body: FutureBuilder<List<Character>>(
        future: _loadDrafts(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drafts, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '没有草稿',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '创建人物时选择"草稿"状态会出现在这里',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      draft.name.isNotEmpty ? draft.name[0] : '?',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  title: Text(draft.name),
                  subtitle: FutureBuilder<World>(
                    future: ref
                        .read(databaseProvider)
                        .worldDao
                        .getWorldById(draft.worldId),
                    builder: (context, snapshot) {
                      return Text(snapshot.data?.name ?? '加载中');
                    },
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'publish',
                        child: Text('转为正式'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'publish') {
                        _publishDraft(ref, draft);
                      } else if (value == 'delete') {
                        _confirmDelete(context, ref, draft);
                      }
                    },
                  ),
                  onTap: () => context.push(
                    '/world/${draft.worldId}/character/${draft.id}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Character>> _loadDrafts(WidgetRef ref) async {
    return ref.read(databaseProvider).characterDao.getDraftCharacters();
  }

  void _publishDraft(WidgetRef ref, Character character) async {
    await ref.read(databaseProvider).characterDao.updateCharacter(
          CharactersCompanion(
            id: drift.Value(character.id),
            worldId: drift.Value(character.worldId),
            name: drift.Value(character.name),
            avatarPath: drift.Value(character.avatarPath),
            status: const drift.Value(0),
            isFavorite: drift.Value(character.isFavorite),
            isPinned: drift.Value(character.isPinned),
            createdAt: drift.Value(character.createdAt),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Character character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除草稿'),
        content: Text('确定要删除"${character.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(databaseProvider)
                  .characterDao
                  .deleteCharacter(character.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
