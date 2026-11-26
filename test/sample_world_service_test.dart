import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/services/sample_world_service.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/world/world_list_page.dart';
import 'package:oc_manager/providers/world_provider.dart';

void main() {
  group('SampleWorldService Tests (UX-004)', () {
    test(
      'seeds complete sample world with chars, stats, relations, and canvas',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final worldId1 = await SampleWorldService.createSampleWorld(db);
        final worldId2 = await SampleWorldService.createSampleWorld(db);

        final worlds = await db.worldDao.getAllWorlds();
        expect(worlds.length, 2);
        expect(worlds.map((w) => w.name).toSet(), {'星海边境（示例）', '星海边境（示例 2）'});

        final chars = await db.characterDao.getCharactersByWorld(worldId1);
        expect(chars.length, 4);
        expect(chars.any((c) => c.description.contains('[[艾琳]]')), isTrue);

        final stats = await db.characterDao.getCharacterStats(chars.first.id);
        expect(stats.length, 6);

        final relations = await db.relationDao.getRelationsByWorld(worldId1);
        expect(relations.length, 4);

        final canvases = await db.canvasDao.getCanvasesByWorld(worldId1);
        expect(canvases.length, 1);
        final layouts = await db.canvasDao.getLayoutsByCanvas(
          canvases.first.id,
        );
        expect(layouts.length, 4);

        // Verify world isolation between seeded world 1 and world 2
        final chars2 = await db.characterDao.getCharactersByWorld(worldId2);
        expect(chars2.length, 4);
      },
    );

    testWidgets(
      'WorldListPage shows optional sample world button on empty state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [worldsProvider.overrideWith((ref) => Stream.value([]))],
            child: const MaterialApp(home: WorldListPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('创建世界观'), findsOneWidget);
        expect(find.text('导入示例世界观'), findsOneWidget);
      },
    );
  });
}
