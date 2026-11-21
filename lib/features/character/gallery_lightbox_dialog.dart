import '../../core/storage/image_storage_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import 'color_palette_bar.dart';

class GalleryLightboxDialog extends StatefulWidget {
  final List<CharacterGallery> galleries;
  final int initialIndex;
  final ValueChanged<CharacterGallery> onSetPrimary;

  const GalleryLightboxDialog({
    super.key,
    required this.galleries,
    required this.initialIndex,
    required this.onSetPrimary,
  });

  @override
  State<GalleryLightboxDialog> createState() => _GalleryLightboxDialogState();
}

class _GalleryLightboxDialogState extends State<GalleryLightboxDialog> {
  late int _currentIndex;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.galleries.length - 1) {
      setState(() {
        _currentIndex++;
        _transformController.value = Matrix4.identity();
      });
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _transformController.value = Matrix4.identity();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.galleries[_currentIndex];
    final total = widget.galleries.length;

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: Stack(
          children: [
            // 顶栏：序号、备注、操作与关闭按钮
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.black45,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      current.caption.isNotEmpty ? current.caption : '未命名立绘',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (current.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '当前主封面',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!current.isPrimary)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.star_rounded, size: 16),
                        label: const Text('设为主封面'),
                        onPressed: () {
                          widget.onSetPrimary(current);
                          setState(() {});
                        },
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      tooltip: '关闭预览',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // 中间：原图查看区域（支持手势拖拽平移与滚轮双指无损放大）
            Positioned.fill(
              top: 60,
              bottom: 110,
              child: FutureBuilder<File?>(
                future: ImageStorageService.instance.resolveImageFile(
                  current.imagePath,
                ),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file == null || !file.existsSync()) {
                    return const Center(
                      child: Text(
                        '立绘文件缺失',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Center(child: Image.file(file, fit: BoxFit.contain)),
                  );
                },
              ),
            ),

            // 左右翻页箭头按钮
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 110,
                child: Center(
                  child: FloatingActionButton.small(
                    heroTag: 'gallery_prev',
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    onPressed: _prev,
                    child: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
              ),
            if (_currentIndex < total - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 110,
                child: Center(
                  child: FloatingActionButton.small(
                    heroTag: 'gallery_next',
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    onPressed: _next,
                    child: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
              ),

            // 底部：主色调色卡提取面板 (Color Palette Hex)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FutureBuilder<File?>(
                future: ImageStorageService.instance.resolveImageFile(
                  current.imagePath,
                ),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file == null || !file.existsSync()) {
                    return const SizedBox.shrink();
                  }

                  return ColorPaletteBar(imageFile: file);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 色卡提取面板
