import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/features/relation/graph_geometry.dart';

// 验证关系配对与方向判定逻辑
String pairKey(int a, int b) {
  final minId = a < b ? a : b;
  final maxId = a < b ? b : a;
  return '$minId-$maxId';
}

class TestRelation {
  final int id;
  final int fromCharacterId;
  final int toCharacterId;
  final String relationType;
  final bool isBidirectional;

  TestRelation({
    required this.id,
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.relationType,
    required this.isBidirectional,
  });
}

void main() {
  group('Relation Graph Logic Tests', () {
    test('pairKey should be order independent', () {
      expect(pairKey(1, 2), equals('1-2'));
      expect(pairKey(2, 1), equals('1-2'));
      expect(pairKey(10, 5), equals('5-10'));
    });

    test('reverse edge detection in normal group', () {
      final relAtoB = TestRelation(
        id: 1,
        fromCharacterId: 101,
        toCharacterId: 102,
        relationType: '师徒',
        isBidirectional: false,
      );

      final relBtoA = TestRelation(
        id: 2,
        fromCharacterId: 102,
        toCharacterId: 101,
        relationType: '宿敌',
        isBidirectional: false,
      );

      final group = [relAtoB, relBtoA];
      final baseFromId = group.first.fromCharacterId; // 101
      final baseToId = group.first.toCharacterId; // 102

      // 第一条边是从 101 到 102，不是反向
      final isReversed1 = (relAtoB.fromCharacterId != baseFromId);
      expect(isReversed1, isFalse);

      // 第二条边是从 102 到 101，必须被正确识别为反向边
      final isReversed2 = (relBtoA.fromCharacterId != baseFromId);
      expect(isReversed2, isTrue);

      // 正向边真实终点为 102，反向边真实终点为 101
      final actualTarget1 = isReversed1 ? baseFromId : baseToId;
      final actualTarget2 = isReversed2 ? baseFromId : baseToId;
      expect(actualTarget1, equals(102));
      expect(actualTarget2, equals(101));
    });

    test('incremental position sync preserves existing local edits', () {
      final positions = <int, Offset>{};
      final loadedFromDb = <int>{};

      // 模拟数据库已存布局: 角色 1 (10, 20), 角色 2 (30, 40)
      final dbLayouts = {1: const Offset(10, 20), 2: const Offset(30, 40)};

      void sync(List<int> characterIds, Map<int, Offset> saved) {
        for (final id in characterIds) {
          if (!loadedFromDb.contains(id) && saved.containsKey(id)) {
            positions[id] = saved[id]!;
            loadedFromDb.add(id);
          }
        }
      }

      // 首次加载
      sync([1, 2], dbLayouts);
      expect(positions[1], equals(const Offset(10, 20)));
      expect(positions[2], equals(const Offset(30, 40)));

      // 用户拖动了角色 1 到新位置 (100, 200)
      positions[1] = const Offset(100, 200);

      // 即使此时有重复或延迟的布局流到达，角色 1 的本地最新位置不会被旧的 DB 坐标冲掉
      sync([1, 2], dbLayouts);
      expect(positions[1], equals(const Offset(100, 200)));
    });

    test('GraphGeometry boundary calculation for female (circle)', () {
      const center = Offset(100, 100);
      final pRight = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: center,
        gender: '女',
        angle: 0,
        padding: 0,
      );
      expect(pRight.dx, closeTo(124.0, 1e-4));
      expect(pRight.dy, closeTo(100.0, 1e-4));

      final pDown = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: center,
        gender: '女',
        angle: pi / 2,
        padding: 0,
      );
      expect(pDown.dx, closeTo(100.0, 1e-4));
      expect(pDown.dy, closeTo(124.0, 1e-4));
    });

    test('GraphGeometry boundary calculation for male (square)', () {
      const center = Offset(100, 100);
      // Right edge
      final pRight = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: center,
        gender: '男',
        angle: 0,
        padding: 0,
      );
      expect(pRight.dx, closeTo(124.0, 1e-4));
      expect(pRight.dy, closeTo(100.0, 1e-4));

      // Diagonal (45 degrees) hits the corner (124, 124)
      final pCorner = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: center,
        gender: '男',
        angle: pi / 4,
        padding: 0,
      );
      expect(pCorner.dx, closeTo(124.0, 1e-4));
      expect(pCorner.dy, closeTo(124.0, 1e-4));
    });

    test('GraphGeometry boundary calculation for other (diamond)', () {
      const center = Offset(100, 100);
      final pRight = GraphGeometry.calculateBoundaryIntersection(
        nodeCenter: center,
        gender: '其他',
        angle: 0,
        padding: 0,
      );
      final expectedD = 38.4 / sqrt(2);
      expect(pRight.dx, closeTo(100.0 + expectedD, 1e-3));
      expect(pRight.dy, closeTo(100.0, 1e-3));
    });
  });
}
