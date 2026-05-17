import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tag_provider.dart';
import '../../data/database/app_database.dart';

class TagSelector extends ConsumerWidget {
  final int characterId;

  const TagSelector({super.key, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterTagsAsync = ref.watch(characterTagsProvider(characterId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('标签',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      _showTagPicker(context, ref, characterTagsAsync),
                ),
              ],
            ),
            const Divider(),
            characterTagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('暂无标签', style: TextStyle(color: Colors.grey)),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final color = _parseColor(tag.color);
                    return Chip(
                      label: Text(tag.name),
                      backgroundColor: color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: color),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        ref
                            .read(tagActionsProvider)
                            .removeFromCharacter(characterId, tag.id);
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('错误: $error'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagPicker(
      BuildContext context, WidgetRef ref, AsyncValue<List<Tag>> characterTagsAsync) {
    final allTags = ref.read(tagsProvider).valueOrNull ?? [];
    final currentTagIds =
        characterTagsAsync.valueOrNull?.map((t) => t.id).toSet() ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择标签'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = currentTagIds.contains(tag.id);
              final color = _parseColor(tag.color);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  radius: 12,
                ),
                title: Text(tag.name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  if (isSelected) {
                    ref
                        .read(tagActionsProvider)
                        .removeFromCharacter(characterId, tag.id);
                  } else {
                    ref
                        .read(tagActionsProvider)
                        .addToCharacter(characterId, tag.id);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
