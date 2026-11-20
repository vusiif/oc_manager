import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';

void main() {
  group('CONSIST-002 Timeline Date Parser Tests', () {
    test('parses exact positive and BCE years correctly', () {
      final res2024 = TimelineDateParser.parseYear('2024');
      expect(res2024.hasExactYear, isTrue);
      expect(res2024.year, equals(2024));
      expect(res2024.isBce, isFalse);

      final resBce = TimelineDateParser.parseYear('公元前 500 年');
      expect(resBce.hasExactYear, isTrue);
      expect(resBce.year, equals(-500));
      expect(resBce.isBce, isTrue);

      final resStar = TimelineDateParser.parseYear('星历 1042 年');
      expect(resStar.hasExactYear, isTrue);
      expect(resStar.year, equals(1042));

      final resNegative = TimelineDateParser.parseYear('-250');
      expect(resNegative.hasExactYear, isTrue);
      expect(resNegative.year, equals(-250));
    });

    test('safely identifies ambiguous eras without guessing', () {
      for (final raw in ['未知', '不详', '太古时代', '很久以前', '神话时代', '???', '']) {
        final parsed = TimelineDateParser.parseYear(raw);
        expect(
          parsed.hasExactYear,
          isFalse,
          reason: 'Era "$raw" should be ambiguous',
        );
      }
    });
  });

  group('CONSIST-002 Timeline and Age Consistency Rule Tests', () {
    final rule = TimelineLifespanRule();

    Character createChar({
      int id = 1,
      String name = '测试角色',
      String description = '普通人类冒险者',
      int status = 0,
    }) {
      return Character(
        id: id,
        worldId: 1,
        name: name,
        gender: '男',
        description: description,
        status: status,
        isFavorite: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    TimelineEvent createEvent({
      required int id,
      required int charId,
      required String year,
      required String title,
      String category = 'custom',
    }) {
      return TimelineEvent(
        id: id,
        worldId: 1,
        characterId: charId,
        year: year,
        sortOrder: 0.0,
        title: title,
        description: '',
        category: category,
        importance: 1,
        createdAt: DateTime.now(),
      );
    }

    test('detects inverted lifespan (birth after death) as error', () async {
      final char = createChar(id: 1, name: '时间错乱者');
      final events = [
        createEvent(
          id: 1,
          charId: 1,
          year: '1050',
          title: '出生',
          category: 'birth',
        ),
        createEvent(
          id: 2,
          charId: 1,
          year: '1000',
          title: '牺牲',
          category: 'death',
        ),
      ];

      final context = ConsistencyContext(
        worldId: 1,
        characters: [char],
        relations: [],
        events: events,
        lores: [],
        galleries: [],
      );

      final issues = await rule.evaluate(context);
      final inverted = issues.firstWhere(
        (i) => i.id.contains('lifespan_inverted'),
      );
      expect(inverted.severity, equals(IssueSeverity.error));
      expect(inverted.evidence, contains('1050'));
      expect(inverted.evidence, contains('1000'));
      expect(inverted.suggestion, contains('出生年份早于逝世年份'));
    });

    test('detects ordinary event occurring before birth year', () async {
      final char = createChar(id: 1, name: '英雄');
      final events = [
        createEvent(
          id: 1,
          charId: 1,
          year: '1020',
          title: '诞生',
          category: 'birth',
        ),
        createEvent(
          id: 2,
          charId: 1,
          year: '1010',
          title: '参加圣战',
          category: 'war',
        ),
      ];

      final context = ConsistencyContext(
        worldId: 1,
        characters: [char],
        relations: [],
        events: events,
        lores: [],
        galleries: [],
      );

      final issues = await rule.evaluate(context);
      final beforeBirth = issues.firstWhere(
        (i) => i.id.contains('before_birth'),
      );
      expect(beforeBirth.severity, equals(IssueSeverity.warning));
      expect(beforeBirth.description, contains('发生在角色 “英雄” 出生'));
      expect(beforeBirth.evidence, contains('1010'));
      expect(beforeBirth.evidence, contains('1020'));
    });

    test('allows prequel/origin events before birth without warning', () async {
      final char = createChar(id: 1, name: '传承者');
      final events = [
        createEvent(
          id: 1,
          charId: 1,
          year: '1020',
          title: '诞生',
          category: 'birth',
        ),
        createEvent(
          id: 2,
          charId: 1,
          year: '900',
          title: '先祖开天前尘',
          category: 'origin',
        ),
      ];

      final context = ConsistencyContext(
        worldId: 1,
        characters: [char],
        relations: [],
        events: events,
        lores: [],
        galleries: [],
      );

      final issues = await rule.evaluate(context);
      expect(issues.any((i) => i.id.contains('before_birth')), isFalse);
    });

    test('allows memorial/legacy events after death without warning', () async {
      final char = createChar(id: 1, name: '伟人', status: 1);
      final events = [
        createEvent(
          id: 1,
          charId: 1,
          year: '1000',
          title: '诞生',
          category: 'birth',
        ),
        createEvent(
          id: 2,
          charId: 1,
          year: '1080',
          title: '逝世',
          category: 'death',
        ),
        createEvent(
          id: 3,
          charId: 1,
          year: '1100',
          title: '百年追思纪念与追封',
          category: 'memorial',
        ),
      ];

      final context = ConsistencyContext(
        worldId: 1,
        characters: [char],
        relations: [],
        events: events,
        lores: [],
        galleries: [],
      );

      final issues = await rule.evaluate(context);
      expect(issues.any((i) => i.id.contains('after_death')), isFalse);
    });

    test(
      'detects living status conflict when death event exists in chronicle',
      () async {
        final char = createChar(
          id: 1,
          name: '存活的逝者',
          status: 0,
        ); // status 0 = living
        final events = [
          createEvent(
            id: 1,
            charId: 1,
            year: '1000',
            title: '诞生',
            category: 'birth',
          ),
          createEvent(
            id: 2,
            charId: 1,
            year: '1070',
            title: '终战阵亡',
            category: 'death',
          ),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: [char],
          relations: [],
          events: events,
          lores: [],
          galleries: [],
        );

        final issues = await rule.evaluate(context);
        final statusConflict = issues.firstWhere(
          (i) => i.id.contains('alive_with_death_event'),
        );
        expect(statusConflict.severity, equals(IssueSeverity.warning));
        expect(statusConflict.title, contains('存活状态与死亡事件矛盾'));
        expect(statusConflict.suggestion, contains('建议将人设状态修改为“已故”'));
      },
    );

    test(
      'gives info hint on extreme lifespan for mortals while ignoring immortal keywords',
      () async {
        final mortal = createChar(id: 1, name: '凡人格兰特', description: '普通人类农夫');
        final elf = createChar(
          id: 2,
          name: '高等精灵法师',
          description: '长生不朽的纯血精灵魔导士',
        );

        final mortalEvents = [
          createEvent(
            id: 1,
            charId: 1,
            year: '1000',
            title: '出生',
            category: 'birth',
          ),
          createEvent(
            id: 2,
            charId: 1,
            year: '1350',
            title: '老死',
            category: 'death',
          ),
        ];

        final elfEvents = [
          createEvent(
            id: 3,
            charId: 2,
            year: '1000',
            title: '降生',
            category: 'birth',
          ),
          createEvent(
            id: 4,
            charId: 2,
            year: '1800',
            title: '远渡',
            category: 'custom',
          ),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: [mortal, elf],
          relations: [],
          events: [...mortalEvents, ...elfEvents],
          lores: [],
          galleries: [],
        );

        final issues = await rule.evaluate(context);

        // Mortal gets friendly info hint (350 years lifespan)
        final mortalHint = issues.firstWhere(
          (i) => i.id == 'timeline_extended_lifespan_1',
        );
        expect(mortalHint.severity, equals(IssueSeverity.info));
        expect(mortalHint.evidence, contains('350 年'));

        // Elf has immortal keywords, so no hint
        expect(
          issues.any((i) => i.id == 'timeline_extended_lifespan_2'),
          isFalse,
        );
      },
    );

    test(
      'safely handles missing data and ambiguous era without throwing errors',
      () async {
        final char = createChar(id: 1, name: '太古神秘人');
        final events = [
          createEvent(id: 1, charId: 1, year: '太古时代', title: '从虚空中降临'),
          createEvent(id: 2, charId: 1, year: '未知', title: '隐入尘烟'),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: [char],
          relations: [],
          events: events,
          lores: [],
          galleries: [],
        );

        final issues = await rule.evaluate(context);
        expect(issues, isEmpty); // No false positives on ambiguous data
      },
    );
  });
}
