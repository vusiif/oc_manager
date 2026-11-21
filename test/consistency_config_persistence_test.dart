import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/world/consistency_checker_dialog.dart';
import 'package:oc_manager/providers/consistency_provider.dart';
import 'package:oc_manager/providers/database_provider.dart';

void main() {
  group('CONSIST-006 Consistency Configuration & Persistence Tests', () {
    late AppDatabase db;
    late ConsistencyConfigService configService;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      configService = ConsistencyConfigService(db);

      // Seed a test world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '艾泽拉斯',
              description: const drift.Value('奇幻大陆'),
            ),
          );

      // Seed character with completeness issues (missing description & avatar)
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: '萨尔',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'ConsistencyConfigService saves and loads rule configs correctly',
      () async {
        // 1. Initial load returns empty (defaults apply)
        final initial = await configService.loadRuleConfigs(1);
        expect(initial.isEmpty, isTrue);

        // 2. Save custom configs
        final customConfigs = {
          'RULE_COMPLETENESS': const RuleConfig(
            enabled: true,
            customSeverity: IssueSeverity.error,
          ),
          'RULE_TIMELINE_LIFESPAN': const RuleConfig(enabled: false),
        };
        await configService.saveRuleConfigs(1, customConfigs);

        // 3. Load and verify
        final loaded = await configService.loadRuleConfigs(1);
        expect(loaded.length, equals(2));
        expect(loaded['RULE_COMPLETENESS']?.enabled, isTrue);
        expect(
          loaded['RULE_COMPLETENESS']?.customSeverity,
          equals(IssueSeverity.error),
        );
        expect(loaded['RULE_TIMELINE_LIFESPAN']?.enabled, isFalse);
        expect(loaded['RULE_TIMELINE_LIFESPAN']?.customSeverity, isNull);
      },
    );

    test(
      'ConsistencyConfigService saves and loads issue statuses correctly',
      () async {
        final statuses = {
          'issue_rule_1': IssueHandlingStatus.ignored,
          'issue_rule_2': IssueHandlingStatus.resolved,
          'issue_rule_3':
              IssueHandlingStatus.active, // active shouldn't be stored
        };
        await configService.saveIssueStatuses(1, statuses);

        final loaded = await configService.loadIssueStatuses(1);
        expect(loaded.length, equals(2));
        expect(loaded['issue_rule_1'], equals(IssueHandlingStatus.ignored));
        expect(loaded['issue_rule_2'], equals(IssueHandlingStatus.resolved));
        expect(loaded.containsKey('issue_rule_3'), isFalse);

        // Reset
        await configService.resetWorldConfigs(1);
        final afterReset = await configService.loadIssueStatuses(1);
        expect(afterReset.isEmpty, isTrue);
      },
    );

    test(
      'ConsistencyCheckerEngine respects disabled rules and custom severity overrides',
      () async {
        final engine = ConsistencyCheckerEngine(db);

        // 1. Check with default configs
        final reportDefault = await engine.checkWorld(1);
        final completenessIssues = reportDefault.issues
            .where((i) => i.ruleId == 'RULE_COMPLETENESS')
            .toList();
        expect(completenessIssues.isNotEmpty, isTrue);
        // Default severity of CompletenessRule is warning/info
        expect(
          completenessIssues.every((i) => i.severity != IssueSeverity.error),
          isTrue,
        );

        // 2. Elevate RULE_COMPLETENESS to IssueSeverity.error
        final elevatedReport = await engine.checkWorld(
          1,
          ruleConfigs: {
            'RULE_COMPLETENESS': const RuleConfig(
              enabled: true,
              customSeverity: IssueSeverity.error,
            ),
          },
        );
        final elevatedIssues = elevatedReport.issues
            .where((i) => i.ruleId == 'RULE_COMPLETENESS')
            .toList();
        expect(elevatedIssues.isNotEmpty, isTrue);
        expect(
          elevatedIssues.every((i) => i.severity == IssueSeverity.error),
          isTrue,
        );
        expect(elevatedReport.errorCount, greaterThan(0));

        // 3. Disable RULE_COMPLETENESS completely
        final disabledReport = await engine.checkWorld(
          1,
          ruleConfigs: {'RULE_COMPLETENESS': const RuleConfig(enabled: false)},
        );
        expect(
          disabledReport.issues.any((i) => i.ruleId == 'RULE_COMPLETENESS'),
          isFalse,
        );
      },
    );

    test(
      'WorldRuleConfigsNotifier and IssueStatusNotifier persist across instances',
      () async {
        // Instance 1: Mutate and persist
        final notifier1 = WorldRuleConfigsNotifier(
          service: configService,
          worldId: 1,
        );
        // Disable media rule and set completeness to warning
        notifier1.toggleRule('RULE_MEDIA_FILE_INTEGRITY');
        notifier1.setRuleSeverity('RULE_COMPLETENESS', IssueSeverity.error);

        // Allow async persist to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // Instance 2: Load fresh from disk
        final notifier2 = WorldRuleConfigsNotifier(
          service: configService,
          worldId: 1,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notifier2.state['RULE_MEDIA_FILE_INTEGRITY']?.enabled, isFalse);
        expect(
          notifier2.state['RULE_COMPLETENESS']?.customSeverity,
          equals(IssueSeverity.error),
        );

        // Test IssueStatusNotifier persistence
        final issueNotifier1 = IssueStatusNotifier(
          service: configService,
          worldId: 1,
        );
        issueNotifier1.ignore('mock_issue_1');
        issueNotifier1.resolve('mock_issue_2');
        await Future.delayed(const Duration(milliseconds: 50));

        final issueNotifier2 = IssueStatusNotifier(
          service: configService,
          worldId: 1,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        expect(
          issueNotifier2.state['mock_issue_1'],
          equals(IssueHandlingStatus.ignored),
        );
        expect(
          issueNotifier2.state['mock_issue_2'],
          equals(IssueHandlingStatus.resolved),
        );
      },
    );

    testWidgets(
      'ConsistencyCheckerDialog config dialog allows adjusting severity and toggling rules',
      (tester) async {
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

        // Open Rule Config Dialog
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        expect(find.text('诊断规则启停配置'), findsOneWidget);
        expect(find.text('重置全部启用与默认级别'), findsOneWidget);

        // Check completeness rule item is visible
        expect(find.text('设定完整度与孤立节点检查'), findsOneWidget);

        // Close dialog cleanly
        await tester.tap(find.text('完成'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
