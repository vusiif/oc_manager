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
                      onDeleted: () async {
                        await ref
                            .read(tagActionsProvider)
                            .removeFromCharacter(characterId, tag.id);
                        ref.invalidate(characterTagsProvider(characterId));
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
    final parentRef = ref;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, consumerRef, _) {
          final allTags = consumerRef.watch(tagsProvider).valueOrNull ?? [];
          final myTags = consumerRef.watch(characterTagsProvider(characterId)).valueOrNull ?? [];
          final currentTagIds = myTags.map((t) => t.id).toSet();

          return AlertDialog(
            title: const Text('选择标签'),
            content: SizedBox(
              width: double.maxFinite,
              child: allTags.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('暂无标签，请先创建', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
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
                          onTap: () async {
                            if (isSelected) {
                              await parentRef
                                  .read(tagActionsProvider)
                                  .removeFromCharacter(characterId, tag.id);
                            } else {
                              await parentRef
                                  .read(tagActionsProvider)
                                  .addToCharacter(characterId, tag.id);
                            }
                            consumerRef.invalidate(characterTagsProvider(characterId));
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新建标签'),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateTagDialog(context, parentRef);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedColor = '#FF6B6B';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '标签名称',
                  hintText: '例如：主角团、反派',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('选择颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedColor = color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(tagActionsProvider).create(name, selectedColor);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
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

const _predefinedColors = [
  '#FF6B6B', // 红色
  '#FF8E53', // 橙色
  '#FFD93D', // 黄色
  '#6BCB77', // 绿色
  '#4D96FF', // 蓝色
  '#9B59B6', // 紫色
  '#FF69B4', // 粉色
  '#95A5A6', // 灰色
];
