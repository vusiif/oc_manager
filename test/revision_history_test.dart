import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/revision_provider.dart';
import 'package:oc_manager/features/world/revision_history_dialog.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    // Seed test world
    await db
        .into(db.worlds)
        .insert(WorldsCompanion.insert(id: const drift.Value(1), name: '艾泽拉斯'));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Revision History & Snapshot Rollback Tests (P2-03)', () {
    test(
      'recordRevision saves content, deduplicates unchanged, and prunes beyond maxRetain',
      () async {
        final actions = container.read(revisionActionsProvider);

        // 1. Record snapshot 1
        final id1 = await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '版本 1：洛丹伦的年轻王子',
          title: '初始设定草稿',
        );
        expect(id1, isNotNull);

        final list1 = await db.revisionDao.getRevisions('character', 101);
        expect(list1.length, equals(1));
        expect(list1.first.title, equals('初始设定草稿'));
        expect(list1.first.charCount, equals('版本 1：洛丹伦的年轻王子'.length));

        // 2. Record identical content -> Should deduplicate and return existing ID without creating new row
        final idDuplicate = await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '版本 1：洛丹伦的年轻王子',
        );
        expect(idDuplicate, equals(id1));
        final listDuplicate = await db.revisionDao.getRevisions(
          'character',
          101,
        );
        expect(listDuplicate.length, equals(1));

        // 3. Auto-prune test with maxRetain = 3
        await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '版本 2：斯坦索姆的决断',
          maxRetain: 3,
        );
        await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '版本 3：诺森德拔出魔剑',
          maxRetain: 3,
        );
        await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '版本 4：巫妖王加冕',
          maxRetain: 3,
        );

        // Total added was 4, but maxRetain was 3 -> oldest (版本 1) should be pruned
        final listPruned = await db.revisionDao.getRevisions('character', 101);
        expect(listPruned.length, equals(3));
        expect(listPruned.any((r) => r.content.contains('版本 1')), isFalse);
        expect(listPruned.first.content, contains('版本 4'));
      },
    );

    test(
      'restoreCharacterDescription archives current description and rolls back safely',
      () async {
        final actions = container.read(revisionActionsProvider);

        // Seed character
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(101),
                worldId: 1,
                name: '阿尔萨斯',
                description: const drift.Value('当前版本：冰封王座的君王'),
              ),
            );

        // Create an old historical snapshot: '历史版本：善良的圣骑士'
        final oldRevId = (await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 101,
          content: '历史版本：善良的圣骑士',
          title: '骑士时期',
        ))!;

        final character = await db.characterDao.getCharacterById(101);

        // Restore to old snapshot
        final success = await actions.restoreCharacterDescription(
          revisionId: oldRevId,
          character: character,
        );
        expect(success, isTrue);

        // Verify character description rolled back
        final updatedChar = await db.characterDao.getCharacterById(101);
        expect(updatedChar.description, equals('历史版本：善良的圣骑士'));

        // Verify current version was automatically archived before rollback
        final revisions = await db.revisionDao.getRevisions('character', 101);
        expect(revisions.length, equals(2));
        expect(revisions.any((r) => r.title.contains('回滚前自动归档')), isTrue);
        expect(
          revisions.firstWhere((r) => r.title.contains('回滚前')).content,
          equals('当前版本：冰封王座的君王'),
        );
      },
    );

    test(
      'restoreLoreContent archives current content and rolls back safely',
      () async {
        final actions = container.read(revisionActionsProvider);

        // Seed Lore entity
        final loreId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(201),
            worldId: 1,
            entityType: 'item',
            name: '霜之哀伤',
            content: const drift.Value('当前版本：吸取灵魂的魔剑'),
          ),
        );

        // Record old snapshot
        final oldRevId = (await actions.recordRevision(
          worldId: 1,
          entityType: 'lore',
          entityId: loreId,
          content: '历史版本：原本是一柄普通符文剑',
          title: '早期设定',
        ))!;

        final lore = (await db.loreDao.getEntityById(loreId))!;

        // Restore
        final success = await actions.restoreLoreContent(
          revisionId: oldRevId,
          lore: lore,
        );
        expect(success, isTrue);

        final updatedLore = (await db.loreDao.getEntityById(loreId))!;
        expect(updatedLore.content, equals('历史版本：原本是一柄普通符文剑'));
      },
    );

    testWidgets(
      'RevisionHistoryDialog renders snapshots, diff text and rollback button',
      (tester) async {
        final actions = container.read(revisionActionsProvider);

        await actions.recordRevision(
          worldId: 1,
          entityType: 'character',
          entityId: 301,
          content: '第一代人设：隐世贤者',
          title: '最初设定',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(
                body: RevisionHistoryDialog(
                  worldId: 1,
                  entityType: 'character',
                  entityId: 301,
                  entityName: '梅林',
                  currentContent: '当前人设：大法师',
                  onRestore: (_) async {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify title & entity name
        expect(find.text('设定版本历史与快照恢复'), findsOneWidget);
        expect(find.textContaining('梅林'), findsWidgets);

        // Verify snapshot item in list and preview panel header
        expect(find.text('最初设定'), findsNWidgets(2));

        // Verify content preview
        expect(find.text('第一代人设：隐世贤者'), findsOneWidget);

        // Verify action buttons
        expect(find.text('恢复为此版本'), findsOneWidget);
        expect(find.text('保存新快照'), findsOneWidget);
      },
    );
  });
}
