import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_advanced_analysis.dart';

void main() {
  group('RelationPathFinder Tests', () {
    Relation makeRel(int id, int from, int to, String type, bool isBi) {
      return Relation(
        id: id,
        fromCharacterId: from,
        toCharacterId: to,
        relationType: type,
        isBidirectional: isBi,
        note: null,
        relationGroupId: null,
      );
    }

    test('Self path returns immediate single node with 0 hops', () {
      final relations = <Relation>[];
      final res = RelationPathFinder.findShortestPath(
        startId: 10,
        targetId: 10,
        relations: relations,
      );

      expect(res.found, isTrue);
      expect(res.hopCount, 0);
      expect(res.nodePath, [10]);
      expect(res.edgePath, isEmpty);
    });

    test('Single-hop direct relation finding (bidirectional & directed)', () {
      final relations = [
        makeRel(1, 10, 20, '朋友', false),
        makeRel(2, 20, 30, '搭档', true),
      ];

      // 10 -> 20 (directed exists)
      final res1 = RelationPathFinder.findShortestPath(
        startId: 10,
        targetId: 20,
        relations: relations,
      );
      expect(res1.found, isTrue);
      expect(res1.hopCount, 1);
      expect(res1.nodePath, [10, 20]);
      expect(res1.edgePath.first.relationType, '朋友');

      // 20 -> 10 should not be reachable since it is directed
      final res2 = RelationPathFinder.findShortestPath(
        startId: 20,
        targetId: 10,
        relations: relations,
      );
      expect(res2.found, isFalse);
      expect(res2.hopCount, 0);
      expect(res2.nodePath, isEmpty);

      // 30 -> 20 should be reachable because it is bidirectional
      final res3 = RelationPathFinder.findShortestPath(
        startId: 30,
        targetId: 20,
        relations: relations,
      );
      expect(res3.found, isTrue);
      expect(res3.hopCount, 1);
      expect(res3.nodePath, [30, 20]);
      expect(res3.edgePath.first.relationType, '搭档');
    });

    test('Multi-hop path traversal', () {
      final relations = [
        makeRel(1, 1, 2, '导师', true),
        makeRel(2, 2, 3, '宿敌', false),
        makeRel(3, 3, 4, '盟友', true),
      ];

      final res = RelationPathFinder.findShortestPath(
        startId: 1,
        targetId: 4,
        relations: relations,
      );

      expect(res.found, isTrue);
      expect(res.hopCount, 3);
      expect(res.nodePath, [1, 2, 3, 4]);
      expect(res.edgePath.map((e) => e.relationType).toList(), [
        '导师',
        '宿敌',
        '盟友',
      ]);
    });

    test('Shortest path chooses minimal hops over longer alternate path', () {
      // 1 -> 2 -> 4 (2 hops) vs 1 -> 3 -> 5 -> 6 -> 4 (4 hops)
      final relations = [
        makeRel(1, 1, 2, '连接1', true),
        makeRel(2, 2, 4, '连接2', true),
        makeRel(3, 1, 3, '备选1', true),
        makeRel(4, 3, 5, '备选2', true),
        makeRel(5, 5, 6, '备选3', true),
        makeRel(6, 6, 4, '备选4', true),
      ];

      final res = RelationPathFinder.findShortestPath(
        startId: 1,
        targetId: 4,
        relations: relations,
      );

      expect(res.found, isTrue);
      expect(res.hopCount, 2);
      expect(res.nodePath, [1, 2, 4]);
    });

    test('Disconnected components return not found', () {
      final relations = [
        makeRel(1, 1, 2, '关系A', true),
        makeRel(2, 3, 4, '关系B', true),
      ];

      final res = RelationPathFinder.findShortestPath(
        startId: 1,
        targetId: 4,
        relations: relations,
      );

      expect(res.found, isFalse);
      expect(res.hopCount, 0);
      expect(res.nodePath, isEmpty);
    });
  });

  group('GraphAutoLayoutEngine Tests', () {
    Character makeChar(int id, String name) {
      return Character(
        id: id,
        worldId: 1,
        name: name,
        gender: '男',
        description: 'test',
        avatarPath: null,
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    Relation makeRel(int id, int from, int to) {
      return Relation(
        id: id,
        fromCharacterId: from,
        toCharacterId: to,
        relationType: '关联',
        isBidirectional: true,
        note: null,
        relationGroupId: null,
      );
    }

    test('Empty and single character edge cases', () {
      const center = Offset(500, 500);
      final emptyLayout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.circular,
        characters: [],
        relations: [],
        center: center,
      );
      expect(emptyLayout, isEmpty);

      final singleChar = [makeChar(1, '孤勇者')];
      final singleLayout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.circular,
        characters: singleChar,
        relations: [],
        center: center,
      );
      expect(singleLayout.length, 1);
      expect(singleLayout[1], center);
    });

    test('Circular layout sets highest degree node at center', () {
      final chars = [
        makeChar(1, '普通A'),
        makeChar(2, '核心Hub'),
        makeChar(3, '普通B'),
        makeChar(4, '普通C'),
      ];

      final relations = [makeRel(1, 2, 1), makeRel(2, 2, 3), makeRel(3, 2, 4)];

      const center = Offset(1000, 1000);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.circular,
        characters: chars,
        relations: relations,
        center: center,
      );

      expect(layout.length, 4);
      // Character 2 has degree 3, highest, must be placed at center
      expect(layout[2], center);

      // Remaining nodes should be placed on a circle surrounding center
      for (final id in [1, 3, 4]) {
        final pos = layout[id]!;
        final dist = (pos - center).distance;
        expect(dist, greaterThan(200.0));
      }
    });

    test('Hierarchical layout distributes root nodes to top layers', () {
      final chars = [
        makeChar(1, '祖先/君主'),
        makeChar(2, '子嗣A'),
        makeChar(3, '子嗣B'),
      ];

      final relations = [
        Relation(
          id: 1,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '统领',
          isBidirectional: false,
          note: null,
          relationGroupId: null,
        ),
        Relation(
          id: 2,
          fromCharacterId: 1,
          toCharacterId: 3,
          relationType: '统领',
          isBidirectional: false,
          note: null,
          relationGroupId: null,
        ),
      ];

      const center = Offset(1000, 1000);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.hierarchical,
        characters: chars,
        relations: relations,
        center: center,
      );

      expect(layout.length, 3);
      // Character 1 is root (in-degree 0), its dy must be less than descendants
      expect(layout[1]!.dy, lessThan(layout[2]!.dy));
      expect(layout[1]!.dy, lessThan(layout[3]!.dy));
      // Children should share the same vertical layer
      expect(layout[2]!.dy, equals(layout[3]!.dy));
    });

    test('Grid layout creates balanced columns and rows', () {
      final chars = List.generate(6, (i) => makeChar(i + 1, '角色${i + 1}'));
      const center = Offset(1000, 1000);

      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.grid,
        characters: chars,
        relations: [],
        center: center,
      );

      expect(layout.length, 6);
      // All positions must be distinct
      final uniqueOffsets = layout.values.toSet();
      expect(uniqueOffsets.length, 6);
    });
  });

  group('RelationFilterState Tests', () {
    test('State copyWith and active filter flags', () {
      var state = const RelationFilterState();
      expect(state.hasActiveFilter, isFalse);

      state = state.copyWith(selectedRelationType: () => '宿敌');
      expect(state.hasActiveFilter, isTrue);
      expect(state.selectedRelationType, '宿敌');

      state = state.copyWith(selectedRelationType: () => null);
      expect(state.hasActiveFilter, isFalse);

      final dummyPath = ShortestPathResult(
        startCharacterId: 1,
        targetCharacterId: 2,
        nodePath: [1, 2],
        edgePath: [],
      );
      state = state.copyWith(highlightedPath: () => dummyPath);
      expect(state.hasActiveFilter, isTrue);
      expect(state.highlightedPath?.found, isTrue);
    });
  });
}
