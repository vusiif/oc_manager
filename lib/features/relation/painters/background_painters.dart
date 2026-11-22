import 'package:flutter/material.dart';

/// Painter for rendering active drag connecting lines between relation nodes.
class ConnectingLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  ConnectingLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft atmospheric glow
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawLine(from, to, haloPaint);

    // 2. Main sleek connecting line
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);

    // 3. Magnetic target reticle at cursor/target
    final outerRing = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(to, 8.0, outerRing);

    final innerCircle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 4.0, innerCircle);

    final centerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 1.5, centerDot);
  }

  @override
  bool shouldRepaint(covariant ConnectingLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
}

/// Painter for rendering infinite dynamic grid background on relation canvas.
class InfiniteGridPainter extends CustomPainter {
  final Matrix4 transformMatrix;
  final Color gridColor;
  final double baseStep;

  InfiniteGridPainter({
    required this.transformMatrix,
    required this.gridColor,
    this.baseStep = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transformMatrix.getMaxScaleOnAxis();
    final tx = transformMatrix.getTranslation().x;
    final ty = transformMatrix.getTranslation().y;

    final step = baseStep * scale;
    if (step < 8.0) return;

    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final startX = tx % step;
    for (double x = startX - step; x <= size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final startY = ty % step;
    for (double y = startY - step; y <= size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant InfiniteGridPainter oldDelegate) =>
      oldDelegate.transformMatrix != transformMatrix ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.baseStep != baseStep;
}

/// Painter for rendering grid background on the relation canvas.
class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.color != color;
}
