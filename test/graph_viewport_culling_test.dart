import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oc_manager/core/util/graph_viewport_culling.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_graph_node.dart';
import 'package:oc_manager/features/relation/relation_graph_painters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewportCulling Utility Tests (PERF-001)', () {
    test(
      'computeVisibleWorldRect calculates bounds accurately with translation and scale',
      () {
        // 1. Identity transform
        final identity = Matrix4.identity();
        final rect1 = GraphViewportCulling.computeVisibleWorldRect(
          transform: identity,
          viewportSize: const Size(800, 600),
          bufferMargin: 0,
        );
        expect(rect1, const Rect.fromLTWH(0, 0, 800, 600));

        // 2. Buffer margin inflation
        final rectWithBuffer = GraphViewportCulling.computeVisibleWorldRect(
          transform: identity,
          viewportSize: const Size(800, 600),
          bufferMargin: 100,
        );
        expect(rectWithBuffer, const Rect.fromLTWH(-100, -100, 1000, 800));

        // 3. Scaled and translated matrix
        // Scale by 2.0, translate by (100, 50)
        final matrix = Matrix4.identity()
          ..storage[0] = 2.0
          ..storage[5] = 2.0
          ..storage[12] = 100.0
          ..storage[13] = 50.0;
        final rectScaled = GraphViewportCulling.computeVisibleWorldRect(
          transform: matrix,
          viewportSize: const Size(800, 600),
          bufferMargin: 0,
        );
        // Screen (0, 0) -> World (-50, -25)
        // Screen (800, 600) -> World (350, 275)
        expect(rectScaled.left, closeTo(-50.0, 0.01));
        expect(rectScaled.top, closeTo(-25.0, 0.01));
        expect(rectScaled.right, closeTo(350.0, 0.01));
        expect(rectScaled.bottom, closeTo(275.0, 0.01));

        // 4. Empty or zero viewport returns Rect.largest
        final emptyRect = GraphViewportCulling.computeVisibleWorldRect(
          transform: identity,
          viewportSize: Size.zero,
        );
        expect(emptyRect, Rect.largest);
      },
    );

    test('getLodLevel categorizes zoom tiers properly', () {
      expect(GraphViewportCulling.getLodLevel(1.5), GraphLodLevel.full);
      expect(GraphViewportCulling.getLodLevel(0.85), GraphLodLevel.full);
      expect(GraphViewportCulling.getLodLevel(0.55), GraphLodLevel.full);

      expect(GraphViewportCulling.getLodLevel(0.54), GraphLodLevel.medium);
      expect(GraphViewportCulling.getLodLevel(0.35), GraphLodLevel.medium);
      expect(GraphViewportCulling.getLodLevel(0.28), GraphLodLevel.medium);

      expect(GraphViewportCulling.getLodLevel(0.27), GraphLodLevel.overview);
      expect(GraphViewportCulling.getLodLevel(0.15), GraphLodLevel.overview);
      expect(GraphViewportCulling.getLodLevel(0.05), GraphLodLevel.overview);
    });

    test('isNodeVisible determines visibility with radius margin', () {
      const visibleRect = Rect.fromLTWH(100, 100, 400, 300);

      // Deep inside
      expect(
        GraphViewportCulling.isNodeVisible(const Offset(250, 200), visibleRect),
        isTrue,
      );

      // Far outside
      expect(
        GraphViewportCulling.isNodeVisible(const Offset(900, 900), visibleRect),
        isFalse,
      );

      // Slightly outside boundary, but within radius margin (radius = 40)
      expect(
        GraphViewportCulling.isNodeVisible(
          const Offset(80, 200),
          visibleRect,
          radius: 40.0,
        ),
        isTrue,
      );

      // Beyond radius margin
      expect(
        GraphViewportCulling.isNodeVisible(
          const Offset(40, 200),
          visibleRect,
          radius: 40.0,
        ),
        isFalse,
      );
    });

    test('isEdgeVisible detects intersections and culled segments', () {
      const visibleRect = Rect.fromLTWH(200, 200, 400, 400);

      // Completely inside
      expect(
        GraphViewportCulling.isEdgeVisible(
          const Offset(250, 250),
          const Offset(350, 350),
          visibleRect,
        ),
        isTrue,
      );

      // Spanning through the rect from outside to outside
      expect(
        GraphViewportCulling.isEdgeVisible(
          const Offset(100, 300),
          const Offset(700, 300),
          visibleRect,
        ),
        isTrue,
      );

      // Completely outside beyond padding
      expect(
        GraphViewportCulling.isEdgeVisible(
          const Offset(50, 50),
          const Offset(100, 100),
          visibleRect,
          padding: 20.0,
        ),
        isFalse,
      );
    });

    test(
      'filterVisiblePositions returns only positions intersecting viewport',
      () {
        const visibleRect = Rect.fromLTWH(100, 100, 200, 200);
        final positions = {
          1: const Offset(150, 150), // inside
          2: const Offset(500, 500), // far outside
          3: const Offset(310, 200), // slightly outside within radius
          4: const Offset(800, 100), // far outside
        };

        final filtered = GraphViewportCulling.filterVisiblePositions(
          positions,
          visibleRect,
          radius: 30.0,
        );

        expect(filtered.containsKey(1), isTrue);
        expect(filtered.containsKey(3), isTrue);
        expect(filtered.containsKey(2), isFalse);
        expect(filtered.containsKey(4), isFalse);
        expect(filtered.length, 2);
      },
    );
  });

  group('RelationPainter Viewport Culling & LOD Tests (PERF-001)', () {
    test('shouldRepaint detects changes in visibleRect and scale', () {
      final p1 = RelationPainter(
        characters: const [],
        relations: const [],
        positions: const {},
        revision: 0,
        visibleRect: const Rect.fromLTWH(0, 0, 500, 500),
        scale: 1.0,
      );

      final pSame = RelationPainter(
        characters: const [],
        relations: const [],
        positions: const {},
        revision: 0,
        visibleRect: const Rect.fromLTWH(0, 0, 500, 500),
        scale: 1.0,
      );

      final pRectDiff = RelationPainter(
        characters: const [],
        relations: const [],
        positions: const {},
        revision: 0,
        visibleRect: const Rect.fromLTWH(100, 100, 500, 500),
        scale: 1.0,
      );

      final pScaleDiff = RelationPainter(
        characters: const [],
        relations: const [],
        positions: const {},
        revision: 0,
        visibleRect: const Rect.fromLTWH(0, 0, 500, 500),
        scale: 0.5,
      );

      expect(p1.shouldRepaint(pSame), isFalse);
      expect(p1.shouldRepaint(pRectDiff), isTrue);
      expect(p1.shouldRepaint(pScaleDiff), isTrue);
    });

    testWidgets(
      'RelationPainter paints without crash with visibleRect and LOD',
      (tester) async {
        const rel = Relation(
          id: 1,
          fromCharacterId: 10,
          toCharacterId: 20,
          relationType: '挚友',
          isBidirectional: true,
        );

        final painter = RelationPainter(
          characters: const [],
          relations: const [rel],
          positions: const {10: Offset(100, 100), 20: Offset(200, 200)},
          revision: 0,
          visibleRect: const Rect.fromLTWH(0, 0, 300, 300),
          scale: 0.8,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(size: const Size(400, 400), painter: painter),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter == painter,
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('DraggableNode LOD Widget Rendering Tests (PERF-001)', () {
    final testChar = Character(
      id: 99,
      worldId: 1,
      name: '测试角色',
      gender: '女',
      description: '测试描述',
      status: 2,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets('Overview LOD renders micro-dot container without name text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DraggableNode(
                  character: testChar,
                  position: const Offset(100, 100),
                  allCharacters: [testChar],
                  relations: const [],
                  onDragUpdate: (_) {},
                  onDragEnd: (_) {},
                  onRemove: () {},
                  onManageRelations: () {},
                  onEdit: () {},
                  lodLevel: GraphLodLevel.overview,
                ),
              ],
            ),
          ),
        ),
      );

      // Name text should be omitted for overview tier
      expect(find.text('测试角色'), findsNothing);
      expect(find.byType(DraggableNode), findsOneWidget);
    });

    testWidgets('Medium LOD renders shape without trailing name container', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DraggableNode(
                  character: testChar,
                  position: const Offset(100, 100),
                  allCharacters: [testChar],
                  relations: const [],
                  onDragUpdate: (_) {},
                  onDragEnd: (_) {},
                  onRemove: () {},
                  onManageRelations: () {},
                  onEdit: () {},
                  lodLevel: GraphLodLevel.medium,
                ),
              ],
            ),
          ),
        ),
      );

      // Character icon/shape exists
      expect(find.byType(DraggableNode), findsOneWidget);
    });

    testWidgets('Full LOD renders full name text card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DraggableNode(
                  character: testChar,
                  position: const Offset(100, 100),
                  allCharacters: [testChar],
                  relations: const [],
                  onDragUpdate: (_) {},
                  onDragEnd: (_) {},
                  onRemove: () {},
                  onManageRelations: () {},
                  onEdit: () {},
                  lodLevel: GraphLodLevel.full,
                ),
              ],
            ),
          ),
        ),
      );

      // Full LOD has the name text visible
      expect(find.text('测试角色'), findsOneWidget);
    });
  });
}
