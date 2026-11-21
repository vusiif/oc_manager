import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/color_palette_extractor.dart';
import '../../core/theme/app_theme.dart';

class ColorPaletteBar extends StatelessWidget {
  final File imageFile;

  const ColorPaletteBar({super.key, required this.imageFile});

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
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
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
