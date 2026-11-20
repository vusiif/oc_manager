import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';

void main() {
  group('CONSIST-001 Consistency Rule Engine Foundation Tests', () {
    test('ConsistencyRuleRegistry manages rules and filtering correctly', () {
      final registry = ConsistencyCheckerEngine.createDefaultRegistry();

      expect(registry.allRules.length, equals(6));
      expect(
        registry.allRules.map((r) => r.ruleId).toSet(),
        containsAll([
          'RULE_TIMELINE_LIFESPAN',
          'RULE_RELATION_INTEGRITY',
          'RULE_WIKI_LINK_INTEGRITY',
          'RULE_MEDIA_FILE_INTEGRITY',
          'RULE_COMPLETENESS',
          'RULE_STORY_TIMELINE',
        ]),
      );

      // Filtering with active ruleIds
      final active = registry.getActiveRules({'RULE_TIMELINE_LIFESPAN'});
      expect(active.length, equals(1));
      expect(active.first.ruleId, equals('RULE_TIMELINE_LIFESPAN'));

      // Unregister
      registry.unregister('RULE_COMPLETENESS');
      expect(registry.allRules.length, equals(5));
      expect(registry.getRule('RULE_COMPLETENESS'), isNull);
    });

    test(
      'ConsistencyRule evaluates in-memory context directly with suggestions and evidence',
      () async {
        final rule = TimelineLifespanRule();

        final character = Character(
          id: 1,
          worldId: 1,
          name: '克罗米',
          gender: '女',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final events = [
          TimelineEvent(
            id: 1,
            worldId: 1,
            characterId: 1,
            year: '2050',
            title: '诞生',
            category: 'birth',
            description: '',
            sortOrder: 0.0,
            importance: 1,
            createdAt: DateTime.now(),
          ),
          TimelineEvent(
            id: 2,
            worldId: 1,
            characterId: 1,
            year: '2010',
            title: '逝世',
            category: 'death',
            description: '',
            sortOrder: 1.0,
            importance: 1,
            createdAt: DateTime.now(),
          ),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: [character],
          relations: [],
          events: events,
          lores: [],
          galleries: [],
        );

        final issues = await rule.evaluate(context);
        final issue = issues.firstWhere(
          (i) => i.id.contains('lifespan_inverted'),
        );
        expect(issue.ruleId, equals('RULE_TIMELINE_LIFESPAN'));
        expect(issue.severity, equals(IssueSeverity.error));
        expect(issue.title, equals('生卒年时序矛盾'));
        expect(issue.suggestion, isNotNull);
        expect(issue.suggestion, contains('出生年份早于逝世年份'));
        expect(issue.evidence, contains('2050'));
        expect(issue.evidence, contains('2010'));
      },
    );

    test(
      'RelationIntegrityRule detects self loops and emotional contradictions',
      () async {
        final rule = RelationIntegrityRule();

        final characters = [
          Character(
            id: 1,
            worldId: 1,
            name: 'Hero',
            gender: '男',
            description: '',
            status: 0,
            isFavorite: false,
            isPinned: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Character(
            id: 2,
            worldId: 1,
            name: 'Rival',
            gender: '男',
            description: '',
            status: 0,
            isFavorite: false,
            isPinned: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final relations = [
          const Relation(
            id: 10,
            fromCharacterId: 1,
            toCharacterId: 1, // Self-loop
            relationType: '自恋',
            isBidirectional: false,
          ),
          const Relation(
            id: 11,
            fromCharacterId: 1,
            toCharacterId: 2,
            relationType: '恋人',
            isBidirectional: true,
          ),
          const Relation(
            id: 12,
            fromCharacterId: 2,
            toCharacterId: 1,
            relationType: '宿敌',
            isBidirectional: false,
          ),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: characters,
          relations: relations,
          events: [],
          lores: [],
          galleries: [],
        );

        final issues = await rule.evaluate(context);
        expect(issues.length, equals(2));

        final selfLoop = issues.firstWhere((i) => i.id.contains('self_loop'));
        expect(selfLoop.severity, equals(IssueSeverity.error));
        expect(selfLoop.suggestion, contains('删除该自环关系'));

        final conflict = issues.firstWhere((i) => i.id.contains('conflict'));
        expect(conflict.severity, equals(IssueSeverity.warning));
        expect(conflict.evidence, contains('恋人'));
        expect(conflict.evidence, contains('宿敌'));
      },
    );

    test(
      'checkCharacter performs scoped single-character diagnostics',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(id: const drift.Value(1), name: '测试世界'),
            );

        // Character 1: Has self-loop and broken wiki link
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(101),
                worldId: 1,
                name: 'Alice',
                description: const drift.Value('遇到了 [[UnknownEntity]]'),
              ),
            );

        // Character 2: Isolated empty character
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(102),
                worldId: 1,
                name: 'Bob',
                description: const drift.Value(''),
              ),
            );

        await db
            .into(db.relations)
            .insert(
              RelationsCompanion.insert(
                id: const drift.Value(1),
                fromCharacterId: 101,
                toCharacterId: 101, // Self loop on 101
                relationType: '自己',
              ),
            );

        final engine = ConsistencyCheckerEngine(db);

        // Targeted check on Character 101
        final aliceIssues = await engine.checkCharacter(1, 101);
        expect(aliceIssues.length, equals(2));
        expect(
          aliceIssues.every(
            (i) => i.targetId == 101 || i.targetType == 'relation',
          ),
          isTrue,
        );
        expect(
          aliceIssues.any((i) => i.ruleId == 'RULE_WIKI_LINK_INTEGRITY'),
          isTrue,
        );
        expect(
          aliceIssues.any((i) => i.ruleId == 'RULE_RELATION_INTEGRITY'),
          isTrue,
        );

        // Targeted check on Character 102
        final bobIssues = await engine.checkCharacter(1, 102);
        expect(bobIssues.length, equals(1));
        expect(bobIssues.first.ruleId, equals('RULE_COMPLETENESS'));
        expect(bobIssues.first.targetId, equals(102));
      },
    );

    test(
      'Engine checkWorld calculates report and healthScore correctly',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(id: const drift.Value(1), name: '艾泽拉斯'),
            );

        final engine = ConsistencyCheckerEngine(db);
        final report = await engine.checkWorld(1);

        expect(report.worldId, equals(1));
        expect(report.issues, isEmpty);
        expect(report.healthScore, equals(100)); // Perfect score when no issues
      },
    );
  });
}
