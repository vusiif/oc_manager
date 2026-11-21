import 'package:flutter/material.dart';

import '../../../providers/lore_provider.dart';
import '../lore_cover_image.dart';

/// A widget for selecting, previewing, and clearing the cover image of a lore entity.
class LoreCoverImagePicker extends StatelessWidget {
  final String? coverImagePath;
  final LoreEntityType selectedType;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const LoreCoverImagePicker({
    super.key,
    required this.coverImagePath,
    required this.selectedType,
    required this.onPick,
    required this.onClear,
  });

  String _labelForType(LoreEntityType type) {
    switch (type) {
      case LoreEntityType.faction:
        return '组织徽记';
      case LoreEntityType.item:
        return '装备立绘';
      case LoreEntityType.race:
        return '种族特征';
      case LoreEntityType.ability:
        return '符文法阵';
      default:
        return '上传图鉴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: coverImagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LoreCoverImage(imagePath: coverImagePath),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: InkWell(
                        onTap: onClear,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labelForType(selectedType),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
