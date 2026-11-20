import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/relation_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    // Seed test worlds
    await db
        .into(db.worlds)
        .insert(
          WorldsCompanion.insert(
            id: const drift.Value(1),
            name: '夜之城',
            description: const drift.Value('赛博朋克世界'),
          ),
        );
    await db
        .into(db.worlds)
        .insert(
          WorldsCompanion.insert(
            id: const drift.Value(2),
            name: '魔法异界',
            description: const drift.Value('剑与魔法世界'),
          ),
        );

    // Seed characters in World 1
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(101),
            worldId: 1,
            name: 'V',
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(102),
            worldId: 1,
            name: '强尼·银手',
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(103),
            worldId: 1,
            name: '帕南',
          ),
        );

    // Seed character in World 2
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(201),
            worldId: 2,
            name: '梅林',
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Relation Validation & Constraints (P1-04)', () {
    test('create rejects self-loops and cross-world relations', () async {
      final actions = container.read(relationActionsProvider);

      // 1. Self-relation should throw ArgumentError
      expect(
        () => actions.create(
          fromCharacterId: 101,
          toCharacterId: 101,
          relationType: '自我纠缠',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Cannot create a relation from a character to themselves'),
          ),
        ),
      );

      // 2. Cross-world relation (101 in World 1, 201 in World 2) should throw ArgumentError
      expect(
        () => actions.create(
          fromCharacterId: 101,
          toCharacterId: 201,
          relationType: '跨界盟友',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Characters must belong to the same world'),
          ),
        ),
      );

      // 3. Non-existent character should throw ArgumentError
      expect(
        () => actions.create(
          fromCharacterId: 101,
          toCharacterId: 999,
          relationType: '幽灵链接',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Both characters must exist'),
          ),
        ),
      );

      // 4. Valid relation should succeed
      final relId = await actions.create(
        fromCharacterId: 101,
        toCharacterId: 102,
        relationType: '搭档',
        isBidirectional: true,
      );
      expect(relId, greaterThan(0));

      final rels = await db.relationDao.getRelationsByWorld(1);
      expect(rels.length, equals(1));
      expect(rels.first.relationType, equals('搭档'));
    });

    test(
      'createFamilyRelation rejects parent-child overlap and cross-world members',
      () async {
        final actions = container.read(relationActionsProvider);

        // 1. Overlapping parent and child sets
        expect(
          () => actions.createFamilyRelation(
            parentIds: [101, 102],
            childIds: [101, 103],
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('A character cannot be both a parent and a child'),
            ),
          ),
        );

        // 2. Cross-world family member (201 is in World 2)
        expect(
          () => actions.createFamilyRelation(parentIds: [101], childIds: [201]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('All family members must belong to the same world'),
            ),
          ),
        );

        // 3. Valid family relation creation
        await actions.createFamilyRelation(
          parentIds: [101, 102],
          childIds: [103],
          note: '领养抚养',
        );

        final rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.length, equals(2)); // (101->103) and (102->103)
        expect(rels[0].relationGroupId, isNotNull);
        expect(rels[0].relationGroupId, equals(rels[1].relationGroupId));
        expect(rels.every((r) => r.relationType == '亲子'), isTrue);
      },
    );

    test(
      'createGroupRelation filters self and rejects cross-world members',
      () async {
        final actions = container.read(relationActionsProvider);

        // 1. Cross-world group relation
        expect(
          () => actions.createGroupRelation(
            hubId: 101,
            characterIds: [102, 201],
            relationType: '联合突击',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                'All characters in a group relation must belong to the same world',
              ),
            ),
          ),
        );

        // 2. Valid group relation with self in list (should ignore self and create 101->102, 101->103)
        await actions.createGroupRelation(
          hubId: 101,
          characterIds: [101, 102, 103],
          relationType: '战术小队',
        );

        final rels = await db.relationDao.getRelationsByWorld(1);
        expect(rels.length, equals(2));
        expect(rels[0].relationGroupId, isNotNull);
        expect(rels[0].relationGroupId, equals(rels[1].relationGroupId));
      },
    );
  });

  group('Graph Layout Deduplication & Batch Operations (P1-04)', () {
    test(
      'cleanupDuplicateLayouts removes stale duplicates and keeps latest entry',
      () async {
        final trashDao = db.trashDao;

        // Manually insert duplicate layout records for character 101 in world 1
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: 1,
                characterId: 101,
                x: const drift.Value(10.0),
                y: const drift.Value(10.0),
              ),
            );
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: 1,
                characterId: 101,
                x: const drift.Value(20.0),
                y: const drift.Value(20.0),
              ),
            );
        final latestId = await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: 1,
                characterId: 101,
                x: const drift.Value(99.0),
                y: const drift.Value(88.0),
              ),
            );

        // Also insert a clean record for character 102
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: 1,
                characterId: 102,
                x: const drift.Value(50.0),
                y: const drift.Value(50.0),
              ),
            );

        // Before cleanup: 4 records total
        final beforeRows = await db.select(db.graphLayouts).get();
        expect(beforeRows.length, equals(4));

        // Run cleanup
        final deletedCount = await trashDao.cleanupDuplicateLayouts(worldId: 1);
        expect(
          deletedCount,
          equals(2),
        ); // The 2 older records for 101 were deleted

        final afterRows = await db.select(db.graphLayouts).get();
        expect(afterRows.length, equals(2));

        // Verify the surviving record for 101 is the latest one
        final char101Layout = afterRows.firstWhere((r) => r.characterId == 101);
        expect(char101Layout.id, equals(latestId));
        expect(char101Layout.x, equals(99.0));
        expect(char101Layout.y, equals(88.0));
      },
    );

    test(
      'batchSaveLayouts inserts and updates in a single transaction idempotently',
      () async {
        final layoutActions = container.read(graphLayoutActionsProvider);

        // Batch 1: Initial placement of 101, 102, 103
        await layoutActions.batchSavePositions(1, {
          101: const Offset(100.0, 100.0),
          102: const Offset(200.0, 200.0),
          103: const Offset(300.0, 300.0),
        });

        var layouts = await db.trashDao.getLayoutsByWorld(1);
        expect(layouts.length, equals(3));
        expect(
          layouts.firstWhere((l) => l.characterId == 101).x,
          equals(100.0),
        );

        // Batch 2: Update 101 and 102 positions
        await layoutActions.batchSavePositions(1, {
          101: const Offset(150.0, 160.0),
          102: const Offset(250.0, 260.0),
        });

        layouts = await db.trashDao.getLayoutsByWorld(1);
        expect(
          layouts.length,
          equals(3),
        ); // Still exactly 3 records, no duplicates created
        expect(
          layouts.firstWhere((l) => l.characterId == 101).x,
          equals(150.0),
        );
        expect(
          layouts.firstWhere((l) => l.characterId == 101).y,
          equals(160.0),
        );
        expect(
          layouts.firstWhere((l) => l.characterId == 102).x,
          equals(250.0),
        );
        expect(
          layouts.firstWhere((l) => l.characterId == 103).x,
          equals(300.0),
        ); // 103 untouched
      },
    );
  });
}
