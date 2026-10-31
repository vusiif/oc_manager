import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// 图像主色调调色板提取工具
class PaletteExtractor {
  /// 从本地图片文件中提取前 [maxColors] 种最具代表性的主色调
  static Future<List<Color>> extractPalette(File imageFile, {int maxColors = 5}) async {
    try {
      if (!imageFile.existsSync()) return [];
      final bytes = await imageFile.readAsBytes();
      return await extractFromBytes(bytes, maxColors: maxColors);
    } catch (_) {
      return [];
    }
  }

  /// 从图片字节中提取主色调
  static Future<List<Color>> extractFromBytes(Uint8List bytes, {int maxColors = 5}) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 80,
        targetHeight: 80,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return [];

      final buffer = byteData.buffer.asUint8List();
      final counts = <int, int>{};

      for (var i = 0; i < buffer.length; i += 4) {
        final r = buffer[i];
        final g = buffer[i + 1];
        final b = buffer[i + 2];
        final a = buffer[i + 3];

        // 过滤透明或近透明像素
        if (a < 120) continue;

        // 过滤极黑与极白背景干扰（如底图纯白纯黑背景）
        final brightness = (r * 299 + g * 587 + b * 114) / 1000;
        if (brightness < 12 || brightness > 248) continue;

        // 5 位量化 (0..31)
        final qr = r >> 3;
        final qg = g >> 3;
        final qb = b >> 3;
        final key = (qr << 10) | (qg << 5) | qb;
        counts[key] = (counts[key] ?? 0) + 1;
      }

      if (counts.isEmpty) return [];

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final result = <Color>[];
      for (final entry in sorted) {
        final key = entry.key;
        final r = ((key >> 10) & 0x1F) << 3;
        final g = ((key >> 5) & 0x1F) << 3;
        final b = (key & 0x1F) << 3;
        final color = Color.fromARGB(255, r, g, b);

        // 差异度去重：确保提取的颜色之间有可感知的色彩区分
        bool isTooClose = false;
        for (final existing in result) {
          final dr = ((color.r - existing.r) * 255).abs();
          final dg = ((color.g - existing.g) * 255).abs();
          final db = ((color.b - existing.b) * 255).abs();
          if (dr + dg + db < 68) {
            isTooClose = true;
            break;
          }
        }

        if (!isTooClose) {
          result.add(color);
          if (result.length >= maxColors) break;
        }
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  /// 将 Color 转换为标准的 '#RRGGBB' 十六进制文本
  static String toHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }
}
