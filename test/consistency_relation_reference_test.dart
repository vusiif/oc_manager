import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';

void main() {
  group('CONSIST-003 Relation & Reference Consistency Tests', () {
    Character makeChar({
      required int id,
      required String name,
      String description = '',
    }) {
      return Character(
        id: id,
        worldId: 1,
        name: name,
        gender: '未知',
        description: description,
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test(
      'detects dangling / orphan relations when referenced character does not exist',
      () async {
        final rule = RelationIntegrityRule();

        final characters = [makeChar(id: 1, name: 'Alice')];

        // Relation pointing to non-existent character ID 999
        final relations = [
          const Relation(
            id: 101,
            fromCharacterId: 1,
            toCharacterId: 999, // Missing target!
            relationType: '导师',
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
        final dangling = issues.firstWhere(
          (i) => i.id == 'relation_dangling_101',
        );

        expect(dangling.severity, equals(IssueSeverity.error));
        expect(dangling.title, contains('失效幽灵关系'));
        expect(dangling.evidence, contains('#999 (缺失)'));
        expect(dangling.suggestion, contains('清理该失效关系记录'));
      },
    );

    test(
      'detects duplicate redundant relations between same character pair',
      () async {
        final rule = RelationIntegrityRule();

        final characters = [
          makeChar(id: 1, name: 'Alice'),
          makeChar(id: 2, name: 'Bob'),
        ];

        // Two duplicate "朋友" relations in the same direction
        final relations = [
          const Relation(
            id: 10,
            fromCharacterId: 1,
            toCharacterId: 2,
            relationType: '朋友',
            isBidirectional: false,
          ),
          const Relation(
            id: 20,
            fromCharacterId: 1,
            toCharacterId: 2,
            relationType: '朋友',
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
        final duplicate = issues.firstWhere(
          (i) => i.id == 'relation_duplicate_10_20',
        );

        expect(duplicate.severity, equals(IssueSeverity.warning));
        expect(duplicate.title, contains('存在重复冗余关系'));
        expect(duplicate.evidence, contains('ID #10 与 ID #20'));
        expect(duplicate.suggestion, contains('删除多余的重复关系连线'));
      },
    );

    test('detects isolated residual relation group', () async {
      final rule = RelationIntegrityRule();

      final characters = [
        makeChar(id: 1, name: 'Father'),
        makeChar(id: 2, name: 'Child'),
      ];

      // Lone relation with a relationGroupId whose counterpart is missing
      final relations = [
        const Relation(
          id: 50,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '父子',
          isBidirectional: false,
          relationGroupId: 'family_batch_001',
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
      final orphanGroup = issues.firstWhere(
        (i) => i.id == 'relation_orphan_group_50',
      );

      expect(orphanGroup.severity, equals(IssueSeverity.info));
      expect(orphanGroup.title, contains('关系分组孤立残留'));
      expect(orphanGroup.evidence, contains('family_batch_001'));
    });

    test(
      'distinguishes between broken wiki link and cross-world reference',
      () async {
        final rule = WikiLinkIntegrityRule();

        final characters = [
          makeChar(
            id: 1,
            name: '艾琳',
            description: '曾经遇到过 [[外星来客]]，但也听说过 [[绝不存在的虚构者]]。',
          ),
        ];

        // Context aware of "外星来客" existing in another world
        final context = ConsistencyContext(
          worldId: 1,
          characters: characters,
          relations: [],
          events: [],
          lores: [],
          galleries: [],
          otherWorldEntityNames: {'外星来客'},
        );

        final issues = await rule.evaluate(context);
        expect(issues.length, equals(2));

        // 1. Cross-world reference warning
        final crossWorld = issues.firstWhere(
          (i) => i.id.contains('link_cross_world_char_1_外星来客'),
        );
        expect(crossWorld.severity, equals(IssueSeverity.warning));
        expect(crossWorld.title, contains('跨世界观双链越界引用'));
        expect(crossWorld.evidence, contains('存在于外部世界观中'));
        expect(crossWorld.suggestion, contains('世界观独立隔离原则'));

        // 2. Pure broken link error
        final broken = issues.firstWhere(
          (i) => i.id.contains('link_broken_char_1_绝不存在的虚构者'),
        );
        expect(broken.severity, equals(IssueSeverity.error));
        expect(broken.title, contains('双向链接失效（目标不存在）'));
        expect(broken.suggestion, contains('检查被链接实体名称拼写'));
      },
    );

    test(
      'checkWorld integrates cross-world reference detection from SQLite database',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        // Create World 1 & World 2
        await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(id: const drift.Value(1), name: '艾泽拉斯'),
            );
        await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(id: const drift.Value(2), name: '赛博纪元'),
            );

        // Character in World 2: 强尼·银手
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(201),
                worldId: 2,
                name: '强尼·银手',
              ),
            );

        // Character in World 1 referencing World 2's character via [[强尼·银手]]
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(101),
                worldId: 1,
                name: '吉安娜',
                description: const drift.Value('从裂隙中见到了 [[强尼·银手]] 的幻影'),
              ),
            );

        final engine = ConsistencyCheckerEngine(db);
        final report = await engine.checkWorld(1);

        final crossWorldIssue = report.issues.firstWhere(
          (i) => i.id.contains('link_cross_world'),
        );
        expect(crossWorldIssue.severity, equals(IssueSeverity.warning));
        expect(crossWorldIssue.targetName, equals('吉安娜'));
        expect(crossWorldIssue.description, contains('强尼·银手'));
      },
    );
  });
}
