import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/storage/image_storage_service.dart';
import '../../../data/database/app_database.dart';

/// Single gallery card displaying thumbnail, badges, caption, and actions menu.
class CharacterGalleryCard extends StatelessWidget {
  final CharacterGallery item;
  final double width;
  final double height;
  final VoidCallback onOpenLightbox;
  final VoidCallback onSetPrimary;
  final VoidCallback onEditCaption;
  final VoidCallback onDelete;

  const CharacterGalleryCard({
    super.key,
    required this.item,
    required this.width,
    required this.height,
    required this.onOpenLightbox,
    required this.onSetPrimary,
    required this.onEditCaption,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isPrimary
              ? Colors.amber.shade600
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: item.isPrimary ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片本体（点击打开全屏灯箱）
          InkWell(
            onTap: onOpenLightbox,
            child: FutureBuilder<File?>(
              future: ImageStorageService.instance.resolveImageFile(
                item.imagePath,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final file = snapshot.data;
                if (file != null && file.existsSync()) {
                  final cacheW = (width * 2.5).toInt().clamp(200, 600);
                  final cacheH = (height * 2.5).toInt().clamp(280, 800);
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: cacheW,
                    cacheHeight: cacheH,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }
                return Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: theme.colorScheme.error,
                  ),
                );
              },
            ),
          ),

          // 主封面金色徽标
          if (item.isPrimary)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      '主封面',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 更多操作按钮
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                itemBuilder: (ctx) => [
                  if (!item.isPrimary)
                    const PopupMenuItem(
                      value: 'set_primary',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('设为主封面/头像'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'view_lightbox',
                    child: Row(
                      children: [
                        Icon(Icons.fullscreen_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('放大预览 / 提取色卡'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_caption',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('修改标签备注'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('删除此立绘', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'set_primary') {
                    onSetPrimary();
                  } else if (val == 'view_lightbox') {
                    onOpenLightbox();
                  } else if (val == 'edit_caption') {
                    onEditCaption();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
              ),
            ),
          ),

          // 底部标签与分类栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Text(
                item.caption.isNotEmpty ? item.caption : '立绘',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
