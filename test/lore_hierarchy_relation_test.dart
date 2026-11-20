import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/features/world/lore_entity_detail_dialog.dart';

void main() {
  group('LORE-001 & LORE-002 World Lore Hierarchy & Character Link Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // Seed world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '艾泽拉斯',
              description: const drift.Value('奇幻史诗世界'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Schema v13/v14 supports parentId for hierarchical locations and organizations',
      () async {
        expect(db.schemaVersion, greaterThanOrEqualTo(14));

        // 1. Create top-level Nation (国家)
        final countryId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '洛丹伦王国',
            summary: const drift.Value('北境人类文明的核心王国'),
          ),
        );

        // 2. Create Region under Country (地区)
        final regionId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(countryId),
            entityType: 'location',
            name: '提瑞斯法林地',
            summary: const drift.Value('迷雾笼罩的森林之境'),
          ),
        );

        // 3. Create City under Region (城市)
        final cityId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(regionId),
            entityType: 'location',
            name: '洛丹伦王城',
            summary: const drift.Value('雄伟的白色王城'),
          ),
        );

        // Verify child query
        final countryChildren = await db.loreDao.getChildEntities(countryId);
        expect(countryChildren.length, equals(1));
        expect(countryChildren.first.name, equals('提瑞斯法林地'));

        final regionChildren = await db.loreDao.getChildEntities(regionId);
        expect(regionChildren.length, equals(1));
        expect(regionChildren.first.name, equals('洛丹伦王城'));

        // Verify ancestor breadcrumbs from City
        final ancestors = await db.loreDao.getAncestors(cityId);
        expect(ancestors.length, equals(2));
        expect(ancestors[0].name, equals('洛丹伦王国'));
        expect(ancestors[1].name, equals('提瑞斯法林地'));
      },
    );

    test(
      'getAvailableParents prevents self-reference and cyclic descendant hierarchy',
      () async {
        final countryId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '暴风王国',
          ),
        );

        final regionId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(countryId),
            entityType: 'location',
            name: '艾尔文森林',
          ),
        );

        final cityId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(regionId),
            entityType: 'location',
            name: '暴风城',
          ),
        );

        // When editing '暴风王国', available parents must NOT contain itself or its children/descendants
        final parentsForCountry = await db.loreDao.getAvailableParents(
          1,
          currentEntityId: countryId,
          entityType: 'location',
        );
        expect(parentsForCountry.any((e) => e.id == countryId), isFalse);
        expect(parentsForCountry.any((e) => e.id == regionId), isFalse);
        expect(parentsForCountry.any((e) => e.id == cityId), isFalse);

        // When editing '暴风城', '暴风王国' and '艾尔文森林' are valid candidates, but '暴风城' itself is excluded
        final parentsForCity = await db.loreDao.getAvailableParents(
          1,
          currentEntityId: cityId,
          entityType: 'location',
        );
        expect(parentsForCity.any((e) => e.id == countryId), isTrue);
        expect(parentsForCity.any((e) => e.id == regionId), isTrue);
        expect(parentsForCity.any((e) => e.id == cityId), isFalse);
      },
    );

    test(
      'LoreRelations links characters to locations and factions with stable IDs',
      () async {
        // Create character
        final charId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                worldId: 1,
                name: '阿尔萨斯',
                description: const drift.Value('洛丹伦王子'),
              ),
            );

        // Create faction & location
        final factionId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '白银之手骑士团',
          ),
        );

        final locationId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '洛丹伦王城',
          ),
        );

        // 1. Link character to faction as '圣骑士'
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: factionId,
          characterId: charId,
          role: '圣骑士',
        );

        // 2. Link character to location as '出生地/王子'
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: locationId,
          characterId: charId,
          role: '王储',
        );

        // Query faction members
        final members = await db.loreDao.getCharactersByLore(factionId);
        expect(members.length, equals(1));
        expect(members.first.character.name, equals('阿尔萨斯'));
        expect(members.first.relation.role, equals('圣骑士'));

        // Query character affiliations
        final affiliations = await db.loreDao.getLoresByCharacter(charId);
        expect(affiliations.length, equals(2));
        expect(
          affiliations.any(
            (a) => a.lore.name == '白银之手骑士团' && a.relation.role == '圣骑士',
          ),
          isTrue,
        );
        expect(
          affiliations.any(
            (a) => a.lore.name == '洛丹伦王城' && a.relation.role == '王储',
          ),
          isTrue,
        );

        // Unlink from faction
        await db.loreDao.removeCharacterRelation(factionId, charId);
        final remainingMembers = await db.loreDao.getCharactersByLore(
          factionId,
        );
        expect(remainingMembers, isEmpty);
      },
    );

    test(
      'Deleting parent entity detaches child entities safely without dangling foreign keys',
      () async {
        final parentId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '东部王国',
          ),
        );

        final childId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(parentId),
            entityType: 'location',
            name: '提瑞斯法林地',
          ),
        );

        // Delete parent entity
        await db.loreDao.deleteEntity(parentId);

        // Parent is deleted
        expect(await db.loreDao.getEntityById(parentId), isNull);

        // Child entity is preserved, and its parentId is safely set to null
        final child = await db.loreDao.getEntityById(childId);
        expect(child, isNotNull);
        expect(child!.name, equals('提瑞斯法林地'));
        expect(child.parentId, isNull);
      },
    );

    testWidgets(
      'LoreEntityDetailDialog renders breadcrumbs, child entities, and linked characters',
      (tester) async {
        // 1. Seed Parent Location
        final parentId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '洛丹伦王国',
            summary: const drift.Value('北境大国'),
          ),
        );

        // 2. Seed Current Location (child of country)
        final cityId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(parentId),
            entityType: 'location',
            name: '洛丹伦王城',
            summary: const drift.Value('繁华都城'),
            content: const drift.Value('圣光大教堂座落于此。'),
          ),
        );

        // 3. Seed Child Location (child of city)
        await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            parentId: drift.Value(cityId),
            entityType: 'location',
            name: '王宫大殿',
          ),
        );

        // 4. Seed Character and link
        final charId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                worldId: 1,
                name: '泰瑞纳斯国王',
                description: const drift.Value('洛丹伦的统治者'),
              ),
            );

        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: cityId,
          characterId: charId,
          role: '国王',
        );

        final cityEntity = (await db.loreDao.getEntityById(cityId))!;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(body: LoreEntityDetailDialog(entity: cityEntity)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify breadcrumb
        expect(find.text('洛丹伦王国'), findsOneWidget);
        expect(find.text('洛丹伦王城'), findsWidgets);

        // Verify child entity chip
        expect(find.text('王宫大殿'), findsOneWidget);

        // Verify linked character & role badge
        expect(find.text('泰瑞纳斯国王'), findsOneWidget);
        expect(find.text('国王'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
