import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/consistency_provider.dart';
import 'package:oc_manager/core/consistency/consistency_checker_engine.dart';
import 'package:oc_manager/features/world/consistency_checker_dialog.dart';

void main() {
  group('CONSIST-004 & CONSIST-005 Completeness & Workbench Tests', () {
    test(
      'CompletenessRule.isIntentionalBlank accurately detects intentional blanks without false alarms',
      () {
        // 1. 显式留白名称与标记
        expect(
          CompletenessRule.isIntentionalBlank(
            name: '无名小卒[留白]',
            description: '',
          ),
          isTrue,
        );
        expect(
          CompletenessRule.isIntentionalBlank(
            name: '神秘刺客【草稿】',
            description: '',
          ),
          isTrue,
        );
        expect(
          CompletenessRule.isIntentionalBlank(
            name: 'NPC守卫(待定)',
            description: '',
          ),
          isTrue,
        );
        expect(
          CompletenessRule.isIntentionalBlank(name: 'TBD', description: ''),
          isTrue,
        );

        // 2. 标签包含留白
        expect(
          CompletenessRule.isIntentionalBlank(
            name: '普通角色',
            description: '',
            tags: '主角,草稿,剑士',
          ),
          isTrue,
        );

        // 3. 描述本身为占位词
        expect(
          CompletenessRule.isIntentionalBlank(name: '普通角色', description: '待补充'),
          isTrue,
        );
        expect(
          CompletenessRule.isIntentionalBlank(
            name: '普通角色',
            description: '【留白】',
          ),
          isTrue,
        );

        // 4. 正常角色名绝不误判
        expect(
          CompletenessRule.isIntentionalBlank(
            name: '阿尔萨斯',
            description: '洛丹伦王子',
          ),
          isFalse,
        );
        expect(
          CompletenessRule.isIntentionalBlank(name: '路人甲', description: ''),
          isFalse,
        );
      },
    );

    test(
      'CompletenessRule diagnoses isolated empty characters, connected empty desc, and missing avatars',
      () async {
        final rule = CompletenessRule();

        // 角色 1: 空白孤岛角色 (无小传, 无关系)
        final char1 = Character(
          id: 1,
          worldId: 1,
          name: '孤岛甲',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 角色 2: 有关系但无小传，且注明了待约稿立绘
        final char2 = Character(
          id: 2,
          worldId: 1,
          name: '同伴乙',
          gender: '女',
          description: '待约稿立绘',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 角色 3: 有小传、有头像、有画廊立绘
        final char3 = Character(
          id: 3,
          worldId: 1,
          name: '完备丙',
          gender: '男',
          avatarPath: '/avatars/bing.jpg',
          description: '一名经验老道的魔法师。',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 角色 4: 有意留白角色 [留白]
        final char4 = Character(
          id: 4,
          worldId: 1,
          name: '路人丁[留白]',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final relations = [
          Relation(
            id: 1,
            fromCharacterId: 2,
            toCharacterId: 3,
            relationType: '战友',
            isBidirectional: false,
          ),
        ];

        final galleries = [
          CharacterGallery(
            id: 1,
            characterId: 3,
            imagePath: '/gallery/bing_pose.jpg',
            caption: '战斗立绘',
            isPrimary: true,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        ];

        final context = ConsistencyContext(
          worldId: 1,
          characters: [char1, char2, char3, char4],
          relations: relations,
          events: [],
          lores: [],
          galleries: galleries,
        );

        final issues = await rule.evaluate(context);

        // char1: 空白孤岛角色
        expect(
          issues.any(
            (i) =>
                i.id == 'completeness_isolated_empty_1' && i.title == '空白孤岛角色',
          ),
          isTrue,
        );

        // char2: 有立绘需求但尚未上传头像或画廊
        expect(
          issues.any((i) => i.id == 'completeness_character_avatar_missing_2'),
          isTrue,
        );

        // char3: 完备，不产生任何缺失报警
        expect(issues.any((i) => i.targetId == 3), isFalse);

        // char4: 有意留白，免检放行
        expect(issues.any((i) => i.targetId == 4), isFalse);
      },
    );

    test(
      'CompletenessRule diagnoses uncategorized lore and completely empty lore entities',
      () async {
        final rule = CompletenessRule();

        final lore1 = LoreEntity(
          id: 10,
          worldId: 1,
          entityType: 'default', // 默认分类未明确
          name: '未知神殿',
          summary: '',
          content: '',
          tags: '',
          customFields: '{}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final lore2 = LoreEntity(
          id: 11,
          worldId: 1,
          entityType: '地点',
          name: '暴风要塞',
          summary: '暴风城的核心指挥中心。',
          content: '历史悠久的石砌要塞。',
          tags: '',
          customFields: '{}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final lore3 = LoreEntity(
          id: 12,
          worldId: 1,
          entityType: '未分类',
          name: '太古遗物(待补充)', // 有意留白
          summary: '',
          content: '',
          tags: '',
          customFields: '{}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = ConsistencyContext(
          worldId: 1,
          characters: [],
          relations: [],
          events: [],
          lores: [lore1, lore2, lore3],
          galleries: [],
        );

        final issues = await rule.evaluate(context);

        // lore1 触发分类待明确与内容为空
        expect(
          issues.any((i) => i.id == 'completeness_lore_uncategorized_10'),
          isTrue,
        );
        expect(issues.any((i) => i.id == 'completeness_empty_lore_10'), isTrue);

        // lore2 正常通过
        expect(issues.any((i) => i.targetId == 11), isFalse);

        // lore3 有意留白免检放行
        expect(issues.any((i) => i.targetId == 12), isFalse);
      },
    );

    test(
      'Single character check mode focuses only on target character completeness',
      () async {
        final rule = CompletenessRule();

        final char1 = Character(
          id: 100,
          worldId: 1,
          name: '定向检查角色',
          gender: '男',
          description: '',
          status: 0,
          isFavorite: false,
          isPinned: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final lore = LoreEntity(
          id: 200,
          worldId: 1,
          entityType: 'default',
          name: '其他未分类词条',
          summary: '',
          content: '',
          tags: '',
          customFields: '{}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final context = ConsistencyContext(
          worldId: 1,
          targetCharacterId: 100,
          characters: [char1],
          relations: [],
          events: [],
          lores: [lore],
          galleries: [],
        );

        final issues = await rule.evaluate(context);

        // 仅包含目标角色 100 的问题，绝对不混入百科词条问题
        expect(issues.every((i) => i.targetId == 100), isTrue);
        expect(
          issues.any((i) => i.id == 'completeness_isolated_empty_100'),
          isTrue,
        );
      },
    );

    test(
      'IssueStatusNotifier and WorldEnabledRulesNotifier manage workbench lifecycle',
      () {
        final statusNotifier = IssueStatusNotifier();

        // 默认空
        expect(statusNotifier.state.isEmpty, isTrue);

        // 忽略
        statusNotifier.ignore('issue_1');
        expect(
          statusNotifier.state['issue_1'],
          equals(IssueHandlingStatus.ignored),
        );

        // 解决
        statusNotifier.resolve('issue_2');
        expect(
          statusNotifier.state['issue_2'],
          equals(IssueHandlingStatus.resolved),
        );

        // 恢复待办
        statusNotifier.reset('issue_1');
        expect(statusNotifier.state['issue_1'], isNull);

        // 清空
        statusNotifier.clearAll();
        expect(statusNotifier.state.isEmpty, isTrue);

        // 规则启停
        final rulesNotifier = WorldEnabledRulesNotifier();
        expect(rulesNotifier.state.contains('RULE_COMPLETENESS'), isTrue);

        rulesNotifier.toggleRule('RULE_COMPLETENESS');
        expect(rulesNotifier.state.contains('RULE_COMPLETENESS'), isFalse);

        rulesNotifier.resetDefaults();
        expect(rulesNotifier.state.contains('RULE_COMPLETENESS'), isTrue);
      },
    );

    testWidgets(
      'ConsistencyCheckerDialog renders workbench segmented button, rule config and empty state',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());

        // Seed a clean world
        await db
            .into(db.worlds)
            .insert(
              WorldsCompanion.insert(
                id: const drift.Value(1),
                name: '泰拉世界',
                description: const drift.Value('自洽大陆'),
              ),
            );

        // Seed one character with description
        await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                id: const drift.Value(1),
                worldId: 1,
                name: '阿米娅',
                description: const drift.Value('罗德岛公开领袖。'),
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: ConsistencyCheckerDialog(worldId: 1, worldName: '泰拉世界'),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify title & workbench controls
        expect(find.text('世界设定一致性检查器'), findsOneWidget);
        expect(find.textContaining('泰拉世界'), findsWidgets);
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget); // 规则配置按钮
        expect(
          find.byType(SegmentedButton<bool>),
          findsOneWidget,
        ); // 待办 vs 已处理切换
        expect(find.textContaining('自洽优秀'), findsOneWidget);

        // Tap rule config button
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('诊断规则启停配置'), findsOneWidget);
        expect(find.text('设定完整度与孤立节点检查'), findsOneWidget);
        expect(find.text('完成'), findsOneWidget);

        await tester.tap(find.text('完成'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await db.close();
      },
    );
  });
}
