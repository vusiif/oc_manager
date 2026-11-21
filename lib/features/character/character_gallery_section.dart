import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import 'gallery_lightbox_dialog.dart';
import 'widgets/character_gallery_card.dart';
import 'widgets/gallery_action_dialogs.dart';

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
      await showGalleryUploadDialog(
        context,
        pickedPath: picked.path,
        characterId: widget.characterId,
        worldId: widget.worldId,
        ref: ref,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  void _openLightbox(List<CharacterGallery> galleries, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GalleryLightboxDialog(
        galleries: galleries,
        initialIndex: initialIndex,
        onSetPrimary: (gallery) async {
          await ref
              .read(characterActionsProvider)
              .setPrimaryGalleryImage(widget.characterId, gallery.id);
          ref.invalidate(characterByIdProvider(widget.characterId));
          ref.invalidate(charactersByWorldProvider(widget.worldId));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final galleriesAsync = ref.watch(
      characterGalleriesProvider(widget.characterId),
    );

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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                galleriesAsync.when(
                  data: (list) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                            ),
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
                    const itemWidth = 140.0;
                    const itemHeight = 200.0;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < galleries.length; i++)
                          CharacterGalleryCard(
                            item: galleries[i],
                            width: itemWidth,
                            height: itemHeight,
                            onOpenLightbox: () => _openLightbox(galleries, i),
                            onSetPrimary: () async {
                              await ref
                                  .read(characterActionsProvider)
                                  .setPrimaryGalleryImage(
                                    widget.characterId,
                                    galleries[i].id,
                                  );
                              ref.invalidate(
                                characterByIdProvider(widget.characterId),
                              );
                              ref.invalidate(
                                charactersByWorldProvider(widget.worldId),
                              );
                            },
                            onEditCaption: () => showEditCaptionDialog(
                              context,
                              item: galleries[i],
                              ref: ref,
                            ),
                            onDelete: () => showConfirmDeleteGalleryDialog(
                              context,
                              item: galleries[i],
                              ref: ref,
                            ),
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
}
