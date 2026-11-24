import 'package:flutter/material.dart';

/// Data result returned from snapshot creation dialog.
class SnapshotDialogResult {
  final String title;
  final String note;
  final bool isMilestone;

  const SnapshotDialogResult({
    required this.title,
    required this.note,
    required this.isMilestone,
  });
}

/// Shows a dialog for user to enter snapshot title, note, and milestone flag.
Future<SnapshotDialogResult?> showCreateSnapshotDialog(
  BuildContext context,
) async {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  bool isMilestone = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.bookmark_add_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text('保存新设定快照'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '快照说明 / 版本标签 *',
                    hintText: '例如：初稿草案、大战后剧情大修',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '版本备注（可选）',
                    hintText: '记录本次快照的核心变动原因...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isMilestone,
                  onChanged: (val) {
                    setDialogState(() => isMilestone = val ?? false);
                  },
                  title: const Text(
                    '设为重要里程碑快照 (⭐)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    '里程碑快照受到永久保护，历史版本超出上限时绝不会被自动修剪淘汰。',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('保存快照'),
            ),
          ],
        );
      },
    ),
  );

  SnapshotDialogResult? result;
  if (confirmed == true) {
    result = SnapshotDialogResult(
      title: titleController.text.trim(),
      note: noteController.text.trim(),
      isMilestone: isMilestone,
    );
  }
  titleController.dispose();
  noteController.dispose();
  return result;
}
