import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/features/character/character_story_appearance_section.dart';
import 'package:oc_manager/features/story/story_cast_dialog.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    // 1. Seed Worlds
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
            description: const drift.Value('未来世界'),
          ),
        );

    // 2. Seed Characters
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(101),
            worldId: 1,
            name: '阿尔萨斯',
            gender: const drift.Value('男'),
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(102),
            worldId: 1,
            name: '吉安娜',
            gender: const drift.Value('女'),
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(103),
            worldId: 1,
            name: '穆拉丁',
            gender: const drift.Value('男'),
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(201),
            worldId: 2,
            name: '赛博义体人',
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Story Character Appearances Engine Tests (STORY-003)', () {
    test(
      'getCharacterAppearanceSummary aggregates scenes, chapters, and POV',
      () async {
        final storyDao = db.storyDao;

        // Work 1
        final work1Id = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '阿尔萨斯史诗'),
        );
        // Work 2
        final work2Id = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '达拉然外传'),
        );

        // Chapters
        final w1Ch1Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: work1Id,
            title: '序章：洛丹伦的阴影',
            sortOrder: const drift.Value(0),
          ),
        );
        final w1Ch2Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: work1Id,
            title: '第二章：斯坦索姆抉择',
            sortOrder: const drift.Value(1),
          ),
        );
        final w2Ch1Id = await storyDao.createChapter(
          StoryChaptersCompanion.insert(
            workId: work2Id,
            title: '第一章：肯瑞托秘典',
            sortOrder: const drift.Value(0),
          ),
        );

        // Scenes:
        // S1: POV = 101 (Arthas), cast = [101]
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: w1Ch1Id,
            title: '王都的警钟',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101]'),
            timelineTime: const drift.Value('天灾历初年 夏暮'),
            sortOrder: const drift.Value(0),
          ),
        );

        // S2: POV = 102 (Jaina), cast = [101, 102]
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: w1Ch1Id,
            title: '重逢于营地',
            povCharacterId: const drift.Value(102),
            characterIds: const drift.Value('[101, 102]'),
            timelineTime: const drift.Value('天灾历初年 秋初'),
            sortOrder: const drift.Value(1),
          ),
        );

        // S3: POV = 101 (Arthas), cast = [101, 102]
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: w1Ch2Id,
            title: '城门前的分道扬镳',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101, 102]'),
            timelineTime: const drift.Value('天灾历初年 暴雨之夜'),
            sortOrder: const drift.Value(0),
          ),
        );

        // S4: in Work 2: POV = 102 (Jaina), cast = [102]
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: w2Ch1Id,
            title: '法师塔的占卜',
            povCharacterId: const drift.Value(102),
            characterIds: const drift.Value('[102]'),
            timelineTime: const drift.Value('天灾历二年 春初'),
            sortOrder: const drift.Value(0),
          ),
        );

        // --- Verify Character 101 (Arthas) ---
        final arthasSummary = await storyDao.getCharacterAppearanceSummary(101);
        expect(arthasSummary.characterId, 101);
        expect(arthasSummary.totalScenes, 3);
        expect(arthasSummary.totalChapters, 2);
        expect(arthasSummary.totalPovScenes, 2);
        expect(arthasSummary.scenesCountByWork[work1Id], 3);
        expect(arthasSummary.scenesCountByWork[work2Id], isNull);

        // First appearance
        expect(arthasSummary.firstAppearance, isNotNull);
        expect(arthasSummary.firstAppearance!.work.id, work1Id);
        expect(arthasSummary.firstAppearance!.chapter.title, '序章：洛丹伦的阴影');
        expect(arthasSummary.firstAppearance!.scene.title, '王都的警钟');
        expect(arthasSummary.firstAppearance!.isPov, isTrue);

        // Last appearance
        expect(arthasSummary.lastAppearance, isNotNull);
        expect(arthasSummary.lastAppearance!.chapter.title, '第二章：斯坦索姆抉择');
        expect(arthasSummary.lastAppearance!.scene.title, '城门前的分道扬镳');

        // --- Verify Character 102 (Jaina) ---
        final jainaSummary = await storyDao.getCharacterAppearanceSummary(102);
        expect(jainaSummary.totalScenes, 3);
        expect(jainaSummary.totalChapters, 3);
        expect(jainaSummary.totalPovScenes, 2);
        expect(jainaSummary.scenesCountByWork[work1Id], 2);
        expect(jainaSummary.scenesCountByWork[work2Id], 1);
        expect(jainaSummary.firstAppearance!.work.title, '阿尔萨斯史诗');
        expect(jainaSummary.lastAppearance!.work.title, '达拉然外传');

        // --- Verify Character 103 (Muradin, 0 appearances) ---
        final muradinSummary = await storyDao.getCharacterAppearanceSummary(
          103,
        );
        expect(muradinSummary.totalScenes, 0);
        expect(muradinSummary.totalChapters, 0);
        expect(muradinSummary.totalPovScenes, 0);
        expect(muradinSummary.firstAppearance, isNull);
        expect(muradinSummary.lastAppearance, isNull);

        // --- Verify World 2 Character 201 (World Isolation) ---
        final cyberSummary = await storyDao.getCharacterAppearanceSummary(201);
        expect(cyberSummary.totalScenes, 0);
      },
    );

    test(
      'getWorkCharacterCastStats correctly ranks and counts cast members',
      () async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '洛丹伦挽歌'),
        );

        final chId = await storyDao.createChapter(
          StoryChaptersCompanion.insert(workId: workId, title: '第一章 亡灵天灾'),
        );

        // Scene 1: Arthas (POV) + Jaina + Muradin
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '初遇天灾',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101, 102, 103]'),
            sortOrder: const drift.Value(0),
          ),
        );

        // Scene 2: Arthas (POV) + Jaina
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '净化粮仓',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101, 102]'),
            sortOrder: const drift.Value(1),
          ),
        );

        // Scene 3: Arthas only
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '独坐寒夜',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101]'),
            sortOrder: const drift.Value(2),
          ),
        );

        final castStats = await storyDao.getWorkCharacterCastStats(workId);
        expect(castStats.length, 3);

        // Rank 1: Arthas (3 scenes, 3 POV)
        expect(castStats[0].character.id, 101);
        expect(castStats[0].character.name, '阿尔萨斯');
        expect(castStats[0].sceneCount, 3);
        expect(castStats[0].povCount, 3);
        expect(castStats[0].firstAppearance?.scene.title, '初遇天灾');

        // Rank 2: Jaina (2 scenes, 0 POV)
        expect(castStats[1].character.id, 102);
        expect(castStats[1].character.name, '吉安娜');
        expect(castStats[1].sceneCount, 2);
        expect(castStats[1].povCount, 0);

        // Rank 3: Muradin (1 scene, 0 POV)
        expect(castStats[2].character.id, 103);
        expect(castStats[2].character.name, '穆拉丁');
        expect(castStats[2].sceneCount, 1);
      },
    );
  });

  group('Story Character Appearances Widget Tests (STORY-003)', () {
    testWidgets(
      'CharacterStoryAppearanceSection renders empty state when no appearances',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: CharacterStoryAppearanceSection(
                  worldId: 1,
                  characterId: 103, // Muradin has 0 appearances
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('故事线出场记录'), findsOneWidget);
        expect(find.text('该角色暂无故事作品出场记录'), findsOneWidget);
        expect(find.text('故事工作台'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'CharacterStoryAppearanceSection renders metrics, first/last cards and scenes',
      (tester) async {
        final storyDao = db.storyDao;

        final workId = await storyDao.createWork(
          StoryWorksCompanion.insert(worldId: 1, title: '巫妖王之怒'),
        );
        final chId = await storyDao.createChapter(
          StoryChaptersCompanion.insert(workId: workId, title: '拔剑之章'),
        );
        await storyDao.createScene(
          StoryScenesCompanion.insert(
            chapterId: chId,
            title: '祭坛冰裂',
            povCharacterId: const drift.Value(101),
            characterIds: const drift.Value('[101]'),
            timelineTime: const drift.Value('天灾历三年 深冬'),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: CharacterStoryAppearanceSection(
                  worldId: 1,
                  characterId: 101,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Header & Metrics
        expect(find.text('故事线出场记录'), findsOneWidget);
        expect(find.text('1 场次'), findsOneWidget);
        expect(find.text('出场 1 场景'), findsOneWidget);
        expect(find.text('覆盖 1 章节'), findsOneWidget);
        expect(find.text('POV 视点 1 场'), findsOneWidget);

        // Verify First / Latest Appearance Highlights
        expect(find.text('首次登场'), findsOneWidget);
        expect(find.text('最近登场'), findsOneWidget);
        expect(find.text('《巫妖王之怒》'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('StoryCastDialog renders cast rankings and filters by query', (
      tester,
    ) async {
      final storyDao = db.storyDao;

      final workId = await storyDao.createWork(
        StoryWorksCompanion.insert(worldId: 1, title: '巫妖王之怒'),
      );
      final chId = await storyDao.createChapter(
        StoryChaptersCompanion.insert(workId: workId, title: '第一章'),
      );
      await storyDao.createScene(
        StoryScenesCompanion.insert(
          chapterId: chId,
          title: '战舰起航',
          povCharacterId: const drift.Value(101),
          characterIds: const drift.Value('[101, 102]'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    StoryCastDialog.show(
                      context,
                      workId: workId,
                      workTitle: '巫妖王之怒',
                      worldId: 1,
                    );
                  },
                  child: const Text('打开登场角色表'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开登场角色表'));
      await tester.pumpAndSettle();

      expect(find.text('《巫妖王之怒》登场角色表'), findsOneWidget);
      expect(find.text('阿尔萨斯'), findsOneWidget);
      expect(find.text('吉安娜'), findsOneWidget);
      expect(find.text('出场 1 场'), findsWidgets);

      // Search Filter
      await tester.enterText(find.byType(TextField), '吉安娜');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, '吉安娜'), findsOneWidget);
      expect(find.text('阿尔萨斯'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
