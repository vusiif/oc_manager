import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/graph_svg_exporter.dart';
import 'package:oc_manager/features/relation/widgets/graph_minimap.dart';

void main() {
  group('GRAPH-005 GraphSvgExporter Tests', () {
    test('exportToSvg returns empty placeholder when positions is empty', () {
      final svg = GraphSvgExporter.exportToSvg(
        characters: [],
        relations: [],
        positions: {},
        isDark: false,
      );

      expect(svg, contains('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('画布上暂无角色'));
      expect(svg, contains('fill="#F8F9FA"'));
    });

    test('exportToSvg escapes XML characters correctly', () {
      const unsafe = '<Hero & "Villain\'>';
      final escaped = GraphSvgExporter.escapeXml(unsafe);
      expect(escaped, equals('&lt;Hero &amp; &quot;Villain&apos;&gt;'));
    });

    test('exportToSvg correctly renders nodes, shapes and relations', () {
      final characters = [
        Character(
          id: 1,
          worldId: 1,
          name: 'Alice <A>',
          gender: '女',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Character(
          id: 2,
          worldId: 1,
          name: 'Bob "B"',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Character(
          id: 3,
          worldId: 1,
          name: 'Charlie',
          gender: '其他',
          description: '',
          status: 1, // Dead status
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final relations = [
        const Relation(
          id: 101,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '朋友 & 伙伴',
          isBidirectional: false,
        ),
      ];

      final positions = {
        1: const Offset(100, 100),
        2: const Offset(300, 100),
        3: const Offset(200, 300),
      };

      final svg = GraphSvgExporter.exportToSvg(
        characters: characters,
        relations: relations,
        positions: positions,
        isDark: true,
      );

      // Verify SVG Document structure
      expect(svg, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(svg, contains('<marker id="arrow"'));
      expect(svg, contains('fill="#18181B"')); // Dark background

      // Verify Female node (circle)
      expect(
        svg,
        contains('<circle cx="100.0" cy="100.0" r="24" fill="#4F46E5"/>'),
      );
      expect(svg, contains('Alice &lt;A&gt;'));

      // Verify Male node (rect)
      expect(
        svg,
        contains(
          '<rect x="276.0" y="76.0" width="48" height="48" rx="6" fill="#4F46E5"/>',
        ),
      );
      expect(svg, contains('Bob &quot;B&quot;'));

      // Verify Other/Dead node (polygon & grey)
      expect(svg, contains('<polygon points="'));
      expect(svg, contains('fill="#6B7280"')); // Dead color

      // Verify Relation line and label
      expect(svg, contains('marker-end="url(#arrow)"'));
      expect(svg, contains('朋友 &amp; 伙伴'));
    });

    test('exportToSvg curves multi-relations between same pair', () {
      final characters = [
        Character(
          id: 1,
          worldId: 1,
          name: 'Hero',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Character(
          id: 2,
          worldId: 1,
          name: 'Rival',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final relations = [
        const Relation(
          id: 1,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '同窗',
          isBidirectional: true,
        ),
        const Relation(
          id: 2,
          fromCharacterId: 2,
          toCharacterId: 1,
          relationType: '宿敌',
          isBidirectional: false,
        ),
      ];

      final positions = {1: const Offset(100, 200), 2: const Offset(400, 200)};

      final svg = GraphSvgExporter.exportToSvg(
        characters: characters,
        relations: relations,
        positions: positions,
      );

      // Multi-edges should generate quadratic bezier 'Q' curves
      expect(svg, contains(' Q '));
      // First is bidirectional, so no arrow marker on that path
      expect(svg, contains('stroke-width="2" fill="none"/>'));
      // Second is directional, has arrow marker
      expect(svg, contains('marker-end="url(#arrow)"'));
    });
  });

  group('GRAPH-005 GraphMinimap Widget Tests', () {
    testWidgets('renders empty state message when no positions exist', (
      tester,
    ) async {
      final controller = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphMinimap(
              positions: const {},
              characters: const [],
              relations: const [],
              transformController: controller,
              viewportSize: const Size(800, 600),
              isDark: false,
              onNavigate: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('暂无节点'), findsOneWidget);
      expect(find.text('0 节点'), findsOneWidget);
    });

    testWidgets('toggles expand/collapse when button clicked', (tester) async {
      final controller = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphMinimap(
              positions: {1: const Offset(200, 200)},
              characters: const [],
              relations: const [],
              transformController: controller,
              viewportSize: const Size(800, 600),
              isDark: false,
              onNavigate: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('全局导览'), findsOneWidget);
      expect(find.text('1 节点'), findsOneWidget);

      // Collapse
      await tester.tap(find.byIcon(Icons.close_fullscreen_rounded));
      await tester.pumpAndSettle();

      expect(find.text('全局导览'), findsNothing);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);

      // Expand
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      expect(find.text('全局导览'), findsOneWidget);
    });

    testWidgets('calls onNavigate with mapped world coordinates on tap', (
      tester,
    ) async {
      final controller = TransformationController();
      Offset? navigatedOffset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GraphMinimap(
                width: 200,
                height: 100,
                positions: {
                  1: const Offset(100, 100),
                  2: const Offset(500, 500),
                },
                characters: const [],
                relations: const [],
                transformController: controller,
                viewportSize: const Size(800, 600),
                isDark: false,
                onNavigate: (pos) {
                  navigatedOffset = pos;
                },
              ),
            ),
          ),
        ),
      );

      // Tap on the CustomPaint minimap canvas area
      final canvasFinder = find.byType(CustomPaint).last;
      await tester.tap(canvasFinder);
      await tester.pump();

      expect(navigatedOffset, isNotNull);
      // Ensure mapped coordinate is inside the expected bounds
      expect(navigatedOffset!.dx, inInclusiveRange(-100.0, 700.0));
      expect(navigatedOffset!.dy, inInclusiveRange(-100.0, 700.0));
    });
  });
}
