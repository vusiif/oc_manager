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
  group('LORE-004 Item & Equipment Management Tests', () {
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
      'Item creation with structured traits, bearer relations, and entity ties',
      () async {
        // 1. 创建地点与组织作为关联依托
        final throneLocationId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '冰封王座',
            summary: const drift.Value('诺森德大陆之巅的极寒王座'),
          ),
        );

        final silverHandFactionId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'faction',
            name: '白银之手骑士团',
          ),
        );

        // 2. 创建神器装备：霜之哀伤
        final frostmourneId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'item',
            name: '霜之哀伤',
            summary: const drift.Value('吸取灵魂的魔剑，巫妖王意志的载体'),
            content: const drift.Value('这把诅咒符文剑由恐惧魔王锻造，封印于诺森德深处。'),
            customFields: const drift.Value(
              '{"物品类别":"符文魔剑","品阶稀有度":"神器 (Artifact)","持有状态":"现世活跃","来源出处":"纳斯雷兹姆锻造","特殊效果":"击杀目标直接吸取并奴役灵魂","使用代价":"逐步腐蚀并夺取持有者心智"}',
            ),
          ),
        );

        // 3. 创建圣物装备：灰烬使者
        final ashbringerId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'item',
            name: '灰烬使者',
            summary: const drift.Value('由纯净圣光水晶锻造的神圣巨剑'),
            customFields: const drift.Value(
              '{"物品类别":"神圣双手剑","品阶稀有度":"传说 (Legendary)","持有状态":"现世活跃","特殊效果":"圣光审判将亡灵化为飞灰"}',
            ),
          ),
        );

        // 4. 关联角色：持有者、制造工匠
        final arthasId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '阿尔萨斯'),
        );
        final magniId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '麦格尼·铜须'),
        );

        // 阿尔萨斯 -> 霜之哀伤【持有者】
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: frostmourneId,
          characterId: arthasId,
          role: '堕落持有者',
        );

        // 麦格尼·铜须 -> 灰烬使者【锻造制造者】
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: ashbringerId,
          characterId: magniId,
          role: '神圣铸剑师（制造者）',
        );

        // 5. 建立物品与地缘/组织/装备之间的相互关系
        // 霜之哀伤 【存放于/封印地】 冰封王座
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: frostmourneId,
          toLoreId: throneLocationId,
          relationType: '存放于/封印地',
          isBidirectional: true,
          note: '最初封印在极地坚冰之中',
        );

        // 灰烬使者 【归属于/宗派圣物】 白银之手骑士团
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: ashbringerId,
          toLoreId: silverHandFactionId,
          relationType: '归属于/宗派圣物',
          isBidirectional: true,
          note: '大领主莫格莱尼的传奇佩剑',
        );

        // 霜之哀伤 与 灰烬使者 【克制对立】
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: frostmourneId,
          toLoreId: ashbringerId,
          relationType: '克制对立',
          isBidirectional: true,
          note: '光与暗的终极碰撞',
        );

        // 6. 验证查询
        // 查询霜之哀伤的关联角色
        final frostmourneWielders = await db.loreDao.getCharactersByLore(
          frostmourneId,
        );
        expect(frostmourneWielders.length, equals(1));
        expect(frostmourneWielders.first.character.name, equals('阿尔萨斯'));
        expect(frostmourneWielders.first.relation.role, equals('堕落持有者'));

        // 查询霜之哀伤的外部实体关系（包含冰封王座与灰烬使者）
        final frostRelations = await db.loreDao.getEntityRelations(
          frostmourneId,
        );
        expect(frostRelations.length, equals(2));
        expect(
          frostRelations.any(
            (r) =>
                r.otherEntity.name == '冰封王座' &&
                r.relation.relationType == '存放于/封印地',
          ),
          isTrue,
        );
        expect(
          frostRelations.any(
            (r) =>
                r.otherEntity.name == '灰烬使者' &&
                r.relation.relationType == '克制对立',
          ),
          isTrue,
        );

        // 反向从阿尔萨斯查询其随身佩戴的装备
        final arthasLores = await db.loreDao.getLoresByCharacter(arthasId);
        expect(arthasLores.length, equals(1));
        expect(arthasLores.first.lore.name, equals('霜之哀伤'));
        expect(arthasLores.first.relation.role, equals('堕落持有者'));
      },
    );

    testWidgets(
      'LoreEntityDetailDialog renders item rarity badge, powers, costs, and bearers',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. 种子装备
        final itemId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'item',
            name: '埃提耶什·守护者的传说之杖',
            summary: const drift.Value('提瑞斯法守护者历代相传的神圣法杖'),
            content: const drift.Value('法杖镶嵌有乌鸦之神印记，可打开通往卡拉赞的传送门。'),
            customFields: const drift.Value(
              '{"物品类别":"传奇法杖","品阶稀有度":"神话 (Mythic)","持有状态":"现世活跃","特殊效果":"极大增幅奥术法术，可化身渡鸦自由翱翔","使用代价":"需与提瑞斯法历代守护者意志共鸣"}',
            ),
          ),
        );

        final medivhId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(worldId: 1, name: '麦迪文'),
        );

        final karazhanId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '卡拉赞高塔',
          ),
        );

        // 关联麦迪文为持有者
        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: itemId,
          characterId: medivhId,
          role: '最后守护者（持有者）',
        );

        // 关联存放地卡拉赞
        await db.loreDao.addEntityRelation(
          worldId: 1,
          fromLoreId: itemId,
          toLoreId: karazhanId,
          relationType: '存放于/封印地',
          isBidirectional: true,
          note: '常驻于卡拉赞藏书塔顶',
        );

        final loadedItem = (await db.loreDao.getEntityById(itemId))!;

        // 2. 渲染详情弹窗
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(body: LoreEntityDetailDialog(entity: loadedItem)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. 验证渲染
        expect(find.text('埃提耶什·守护者的传说之杖'), findsWidgets);
        expect(find.text('神话 (Mythic)'), findsWidgets); // 品阶徽章
        expect(find.text('现世活跃'), findsWidgets); // 状态
        expect(
          find.textContaining('装备特效与威能：极大增幅奥术法术，可化身渡鸦自由翱翔'),
          findsOneWidget,
        ); // 特效卡片
        expect(
          find.textContaining('使用代价与限制：需与提瑞斯法历代守护者意志共鸣'),
          findsOneWidget,
        ); // 代价卡片
        expect(find.textContaining('持有者与制造传承'), findsOneWidget); // 角色区域标题
        expect(find.text('麦迪文'), findsOneWidget); // 角色姓名
        expect(find.text('最后守护者（持有者）'), findsOneWidget); // 角色身份
        expect(find.textContaining('归属势力与存放地缘'), findsOneWidget); // 关系区域标题
        expect(find.text('卡拉赞高塔'), findsOneWidget); // 地点
        expect(find.text('存放于/封印地'), findsOneWidget); // 关系类型

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'CharacterDetailPage renders equipment & weapon affiliation cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. 种子数据
        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(
            worldId: 1,
            name: '伊利丹·怒风',
            gender: const drift.Value('男'),
          ),
        );

        final warglaivesId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'item',
            name: '埃辛诺斯战刃',
            summary: const drift.Value('末日守卫指挥官埃辛诺斯的双生战刃'),
          ),
        );

        await db.loreDao.addCharacterRelation(
          worldId: 1,
          loreId: warglaivesId,
          characterId: charId,
          role: '灵魂契约持有者',
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

        // 滚动直到装备/势力卡片可见
        final affiliationFinder = find.textContaining('所属势力与地点归属');
        await tester.scrollUntilVisible(
          affiliationFinder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. 验证卡片呈现装备
        expect(affiliationFinder, findsOneWidget);
        expect(find.text('埃辛诺斯战刃'), findsOneWidget);
        expect(find.text('灵魂契约持有者'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
