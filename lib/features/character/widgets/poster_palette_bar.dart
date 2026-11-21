import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/storage/image_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/color_palette_extractor.dart';
import 'poster_theme_style.dart';

/// 角色海报中的调色板色卡条
class PosterPaletteBar extends StatelessWidget {
  final String? imagePath;
  final PosterStyle style;

  const PosterPaletteBar({
    super.key,
    required this.imagePath,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: ImageStorageService.instance.resolveImageFile(imagePath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) return const SizedBox.shrink();

        return FutureBuilder<List<Color>>(
          future: PaletteExtractor.extractPalette(file, maxColors: 6),
          builder: (context, pSnapshot) {
            final colors = pSnapshot.data ?? [];
            if (colors.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: style.cardBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: style.cardBorderColor),
              ),
              child: Row(
                children: [
                  Text(
                    'COLOR PALETTE',
                    style: AppFonts.textStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: style.subtextColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: colors.map((c) {
                        final hex = PaletteExtractor.toHex(c);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hex,
                              style: AppFonts.textStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: style.textColor,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
