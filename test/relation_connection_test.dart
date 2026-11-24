import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/features/relation/widgets/relation_connection_helper.dart';

void main() {
  group('RelationConnectionHelper Target Detection Tests', () {
    final positions = {
      1: const Offset(100, 100),
      2: const Offset(300, 100),
      3: const Offset(100, 300),
    };

    test('ignores connecting source node itself', () {
      final target = RelationConnectionHelper.findConnectTarget(
        sourceId: 1,
        currentPos: const Offset(100, 100),
        positions: positions,
      );
      expect(target, isNull);
    });

    test('accurately detects target node within tolerance radius', () {
      // Near node 2 center (300, 100)
      final target = RelationConnectionHelper.findConnectTarget(
        sourceId: 1,
        currentPos: const Offset(290, 105),
        positions: positions,
      );
      expect(target, equals(2));
    });

    test(
      'detects target when hovering over character text label below avatar',
      () {
        // Node 2 visual center is (300, 110), text extends downwards to (300, 135)
        final target = RelationConnectionHelper.findConnectTarget(
          sourceId: 1,
          currentPos: const Offset(300, 130),
          positions: positions,
        );
        expect(target, equals(2));
      },
    );

    test('returns closest target when multiple targets are near', () {
      final densePositions = {
        10: const Offset(200, 200),
        20: const Offset(250, 200),
        30: const Offset(310, 200),
      };

      // Cursor at (260, 205) is closer to node 20 (distance ~11) than node 30 (distance ~50)
      final target = RelationConnectionHelper.findConnectTarget(
        sourceId: 10,
        currentPos: const Offset(260, 205),
        positions: densePositions,
      );
      expect(target, equals(20));
    });

    test('returns null when cursor is too far from any candidate node', () {
      final target = RelationConnectionHelper.findConnectTarget(
        sourceId: 1,
        currentPos: const Offset(200, 200),
        positions: positions,
      );
      expect(target, isNull);
    });
  });
}
