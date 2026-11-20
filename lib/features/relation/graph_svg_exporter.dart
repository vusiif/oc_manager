import 'dart:math';
import 'dart:ui';
import '../../data/database/app_database.dart';
import 'graph_geometry.dart';

/// Service for exporting relation graphs to clean, valid, standalone W3C SVG vector files.
class GraphSvgExporter {
  const GraphSvgExporter._();

  /// Generates a complete SVG document string representing the current graph layout.
  static String exportToSvg({
    required List<Character> characters,
    required List<Relation> relations,
    required Map<int, Offset> positions,
    bool isDark = false,
    String? title,
  }) {
    if (positions.isEmpty) {
      return '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="200">'
          '<rect width="100%" height="100%" fill="${isDark ? '#1C1C1E' : '#F8F9FA'}"/>'
          '<text x="200" y="100" fill="${isDark ? '#8E8E93' : '#6B7280'}" font-size="14" text-anchor="middle" dominant-baseline="middle">画布上暂无角色</text>'
          '</svg>';
    }

    // 1. Calculate bounding box with padding
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final pos in positions.values) {
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx);
      maxY = max(maxY, pos.dy);
    }

    const padding = 120.0;
    final originX = minX - padding;
    final originY = minY - padding;
    final width = (maxX - minX) + padding * 2;
    final height = (maxY - minY) + padding * 2;

    final bgColor = isDark ? '#18181B' : '#F8FAFC';
    final textColor = isDark ? '#F4F4F5' : '#0F172A';
    final mutedText = isDark ? '#A1A1AA' : '#64748B';
    final lineColor = isDark ? '#52525B' : '#94A3B8';
    final labelBgColor = isDark ? '#27272A' : '#FFFFFF';
    final labelBorderColor = isDark ? '#3F3F46' : '#E2E8F0';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$originX $originY $width $height" width="$width" height="$height">',
    );

    // Metadata and Defs
    buffer.writeln('  <defs>');
    buffer.writeln('    <style>');
    buffer.writeln(
      '      .node-label { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-weight: 600; }',
    );
    buffer.writeln(
      '      .relation-label { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 11px; font-weight: 500; }',
    );
    buffer.writeln('    </style>');
    buffer.writeln(
      '    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">',
    );
    buffer.writeln(
      '      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="$lineColor"/>',
    );
    buffer.writeln('    </marker>');
    buffer.writeln('  </defs>');

    // Canvas Background
    buffer.writeln(
      '  <rect x="$originX" y="$originY" width="$width" height="$height" fill="$bgColor"/>',
    );

    final characterMap = {for (final c in characters) c.id: c};

    // 2. Draw Relations (grouped by character pair)
    buffer.writeln('  <g id="relations">');
    final pairGroups = <String, List<Relation>>{};
    for (final rel in relations) {
      if (!positions.containsKey(rel.fromCharacterId) ||
          !positions.containsKey(rel.toCharacterId)) {
        continue;
      }
      final key = rel.fromCharacterId < rel.toCharacterId
          ? '${rel.fromCharacterId}_${rel.toCharacterId}'
          : '${rel.toCharacterId}_${rel.fromCharacterId}';
      pairGroups.putIfAbsent(key, () => []).add(rel);
    }

    for (final group in pairGroups.values) {
      final baseFromId = group.first.fromCharacterId;
      final baseToId = group.first.toCharacterId;
      final fromCenter = positions[baseFromId]!;
      final toCenter = positions[baseToId]!;
      final fromGender = characterMap[baseFromId]?.gender ?? '';
      final toGender = characterMap[baseToId]?.gender ?? '';
      final count = group.length;

      for (int i = 0; i < count; i++) {
        final rel = group[i];
        final isReverse = (rel.fromCharacterId != baseFromId);
        final startCenter = isReverse ? toCenter : fromCenter;
        final endCenter = isReverse ? fromCenter : toCenter;
        final startGender = isReverse ? toGender : fromGender;
        final endGender = isReverse ? fromGender : toGender;

        final startPoint = GraphGeometry.getExitPoint(
          fromCenter: startCenter,
          toCenter: endCenter,
          fromGender: startGender,
          padding: 3.0,
        );
        final endPoint = GraphGeometry.getEntryPoint(
          fromCenter: startCenter,
          toCenter: endCenter,
          toGender: endGender,
          padding: 3.0,
        );

        final midX = (startPoint.dx + endPoint.dx) / 2;
        final midY = (startPoint.dy + endPoint.dy) / 2;

        final isCurve = count > 1;
        String pathData;
        double labelX = midX;
        double labelY = midY;

        if (isCurve) {
          final offsetMultiplier = (i - (count - 1) / 2.0);
          final curvature = offsetMultiplier * 36.0;
          final dx = endPoint.dx - startPoint.dx;
          final dy = endPoint.dy - startPoint.dy;
          final len = sqrt(dx * dx + dy * dy);
          final normX = len > 0 ? -dy / len : 0.0;
          final normY = len > 0 ? dx / len : 0.0;

          final controlX = midX + normX * curvature;
          final controlY = midY + normY * curvature;
          pathData =
              'M ${startPoint.dx.toStringAsFixed(1)} ${startPoint.dy.toStringAsFixed(1)} Q ${controlX.toStringAsFixed(1)} ${controlY.toStringAsFixed(1)} ${endPoint.dx.toStringAsFixed(1)} ${endPoint.dy.toStringAsFixed(1)}';
          labelX = (startPoint.dx + 2 * controlX + endPoint.dx) / 4;
          labelY = (startPoint.dy + 2 * controlY + endPoint.dy) / 4;
        } else {
          pathData =
              'M ${startPoint.dx.toStringAsFixed(1)} ${startPoint.dy.toStringAsFixed(1)} L ${endPoint.dx.toStringAsFixed(1)} ${endPoint.dy.toStringAsFixed(1)}';
        }

        final markerAttr = rel.isBidirectional
            ? ''
            : ' marker-end="url(#arrow)"';
        buffer.writeln(
          '    <path d="$pathData" stroke="$lineColor" stroke-width="2" fill="none"$markerAttr/>',
        );

        // Draw Relation Label Pill
        final labelText = escapeXml(rel.relationType);
        final labelWidth = max(labelText.length * 12.0 + 16.0, 36.0);
        const labelHeight = 20.0;
        final rectX = labelX - labelWidth / 2;
        final rectY = labelY - labelHeight / 2;

        buffer.writeln(
          '    <rect x="${rectX.toStringAsFixed(1)}" y="${rectY.toStringAsFixed(1)}" width="${labelWidth.toStringAsFixed(1)}" height="${labelHeight.toStringAsFixed(1)}" rx="10" fill="$labelBgColor" stroke="$labelBorderColor" stroke-width="1"/>',
        );
        buffer.writeln(
          '    <text class="relation-label" x="${labelX.toStringAsFixed(1)}" y="${(labelY + 0.5).toStringAsFixed(1)}" fill="$mutedText" text-anchor="middle" dominant-baseline="central">$labelText</text>',
        );
      }
    }
    buffer.writeln('  </g>');

    // 3. Draw Nodes (Shapes, Initials, Names)
    buffer.writeln('  <g id="nodes">');
    for (final c in characters) {
      if (!positions.containsKey(c.id)) continue;
      final pos = positions[c.id]!;
      final isDead = c.status == 1;
      final nodeColor = isDead ? '#6B7280' : '#4F46E5';
      final initial = c.name.isNotEmpty ? c.name[0] : '?';

      // Shape
      if (c.gender == '男') {
        buffer.writeln(
          '    <rect x="${(pos.dx - 24).toStringAsFixed(1)}" y="${(pos.dy - 24).toStringAsFixed(1)}" width="48" height="48" rx="6" fill="$nodeColor"/>',
        );
      } else if (c.gender == '女') {
        buffer.writeln(
          '    <circle cx="${pos.dx.toStringAsFixed(1)}" cy="${pos.dy.toStringAsFixed(1)}" r="24" fill="$nodeColor"/>',
        );
      } else {
        const half = 27.0;
        final p1 =
            '${pos.dx.toStringAsFixed(1)},${(pos.dy - half).toStringAsFixed(1)}';
        final p2 =
            '${(pos.dx + half).toStringAsFixed(1)},${pos.dy.toStringAsFixed(1)}';
        final p3 =
            '${pos.dx.toStringAsFixed(1)},${(pos.dy + half).toStringAsFixed(1)}';
        final p4 =
            '${(pos.dx - half).toStringAsFixed(1)},${pos.dy.toStringAsFixed(1)}';
        buffer.writeln(
          '    <polygon points="$p1 $p2 $p3 $p4" fill="$nodeColor"/>',
        );
      }

      // Initial character text
      buffer.writeln(
        '    <text x="${pos.dx.toStringAsFixed(1)}" y="${(pos.dy + 1).toStringAsFixed(1)}" font-family="-apple-system, sans-serif" font-size="16" font-weight="bold" fill="#FFFFFF" text-anchor="middle" dominant-baseline="central">${escapeXml(initial)}</text>',
      );

      // Character Name
      buffer.writeln(
        '    <text class="node-label" x="${pos.dx.toStringAsFixed(1)}" y="${(pos.dy + 38).toStringAsFixed(1)}" font-size="12" fill="$textColor" text-anchor="middle">${escapeXml(c.name)}</text>',
      );
    }
    buffer.writeln('  </g>');

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Escapes special XML characters to prevent injection and rendering errors.
  static String escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
