import 'dart:math';
import 'dart:ui';

/// Geometry calculations for relation graph nodes and edges.
class GraphGeometry {
  const GraphGeometry._();

  /// Calculates the intersection point between the boundary of a character node
  /// and a ray starting from [nodeCenter] at [angle] (in radians).
  ///
  /// - '女': Circle with base radius = 24.0.
  /// - '男': Rectangle/Square with half-width = 24.0, half-height = 24.0.
  /// - Other: Diamond (square with side = 38.4 rotated by 45°).
  static Offset calculateBoundaryIntersection({
    required Offset nodeCenter,
    required String gender,
    required double angle,
    double padding = 2.0,
  }) {
    final cosA = cos(angle);
    final sinA = sin(angle);

    if (gender == '女') {
      final r = 24.0 + padding;
      return Offset(
        nodeCenter.dx + cosA * r,
        nodeCenter.dy + sinA * r,
      );
    } else if (gender == '男') {
      final w = 24.0 + padding;
      final h = 24.0 + padding;
      final absCos = cosA.abs();
      final absSin = sinA.abs();

      // Avoid division by zero
      final tX = absCos > 1e-6 ? w / absCos : double.infinity;
      final tY = absSin > 1e-6 ? h / absSin : double.infinity;
      final t = min(tX, tY);

      return Offset(
        nodeCenter.dx + cosA * t,
        nodeCenter.dy + sinA * t,
      );
    } else {
      // Diamond: side s = 38.4, vertex distance from center d = s / sqrt(2) + padding.
      // Equation of diamond: |x| + |y| = d
      // Along ray (cosA, sinA): t * (|cosA| + |sinA|) = d => t = d / (|cosA| + |sinA|)
      final baseDistance = 38.4 / sqrt(2) + padding;
      final denom = cosA.abs() + sinA.abs();
      final t = denom > 1e-6 ? baseDistance / denom : baseDistance;

      return Offset(
        nodeCenter.dx + cosA * t,
        nodeCenter.dy + sinA * t,
      );
    }
  }

  /// Calculates boundary intersection for a line starting at [fromCenter]
  /// heading towards [toCenter].
  static Offset getExitPoint({
    required Offset fromCenter,
    required Offset toCenter,
    required String fromGender,
    double padding = 2.0,
  }) {
    final angle = (toCenter - fromCenter).direction;
    return calculateBoundaryIntersection(
      nodeCenter: fromCenter,
      gender: fromGender,
      angle: angle,
      padding: padding,
    );
  }

  /// Calculates boundary intersection for a line entering [toCenter]
  /// coming from [fromCenter].
  static Offset getEntryPoint({
    required Offset fromCenter,
    required Offset toCenter,
    required String toGender,
    double padding = 2.0,
  }) {
    final reverseAngle = (fromCenter - toCenter).direction;
    return calculateBoundaryIntersection(
      nodeCenter: toCenter,
      gender: toGender,
      angle: reverseAngle,
      padding: padding,
    );
  }
}
