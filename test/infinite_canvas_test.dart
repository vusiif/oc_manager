import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_graph_page.dart';
import 'package:oc_manager/features/relation/relation_graph_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/relation_provider.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('Test dragging character node in RelationGraphPage on desktop', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1);
    final character = Character(
      id: 1,
      worldId: 1,
      name: '测试角色',
      gender: '男',
      description: '',
      status: 0,
      isFavorite: false,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    final mockLayout = GraphLayout(
      id: 1,
      worldId: 1,
      characterId: 1,
      x: 300.0,
      y: 200.0,
      canvasId: 1,
    );

    final mockCanvas = GraphCanvas(
      id: 1,
      worldId: 1,
      name: '主画布',
      description: '',
      isDefault: true,
      viewportX: 0.0,
      viewportY: 0.0,
      zoomScale: 1.0,
      filterConfig: null,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          charactersByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value([character])),
          relationsByWorldProvider(
            1,
          ).overrideWith((ref) => Future.value(<Relation>[])),
          canvasesByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value([mockCanvas])),
          layoutsByCanvasProvider(
            1,
          ).overrideWith((ref) => Future.value([mockLayout])),
          graphLayoutsProvider(
            1,
          ).overrideWith((ref) => Future.value([mockLayout])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: RelationGraphPage(worldId: 1),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify node is rendered on canvas
    final nodeFinder = find.byType(DraggableNode);
    expect(nodeFinder, findsOneWidget);
    final initialPos = tester.getCenter(nodeFinder);

    // Drag with mouse
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: initialPos);
    await tester.pump();
    await mouse.down(initialPos);
    await tester.pump();

    for (int i = 0; i < 5; i++) {
      await mouse.moveBy(const Offset(20, 20));
      await tester.pump();
    }
    await mouse.up();
    await mouse.removePointer();
    await tester.pumpAndSettle();

    final finalPos = tester.getCenter(nodeFinder);
    expect(finalPos.dx, greaterThan(initialPos.dx + 50));
    expect(finalPos.dy, greaterThan(initialPos.dy + 50));
  });

  testWidgets('Test dragging character node with touch or after auto layout', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1);
    final character = Character(
      id: 1,
      worldId: 1,
      name: '测试角色',
      gender: '男',
      description: '',
      status: 0,
      isFavorite: false,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    final mockLayout = GraphLayout(
      id: 1,
      worldId: 1,
      characterId: 1,
      x: 300.0,
      y: 200.0,
      canvasId: 1,
    );

    final mockCanvas = GraphCanvas(
      id: 1,
      worldId: 1,
      name: '主画布',
      description: '',
      isDefault: true,
      viewportX: 0.0,
      viewportY: 0.0,
      zoomScale: 0.2, // Zoomed out / overview LOD
      filterConfig: null,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          charactersByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value([character])),
          relationsByWorldProvider(
            1,
          ).overrideWith((ref) => Future.value(<Relation>[])),
          canvasesByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value([mockCanvas])),
          layoutsByCanvasProvider(
            1,
          ).overrideWith((ref) => Future.value([mockLayout])),
          graphLayoutsProvider(
            1,
          ).overrideWith((ref) => Future.value([mockLayout])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: RelationGraphPage(worldId: 1),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final nodeFinder = find.byType(DraggableNode);
    expect(nodeFinder, findsOneWidget);
    final initialPos = tester.getCenter(nodeFinder);

    // Drag with touch
    final touch = await tester.createGesture(kind: PointerDeviceKind.touch);
    await touch.down(initialPos);
    await tester.pump();

    for (int i = 0; i < 5; i++) {
      await touch.moveBy(const Offset(20, 20));
      await tester.pump();
    }
    await touch.up();
    await tester.pumpAndSettle();

    final finalPos = tester.getCenter(nodeFinder);
    expect(finalPos.dx, greaterThan(initialPos.dx + 50));
    expect(finalPos.dy, greaterThan(initialPos.dy + 50));
  });

  testWidgets('Test dragging real user nodes with panEnabled: false', (
    tester,
  ) async {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) return;
    final file = File('$userProfile/Documents/oc_manager.db');
    if (!file.existsSync()) return;
    final db = AppDatabase.forTesting(NativeDatabase(file));

    final characters = await db.characterDao.getCharactersByWorld(1);
    final relations = await db.relationDao.getRelationsByWorld(1);
    final canvases = await db.canvasDao.getCanvasesByWorld(1);
    final layouts = await db.canvasDao.getLayoutsByCanvas(1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          charactersByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value(characters)),
          relationsByWorldProvider(
            1,
          ).overrideWith((ref) => Future.value(relations)),
          canvasesByWorldProvider(
            1,
          ).overrideWith((ref) => Stream.value(canvases)),
          layoutsByCanvasProvider(
            1,
          ).overrideWith((ref) => Future.value(layouts)),
          graphLayoutsProvider(1).overrideWith((ref) => Future.value(layouts)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: RelationGraphPage(worldId: 1),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final nodeFinders = find.byType(DraggableNode);
    final firstNode = nodeFinders.first;
    final firstNodeWidget = tester.widget<DraggableNode>(firstNode);
    final initialPos = tester.getCenter(firstNode);

    final ivBefore = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final matrixBefore = ivBefore.transformationController!.value.clone();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: initialPos);
    await tester.pump();
    await mouse.down(initialPos);
    await tester.pump();

    for (int i = 0; i < 5; i++) {
      await mouse.moveBy(const Offset(20, 20));
      await tester.pump();
    }
    await mouse.up();
    await mouse.removePointer();
    await tester.pumpAndSettle();

    final finalNodeWidget = tester.widget<DraggableNode>(firstNode);
    final ivAfter = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final matrixAfter = ivAfter.transformationController!.value;

    expect(
      finalNodeWidget.position.dx,
      greaterThan(firstNodeWidget.position.dx + 40),
    );
    expect(
      finalNodeWidget.position.dy,
      greaterThan(firstNodeWidget.position.dy + 40),
    );
    expect(matrixAfter.storage[12], equals(matrixBefore.storage[12]));
    expect(matrixAfter.storage[13], equals(matrixBefore.storage[13]));

    await db.close();
  });
}
