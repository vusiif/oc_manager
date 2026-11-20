import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_graph_page.dart';
import 'package:oc_manager/providers/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multiple Named Canvases (GRAPH-001) DAO & Service Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Create a test world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(id: const drift.Value(1), name: '赛博纪元'),
          );

      // Create two test characters
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: 'V',
              status: const drift.Value(2),
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(102),
              worldId: 1,
              name: '强尼·银手',
              status: const drift.Value(2),
            ),
          );

      // Create a relation
      await db
          .into(db.relations)
          .insert(
            RelationsCompanion.insert(
              fromCharacterId: 101,
              toCharacterId: 102,
              relationType: '亦敌亦友',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'ensureDefaultCanvas creates 主画布 when no canvas exists and migrates unlinked layouts',
      () async {
        // Insert legacy layout without canvasId
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: 1,
                characterId: 101,
                x: const drift.Value(100.0),
                y: const drift.Value(200.0),
              ),
            );

        final defaultCanvas = await db.canvasDao.ensureDefaultCanvas(1);
        expect(defaultCanvas.name, equals('主画布'));
        expect(defaultCanvas.isDefault, isTrue);

        // Verify unlinked legacy layout is now linked to defaultCanvas
        final layouts = await db.canvasDao.getLayoutsByCanvas(defaultCanvas.id);
        expect(layouts.length, equals(1));
        expect(layouts.first.characterId, equals(101));
        expect(layouts.first.canvasId, equals(defaultCanvas.id));
        expect(layouts.first.x, equals(100.0));
        expect(layouts.first.y, equals(200.0));
      },
    );

    test(
      'Multiple canvases maintain isolated node positions and settings',
      () async {
        // 1. Ensure default canvas
        final canvasMain = await db.canvasDao.ensureDefaultCanvas(1);

        // 2. Create custom canvas "主角团羁绊"
        final now = DateTime.now();
        final canvasTeamId = await db.canvasDao.createCanvas(
          GraphCanvasesCompanion(
            worldId: const drift.Value(1),
            name: const drift.Value('主角团羁绊'),
            description: const drift.Value('仅展示核心主角队伍关系'),
            isDefault: const drift.Value(false),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
        final canvasTeam = (await db.canvasDao.getCanvasById(canvasTeamId))!;

        // 3. Save different coordinates on canvasMain vs canvasTeam
        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: canvasMain.id,
          characterId: 101,
          x: 50.0,
          y: 50.0,
        );
        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: canvasMain.id,
          characterId: 102,
          x: 150.0,
          y: 150.0,
        );

        // On canvasTeam, place 101 at completely different location
        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: canvasTeam.id,
          characterId: 101,
          x: 999.0,
          y: 888.0,
        );

        // 4. Verify isolation
        final mainLayouts = await db.canvasDao.getLayoutsByCanvas(
          canvasMain.id,
        );
        final teamLayouts = await db.canvasDao.getLayoutsByCanvas(
          canvasTeam.id,
        );

        expect(mainLayouts.length, equals(2));
        expect(teamLayouts.length, equals(1));

        final mainV = mainLayouts.firstWhere((l) => l.characterId == 101);
        final teamV = teamLayouts.firstWhere((l) => l.characterId == 101);

        expect(mainV.x, equals(50.0));
        expect(mainV.y, equals(50.0));
        expect(teamV.x, equals(999.0));
        expect(teamV.y, equals(888.0));
      },
    );

    test(
      'Viewport and filter configs are saved and retrieved per canvas',
      () async {
        final canvas = await db.canvasDao.ensureDefaultCanvas(1);

        // Update viewport
        await db.canvasDao.updateViewport(
          canvas.id,
          x: 250.0,
          y: -100.0,
          scale: 1.5,
        );
        // Update filter config
        await db.canvasDao.updateFilterConfig(
          canvas.id,
          '{"selectedStatus":2}',
        );

        final updated = (await db.canvasDao.getCanvasById(canvas.id))!;
        expect(updated.viewportX, equals(250.0));
        expect(updated.viewportY, equals(-100.0));
        expect(updated.zoomScale, equals(1.5));
        expect(updated.filterConfig, equals('{"selectedStatus":2}'));
      },
    );

    test(
      'Duplicate canvas clones all node coordinates without modifying source',
      () async {
        final source = await db.canvasDao.ensureDefaultCanvas(1);
        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: source.id,
          characterId: 101,
          x: 120.0,
          y: 240.0,
        );
        await db.canvasDao.updateViewport(
          source.id,
          x: 10.0,
          y: 20.0,
          scale: 1.2,
        );

        // Duplicate canvas
        final copy = await db.canvasDao.duplicateCanvas(source.id, '主画布 (副本)');
        expect(copy.name, equals('主画布 (副本)'));
        expect(copy.isDefault, isFalse);
        expect(copy.viewportX, equals(10.0));
        expect(copy.zoomScale, equals(1.2));

        // Check cloned layouts
        final copyLayouts = await db.canvasDao.getLayoutsByCanvas(copy.id);
        expect(copyLayouts.length, equals(1));
        expect(copyLayouts.first.characterId, equals(101));
        expect(copyLayouts.first.x, equals(120.0));

        // Modify copy, ensure source is unchanged
        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: copy.id,
          characterId: 101,
          x: 777.0,
          y: 888.0,
        );

        final sourceLayouts = await db.canvasDao.getLayoutsByCanvas(source.id);
        expect(sourceLayouts.first.x, equals(120.0)); // original preserved!
      },
    );

    test(
      'Deleting canvas deletes only canvas layouts, preserving characters and relations',
      () async {
        final canvas1 = await db.canvasDao.ensureDefaultCanvas(1);
        final canvas2Id = await db.canvasDao.createCanvas(
          GraphCanvasesCompanion.insert(worldId: 1, name: '次要势力网'),
        );

        await db.canvasDao.savePosition(
          worldId: 1,
          canvasId: canvas2Id,
          characterId: 101,
          x: 300.0,
          y: 300.0,
        );

        // Delete canvas2
        await db.canvasDao.deleteCanvas(canvas2Id);

        // Verify canvas2 is deleted
        expect(await db.canvasDao.getCanvasById(canvas2Id), isNull);
        final canvas2Layouts = await db.canvasDao.getLayoutsByCanvas(canvas2Id);
        expect(canvas2Layouts.isEmpty, isTrue);

        // CRITICAL: Characters and relations MUST still exist intact!
        final chars = await db.characterDao.getCharactersByWorld(1);
        final rels = await db.relationDao.getRelationsByWorld(1);
        expect(chars.length, equals(2));
        expect(rels.length, equals(1));
        expect(await db.canvasDao.getCanvasById(canvas1.id), isNotNull);
      },
    );

    test('setDefaultCanvas updates default flag across canvases', () async {
      final canvas1 = await db.canvasDao.ensureDefaultCanvas(1);
      final canvas2Id = await db.canvasDao.createCanvas(
        GraphCanvasesCompanion.insert(worldId: 1, name: '第二画布'),
      );

      expect(canvas1.isDefault, isTrue);

      // Set canvas2 as default
      await db.canvasDao.setDefaultCanvas(1, canvas2Id);

      final c1 = (await db.canvasDao.getCanvasById(canvas1.id))!;
      final c2 = (await db.canvasDao.getCanvasById(canvas2Id))!;

      expect(c1.isDefault, isFalse);
      expect(c2.isDefault, isTrue);
    });
  });

  group('RelationGraphPage Multiple Canvases Widget Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(id: const drift.Value(1), name: '赛博纪元'),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: 'V',
              status: const drift.Value(2),
            ),
          );

      // Pre-create two canvases
      await db.canvasDao.createCanvas(
        GraphCanvasesCompanion.insert(
          worldId: 1,
          name: '主关系网',
          isDefault: const drift.Value(true),
        ),
      );

      await db.canvasDao.createCanvas(
        GraphCanvasesCompanion.insert(
          worldId: 1,
          name: '势力派系图',
          isDefault: const drift.Value(false),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Renders canvas selector dropdown with default canvas name and menu options',
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

        // Check that the canvas selector displays the current default canvas name
        expect(find.text('主关系网'), findsOneWidget);
        expect(find.text('默认'), findsOneWidget);

        // Tap on the canvas selector button to open the popup menu
        await tester.tap(find.text('主关系网'));
        await tester.pumpAndSettle();

        // Check menu contents
        expect(find.text('当前世界观画布'), findsOneWidget);
        expect(find.text('势力派系图'), findsOneWidget);
        expect(find.text('新建画布...'), findsOneWidget);
        expect(find.text('复制当前画布...'), findsOneWidget);
        expect(find.text('重命名画布...'), findsOneWidget);
        expect(find.text('删除此画布'), findsOneWidget);

        // Tap to switch to '势力派系图'
        await tester.tap(find.text('势力派系图'));
        await tester.pumpAndSettle();

        // Verify that active canvas switched
        expect(find.text('势力派系图'), findsOneWidget);
      },
    );
  });
}
