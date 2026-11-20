import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/graph_history_manager.dart';
import 'package:oc_manager/features/relation/relation_graph_page.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/relation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Relation Graph Undo & Redo (GRAPH-002) Manager & Command Tests', () {
    late AppDatabase db;
    late ProviderContainer container;
    late GraphCanvas defaultCanvas;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      // Create a test world
      await db
          .into(db.worlds)
          .insert(
            const WorldsCompanion(
              id: drift.Value(1),
              name: drift.Value('赛博纪元'),
            ),
          );

      // Create test characters
      await db
          .into(db.characters)
          .insert(
            const CharactersCompanion(
              id: drift.Value(101),
              worldId: drift.Value(1),
              name: drift.Value('V'),
            ),
          );
      await db
          .into(db.characters)
          .insert(
            const CharactersCompanion(
              id: drift.Value(102),
              worldId: drift.Value(1),
              name: drift.Value('强尼·银手'),
            ),
          );

      defaultCanvas = await db.canvasDao.ensureDefaultCanvas(1);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'MoveNodeCommand: undo restores old coordinate in memory & DB, redo restores new coordinate',
      () async {
        final history = GraphHistoryManager();
        final layoutActions = container.read(graphLayoutActionsProvider);
        final memoryPositions = <int, Offset>{101: const Offset(100.0, 100.0)};

        // Initial save
        await layoutActions.savePosition(
          1,
          101,
          100.0,
          100.0,
          canvasId: defaultCanvas.id,
        );

        // User drags node to (250.0, 300.0)
        memoryPositions[101] = const Offset(250.0, 300.0);
        await layoutActions.savePosition(
          1,
          101,
          250.0,
          300.0,
          canvasId: defaultCanvas.id,
        );

        history.record(
          MoveNodeCommand(
            characterId: 101,
            characterName: 'V',
            oldPos: const Offset(100.0, 100.0),
            newPos: const Offset(250.0, 300.0),
            onUpdateMemory: (id, pos) => memoryPositions[id] = pos,
            onPersist: (id, pos) => layoutActions.savePosition(
              1,
              id,
              pos.dx,
              pos.dy,
              canvasId: defaultCanvas.id,
            ),
          ),
        );

        expect(history.canUndo, isTrue);
        expect(history.canRedo, isFalse);
        expect(history.undoDescription, contains('V'));

        // Perform Undo
        final undoSuccess = await history.undo();
        expect(undoSuccess, isTrue);
        expect(memoryPositions[101], equals(const Offset(100.0, 100.0)));
        var layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(
          layouts.firstWhere((l) => l.characterId == 101).x,
          equals(100.0),
        );
        expect(
          layouts.firstWhere((l) => l.characterId == 101).y,
          equals(100.0),
        );

        // Perform Redo
        expect(history.canRedo, isTrue);
        final redoSuccess = await history.redo();
        expect(redoSuccess, isTrue);
        expect(memoryPositions[101], equals(const Offset(250.0, 300.0)));
        layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(
          layouts.firstWhere((l) => l.characterId == 101).x,
          equals(250.0),
        );
        expect(
          layouts.firstWhere((l) => l.characterId == 101).y,
          equals(300.0),
        );
      },
    );

    test(
      'BatchMoveCommand: auto layout undo restores all positions, redo reapplies auto layout',
      () async {
        final history = GraphHistoryManager();
        final layoutActions = container.read(graphLayoutActionsProvider);

        final initialMap = {
          101: const Offset(10.0, 10.0),
          102: const Offset(20.0, 20.0),
        };
        final autoLayoutMap = {
          101: const Offset(500.0, 400.0),
          102: const Offset(600.0, 400.0),
        };
        final memoryMap = Map<int, Offset>.of(initialMap);

        await layoutActions.batchSavePositions(
          1,
          autoLayoutMap,
          canvasId: defaultCanvas.id,
        );
        memoryMap.addAll(autoLayoutMap);

        history.record(
          BatchMoveCommand(
            descriptionText: '应用【环形聚类布局】',
            oldPositions: initialMap,
            newPositions: autoLayoutMap,
            onUpdateMemory: (map) {
              memoryMap.clear();
              memoryMap.addAll(map);
            },
            onPersist: (map) => layoutActions.batchSavePositions(
              1,
              map,
              canvasId: defaultCanvas.id,
            ),
          ),
        );

        // Undo auto layout
        await history.undo();
        expect(memoryMap[101], equals(const Offset(10.0, 10.0)));
        expect(memoryMap[102], equals(const Offset(20.0, 20.0)));
        var layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(layouts.firstWhere((l) => l.characterId == 101).x, equals(10.0));

        // Redo auto layout
        await history.redo();
        expect(memoryMap[101], equals(const Offset(500.0, 400.0)));
        expect(memoryMap[102], equals(const Offset(600.0, 400.0)));
        layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(
          layouts.firstWhere((l) => l.characterId == 101).x,
          equals(500.0),
        );
      },
    );

    test(
      'AddNodeCommand & RemoveNodeCommand: dropping to canvas and removing can be fully undone/redone',
      () async {
        final history = GraphHistoryManager();
        final layoutActions = container.read(graphLayoutActionsProvider);
        final memory = <int, Offset>{};

        // Drop node
        memory[101] = const Offset(300.0, 300.0);
        await layoutActions.savePosition(
          1,
          101,
          300.0,
          300.0,
          canvasId: defaultCanvas.id,
        );

        history.record(
          AddNodeCommand(
            characterId: 101,
            characterName: 'V',
            pos: const Offset(300.0, 300.0),
            onAddMemory: (id, pos) => memory[id] = pos,
            onRemoveMemory: (id) => memory.remove(id),
            onPersistAdd: (id, pos) => layoutActions.savePosition(
              1,
              id,
              pos.dx,
              pos.dy,
              canvasId: defaultCanvas.id,
            ),
            onPersistRemove: (id) =>
                layoutActions.removePosition(1, id, canvasId: defaultCanvas.id),
          ),
        );

        // Undo add node -> node should be removed from memory and DB
        await history.undo();
        expect(memory.containsKey(101), isFalse);
        var layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(layouts.any((l) => l.characterId == 101), isFalse);

        // Redo add node -> node restored
        await history.redo();
        expect(memory[101], equals(const Offset(300.0, 300.0)));
        layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(layouts.any((l) => l.characterId == 101), isTrue);

        // Now remove node
        memory.remove(101);
        await layoutActions.removePosition(1, 101, canvasId: defaultCanvas.id);

        history.record(
          RemoveNodeCommand(
            characterId: 101,
            characterName: 'V',
            pos: const Offset(300.0, 300.0),
            onAddMemory: (id, pos) => memory[id] = pos,
            onRemoveMemory: (id) => memory.remove(id),
            onPersistAdd: (id, pos) => layoutActions.savePosition(
              1,
              id,
              pos.dx,
              pos.dy,
              canvasId: defaultCanvas.id,
            ),
            onPersistRemove: (id) =>
                layoutActions.removePosition(1, id, canvasId: defaultCanvas.id),
          ),
        );

        // Undo remove node -> node returns to canvas
        await history.undo();
        expect(memory[101], equals(const Offset(300.0, 300.0)));
        layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(layouts.any((l) => l.characterId == 101), isTrue);
      },
    );

    test(
      'Relation commands: create, update, delete relations can be undone and redone consistently',
      () async {
        final history = GraphHistoryManager();
        final relationActions = container.read(relationActionsProvider);

        // 1. Create relation
        final relId = await relationActions.create(
          fromCharacterId: 101,
          toCharacterId: 102,
          relationType: '搭档',
          isBidirectional: true,
          note: '夜之城生死搭档',
        );
        final createdRel = Relation(
          id: relId,
          fromCharacterId: 101,
          toCharacterId: 102,
          relationType: '搭档',
          isBidirectional: true,
          note: '夜之城生死搭档',
          relationGroupId: null,
        );

        history.record(
          CreateRelationCommand(
            relation: createdRel,
            descriptionText: 'V 与 强尼·银手 的【搭档】',
            onDelete: (id) => relationActions.delete(id),
            onRestore: (rel) => relationActions.restore(rel),
          ),
        );

        // Undo create relation -> relation should be deleted
        await history.undo();
        var rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.any((r) => r.id == relId), isFalse);

        // Redo create relation -> relation restored with same ID
        await history.redo();
        rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.any((r) => r.id == relId), isTrue);

        // 2. Update relation
        final updatedRel = createdRel.copyWith(
          relationType: '宿敌',
          isBidirectional: false,
        );
        await relationActions.update(updatedRel);

        history.record(
          UpdateRelationCommand(
            oldRelation: createdRel,
            newRelation: updatedRel,
            descriptionText: '修改关系',
            onUpdate: (r) => relationActions.update(r),
          ),
        );

        // Undo update -> reverts back to '搭档' & bidirectional
        await history.undo();
        rels = await db.relationDao.getRelationsByWorld(1);
        final currentRel = rels.firstWhere((r) => r.id == relId);
        expect(currentRel.relationType, equals('搭档'));
        expect(currentRel.isBidirectional, isTrue);

        // Redo update -> reapplies '宿敌'
        await history.redo();
        rels = await db.relationDao.getRelationsByWorld(1);
        expect(
          rels.firstWhere((r) => r.id == relId).relationType,
          equals('宿敌'),
        );

        // 3. Delete relation
        await relationActions.delete(relId);
        history.record(
          DeleteRelationCommand(
            deletedRelation: updatedRel,
            descriptionText: '删除关系',
            onDelete: (id) => relationActions.delete(id),
            onRestore: (r) => relationActions.restore(r),
          ),
        );

        // Undo delete -> relation restored
        await history.undo();
        rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.any((r) => r.id == relId), isTrue);

        // Redo delete -> relation deleted again
        await history.redo();
        rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.any((r) => r.id == relId), isFalse);
      },
    );

    test(
      'History stack respects maxHistory limit and clears on canvas switch',
      () async {
        final history = GraphHistoryManager(maxHistory: 3);

        for (int i = 1; i <= 5; i++) {
          history.record(
            MoveNodeCommand(
              characterId: 101,
              characterName: 'V',
              oldPos: Offset(i.toDouble(), 0),
              newPos: Offset((i + 1).toDouble(), 0),
              onUpdateMemory: (id, pos) {},
              onPersist: (id, pos) async {},
            ),
          );
        }

        // Max history is 3, so only 3 commands remain
        expect(history.undoCount, equals(3));

        // Clearing history (simulates canvas or world switch)
        history.clear();
        expect(history.canUndo, isFalse);
        expect(history.canRedo, isFalse);
        expect(history.undoCount, equals(0));
      },
    );
  });

  group('RelationGraphPage Undo/Redo Widget UI Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db
          .into(db.worlds)
          .insert(
            const WorldsCompanion(
              id: drift.Value(1),
              name: drift.Value('赛博纪元'),
            ),
          );

      await db
          .into(db.characters)
          .insert(
            const CharactersCompanion(
              id: drift.Value(101),
              worldId: drift.Value(1),
              name: drift.Value('V'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Renders Undo and Redo icon buttons in AppBar with initial disabled states',
      (tester) async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: RelationGraphPage(worldId: 1)),
          ),
        );

        await tester.pumpAndSettle();

        // Find Undo & Redo buttons
        final undoFinder = find.byIcon(Icons.undo_rounded);
        final redoFinder = find.byIcon(Icons.redo_rounded);

        expect(undoFinder, findsOneWidget);
        expect(redoFinder, findsOneWidget);

        // Verify IconButton widgets exist in AppBar
        final undoButton = tester.widget<IconButton>(
          find.ancestor(of: undoFinder, matching: find.byType(IconButton)),
        );
        final redoButton = tester.widget<IconButton>(
          find.ancestor(of: redoFinder, matching: find.byType(IconButton)),
        );

        // Initially, undo and redo should be disabled (onPressed is null)
        expect(undoButton.onPressed, isNull);
        expect(redoButton.onPressed, isNull);
      },
    );
  });
}
