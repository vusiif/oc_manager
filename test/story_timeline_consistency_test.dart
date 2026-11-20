import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';

void main() {
  group('STORY-004 StoryTimelineConsistencyRule Tests', () {
    late StoryTimelineConsistencyRule rule;

    setUp(() {
      rule = StoryTimelineConsistencyRule();
    });

    final testWork = StoryWork(
      id: 1,
      worldId: 1,
      title: '终末战歌',
      summary: '',
      type: 'novel',
      status: '连载中',
      coverImagePath: null,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testChapter1 = StoryChapter(
      id: 1,
      workId: 1,
      title: '第一章 启程',
      arcName: '第一卷 破晓',
      sortOrder: 0,
      wordCount: 0,
      status: '已定稿',
      summary: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testChar = Character(
      id: 10,
      worldId: 1,
      name: '艾斯特尔',
      gender: '女',
      description: '星辰之剑使',
      status: 0,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Rule metadata matches STORY-004 requirements', () {
      expect(rule.ruleId, equals('RULE_STORY_TIMELINE'));
      expect(rule.category, equals(IssueCategory.story));
      expect(rule.defaultSeverity, equals(IssueSeverity.warning));
    });

    test(
      'Diagnoses narrative timeline inversion between sequential scenes',
      () async {
        final scene1 = StoryScene(
          id: 1,
          chapterId: 1,
          title: '集结圣城',
          summary: '',
          content: '',
          timelineTime: '2025年',
          locationName: '',
          povCharacterId: null,
          characterIds: '[]',
          sortOrder: 0,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final scene2 = StoryScene(
          id: 2,
          chapterId: 1,
          title: '夜袭营地',
          summary: '',
          content: '',
          timelineTime: '2020年', // Earlier than 2025
          locationName: '',
          povCharacterId: null,
          characterIds: '[]',
          sortOrder: 1,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = ConsistencyContext(
          worldId: 1,
          characters: [testChar],
          relations: [],
          events: [],
          lores: [],
          galleries: [],
          works: [testWork],
          chapters: [testChapter1],
          scenes: [scene1, scene2],
        );

        final issues = await rule.evaluate(context);
        final invertedIssues = issues
            .where((i) => i.id.startsWith('story_timeline_inverted_'))
            .toList();

        expect(invertedIssues.length, equals(1));
        expect(invertedIssues.first.severity, equals(IssueSeverity.warning));
        expect(invertedIssues.first.title, contains('倒错'));
        expect(invertedIssues.first.evidence, contains('2025年'));
        expect(invertedIssues.first.evidence, contains('2020年'));
      },
    );

    test(
      'Exempts flashback / reminiscence scenes from inversion warning',
      () async {
        final scene1 = StoryScene(
          id: 1,
          chapterId: 1,
          title: '决战前夕',
          summary: '',
          content: '',
          timelineTime: '2030年',
          locationName: '',
          povCharacterId: null,
          characterIds: '[]',
          sortOrder: 0,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final scene2Flashback = StoryScene(
          id: 2,
          chapterId: 1,
          title: '回忆：童年的誓言', // Contains flashback keyword '回忆'
          summary: '昔日的回忆',
          content: '',
          timelineTime: '2010年',
          locationName: '',
          povCharacterId: null,
          characterIds: '[]',
          sortOrder: 1,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = ConsistencyContext(
          worldId: 1,
          characters: [testChar],
          relations: [],
          events: [],
          lores: [],
          galleries: [],
          works: [testWork],
          chapters: [testChapter1],
          scenes: [scene1, scene2Flashback],
        );

        final issues = await rule.evaluate(context);
        final invertedIssues = issues
            .where((i) => i.id.startsWith('story_timeline_inverted_'))
            .toList();

        expect(invertedIssues, isEmpty);
      },
    );

    test(
      'Diagnoses posthumous character appearance conflict and respects exemption',
      () async {
        final deathEvent = TimelineEvent(
          id: 1,
          worldId: 1,
          characterId: 10,
          year: '2030年',
          title: '在圣战中牺牲',
          category: 'death',
          description: '',
          sortOrder: 0.0,
          importance: 1,
          createdAt: DateTime.now(),
        );

        final conflictScene = StoryScene(
          id: 3,
          chapterId: 1,
          title: '战后庆典',
          summary: '全员庆功',
          content: '',
          timelineTime: '2035年', // After death in 2030
          locationName: '',
          povCharacterId: 10, // Dead character as POV
          characterIds: '[]',
          sortOrder: 0,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final exemptScene = StoryScene(
          id: 4,
          chapterId: 1,
          title: '亡魂之低语',
          summary: '英灵显圣',
          content: '',
          timelineTime: '2035年',
          locationName: '',
          povCharacterId: null,
          characterIds: '[10]', // Appears as spirit
          sortOrder: 1,
          mood: '亡魂', // Posthumous exempt keyword
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Evaluate conflict
        final context1 = ConsistencyContext(
          worldId: 1,
          characters: [testChar],
          relations: [],
          events: [deathEvent],
          lores: [],
          galleries: [],
          works: [testWork],
          chapters: [testChapter1],
          scenes: [conflictScene],
        );

        final issues1 = await rule.evaluate(context1);
        final posthumousIssues1 = issues1
            .where((i) => i.id.startsWith('story_char_posthumous_'))
            .toList();
        expect(posthumousIssues1.length, equals(1));
        expect(posthumousIssues1.first.severity, equals(IssueSeverity.error));
        expect(posthumousIssues1.first.description, contains('逝世/阵亡'));

        // Evaluate exempt
        final context2 = ConsistencyContext(
          worldId: 1,
          characters: [testChar],
          relations: [],
          events: [deathEvent],
          lores: [],
          galleries: [],
          works: [testWork],
          chapters: [testChapter1],
          scenes: [exemptScene],
        );

        final issues2 = await rule.evaluate(context2);
        final posthumousIssues2 = issues2
            .where((i) => i.id.startsWith('story_char_posthumous_'))
            .toList();
        expect(posthumousIssues2, isEmpty);
      },
    );

    test('Diagnoses pre-birth character appearance conflict', () async {
      final birthEvent = TimelineEvent(
        id: 1,
        worldId: 1,
        characterId: 10,
        year: '2000年',
        title: '降生于雪夜',
        category: 'birth',
        description: '',
        sortOrder: 0.0,
        importance: 1,
        createdAt: DateTime.now(),
      );

      final earlyScene = StoryScene(
        id: 5,
        chapterId: 1,
        title: '百年前风云',
        summary: '年轻的剑圣拔剑',
        content: '',
        timelineTime: '1980年', // 20 years before birth
        locationName: '',
        povCharacterId: null,
        characterIds: '[10]',
        sortOrder: 0,
        mood: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final context = ConsistencyContext(
        worldId: 1,
        characters: [testChar],
        relations: [],
        events: [birthEvent],
        lores: [],
        galleries: [],
        works: [testWork],
        chapters: [testChapter1],
        scenes: [earlyScene],
      );

      final issues = await rule.evaluate(context);
      final prebirthIssues = issues
          .where((i) => i.id.startsWith('story_char_prebirth_'))
          .toList();
      expect(prebirthIssues.length, equals(1));
      expect(prebirthIssues.first.severity, equals(IssueSeverity.error));
      expect(prebirthIssues.first.description, contains('出生年份'));
    });

    test('Diagnoses timeline mismatch with chronicle event', () async {
      final chronicleEvent = TimelineEvent(
        id: 100,
        worldId: 1,
        characterId: null,
        year: '2040年',
        title: '苍穹裂隙战役',
        category: 'battle',
        description: '世界级大战',
        sortOrder: 0.0,
        importance: 2,
        createdAt: DateTime.now(),
      );

      final sceneWithEvent = StoryScene(
        id: 6,
        chapterId: 1,
        title: '决战',
        summary: '发生在[[苍穹裂隙战役]]前夜',
        content: '',
        timelineTime: '2050年', // Mismatch: 2050 vs 2040
        locationName: '',
        povCharacterId: null,
        characterIds: '[]',
        sortOrder: 0,
        mood: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final context = ConsistencyContext(
        worldId: 1,
        characters: [testChar],
        relations: [],
        events: [chronicleEvent],
        lores: [],
        galleries: [],
        works: [testWork],
        chapters: [testChapter1],
        scenes: [sceneWithEvent],
      );

      final issues = await rule.evaluate(context);
      final eventMismatchIssues = issues
          .where((i) => i.id.startsWith('story_event_mismatch_'))
          .toList();
      expect(eventMismatchIssues.length, equals(1));
      expect(eventMismatchIssues.first.severity, equals(IssueSeverity.warning));
      expect(eventMismatchIssues.first.description, contains('苍穹裂隙战役'));
      expect(eventMismatchIssues.first.evidence, contains('2040'));
      expect(eventMismatchIssues.first.evidence, contains('2050'));
    });

    test('Diagnoses blank scene in finalized chapter', () async {
      final blankScene = StoryScene(
        id: 7,
        chapterId: 1, // Chapter status is '已定稿'
        title: '待命名分镜',
        summary: '',
        content: '',
        timelineTime: '',
        locationName: '',
        povCharacterId: null,
        characterIds: '[]',
        sortOrder: 0,
        mood: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final draftChapter = StoryChapter(
        id: 2,
        workId: 1,
        title: '第二章 大纲草案',
        arcName: '',
        sortOrder: 1,
        wordCount: 0,
        status: '草稿',
        summary: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final draftBlankScene = StoryScene(
        id: 8,
        chapterId: 2, // Draft chapter, should NOT trigger issue
        title: '占位',
        summary: '',
        content: '',
        timelineTime: '',
        locationName: '',
        povCharacterId: null,
        characterIds: '[]',
        sortOrder: 0,
        mood: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final context = ConsistencyContext(
        worldId: 1,
        characters: [testChar],
        relations: [],
        events: [],
        lores: [],
        galleries: [],
        works: [testWork],
        chapters: [testChapter1, draftChapter],
        scenes: [blankScene, draftBlankScene],
      );

      final issues = await rule.evaluate(context);
      final blankIssues = issues
          .where((i) => i.id.startsWith('story_blank_scene_'))
          .toList();

      expect(blankIssues.length, equals(1));
      expect(blankIssues.first.targetId, equals(7));
      expect(blankIssues.first.severity, equals(IssueSeverity.info));
    });

    test(
      'Single character check mode focuses only on target character',
      () async {
        final deathEvent = TimelineEvent(
          id: 1,
          worldId: 1,
          characterId: 10,
          year: '2030年',
          title: '牺牲',
          category: 'death',
          description: '',
          sortOrder: 0.0,
          importance: 1,
          createdAt: DateTime.now(),
        );

        final invertedScene1 = StoryScene(
          id: 10,
          chapterId: 1,
          title: '序章',
          summary: '',
          content: '',
          timelineTime: '2050年',
          locationName: '',
          povCharacterId: 10,
          characterIds: '[]',
          sortOrder: 0,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final invertedScene2 = StoryScene(
          id: 11,
          chapterId: 1,
          title: '次章',
          summary: '',
          content: '',
          timelineTime: '2020年',
          locationName: '',
          povCharacterId: null,
          characterIds: '[]',
          sortOrder: 1,
          mood: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Single character mode for character 10
        final context = ConsistencyContext(
          worldId: 1,
          targetCharacterId: 10,
          characters: [testChar],
          relations: [],
          events: [deathEvent],
          lores: [],
          galleries: [],
          works: [testWork],
          chapters: [testChapter1],
          scenes: [invertedScene1, invertedScene2],
        );

        final issues = await rule.evaluate(context);

        // Sequence inversion check is skipped in single character mode
        expect(
          issues.any((i) => i.id.startsWith('story_timeline_inverted_')),
          isFalse,
        );

        // But posthumous conflict for character 10 is detected!
        expect(
          issues.any((i) => i.id.startsWith('story_char_posthumous_10_')),
          isTrue,
        );
      },
    );
  });

  group('ConsistencyCheckerEngine Integration with Story Rules', () {
    late AppDatabase db;
    late ConsistencyCheckerEngine engine;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      engine = ConsistencyCheckerEngine(db);

      // Seed world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              name: '测试异世界',
              description: drift.Value('用于集成测试'),
            ),
          );

      // Seed character
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              worldId: 1,
              name: '阿尔托利亚',
              gender: drift.Value('女'),
              description: drift.Value('骑士王'),
            ),
          );

      // Seed death event
      await db
          .into(db.timelineEvents)
          .insert(
            TimelineEventsCompanion.insert(
              worldId: 1,
              characterId: drift.Value(1),
              year: '公元537年',
              title: '剑栏之战阵亡',
              category: drift.Value('death'),
              description: drift.Value(''),
              sortOrder: drift.Value(1.0),
              importance: drift.Value(2),
            ),
          );

      // Seed work, chapter, scene
      final workId = await db.storyDao.createWork(
        StoryWorksCompanion.insert(
          worldId: 1,
          title: '亚瑟王传奇',
          type: drift.Value('novel'),
          status: drift.Value('已完结'),
        ),
      );

      final chapterId = await db.storyDao.createChapter(
        StoryChaptersCompanion.insert(
          workId: workId,
          title: '终幕 战后岁月',
          status: drift.Value('已定稿'),
          sortOrder: drift.Value(0),
        ),
      );

      // Scene occurring in year 600, with dead character Arthur
      await db.storyDao.createScene(
        StoryScenesCompanion.insert(
          chapterId: chapterId,
          title: '百年后的重聚',
          timelineTime: drift.Value('公元600年'),
          characterIds: drift.Value('[1]'),
          sortOrder: drift.Value(0),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Engine detects story timeline issues across database entities',
      () async {
        final report = await engine.checkWorld(1);

        expect(report.worldId, equals(1));
        final storyIssues = report.issues
            .where((i) => i.category == IssueCategory.story)
            .toList();

        expect(storyIssues.isNotEmpty, isTrue);
        expect(
          storyIssues.any((i) => i.ruleId == 'RULE_STORY_TIMELINE'),
          isTrue,
        );
        expect(
          storyIssues.any((i) => i.id.startsWith('story_char_posthumous_')),
          isTrue,
        );
      },
    );
  });
}
