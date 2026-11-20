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
  group('LORE-005 Race & LORE-006 Ability Management Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // Seed world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '艾泽拉斯世界',
              description: const drift.Value('奇幻魔幻世界观'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Race creation with hierarchical sub-species branches and origin habitat',
      () async {
        // 1. 创建发源故土地点
        final quelThalasId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '奎尔萨拉斯',
            summary: const drift.Value('高等精灵与血精灵永恒的太阳之国'),
          ),
        );

        // 2. 创建起源母种族：高等精灵
        final highElfId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '高等精灵',
            summary: const drift.Value('崇尚太阳与奥术魔法的古老长生种族'),
            customFields: const drift.Value(
              '{"种族类别":"智慧人型","平均寿命":"2000-3000年","外貌特征":"修长优雅，银发金瞳，长耳感知魔能","生活习性":"聚居于魔法都城，研习奥术与艺术","信仰崇拜":"崇拜太阳之井的圣洁奥术之源"}',
            ),
          ),
        );

        // 3. 创建衍生亚种分支：血精灵 (parentId 指向高等精灵)
        final bloodElfId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '血精灵',
            parentId: drift.Value(highElfId),
            summary: const drift.Value('在天灾入侵天崩地裂后自称的幸存者分支'),
            customFields: const drift.Value(
              '{"种族类别":"变种分支","平均寿命":"约2000年","外貌特征":"双眸泛着魔能幽绿光芒，背负魔瘾","信仰崇拜":"为了生存与复仇，不惜吸取邪能"}',
            ),
          ),
        );

        // 4. 验证树形层级
        final subRaces = await db.loreDao.getChildEntities(highElfId);
        expect(subRaces.length, 1);
        expect(subRaces.first.id, bloodElfId);
        expect(subRaces.first.name, '血精灵');

        final ancestors = await db.loreDao.getAncestors(bloodElfId);
        expect(ancestors.length, 1);
        expect(ancestors.first.id, highElfId);
        expect(ancestors.first.name, '高等精灵');

        // 5. 建立种族发源地关联 (LoreEntityRelations)
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: highElfId,
          toLoreId: quelThalasId,
          relationType: '发源故土',
          isBidirectional: false,
          note: '高等精灵在东部王国北端开创的太阳文明圣地',
        );

        final relations = await db.loreDao.getEntityRelations(highElfId);
        expect(relations.length, 1);
        expect(relations.first.relation.relationType, '发源故土');
        expect(relations.first.otherEntity.name, '奎尔萨拉斯');
      },
    );

    test(
      'Ability creation with progression tree, power rank, and enchantments',
      () async {
        // 1. 创建法术基础体系：元素魔法
        final elementalMagicId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'ability',
            name: '元素魔法',
            summary: const drift.Value('操控水火风土四大自然元素的奥术魔法根基'),
            customFields: const drift.Value(
              '{"能力分类":"奥术自然","威能阶位":"基础至大成","生效方式":"引导魔能呼唤自然四大元素形成物理能量冲击","前置条件":"具备纯净魔力源与元素共鸣亲和力"}',
            ),
          ),
        );

        // 2. 创建进阶禁咒体系：极寒风暴禁咒 (parentId 指向元素魔法)
        final blizzardSpellId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'ability',
            name: '极寒风暴禁咒',
            parentId: drift.Value(elementalMagicId),
            summary: const drift.Value('将水元素极限压缩升华的极冰毁灭魔法'),
            customFields: const drift.Value(
              '{"能力分类":"禁断冰霜体系","威能阶位":"天灾禁咒 (Forbidden)","生效方式":"在数平方公里内引发绝对零度风暴暴风雪，冰封一切生机","前置条件":"掌握大成冰霜亲和与高阶施法引导法杖","反噬代价":"持续施法将永久冻损施法者神经脉络并燃烧生命力"}',
            ),
          ),
        );

        // 3. 验证能力进阶树
        final advancedSpells = await db.loreDao.getChildEntities(
          elementalMagicId,
        );
        expect(advancedSpells.length, 1);
        expect(advancedSpells.first.id, blizzardSpellId);
        expect(advancedSpells.first.name, '极寒风暴禁咒');

        // 4. 创建承载法宝装备
        final frostStaffId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'item',
            name: '极冰法杖',
            summary: const drift.Value('由千年玄冰打造的施法法杖'),
          ),
        );

        // 5. 建立能力与装备附魔载体关联 (LoreEntityRelations)
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: blizzardSpellId,
          toLoreId: frostStaffId,
          relationType: '载体附魔',
          isBidirectional: true,
          note: '法杖刻印了极寒风暴禁咒的法阵符文',
        );

        final spellRelations = await db.loreDao.getEntityRelations(
          blizzardSpellId,
        );
        expect(spellRelations.length, 1);
        expect(spellRelations.first.relation.relationType, '载体附魔');
        expect(spellRelations.first.otherEntity.name, '极冰法杖');
      },
    );

    test(
      'Character race lineage and ability mastery with leader/master priority',
      () async {
        // 1. 创建种族与能力
        final bloodElfId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '血精灵',
          ),
        );

        final blizzardSpellId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'ability',
            name: '极寒风暴禁咒',
          ),
        );

        // 2. 创建角色
        final kaelthasId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '凯尔萨斯·逐日者'),
        );
        final ordinaryElfId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '辛多雷巡逻斥候'),
        );
        final jainaId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '吉安娜·普罗德摩尔'),
        );
        final apprenticeId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '达拉然法师学徒'),
        );

        // 3. 关联种族角色：凯尔萨斯是王室始祖，斥候是普通游侠
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: bloodElfId,
          characterId: ordinaryElfId,
          role: '族系游侠',
        );
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: bloodElfId,
          characterId: kaelthasId,
          role: '王室始祖 / 太阳王',
        );

        // 4. 关联能力角色：吉安娜是巅峰宗师，学徒是初窥门径
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: blizzardSpellId,
          characterId: apprenticeId,
          role: '初窥门径',
        );
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: blizzardSpellId,
          characterId: jainaId,
          role: '巅峰大成宗师',
        );

        // 5. 验证关联检索
        final elfMembers = await db.loreDao.getCharactersByLore(bloodElfId);
        expect(elfMembers.length, 2);
        expect(
          elfMembers.map((m) => m.character.name).toSet(),
          containsAll(['凯尔萨斯·逐日者', '辛多雷巡逻斥候']),
        );

        final abilityUsers = await db.loreDao.getCharactersByLore(
          blizzardSpellId,
        );
        expect(abilityUsers.length, 2);
        expect(
          abilityUsers.map((m) => m.character.name).toSet(),
          containsAll(['吉安娜·普罗德摩尔', '达拉然法师学徒']),
        );

        // 6. 验证角色视角下的条目归属
        final kaelthasAffiliations = await db.loreDao.getLoresByCharacter(
          kaelthasId,
        );
        expect(kaelthasAffiliations.length, 1);
        expect(kaelthasAffiliations.first.lore.name, '血精灵');
        expect(kaelthasAffiliations.first.relation.role, '王室始祖 / 太阳王');

        final jainaAffiliations = await db.loreDao.getLoresByCharacter(jainaId);
        expect(jainaAffiliations.length, 1);
        expect(jainaAffiliations.first.lore.name, '极寒风暴禁咒');
        expect(jainaAffiliations.first.relation.role, '巅峰大成宗师');
      },
    );

    testWidgets(
      'UI Widget Test: LoreEntityDetailDialog renders Race badges, traits and faith cards',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final highElfId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '高等精灵',
            summary: const drift.Value('永恒纯净的太阳种族'),
            customFields: const drift.Value(
              '{"种族类别":"智慧人型","平均寿命":"2000-3000年","外貌特征":"修长优雅，银发金瞳，长耳感知魔能","生活习性":"聚居于魔法都城","信仰崇拜":"崇拜太阳之井"}',
            ),
          ),
        );

        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '阿纳斯特里安·逐日者'),
        );
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: highElfId,
          characterId: charId,
          role: '先祖始祖国王',
        );

        final entity = (await db.loreDao.getEntityById(highElfId))!;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(body: LoreEntityDetailDialog(entity: entity)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 验证种族名称
        expect(find.text('高等精灵'), findsWidgets);

        // 验证种族特征徽章
        expect(find.text('智慧人型'), findsWidgets);
        expect(find.text('寿命: 2000-3000年'), findsWidgets);

        // 验证种族外貌特征卡片与信仰卡片
        expect(find.textContaining('生理与外貌特征：修长优雅，银发金瞳，长耳感知魔能'), findsOneWidget);
        expect(
          find.textContaining('文化习俗与信仰：聚居于魔法都城 | 信仰崇拜：崇拜太阳之井'),
          findsOneWidget,
        );

        // 验证族系角色标题
        expect(find.textContaining('族系角色与血脉成员'), findsOneWidget);
        expect(find.text('阿纳斯特里安·逐日者'), findsOneWidget);
        expect(find.text('先祖始祖国王'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'UI Widget Test: LoreEntityDetailDialog renders Ability badges, power and cost cards',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final blizzardSpellId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'ability',
            name: '极寒风暴禁咒',
            summary: const drift.Value('极冰毁灭魔法'),
            customFields: const drift.Value(
              '{"能力分类":"禁断冰霜体系","威能阶位":"天灾禁咒","生效方式":"数平方公里内引发绝对零度暴风雪","前置条件":"掌握高阶冰霜亲和","反噬代价":"永久冻损施法者神经脉络"}',
            ),
          ),
        );

        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '吉安娜'),
        );
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: blizzardSpellId,
          characterId: charId,
          role: '大成创造宗师',
        );

        final entity = (await db.loreDao.getEntityById(blizzardSpellId))!;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(body: LoreEntityDetailDialog(entity: entity)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 验证能力名称
        expect(find.text('极寒风暴禁咒'), findsWidgets);

        // 验证阶位与派系徽章
        expect(find.text('天灾禁咒'), findsWidgets);
        expect(find.text('禁断冰霜体系'), findsWidgets);

        // 验证威能生效方式与前置反噬代价卡片
        expect(
          find.textContaining('生效方式与威能表现：数平方公里内引发绝对零度暴风雪'),
          findsOneWidget,
        );
        expect(
          find.textContaining('修习前置与限制代价：前置要求: 掌握高阶冰霜亲和 | 代价限制: 永久冻损施法者神经脉络'),
          findsOneWidget,
        );

        // 验证修习角色标题与宗师
        expect(find.textContaining('创造宗师与修习掌握者'), findsOneWidget);
        expect(find.text('吉安娜'), findsOneWidget);
        expect(find.text('大成创造宗师'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'UI Widget Test: CharacterDetailPage renders World Lore affiliations card',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final highElfId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '高等精灵',
          ),
        );

        final frostId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'ability',
            name: '寒冰奥义',
          ),
        );

        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '凯尔萨斯'),
        );

        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: highElfId,
          characterId: charId,
          role: '王室血脉',
        );
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: frostId,
          characterId: charId,
          role: '精通修习',
        );

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

        final affiliationFinder = find.textContaining('种族与能力');
        await tester.scrollUntilVisible(
          affiliationFinder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 验证板块标题
        expect(affiliationFinder, findsOneWidget);

        // 验证种族与能力归属 Chip 展示
        expect(find.text('高等精灵'), findsOneWidget);
        expect(find.text('王室血脉'), findsOneWidget);
        expect(find.text('寒冰奥义'), findsOneWidget);
        expect(find.text('精通修习'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
