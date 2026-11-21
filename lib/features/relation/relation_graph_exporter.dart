import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import 'graph_svg_exporter.dart';
import 'relation_graph_painters.dart';

/// Helper for exporting the relation graph to PNG or SVG.
class RelationGraphExporter {
  RelationGraphExporter._();

  static Future<void> exportToImage({
    required BuildContext context,
    required List<Character> characters,
    required List<Relation> relations,
    required Map<int, Offset> positions,
    required int graphRevision,
  }) async {
    if (positions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画布上暂无人物，无法导出')));
      return;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final pos in positions.values) {
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx);
      maxY = max(maxY, pos.dy);
    }

    const margin = 120.0;
    final exportRect = Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    );

    final width = exportRect.width;
    final height = exportRect.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    canvas.translate(-exportRect.left, -exportRect.top);

    final relPainter = RelationPainter(
      relations: relations,
      positions: positions,
      characters: characters,
      revision: graphRevision,
      isDark: isDark,
    );
    relPainter.paint(canvas, Size(maxX + margin, maxY + margin));

    for (final c in characters) {
      if (!positions.containsKey(c.id)) continue;
      final pos = positions[c.id]!;
      final color = c.status == 1 ? Colors.grey : AppColors.brand;
      drawNodeOnCanvas(canvas, c, pos, color, isDark);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'relation_graph_$dateStr.png';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出图片保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (result == null) return;

    var savePath = result;
    if (!savePath.toLowerCase().endsWith('.png')) {
      savePath += '.png';
    }

    await File(savePath).writeAsBytes(pngBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('关系图已成功导出至: $savePath')));
    }
  }

  static Future<void> exportToSvg({
    required BuildContext context,
    required List<Character> characters,
    required List<Relation> relations,
    required Map<int, Offset> positions,
  }) async {
    if (positions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画布上暂无人物，无法导出')));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgString = GraphSvgExporter.exportToSvg(
      characters: characters,
      relations: relations,
      positions: positions,
      isDark: isDark,
    );

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'relation_graph_$dateStr.svg';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出矢量图保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );

    if (result == null) return;

    var savePath = result;
    if (!savePath.toLowerCase().endsWith('.svg')) {
      savePath += '.svg';
    }

    await File(savePath).writeAsString(svgString);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('矢量关系图已成功导出至: $savePath')));
    }
  }

  static void drawNodeOnCanvas(
    Canvas canvas,
    Character c,
    Offset pos,
    Color color,
    bool isDark,
  ) {
    final shapePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const half = 24.0;
    final initial = c.name.isNotEmpty ? c.name[0] : '?';

    if (c.gender == '男') {
      final rect = Rect.fromCenter(
        center: pos,
        width: half * 2,
        height: half * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        shapePaint,
      );
    } else if (c.gender == '女') {
      canvas.drawCircle(pos, half, shapePaint);
    } else {
      final path = Path()
        ..moveTo(pos.dx, pos.dy - half * 1.13)
        ..lineTo(pos.dx + half * 1.13, pos.dy)
        ..lineTo(pos.dx, pos.dy + half * 1.13)
        ..lineTo(pos.dx - half * 1.13, pos.dy)
        ..close();
      canvas.drawPath(path, shapePaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: AppFonts.textStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    final nameTp = TextPainter(
      text: TextSpan(
        text: c.name,
        style: AppFonts.textStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    nameTp.paint(canvas, Offset(pos.dx - nameTp.width / 2, pos.dy + half + 4));
  }
}
