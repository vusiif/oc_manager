import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/lore_provider.dart';
import 'package:oc_manager/core/util/wiki_link_parser.dart';
import 'package:oc_manager/features/world/lore_encyclopedia_page.dart';

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
            name: '艾泽拉斯',
            description: const drift.Value('奇幻史诗世界'),
          ),
        );
    await db
        .into(db.worlds)
        .insert(
          WorldsCompanion.insert(
            id: const drift.Value(2),
            name: '赛博空间',
            description: const drift.Value('近未来科幻世界'),
          ),
        );

    // Seed test characters
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(101),
            worldId: 1,
            name: '阿尔萨斯',
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('World Lore Entity System Tests (P2-01)', () {
    test('Lore entity CRUD and custom fields JSON serialization', () async {
      final actions = container.read(loreActionsProvider);

      // 1. Create a Location entity with structured custom fields
      final locId = await actions.createEntity(
        worldId: 1,
        entityType: 'location',
        name: '洛丹伦王城',
        summary: '北境最繁荣的人类城邦',
        content: '座落于提瑞斯法林地之南，[[阿尔萨斯]]在此诞生。',
        tags: '王城, 圣光, 历史',
        customFields: '{"坐标": "北纬42度", "危险等级": "极低"}',
      );
      expect(locId, greaterThan(0));

      // 2. Fetch and verify
      final entity = await db.loreDao.getEntityById(locId);
      expect(entity, isNotNull);
      expect(entity!.name, equals('洛丹伦王城'));
      expect(entity.entityType, equals('location'));
      expect(entity.customFields, contains('危险等级'));

      // 3. Update entity
      final updated = await actions.updateEntity(
        id: locId,
        worldId: 1,
        entityType: 'location',
        name: '洛丹伦废墟',
        summary: '天灾军团肆虐后的破败之都',
        tags: '亡灵, 天灾, 废墟',
      );
      expect(updated, isTrue);

      final reloaded = await db.loreDao.getEntityById(locId);
      expect(reloaded!.name, equals('洛丹伦废墟'));
      expect(reloaded.summary, equals('天灾军团肆虐后的破败之都'));

      // 4. Delete entity
      final deleted = await actions.deleteEntity(locId);
      expect(deleted, equals(1));
      expect(await db.loreDao.getEntityById(locId), isNull);
    });

    test('Cross-world isolation and type filtering', () async {
      final actions = container.read(loreActionsProvider);

      // World 1 entities
      await actions.createEntity(
        worldId: 1,
        entityType: 'faction',
        name: '白银之手骑士团',
        summary: '由圣骑士组成的崇高组织',
      );
      await actions.createEntity(
        worldId: 1,
        entityType: 'item',
        name: '霜之哀伤',
        summary: '蕴含无尽怨念的符文魔剑',
      );

      // World 2 entity
      await actions.createEntity(
        worldId: 2,
        entityType: 'faction',
        name: '荒坂情报课',
        summary: '跨国巨型企业的情报中枢',
      );

      // World 1 should only see its 2 entities
      final w1All = await db.loreDao.getEntitiesByWorld(1);
      expect(w1All.length, equals(2));
      expect(w1All.any((e) => e.name == '荒坂情报课'), isFalse);

      // Filter by type: faction in World 1
      final w1Factions = await db.loreDao.getEntitiesByWorld(
        1,
        entityType: 'faction',
      );
      expect(w1Factions.length, equals(1));
      expect(w1Factions.first.name, equals('白银之手骑士团'));

      // Filter by type: item in World 1
      final w1Items = await db.loreDao.getEntitiesByWorld(
        1,
        entityType: 'item',
      );
      expect(w1Items.length, equals(1));
      expect(w1Items.first.name, equals('霜之哀伤'));

      // World 2 entities
      final w2All = await db.loreDao.getEntitiesByWorld(2);
      expect(w2All.length, equals(1));
      expect(w2All.first.name, equals('荒坂情报课'));
    });

    test(
      'Lore entity search queries by name, summary, tags, and content',
      () async {
        final actions = container.read(loreActionsProvider);

        await actions.createEntity(
          worldId: 1,
          entityType: 'ability',
          name: '圣光术',
          summary: '引导圣光能量治愈伤者',
          content: '需要坚定的圣光信仰与充沛的精神力。',
          tags: '治愈, 神圣',
        );

        // Search by name
        final byName = await db.loreDao.searchEntities(1, '圣光术');
        expect(byName.length, equals(1));

        // Search by summary keyword
        final bySummary = await db.loreDao.searchEntities(1, '治愈伤者');
        expect(bySummary.length, equals(1));

        // Search by tag keyword
        final byTag = await db.loreDao.searchEntities(1, '神圣');
        expect(byTag.length, equals(1));

        // Search by content keyword
        final byContent = await db.loreDao.searchEntities(1, '精神力');
        expect(byContent.length, equals(1));

        // Unmatched keyword
        final unmatched = await db.loreDao.searchEntities(1, '不存在的法术');
        expect(unmatched, isEmpty);
      },
    );

    testWidgets('WikiLinkParser recognizes both Characters and LoreEntities', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final char = Character(
                  id: 101,
                  worldId: 1,
                  name: '阿尔萨斯',
                  gender: '男',
                  description: '',
                  status: 0,
                  isFavorite: false,
                  isPinned: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final lore = LoreEntity(
                  id: 1,
                  worldId: 1,
                  entityType: 'item',
                  name: '霜之哀伤',
                  summary: '符文魔剑',
                  content: '',
                  tags: '',
                  customFields: '{}',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final spans = WikiLinkParser.buildWikiSpans(
                  text: '年轻的王子 [[阿尔萨斯]] 拔出了 [[霜之哀伤]]，步向 [[冰封王座]]。',
                  nameToCharacterMap: {'阿尔萨斯': char},
                  nameToLoreEntityMap: {'霜之哀伤': lore},
                  onCharacterTap: (_) {},
                  onLoreEntityTap: (_) {},
                  context: context,
                );

                return Text.rich(TextSpan(children: spans));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // '阿尔萨斯' should be rendered as Character link badge
      expect(find.text('阿尔萨斯'), findsOneWidget);
      // '霜之哀伤' should be rendered as Lore item link badge
      expect(find.text('霜之哀伤'), findsOneWidget);
      // '冰封王座' is missing from world, should be rendered as unresolved badge
      expect(find.text('冰封王座'), findsOneWidget);
    });

    testWidgets(
      'LoreEncyclopediaPage renders search input, filter chips and empty state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: LoreEncyclopediaPage(worldId: 1)),
          ),
        );

        await tester.pumpAndSettle();

        // Verify title & appbar actions
        expect(find.text('艾泽拉斯 · 世界百科 (Lore)'), findsOneWidget);
        expect(find.text('新建词条'), findsOneWidget);

        // Verify search input
        expect(find.byType(TextField), findsOneWidget);

        // Verify filter chips
        expect(find.text('全部 (0)'), findsOneWidget);
        expect(find.text('地点 (0)'), findsOneWidget);
        expect(find.text('组织 (0)'), findsOneWidget);
        expect(find.text('种族 (0)'), findsOneWidget);
        expect(find.text('物品 (0)'), findsOneWidget);
        expect(find.text('能力 (0)'), findsOneWidget);

        // Verify empty state
        expect(find.text('暂无百科词条'), findsOneWidget);
        expect(find.text('立即创建第一篇百科'), findsOneWidget);
      },
    );
  });
}
