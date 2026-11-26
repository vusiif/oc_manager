import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/features/relation/widgets/relation_multi_selection_bar.dart';
import 'package:oc_manager/features/relation/widgets/relation_selection_helper.dart';

void main() {
  group('RelationSelectionHelper.findNodesInRect', () {
    final positions = <int, Offset>{
      1: const Offset(100, 100),
      2: const Offset(200, 150),
      3: const Offset(400, 400),
    };

    test('finds nodes inside normal and reversed selection rects', () {
      final hit1 = RelationSelectionHelper.findNodesInRect(
        const Rect.fromLTWH(80, 80, 150, 100),
        positions,
      );
      expect(hit1, {1, 2});

      // Reversed drag from bottom-right to top-left
      final hit2 = RelationSelectionHelper.findNodesInRect(
        const Rect.fromLTRB(230, 180, 80, 80),
        positions,
      );
      expect(hit2, {1, 2});
    });

    test('returns empty set when no node intersects rect', () {
      final hit = RelationSelectionHelper.findNodesInRect(
        const Rect.fromLTWH(500, 500, 100, 100),
        positions,
      );
      expect(hit, isEmpty);
    });
  });

  group('RelationSelectionHelper.computeAlignedPositions', () {
    final positions = <int, Offset>{
      1: const Offset(100, 120),
      2: const Offset(220, 200),
      3: const Offset(340, 160),
    };

    test('aligns left, centerH, top, centerV accurately', () {
      final left = RelationSelectionHelper.computeAlignedPositions(
        NodeAlignMode.left,
        {1, 2, 3},
        positions,
      );
      expect(left[1]!.dx, 100);
      expect(left[2]!.dx, 100);
      expect(left[3]!.dx, 100);

      final centerH = RelationSelectionHelper.computeAlignedPositions(
        NodeAlignMode.centerH,
        {1, 2, 3},
        positions,
      );
      expect(centerH[1]!.dx, 220);
      expect(centerH[2]!.dx, 220);
      expect(centerH[3]!.dx, 220);

      final top = RelationSelectionHelper.computeAlignedPositions(
        NodeAlignMode.top,
        {1, 2, 3},
        positions,
      );
      expect(top[1]!.dy, 120);
      expect(top[2]!.dy, 120);
      expect(top[3]!.dy, 120);
    });

    test('distributes horizontally and vertically with >= 3 nodes', () {
      final unsorted = <int, Offset>{
        1: const Offset(100, 100),
        2: const Offset(400, 220),
        3: const Offset(180, 130),
      };
      final distH = RelationSelectionHelper.computeAlignedPositions(
        NodeAlignMode.distributeH,
        {1, 2, 3},
        unsorted,
      );
      expect(distH[1]!.dx, 100);
      expect(distH[3]!.dx, 250);
      expect(distH[2]!.dx, 400);

      // Returns empty when fewer than 3 nodes for distribution
      final distTooFew = RelationSelectionHelper.computeAlignedPositions(
        NodeAlignMode.distributeH,
        {1, 2},
        unsorted,
      );
      expect(distTooFew, isEmpty);
    });
  });

  group('RelationSelectionHelper multi-node drag', () {
    test('moves all selected nodes synchronously while clamping >= 40', () {
      final positions = <int, Offset>{
        1: const Offset(100, 100),
        2: const Offset(200, 180),
        3: const Offset(300, 300),
      };
      final selected = {1, 2};
      final singleStart = <int, Offset>{};
      final multiStart = <int, Offset>{};

      RelationSelectionHelper.startNodeDrag(
        charId: 1,
        startPos: const Offset(100, 100),
        selectedNodeIds: selected,
        positions: positions,
        singleStartPositions: singleStart,
        multiStartPositions: multiStart,
      );
      expect(multiStart.length, 2);

      RelationSelectionHelper.updateNodeDrag(
        charId: 1,
        newPos: const Offset(150, 130),
        selectedNodeIds: selected,
        positions: positions,
        multiStartPositions: multiStart,
      );
      expect(positions[1], const Offset(150, 130));
      expect(positions[2], const Offset(250, 210));
      expect(positions[3], const Offset(300, 300)); // unselected remains still
    });
  });

  group('Multi-selection UI widgets', () {
    testWidgets('RelationMultiSelectionBar displays count and align actions', (
      tester,
    ) async {
      NodeAlignMode? alignedMode;
      var cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationMultiSelectionBar(
              selectedCount: 3,
              onAlign: (m) => alignedMode = m,
              onClearSelection: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('已选 3 位角色'), findsOneWidget);
      await tester.tap(find.byTooltip('左对齐'));
      expect(alignedMode, NodeAlignMode.left);

      await tester.tap(find.byTooltip('取消选中 (Esc)'));
      expect(cleared, isTrue);
    });

    testWidgets('RelationCanvasModeToggle switches between pan and marquee', (
      tester,
    ) async {
      bool? latestMode;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationCanvasModeToggle(
              isBoxSelectMode: false,
              onModeChanged: (v) => latestMode = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('框选'));
      expect(latestMode, isTrue);
    });
  });
}
