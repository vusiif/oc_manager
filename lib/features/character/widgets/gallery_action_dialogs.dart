import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/image_storage_service.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/character_provider.dart';

/// Shows dialog to upload and tag a new gallery portrait / variation.
Future<void> showGalleryUploadDialog(
  BuildContext context, {
  required String pickedPath,
  required int characterId,
  required int worldId,
  required WidgetRef ref,
}) async {
  final captionCtrl = TextEditingController(text: '常服');
  bool isPrimary = false;

  const suggestions = ['常服', '战斗服', '礼服', '立绘三视图', '幼年期', 'Q版表情', '约稿插画'];

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        title: const Text('添加画廊立绘 / 差分'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 140,
                    height: 180,
                    child: Image.file(
                      File(pickedPath),
                      fit: BoxFit.cover,
                      cacheWidth: 350,
                      cacheHeight: 450,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_rounded, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(
                  labelText: '分类 / 标签备注',
                  hintText: '如：战斗形态、三视图、礼服',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: suggestions.map((tag) {
                  return ActionChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setDlgState(() {
                        captionCtrl.text = tag;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '同时设为角色主封面/头像',
                  style: TextStyle(fontSize: 13),
                ),
                value: isPrimary,
                onChanged: (v) => setDlgState(() => isPrimary = v ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final relPath = await ImageStorageService.instance
                    .saveGalleryImage(
                      sourcePath: pickedPath,
                      characterId: characterId,
                    );

                await ref
                    .read(characterActionsProvider)
                    .addGalleryImage(
                      characterId: characterId,
                      imagePath: relPath,
                      caption: captionCtrl.text.trim(),
                      isPrimary: isPrimary,
                    );

                if (isPrimary) {
                  ref.invalidate(characterByIdProvider(characterId));
                  ref.invalidate(charactersByWorldProvider(worldId));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('保存立绘失败: $e')));
                }
              }
            },
            child: const Text('上传并保存'),
          ),
        ],
      ),
    ),
  );
}

/// Shows dialog to edit the caption of a gallery item.
Future<void> showEditCaptionDialog(
  BuildContext context, {
  required CharacterGallery item,
  required WidgetRef ref,
}) async {
  final ctrl = TextEditingController(text: item.caption);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('修改标签 / 备注'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '标签名称',
          hintText: '如：战斗服、三视图',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final newCaption = ctrl.text.trim();
            await ref
                .read(characterActionsProvider)
                .updateGalleryCaption(item.id, newCaption);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

/// Shows confirmation dialog before deleting a gallery item.
Future<void> showConfirmDeleteGalleryDialog(
  BuildContext context, {
  required CharacterGallery item,
  required WidgetRef ref,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('删除立绘'),
      content: const Text('确定要从画廊中删除该立绘吗？（已设为主头像的立绘仍会保留在角色卡片上）'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ref
                .read(characterActionsProvider)
                .deleteGalleryImage(item.id);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
