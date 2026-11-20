import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/features/world/lore_entity_detail_dialog.dart';
import 'package:oc_manager/features/character/character_detail_page.dart';

void main() {
  group('LORE-003 Faction Management & Diplomatic Relations Tests', () {
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
      'Schema v14 supports LoreEntityRelations for faction diplomacy',
      () async {
        expect(db.schemaVersion, greaterThanOrEqualTo(14));

        // 1. 创建三大势力
        final silverHandId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '白银之手骑士团',
            summary: const drift.Value('由阿隆索斯·法奥创立的圣骑士组织'),
            customFields: const drift.Value('{"核心宗旨":"以圣光守护弱者","势力现状":"鼎盛时期"}'),
          ),
        );

        final dalaranId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '达拉然肯瑞托',
            summary: const drift.Value('法师评议会与魔法王国'),
            customFields: const drift.Value(
              '{"核心宗旨":"研究魔法奥秘与守护世界","势力现状":"活跃繁荣"}',
            ),
          ),
        );

        final scourgeId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '天灾军团',
            summary: const drift.Value('亡灵天灾与巫妖王爪牙'),
            customFields: const drift.Value(
              '{"核心宗旨":"将一切生命转化为死亡","势力现状":"全面开战"}',
            ),
          ),
        );

        // 2. 建立关系：
        // 白银之手 与 达拉然：双向【同盟】
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: silverHandId,
          toLoreId: dalaranId,
          relationType: '同盟',
          isBidirectional: true,
          note: '签署《洛丹伦互助协定》',
        );

        // 白银之手 与 天灾军团：双向【敌对】
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: silverHandId,
          toLoreId: scourgeId,
          relationType: '敌对',
          isBidirectional: true,
          note: '净化斯坦索姆与亡灵战争',
        );

        // 3. 验证从【白银之手】查询其所有外交关系
        final silverRelations = await db.loreDao.getEntityRelations(
          silverHandId,
        );
        expect(silverRelations.length, equals(2));
        expect(
          silverRelations.any(
            (r) =>
                r.otherEntity.name == '达拉然肯瑞托' &&
                r.relation.relationType == '同盟',
          ),
          isTrue,
        );
        expect(
          silverRelations.any(
            (r) =>
                r.otherEntity.name == '天灾军团' && r.relation.relationType == '敌对',
          ),
          isTrue,
        );

        // 4. 验证从【达拉然】（作为 toLoreId 接收方）双向也能查到与白银之手的同盟
        final dalaranRelations = await db.loreDao.getEntityRelations(dalaranId);
        expect(dalaranRelations.length, equals(1));
        expect(dalaranRelations.first.otherEntity.name, equals('白银之手骑士团'));
        expect(dalaranRelations.first.relation.relationType, equals('同盟'));

        // 5. 解除白银之手与天灾军团的关系
        final enemyRel = silverRelations.firstWhere(
          (r) => r.relation.relationType == '敌对',
        );
        await db.loreDao.removeEntityRelation(enemyRel.relation.id);

        final updatedSilverRelations = await db.loreDao.getEntityRelations(
          silverHandId,
        );
        expect(updatedSilverRelations.length, equals(1));
        expect(
          updatedSilverRelations.first.relation.relationType,
          equals('同盟'),
        );

        // 6. 验证级联删除：删除白银之手，相关的 LoreEntityRelations 必须被全部安全清理
        await db.loreDao.deleteEntity(silverHandId);
        final remainingDalaranRelations = await db.loreDao.getEntityRelations(
          dalaranId,
        );
        expect(remainingDalaranRelations, isEmpty);
      },
    );

    test('Faction character membership and leader role ranking', () async {
      // 1. 创建势力
      final factionId = await db.loreDao.createEntity(
        LoreEntitiesCompanion.insert(
          worldId: 1,
          entityType: 'faction',
          name: '暴风城皇家卫兵',
        ),
      );

      // 2. 创建三个角色：领袖、副官、见习
      final utherId = await db.characterDao.createCharacter(
        CharactersCompanion.insert(worldId: 1, name: '乌瑟尔'),
      );
      final arthasId = await db.characterDao.createCharacter(
        CharactersCompanion.insert(worldId: 1, name: '阿尔萨斯'),
      );
      final recruitId = await db.characterDao.createCharacter(
        CharactersCompanion.insert(worldId: 1, name: '新兵鲍勃'),
      );

      // 3. 关联人物职务
      await db.loreDao.addCharacterRelation(
        worldId: 1,
        loreId: factionId,
        characterId: recruitId,
        role: '见习侍从',
      );
      await db.loreDao.addCharacterRelation(
        worldId: 1,
        loreId: factionId,
        characterId: utherId,
        role: '骑士团大领袖',
      );
      await db.loreDao.addCharacterRelation(
        worldId: 1,
        loreId: factionId,
        characterId: arthasId,
        role: '圣骑士核心成员',
      );

      // 4. 查询该势力的所有成员
      final members = await db.loreDao.getCharactersByLore(factionId);
      expect(members.length, equals(3));

      // 5. 验证角色反向所属势力
      final utherAffiliations = await db.loreDao.getLoresByCharacter(utherId);
      expect(utherAffiliations.length, equals(1));
      expect(utherAffiliations.first.lore.name, equals('暴风城皇家卫兵'));
      expect(utherAffiliations.first.relation.role, equals('骑士团大领袖'));
    });

    testWidgets(
      'LoreEntityDetailDialog renders faction creed, status, diplomacy and members',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. 种子数据
        final faction = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '铁炉堡探险者协会',
            summary: const drift.Value('探索艾泽拉斯古迹的矮人机构'),
            content: const drift.Value('考古学家与探险家聚集于此。'),
            customFields: const drift.Value(
              '{"核心宗旨":"发掘泰坦遗迹，解开造物奥秘","势力现状":"繁盛兴旺"}',
            ),
          ),
        );

        final alliedFaction = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '侏儒工程学同盟',
          ),
        );

        final leaderChar = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '布莱恩·铜须'),
        );

        // 关联领袖与同盟
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: faction,
          characterId: leaderChar,
          role: '首席探险家（领袖）',
        );

        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: faction,
          toLoreId: alliedFaction,
          relationType: '同盟',
          isBidirectional: true,
          note: '技术与考古互助合作',
        );

        final loadedFaction = (await db.loreDao.getEntityById(faction))!;

        // 2. 构建测试组件
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(
                body: LoreEntityDetailDialog(entity: loadedFaction),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. 验证渲染
        expect(find.text('铁炉堡探险者协会'), findsWidgets);
        expect(find.text('繁盛兴旺'), findsWidgets); // 势力现状徽章与专有属性
        expect(
          find.textContaining('核心宗旨：发掘泰坦遗迹，解开造物奥秘'),
          findsOneWidget,
        ); // 宗旨卡片
        expect(find.textContaining('势力外交与地缘关系'), findsOneWidget);
        expect(find.text('侏儒工程学同盟'), findsOneWidget); // 外交同盟组织
        expect(find.text('同盟'), findsOneWidget); // 同盟类型
        expect(find.text('布莱恩·铜须'), findsOneWidget); // 成员
        expect(find.text('首席探险家（领袖）'), findsOneWidget); // 职务

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('CharacterDetailPage renders lore affiliation section', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. 种子数据
      final charId = await db.characterDao.createCharacter(
        CharactersCompanion.insert(
          worldId: 1,
          name: '吉安娜',
          gender: const drift.Value('女'),
        ),
      );

      final factionId = await db.loreDao.createEntity(
        LoreEntitiesCompanion.insert(
          worldId: 1,
          entityType: 'faction',
          name: '塞拉摩岛国',
        ),
      );

      await db.loreDao.addCharacterRelation(
        worldId: 1,
        loreId: factionId,
        characterId: charId,
        role: '最高统治领袖',
      );

      // 2. 渲染 CharacterDetailPage
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: CharacterDetailPage(worldId: 1, characterId: charId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 滚动直到所属势力卡片可见
      final affiliationFinder = find.textContaining('所属势力与地点归属');
      await tester.scrollUntilVisible(
        affiliationFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. 验证所属势力卡片呈现
      expect(affiliationFinder, findsOneWidget);
      expect(find.text('塞拉摩岛国'), findsOneWidget);
      expect(find.text('最高统治领袖'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
