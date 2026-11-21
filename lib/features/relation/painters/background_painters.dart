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
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, haloPaint);
    canvas.drawLine(from, to, paint);

    final endCircle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 5.0, endCircle);
  }

  @override
  bool shouldRepaint(covariant ConnectingLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
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
