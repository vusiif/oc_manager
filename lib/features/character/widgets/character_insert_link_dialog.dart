import 'package:flutter/material.dart';

import '../../../core/design/components/oc_avatar.dart';
import '../../../data/database/app_database.dart';

/// Dialog to search and pick another character to insert a [[Name]] wiki link.
void showCharacterInsertLinkDialog(
  BuildContext context, {
  required List<Character> allChars,
  required int currentCharacterId,
  required ValueChanged<String> onSelectName,
}) {
  final candidates = allChars.where((c) => c.id != currentCharacterId).toList();

  showDialog(
    context: context,
    builder: (ctx) {
      String query = '';
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = candidates.where((c) {
            if (query.isEmpty) return true;
            return c.name.toLowerCase().contains(query.toLowerCase());
          }).toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.link_rounded, size: 20),
                SizedBox(width: 8),
                Text('插入双向人名链接'),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索角色姓名…',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setDialogState(() => query = val.trim());
                    },
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('无匹配角色'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final char = filtered[index];
                              return ListTile(
                                dense: true,
                                leading: OcAvatar(
                                  avatarPath: char.avatarPath,
                                  name: char.name,
                                  gender: char.gender,
                                  size: 28,
                                ),
                                title: Text(char.name),
                                trailing: const Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                ),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  onSelectName(char.name);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消'),
              ),
            ],
          );
        },
      );
    },
  );
}
