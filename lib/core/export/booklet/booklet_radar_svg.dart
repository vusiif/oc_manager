import 'dart:math' as math;

import '../../../data/database/app_database.dart';
import 'booklet_export_helpers.dart';

String generateRadarSvg(List<CharacterStat> stats) {
  if (stats.length < 3) {
    return '<div class="text-muted">（维度少于 3 项，无法生成雷达图）</div>';
  }

  const double cx = 140.0;
  const double cy = 140.0;
  const double radius = 85.0;
  final int count = stats.length;
  final double angleStep = 2 * math.pi / count;

  final sb = StringBuffer();
  sb.writeln(
    '<svg class="radar-svg" viewBox="0 0 280 280" width="280" height="280" xmlns="http://www.w3.org/2000/svg">',
  );

  // Concentric web lines (4 levels)
  for (int level = 1; level <= 4; level++) {
    final r = radius * (level / 4.0);
    final points = <String>[];
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    sb.writeln(
      '<polygon points="${points.join(' ')}" fill="none" stroke="#e2e8f0" stroke-width="1"/>',
    );
  }

  // Axis radiating lines
  for (int i = 0; i < count; i++) {
    final angle = -math.pi / 2 + i * angleStep;
    final x = cx + radius * math.cos(angle);
    final y = cy + radius * math.sin(angle);
    sb.writeln(
      '<line x1="$cx" y1="$cy" x2="${x.toStringAsFixed(1)}" y2="${y.toStringAsFixed(1)}" stroke="#cbd5e1" stroke-width="1"/>',
    );

    // Labels outside vertices
    final labelR = radius + 22;
    final lx = cx + labelR * math.cos(angle);
    final ly = cy + labelR * math.sin(angle) + 4; // slight vertical centering
    sb.writeln(
      '<text x="${lx.toStringAsFixed(1)}" y="${ly.toStringAsFixed(1)}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle">${escapeHtml(stats[i].label)}</text>',
    );
  }

  // Data polygon
  final dataPoints = <String>[];
  for (int i = 0; i < count; i++) {
    final s = stats[i];
    final ratio = s.maxValue > 0 ? (s.value / s.maxValue).clamp(0.0, 1.0) : 0.0;
    final r = radius * ratio;
    final angle = -math.pi / 2 + i * angleStep;
    final x = cx + r * math.cos(angle);
    final y = cy + r * math.sin(angle);
    dataPoints.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
  }

  sb.writeln(
    '<polygon points="${dataPoints.join(' ')}" fill="rgba(99, 102, 241, 0.3)" stroke="#6366f1" stroke-width="2.5"/>',
  );

  // Data vertex dots
  for (int i = 0; i < count; i++) {
    final s = stats[i];
    final ratio = s.maxValue > 0 ? (s.value / s.maxValue).clamp(0.0, 1.0) : 0.0;
    final r = radius * ratio;
    final angle = -math.pi / 2 + i * angleStep;
    final x = cx + r * math.cos(angle);
    final y = cy + r * math.sin(angle);
    sb.writeln(
      '<circle cx="${x.toStringAsFixed(1)}" cy="${y.toStringAsFixed(1)}" r="4" fill="#6366f1" stroke="#ffffff" stroke-width="1.5"/>',
    );
  }

  sb.writeln('</svg>');
  return sb.toString();
}
