import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_advanced_analysis.dart';
import 'package:oc_manager/features/relation/relation_graph_node.dart';
import 'package:oc_manager/features/relation/widgets/relation_canvas_view.dart';

void main() {
  testWidgets(
    'RelationCanvasView renders character nodes without ParentDataWidget errors',
    (tester) async {
      final transformController = TransformationController();
      final char1 = Character(
        id: 1,
        worldId: 1,
        name: '长亭',
        avatarPath: null,
        gender: '男',
        description: '游侠剑客',
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final char2 = Character(
        id: 2,
        worldId: 1,
        name: '陈胜王',
        avatarPath: null,
        gender: '男',
        description: '领袖',
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final positions = {1: const Offset(400, 300), 2: const Offset(600, 300)};

      final filterState = RelationFilterState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: RelationCanvasView(
                transformController: transformController,
                characters: [char1, char2],
                relations: const [],
                positions: positions,
                graphRevision: 1,
                filterState: filterState,
                currentScale: 1.0,
                onViewportChanged: (_) {},
                onDropCharacter: (_, _, _) {},
                onCanvasTap: (_) {},
                onPersistViewport: () {},
                onNodeDragStart: (_, _) {},
                onNodeDragUpdate: (_, _) {},
                onNodeDragEnd: (_, _) {},
                onConnectStart: (_, _) {},
                onConnectUpdate: (_) {},
                onConnectEnd: () {},
                onRemoveCharacter: (_) {},
                onManageRelations: (_) {},
                onEditCharacter: (_) {},
                onNavigateToPosition: (_) {},
                onClearFilter: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both character nodes are rendered and visible on canvas
      expect(find.byType(DraggableNode), findsNWidgets(2));
      expect(find.text('长亭'), findsOneWidget);
      expect(find.text('陈胜王'), findsOneWidget);

      // Verify no ErrorWidget (gray box) is rendered anywhere
      expect(find.byType(ErrorWidget), findsNothing);
    },
  );
}
