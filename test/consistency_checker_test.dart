import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';
import 'package:oc_manager/features/world/consistency_checker_dialog.dart';

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
        .insert(
          WorldsCompanion.insert(
            id: const drift.Value(1),
            name: '艾泽拉斯',
            description: const drift.Value('奇幻史诗世界'),
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Consistency Checker Engine Tests (P2-02)', () {
    test(
      'Detects lifespan conflicts and events occurring after death',
      () async {
        final engine = ConsistencyCheckerEngine(db);

        // Character: 阿尔萨斯
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(101),
                worldId: 1,
                name: '阿尔萨斯',
                description: const drift.Value('洛丹伦王子'),
              ),
            );

        // Event 1: Birth in Year 1050
        await db
            .into(db.timelineEvents)
            .insert(
              TimelineEventsCompanion.insert(
                worldId: 1,
                characterId: const drift.Value(101),
                year: '1050',
                title: '阿尔萨斯诞生',
                category: const drift.Value('birth'),
              ),
            );

        // Event 2: Death in Year 1020 (Contradiction: died before born)
        await db
            .into(db.timelineEvents)
            .insert(
              TimelineEventsCompanion.insert(
                worldId: 1,
                characterId: const drift.Value(101),
                year: '1020',
                title: '冰冠堡垒陨落',
                category: const drift.Value('death'),
              ),
            );

        // Event 3: Ordinary event in Year 1080 (Occurs after death year 1020)
        await db
            .into(db.timelineEvents)
            .insert(
              TimelineEventsCompanion.insert(
                worldId: 1,
                characterId: const drift.Value(101),
                year: '1080',
                title: '远征诺森德',
                category: const drift.Value('war'),
              ),
            );

        final report = await engine.checkWorld(1);

        // 1. Inverted lifespan error
        final lifespanIssue = report.issues.firstWhere(
          (i) => i.id.contains('lifespan_inverted'),
        );
        expect(lifespanIssue.severity, equals(IssueSeverity.error));
        expect(lifespanIssue.category, equals(IssueCategory.timeline));
        expect(lifespanIssue.description, contains('1050'));
        expect(lifespanIssue.description, contains('1020'));

        // 2. Event after death warning
        final afterDeathIssue = report.issues.firstWhere(
          (i) => i.id.contains('event_after_death'),
        );
        expect(afterDeathIssue.severity, equals(IssueSeverity.warning));
        expect(afterDeathIssue.description, contains('远征诺森德'));
      },
    );

    test('Detects contradictory relations and self-loops', () async {
      final engine = ConsistencyCheckerEngine(db);

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(201),
              worldId: 1,
              name: '伊利丹',
              description: const drift.Value('背叛者'),
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(202),
              worldId: 1,
              name: '玛维·影歌',
              description: const drift.Value('守望者'),
            ),
          );

      // 1. Self-loop relation
      await db
          .into(db.relations)
          .insert(
            RelationsCompanion.insert(
              id: const drift.Value(1),
              fromCharacterId: 201,
              toCharacterId: 201,
              relationType: '自恋',
            ),
          );

      // 2. Contradictory relation: Both '恋人' and '死敌'
      await db
          .into(db.relations)
          .insert(
            RelationsCompanion.insert(
              id: const drift.Value(2),
              fromCharacterId: 201,
              toCharacterId: 202,
              relationType: '恋人',
            ),
          );
      await db
          .into(db.relations)
          .insert(
            RelationsCompanion.insert(
              id: const drift.Value(3),
              fromCharacterId: 201,
              toCharacterId: 202,
              relationType: '死敌',
            ),
          );

      final report = await engine.checkWorld(1);

      // Verify self-loop error
      expect(
        report.issues.any(
          (i) =>
              i.category == IssueCategory.relation &&
              i.severity == IssueSeverity.error &&
              i.title.contains('自环'),
        ),
        isTrue,
      );

      // Verify contradictory relation warning
      expect(
        report.issues.any(
          (i) =>
              i.category == IssueCategory.relation &&
              i.severity == IssueSeverity.warning &&
              i.title.contains('矛盾'),
        ),
        isTrue,
      );
    });

    test('Detects broken wiki links and completeness issues', () async {
      final engine = ConsistencyCheckerEngine(db);

      // Character with broken wiki link [[不存在的安东尼达斯]]
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(301),
              worldId: 1,
              name: '吉安娜',
              description: const drift.Value('肯瑞托大法师，师从 [[不存在的安东尼达斯]]。'),
            ),
          );

      // Isolated character with no description and no relations
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(302),
              worldId: 1,
              name: '路人甲',
              description: const drift.Value(''),
            ),
          );

      final report = await engine.checkWorld(1);

      // Broken link error
      final brokenLinkIssue = report.issues.firstWhere(
        (i) => i.category == IssueCategory.link,
      );
      expect(brokenLinkIssue.severity, equals(IssueSeverity.error));
      expect(brokenLinkIssue.description, contains('不存在的安东尼达斯'));

      // Isolated character completeness info
      final completenessIssue = report.issues.firstWhere(
        (i) => i.category == IssueCategory.completeness,
      );
      expect(completenessIssue.severity, equals(IssueSeverity.info));
      expect(completenessIssue.targetName, equals('路人甲'));

      // Health score calculation
      expect(report.healthScore, lessThan(100));
    });

    testWidgets(
      'ConsistencyCheckerDialog renders health score card and filter chips',
      (tester) async {
        // Seed a clean world with valid character
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(401),
                worldId: 1,
                name: '乌瑟尔',
                description: const drift.Value('白银之手骑士团大领主'),
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: ConsistencyCheckerDialog(worldId: 1, worldName: '艾泽拉斯'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify title & world name
        expect(find.text('世界设定一致性检查器'), findsOneWidget);
        expect(find.textContaining('艾泽拉斯'), findsWidgets);

        // Verify health overview score card exists
        expect(find.textContaining('健康指数'), findsOneWidget);

        // Verify filter chips exist
        expect(find.textContaining('全部'), findsOneWidget);
        expect(find.textContaining('严重矛盾'), findsOneWidget);
        expect(find.textContaining('逻辑警告'), findsOneWidget);
        expect(find.textContaining('设定建议'), findsOneWidget);
      },
    );
  });
}
