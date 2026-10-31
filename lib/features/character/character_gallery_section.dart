import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/image_storage_service.dart';
import '../../core/util/color_palette_extractor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';

/// 角色专属画廊与多立绘/差分管理卡片
class CharacterGallerySection extends ConsumerStatefulWidget {
  final int worldId;
  final int characterId;

  const CharacterGallerySection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  ConsumerState<CharacterGallerySection> createState() =>
      _CharacterGallerySectionState();
}

class _CharacterGallerySectionState
    extends ConsumerState<CharacterGallerySection> {
  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (!mounted) return;
      _showUploadDialog(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  void _showUploadDialog(String pickedPath) {
    final captionCtrl = TextEditingController(text: '常服');
    bool isPrimary = false;

    final suggestions = ['常服', '战斗服', '礼服', '立绘三视图', '幼年期', 'Q版表情', '约稿插画'];

    showDialog(
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
                  title: const Text('同时设为角色主封面/头像', style: TextStyle(fontSize: 13)),
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
                  final relPath =
                      await ImageStorageService.instance.saveGalleryImage(
                    sourcePath: pickedPath,
                    characterId: widget.characterId,
                  );

                  await ref.read(characterActionsProvider).addGalleryImage(
                        characterId: widget.characterId,
                        imagePath: relPath,
                        caption: captionCtrl.text.trim(),
                        isPrimary: isPrimary,
                      );

                  if (isPrimary) {
                    ref.invalidate(characterByIdProvider(widget.characterId));
                    ref.invalidate(charactersByWorldProvider(widget.worldId));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存立绘失败: $e')),
                    );
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

  void _showEditCaptionDialog(CharacterGallery item) {
    final ctrl = TextEditingController(text: item.caption);
    showDialog(
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

  void _confirmDelete(CharacterGallery item) {
    showDialog(
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

  void _openLightbox(List<CharacterGallery> galleries, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _GalleryLightboxDialog(
        galleries: galleries,
        initialIndex: initialIndex,
        onSetPrimary: (gallery) async {
          await ref.read(characterActionsProvider).setPrimaryGalleryImage(
                widget.characterId,
                gallery.id,
              );
          ref.invalidate(characterByIdProvider(widget.characterId));
          ref.invalidate(charactersByWorldProvider(widget.worldId));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final galleriesAsync =
        ref.watch(characterGalleriesProvider(widget.characterId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部标题栏
            Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '立绘画廊与差分',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                galleriesAsync.when(
                  data: (list) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${list.length} 张',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                  label: const Text('添加立绘'),
                  onPressed: _pickAndUpload,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 画廊主体内容
            galleriesAsync.when(
              data: (galleries) {
                if (galleries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections_outlined,
                            size: 40,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '暂无立绘差分。可添加角色的多套服装、三视图、表情差分等，并提取专属色卡。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('上传第一张立绘'),
                            onPressed: _pickAndUpload,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = 140.0;
                    final itemHeight = 200.0;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < galleries.length; i++)
                          _buildGalleryCard(
                            galleries[i],
                            i,
                            galleries,
                            itemWidth,
                            itemHeight,
                            theme,
                          ),
                        // 快捷添加占位卡片
                        InkWell(
                          onTap: _pickAndUpload,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: itemWidth,
                            height: itemHeight,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '添加立绘',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('加载画廊失败: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(
    CharacterGallery item,
    int index,
    List<CharacterGallery> allItems,
    double width,
    double height,
    ThemeData theme,
  ) {
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
            onTap: () => _openLightbox(allItems, index),
            child: FutureBuilder<File?>(
              future: ImageStorageService.instance.resolveImageFile(item.imagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final file = snapshot.data;
                if (file != null && file.existsSync()) {
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
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
                        Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除此立绘', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'set_primary') {
                    ref.read(characterActionsProvider).setPrimaryGalleryImage(
                          widget.characterId,
                          item.id,
                        );
                    ref.invalidate(characterByIdProvider(widget.characterId));
                    ref.invalidate(charactersByWorldProvider(widget.worldId));
                  } else if (val == 'view_lightbox') {
                    _openLightbox(allItems, index);
                  } else if (val == 'edit_caption') {
                    _showEditCaptionDialog(item);
                  } else if (val == 'delete') {
                    _confirmDelete(item);
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

/// 全屏原图灯箱 (Lightbox) 与主色调色卡提取弹窗
class _GalleryLightboxDialog extends StatefulWidget {
  final List<CharacterGallery> galleries;
  final int initialIndex;
  final ValueChanged<CharacterGallery> onSetPrimary;

  const _GalleryLightboxDialog({
    required this.galleries,
    required this.initialIndex,
    required this.onSetPrimary,
  });

  @override
  State<_GalleryLightboxDialog> createState() => _GalleryLightboxDialogState();
}

class _GalleryLightboxDialogState extends State<_GalleryLightboxDialog> {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black45,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                            horizontal: 6, vertical: 2),
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
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 26),
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
                future: ImageStorageService.instance
                    .resolveImageFile(current.imagePath),
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
                    child: Center(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                      ),
                    ),
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
                future: ImageStorageService.instance
                    .resolveImageFile(current.imagePath),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file == null || !file.existsSync()) {
                    return const SizedBox.shrink();
                  }

                  return _ColorPaletteBar(imageFile: file);
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
class _ColorPaletteBar extends StatelessWidget {
  final File imageFile;

  const _ColorPaletteBar({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: FutureBuilder<List<Color>>(
        future: PaletteExtractor.extractPalette(imageFile, maxColors: 6),
        builder: (context, snapshot) {
          final colors = snapshot.data ?? [];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 18, color: Colors.white70),
                  SizedBox(width: 6),
                  Text(
                    '主色调色卡:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                )
              else if (colors.isEmpty)
                const Text(
                  '无法提取主色',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              else
                Wrap(
                  spacing: 12,
                  children: colors.map((c) {
                    final hex = PaletteExtractor.toHex(c);
                    return Tooltip(
                      message: '点击复制色值 $hex',
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: hex));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text('已复制色值: $hex'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hex,
                                style: AppFonts.textStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
