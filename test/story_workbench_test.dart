import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/features/story/story_workbench_page.dart';
import 'package:oc_manager/features/story/story_work_dialog.dart';
import 'package:oc_manager/features/story/story_chapter_dialog.dart';
import 'package:oc_manager/features/story/story_scene_dialog.dart';

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
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(102),
            worldId: 1,
            name: '吉安娜',
          ),
        );

    // Seed test lore location
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(1),
            worldId: 1,
            entityType: 'location',
            name: '诺森德荒原',
            summary: const drift.Value('极寒大陆'),
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Story Works & Storyline System Tests (STORY-001)', () {
    test('StoryWorks CRUD and strict world isolation', () async {
      final storyDao = db.storyDao;

      // 1. Create work in World 1
      final work1Id = await storyDao.createWork(
        StoryWorksCompanion.insert(
          worldId: 1,
          title: '冰封王座之影',
          type: const drift.Value('小说'),
          summary: const drift.Value('关于堕落与宿命的悲剧史诗'),
          status: const drift.Value('连载中'),
        ),
      );

      // 2. Create work in World 2
      final work2Id = await storyDao.createWork(
        StoryWorksCompanion.insert(
          worldId: 2,
          title: '霓虹深渊纪事',
          type: const drift.Value('赛博剧本'),
          summary: const drift.Value('底层黑客的抗争录'),
          status: const drift.Value('策划中'),
        ),
      );

      // 3. Verify world isolation
      final world1Works = await storyDao.getWorksByWorld(1);
      final world2Works = await storyDao.getWorksByWorld(2);

      expect(world1Works.length, 1);
      expect(world1Works.first.id, work1Id);
      expect(world1Works.first.title, '冰封王座之影');
      expect(world1Works.first.type, '小说');
      expect(world1Works.first.status, '连载中');

      expect(world2Works.length, 1);
      expect(world2Works.first.id, work2Id);
      expect(world2Works.first.title, '霓虹深渊纪事');

      // 4. Update work
      await storyDao.updateWorkPartial(
        work1Id,
        const StoryWorksCompanion(
          title: drift.Value('巫妖王之怒：重制版'),
          status: drift.Value('已完结'),
        ),
      );

      final updatedWork = await storyDao.getWorkById(work1Id);
      expect(updatedWork?.title, '巫妖王之怒：重制版');
      expect(updatedWork?.status, '已完结');
    });
  });

  group('Story Chapters & Scenes System Tests (STORY-002)', () {
    test('Chapters arc grouping, sorting, and word counts', () async {
      final storyDao = db.storyDao;

      final workId = await storyDao.createWork(
        StoryWorksCompanion.insert(worldId: 1, title: '巫妖王之怒'),
      );

      // Create 3 chapters across 2 arcs
      final ch1Id = await storyDao.createChapter(
        StoryChaptersCompanion.insert(
          workId: workId,
          arcName: const drift.Value('第一卷：寒冬将至'),
          title: '第一章 诺森德的低语',
          summary: const drift.Value('探险队抵达极北之地'),
          status: const drift.Value('已定稿'),
          sortOrder: const drift.Value(0),
          wordCount: const drift.Value(3500),
        ),
      );

      final ch2Id = await storyDao.createChapter(
        StoryChaptersCompanion.insert(
          workId: workId,
          arcName: const drift.Value('第一卷：寒冬将至'),
          title: '第二章 冰霜哀鸣',
          summary: const drift.Value('在废墟中遭遇冰霜巨龙'),
          status: const drift.Value('撰写中'),
          sortOrder: const drift.Value(1),
          wordCount: const drift.Value(4200),
        ),
      );

      final ch3Id = await storyDao.createChapter(
        StoryChaptersCompanion.insert(
          workId: workId,
          arcName: const drift.Value('第二卷：王座坍塌'),
          title: '第三章 终局之战',
          summary: const drift.Value('冰封王座之巅的最后对峙'),
          status: const drift.Value('大纲'),
          sortOrder: const drift.Value(2),
          wordCount: const drift.Value(1000),
        ),
      );

      final chapters = await storyDao.getChaptersByWork(workId);
      expect(chapters.length, 3);
      expect(chapters[0].id, ch1Id);
      expect(chapters[0].arcName, '第一卷：寒冬将至');
      expect(chapters[1].id, ch2Id);
      expect(chapters[2].id, ch3Id);
      expect(chapters[2].arcName, '第二卷：王座坍塌');
    });

    test(
      'StoryScenes POV, location, mood, timeline, and cast details aggregation',
      () async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '霜之哀伤的宿命'),
        );

        final chId = await storyDao.createChapter(
          StoryChaptersCompanion.insert(workId: workId, title: '第一章 拔剑'),
        );

        // Create scene with POV, Location, Mood, and Cast
        final sceneId = await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '祭坛前的抉择',
            summary: const drift.Value('阿尔萨斯在穆拉丁的劝阻下走向符文之剑'),
            content: const drift.Value(
              '1. 穆拉丁宣读符文警告\n2. 阿尔萨斯执意拔出魔剑\n3. 破冰爆破掀翻众人',
            ),
            povCharacterId: const drift.Value(101), // 阿尔萨斯
            locationId: const drift.Value(1), // 诺森德荒原
            locationName: const drift.Value('极寒祭坛密室'),
            timelineTime: const drift.Value('黑暗之门20年 冬暮'),
            mood: const drift.Value('史诗悲壮'),
            characterIds: const drift.Value('[101, 102]'), // 阿尔萨斯, 吉安娜
            sortOrder: const drift.Value(0),
          ),
        );

        expect(sceneId, isPositive);

        // Fetch aggregated scene details
        final details = await storyDao.getSceneDetailsByChapter(chId);
        expect(details.length, 1);

        final detail = details.first;
        expect(detail.scene.title, '祭坛前的抉择');
        expect(detail.scene.mood, '史诗悲壮');
        expect(detail.scene.locationName, '极寒祭坛密室');
        expect(detail.scene.timelineTime, '黑暗之门20年 冬暮');

        // Verify POV Character loaded
        expect(detail.povCharacter, isNotNull);
        expect(detail.povCharacter?.id, 101);
        expect(detail.povCharacter?.name, '阿尔萨斯');

        // Verify Location Lore loaded
        expect(detail.location, isNotNull);
        expect(detail.location?.id, 1);
        expect(detail.location?.name, '诺森德荒原');

        // Verify Cast characterIds JSON parsed
        expect(detail.characterIds, equals([101, 102]));
      },
    );

    test(
      'Work stats aggregation correctly tallies chapters, scenes, and wordCount',
      () async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '统计测试企划'),
        );

        final ch1Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: workId,
            title: '第一章',
            wordCount: const drift.Value(2500),
          ),
        );
        final ch2Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: workId,
            title: '第二章',
            wordCount: const drift.Value(3500),
          ),
        );

        // 2 scenes in ch1
        await storyDao.createScene(
          StoryScenesCompanion.insert(chapterId: ch1Id, title: '场景1-1'),
        );
        await storyDao.createScene(
          StoryScenesCompanion.insert(chapterId: ch1Id, title: '场景1-2'),
        );
        // 1 scene in ch2
        await storyDao.createScene(
          StoryScenesCompanion.insert(chapterId: ch2Id, title: '场景2-1'),
        );

        final stats = await storyDao.getWorkStats(workId);
        expect(stats.chapterCount, 2);
        expect(stats.sceneCount, 3);
        expect(stats.totalWords, 6000);
      },
    );

    test(
      'Cascade deletion: deleting chapter clears scenes; deleting work clears all',
      () async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '级联删除测试作品'),
        );

        final ch1Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(workId: workId, title: '章节1'),
        );
        final ch2Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(workId: workId, title: '章节2'),
        );

        await storyDao.createScene(
          StoryScenesCompanion.insert(chapterId: ch1Id, title: '场景1-1'),
        );
        await storyDao.createScene(
          StoryScenesCompanion.insert(chapterId: ch2Id, title: '场景2-1'),
        );

        // 1. Delete chapter 1
        await storyDao.deleteChapter(ch1Id);
        final ch1Scenes = await storyDao.getScenesByChapter(ch1Id);
        expect(ch1Scenes, isEmpty);
        final remainingChapters = await storyDao.getChaptersByWork(workId);
        expect(remainingChapters.length, 1);
        expect(remainingChapters.first.id, ch2Id);

        // 2. Delete entire work
        await storyDao.deleteWork(workId);
        final works = await storyDao.getWorksByWorld(1);
        expect(works, isEmpty);
        final chapters = await storyDao.getChaptersByWork(workId);
        expect(chapters, isEmpty);
        final ch2Scenes = await storyDao.getScenesByChapter(ch2Id);
        expect(ch2Scenes, isEmpty);

        // 3. Characters and lore entities must stay completely safe!
        final char = await db.characterDao.getCharacterById(101);
        expect(char.name, '阿尔萨斯');
        final lore = await (db.select(
          db.loreEntities,
        )..where((t) => t.id.equals(1))).getSingle();
        expect(lore.name, '诺森德荒原');
      },
    );
  });

  group('Story Workbench Widget Tests', () {
    testWidgets('StoryWorkbenchPage renders empty state when no works exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: StoryWorkbenchPage(worldId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('艾泽拉斯 · 故事线与场景分镜'), findsOneWidget);
      expect(find.text('暂无故事作品'), findsOneWidget);
      expect(find.text('新建故事作品'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'StoryWorkbenchPage renders active work, arcs, chapters, and scene card',
      (tester) async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(
            worldId: 1,
            title: '巫妖王之怒：完整编年史',
            type: const drift.Value('小说'),
            status: const drift.Value('连载中'),
          ),
        );

        final chId = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: workId,
            arcName: const drift.Value('第一卷：北伐序章'),
            title: '第一章 冰封海岸',
            wordCount: const drift.Value(4500),
            status: const drift.Value('撰写中'),
          ),
        );

        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '战舰靠岸',
            summary: const drift.Value('破冰战舰在迷雾中靠近凛风峡湾'),
            povCharacterId: const drift.Value(101),
            locationId: const drift.Value(1),
            mood: const drift.Value('史诗壮烈'),
            characterIds: const drift.Value('[101]'),
          ),
        );

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: StoryWorkbenchPage(worldId: 1)),
          ),
        );

        await tester.pumpAndSettle();

        // Verify work header
        expect(find.text('巫妖王之怒：完整编年史'), findsWidgets);
        expect(find.text('小说'), findsOneWidget);
        expect(find.text('连载中'), findsOneWidget);

        // Verify Arc section
        expect(find.text('第一卷：北伐序章'), findsWidgets);

        // Verify Chapter item (rendered in left outline and right banner)
        expect(find.text('第一章 冰封海岸'), findsWidgets);
        expect(find.text('4500字'), findsOneWidget);

        // Verify Scene Card
        expect(find.text('场景 #1'), findsOneWidget);
        expect(find.text('战舰靠岸'), findsOneWidget);
        expect(find.text('史诗壮烈'), findsOneWidget);
        expect(find.text('破冰战舰在迷雾中靠近凛风峡湾'), findsOneWidget);
        expect(find.text('阿尔萨斯'), findsWidgets);
        expect(find.text('诺森德荒原'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('StoryWorkDialog creates a new work successfully', (
      tester,
    ) async {
      int? createdId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdId = await StoryWorkDialog.show(context, worldId: 1);
                  },
                  child: const Text('打开作品弹窗'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开作品弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('新建故事作品'), findsOneWidget);

      // Enter title and summary
      await tester.enterText(
        find.widgetWithText(TextFormField, '作品标题 *'),
        '黑曜石圣殿传奇',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '作品简介 / 核心梗概'),
        '黑龙军团的复兴阴谋与守护巨龙的誓约',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(createdId, isNotNull);
      final createdWork = await db.storyDao.getWorkById(createdId!);
      expect(createdWork?.title, '黑曜石圣殿传奇');
      expect(createdWork?.summary, '黑龙军团的复兴阴谋与守护巨龙的誓约');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('StoryChapterDialog creates a new chapter under an arc', (
      tester,
    ) async {
      final workId = await db.storyDao.createWork(
        StoryWorksCompanion.insert(worldId: 1, title: '巨龙纪元'),
      );

      int? createdChapterId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdChapterId = await StoryChapterDialog.show(
                      context,
                      workId: workId,
                    );
                  },
                  child: const Text('打开章节弹窗'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开章节弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('添加新章节'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '章节标题 *'),
        '红玉圣殿失守',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '所属故事阶段 / 分卷'),
        '巨龙之怒卷',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '预估 / 实际字数'),
        '5200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '本章大纲摘要 / 核心冲突'),
        '暮光龙族的突袭导致红龙军团圣所遭到重创',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(createdChapterId, isNotNull);
      final ch = await db.storyDao.getChapterById(createdChapterId!);
      expect(ch?.title, '红玉圣殿失守');
      expect(ch?.arcName, '巨龙之怒卷');
      expect(ch?.wordCount, 5200);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('StorySceneDialog creates a new scene with POV and cast', (
      tester,
    ) async {
      final workId = await db.storyDao.createWork(
        StoryWorksCompanion.insert(worldId: 1, title: '巨龙纪元'),
      );
      final chId = await db.storyDao.createChapter(
        StoryChaptersCompanion.insert(workId: workId, title: '红玉圣殿失守'),
      );

      int? createdSceneId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdSceneId = await StorySceneDialog.show(
                      context,
                      worldId: 1,
                      chapterId: chId,
                    );
                  },
                  child: const Text('打开场景弹窗'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开场景弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('添加场景分镜'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '场景标题 *'),
        '圣殿结界破裂',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '发生地点名称'),
        '红玉圣殿核心枢纽',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '发生时间'),
        '黄昏日落前',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '氛围基调 / 情感色彩'),
        '紧迫绝望',
      );

      // Select cast character: '阿尔萨斯'
      await tester.tap(find.widgetWithText(FilterChip, '阿尔萨斯'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(createdSceneId, isNotNull);
      final scene = await db.storyDao.getSceneById(createdSceneId!);
      expect(scene?.title, '圣殿结界破裂');
      expect(scene?.locationName, '红玉圣殿核心枢纽');
      expect(scene?.mood, '紧迫绝望');
      expect(scene?.timelineTime, '黄昏日落前');
      expect(jsonDecode(scene!.characterIds), contains(101));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
