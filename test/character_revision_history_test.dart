import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/revision_provider.dart';
import 'package:oc_manager/core/history/models/character_snapshot.dart';
import 'package:oc_manager/core/history/diff/character_revision_diff.dart';
import 'package:oc_manager/core/history/diff/text_diff_util.dart';
import 'package:oc_manager/features/world/revision_history_dialog.dart';

void main() {
  group('HISTORY-001 ~ HISTORY-003 Character Revision History Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      // Seed world
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '费伦大陆',
              description: const drift.Value('奇幻DND世界'),
            ),
          );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'HISTORY-001: Structured CharacterSnapshot serialization and milestone pruning protection',
      () async {
        final actions = container.read(revisionActionsProvider);

        // 1. 创建角色与自定义字段、标签
        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(
            worldId: 1,
            name: '崔斯特·杜垩登',
            gender: const drift.Value('男'),
            description: const drift.Value('来自幽暗地域的叛出游侠'),
          ),
        );
        await db.characterDao.createCharacterField(
          CharacterFieldsCompanion.insert(
            characterId: charId,
            fieldName: '武器',
            fieldType: 'text',
            value: const drift.Value('闪光与冰死双弯刀'),
          ),
        );
        final tagId = await db.tagDao.createTag(
          TagsCompanion.insert(name: '黑暗精灵', color: '#10B981'),
        );
        await db.tagDao.addTagToCharacter(charId, tagId);

        final character = await db.characterDao.getCharacterById(charId);

        // 2. 保存快照 1: 普通初稿
        final id1 = await actions.recordCharacterSnapshot(
          character: character,
          title: '初始幽暗地域草案',
          source: 'manual',
          isMilestone: false,
        );
        expect(id1, isNotNull);

        // 3. 保存快照 2: 标记为重要里程碑 (⭐)
        final id2 = await actions.recordCharacterSnapshot(
          character: character.copyWith(description: '来到地表定居冰风谷，结识沃夫加与布鲁诺'),
          title: '冰风谷定居里程碑',
          source: 'manual',
          isMilestone: true,
          note: '第一本三部曲完结关键节点',
        );
        expect(id2, isNotNull);

        // 4. 保存快照 3: 普通修改，设置 maxRetain = 2 触发修剪
        await actions.recordCharacterSnapshot(
          character: character.copyWith(description: '参与秘银厅大战'),
          title: '秘银厅之战草稿',
          isMilestone: false,
          maxRetain: 2,
        );

        // 验证修剪策略：快照 1 (非里程碑) 应被修剪淘汰，而快照 2 (里程碑) 必须受到保护保留！
        final list = await db.revisionDao.getRevisions('character', charId);
        expect(list.length, equals(2));
        expect(list.any((r) => r.title == '冰风谷定居里程碑'), isTrue);
        expect(
          list.any((r) => r.content.contains('"isMilestone":true')),
          isTrue,
        );
        expect(list.any((r) => r.title == '初始幽暗地域草案'), isFalse);

        // 5. 测试切换里程碑状态
        final milestoneRev = list.firstWhere((r) => r.title == '冰风谷定居里程碑');
        final toggleSuccess = await actions.toggleMilestone(
          revisionId: milestoneRev.id,
          isMilestone: false,
          entityType: 'character',
          entityId: charId,
        );
        expect(toggleSuccess, isTrue);

        final updatedRev = (await db.revisionDao.getRevisionById(
          milestoneRev.id,
        ))!;
        expect(updatedRev.content.contains('"isMilestone":false'), isTrue);
      },
    );

    test(
      'HISTORY-002: Multi-field and long-text line-by-line diff comparison',
      () {
        final base = CharacterSnapshot(
          name: '亚瑟·潘德拉贡',
          gender: '男',
          avatarPath: '/path/old_avatar.png',
          description: '第一行：不列颠年轻的见习骑士\n第二行：在石中剑前犹豫不决\n第三行：被梅林所唤醒',
          customFields: {'阵营': '守序善良', '武器': '普通的训练铁剑', '称号': '见习骑士'},
          tags: ['学徒', '主角'],
          timestamp: DateTime(2026, 1, 1),
        );

        final current = CharacterSnapshot(
          name: '亚瑟王 (王者归来)',
          gender: '男',
          avatarPath: '/path/king_avatar.png',
          description: '第一行：不列颠崇高的圣王\n第二行：拔出石中剑号令圆桌骑士\n第三行：被梅林所唤醒\n第四行：开创卡美洛王朝',
          customFields: {'阵营': '守序善良', '武器': '断钢誓约圣剑 (Excalibur)', '王都': '卡美洛'},
          tags: ['主角', '圆桌领袖'],
          timestamp: DateTime(2026, 2, 1),
        );

        final diff = CharacterRevisionDiffEngine.compare(
          base: base,
          current: current,
        );

        // 1. 验证存在变更
        expect(diff.hasAnyChanges, isTrue);
        expect(diff.hasBasicInfoChanges, isTrue);
        expect(diff.hasCustomFieldChanges, isTrue);
        expect(diff.hasTagChanges, isTrue);
        expect(diff.hasDescriptionChanges, isTrue);

        // 2. 验证基本字段比对 (姓名修改、立绘修改、性别未修改)
        final nameDiff = diff.basicFieldDiffs.firstWhere(
          (f) => f.key == 'name',
        );
        expect(nameDiff.status, equals(FieldChangeStatus.modified));
        expect(nameDiff.oldValue, equals('亚瑟·潘德拉贡'));
        expect(nameDiff.newValue, equals('亚瑟王 (王者归来)'));

        final genderDiff = diff.basicFieldDiffs.firstWhere(
          (f) => f.key == 'gender',
        );
        expect(genderDiff.status, equals(FieldChangeStatus.unchanged));

        // 3. 验证自定义字段比对
        final weaponDiff = diff.customFieldDiffs.firstWhere(
          (f) => f.key == '武器',
        );
        expect(weaponDiff.status, equals(FieldChangeStatus.modified));

        final titleDiff = diff.customFieldDiffs.firstWhere(
          (f) => f.key == '称号',
        );
        expect(titleDiff.status, equals(FieldChangeStatus.removed));

        final capitalDiff = diff.customFieldDiffs.firstWhere(
          (f) => f.key == '王都',
        );
        expect(capitalDiff.status, equals(FieldChangeStatus.added));

        // 4. 验证标签比对
        expect(
          diff.tagDiffs.any(
            (t) => t.key == '圆桌领袖' && t.status == FieldChangeStatus.added,
          ),
          isTrue,
        );
        expect(
          diff.tagDiffs.any(
            (t) => t.key == '学徒' && t.status == FieldChangeStatus.removed,
          ),
          isTrue,
        );

        // 5. 验证长文本行级 Diff
        expect(diff.descriptionLineDiffs.isNotEmpty, isTrue);
        expect(
          diff.descriptionLineDiffs.any(
            (l) => l.type == DiffType.unchanged && l.text.contains('第三行'),
          ),
          isTrue,
        );
        expect(
          diff.descriptionLineDiffs.any(
            (l) => l.type == DiffType.added && l.text.contains('第四行'),
          ),
          isTrue,
        );
      },
    );

    test(
      'HISTORY-003: Selective restore with pre-rollback automated snapshot backup',
      () async {
        final actions = container.read(revisionActionsProvider);

        // 1. 创建角色初始状态
        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(
            worldId: 1,
            name: '吉安娜·普罗德摩尔',
            gender: const drift.Value('女'),
            description: const drift.Value('最初版本：达拉然肯瑞托年轻女法师'),
          ),
        );
        await db.characterDao.createCharacterField(
          CharacterFieldsCompanion.insert(
            characterId: charId,
            fieldName: '法系',
            fieldType: 'text',
            value: const drift.Value('奥术学徒'),
          ),
        );

        final initialChar = await db.characterDao.getCharacterById(charId);

        // 保存第一版历史快照
        final revId1 = (await actions.recordCharacterSnapshot(
          character: initialChar,
          title: '青年求学时期',
        ))!;

        // 2. 演进修改角色到当前状态
        await db.characterDao.updatePartial(
          charId,
          const CharactersCompanion(
            name: drift.Value('塞拉摩领主·吉安娜'),
            description: drift.Value('当前版本：经历塞拉摩天降法力炸弹浩劫后的白发大法师'),
          ),
        );
        await db.characterDao.deleteAllCharacterFields(charId);
        await db.characterDao.createCharacterField(
          CharacterFieldsCompanion.insert(
            characterId: charId,
            fieldName: '法系',
            fieldType: 'text',
            value: const drift.Value('绝对零度冰霜禁咒宗师'),
          ),
        );

        final currentChar = await db.characterDao.getCharacterById(charId);
        expect(currentChar.name, '塞拉摩领主·吉安娜');

        // 3. 执行【选择性恢复】：仅恢复小传正文，保留当前最新的姓名与法系技能！
        final restoreSuccess = await actions.restoreCharacterSelective(
          revisionId: revId1,
          currentCharacter: currentChar,
          options: const SelectiveRestoreOptions(
            restoreBasicInfo: false, // 保留当前姓名
            restoreDescription: true, // 恢复旧小传
            restoreCustomFields: false, // 保留当前禁咒法系
            restoreTags: false,
          ),
        );
        expect(restoreSuccess, isTrue);

        // 4. 验证还原结果
        final restoredChar = await db.characterDao.getCharacterById(charId);
        // 姓名保持未变
        expect(restoredChar.name, equals('塞拉摩领主·吉安娜'));
        // 小传成功回滚至最初版本
        expect(restoredChar.description, contains('最初版本：达拉然肯瑞托年轻女法师'));
        // 自定义字段保持最新
        final currentFields = await db.characterDao.getCharacterFields(charId);
        expect(currentFields.first.value, equals('绝对零度冰霜禁咒宗师'));

        // 5. 验证【回滚前自动归档】：数据库中应当自动生成了回滚前的安全备份快照！
        final allRevisions = await db.revisionDao.getRevisions(
          'character',
          charId,
        );
        expect(allRevisions.any((r) => r.title == '回滚前自动归档'), isTrue);
        expect(
          allRevisions.any((r) => r.content.contains('经历塞拉摩天降法力炸弹')),
          isTrue,
        );
      },
    );

    testWidgets(
      'HISTORY UI Widget Test: RevisionHistoryDialog displays snapshots, tabs, and selective restore dialog',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final charId = await db.characterDao.createCharacter(
          CharactersCompanion.insert(
            worldId: 1,
            name: '阿尔萨斯',
            gender: const drift.Value('男'),
            description: const drift.Value('白银之手年轻圣骑士'),
          ),
        );

        final character = await db.characterDao.getCharacterById(charId);
        final actions = container.read(revisionActionsProvider);

        // 保存两条快照，一条为里程碑
        await actions.recordCharacterSnapshot(
          character: character,
          title: '圣骑士初稿',
          isMilestone: true,
        );

        await actions.recordCharacterSnapshot(
          character: character.copyWith(description: '斯坦索姆抉择之后'),
          title: '决断之路',
          isMilestone: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(
                body: RevisionHistoryDialog(
                  worldId: 1,
                  entityType: 'character',
                  entityId: charId,
                  entityName: '阿尔萨斯',
                  currentContent: '白银之手年轻圣骑士',
                  character: character,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 1. 验证标题与实体名称
        expect(find.text('设定版本历史与快照恢复'), findsOneWidget);
        expect(find.textContaining('阿尔萨斯'), findsWidgets);

        // 2. 验证快照列表与里程碑标签
        expect(find.text('圣骑士初稿'), findsWidgets);
        expect(find.text('里程碑'), findsOneWidget);
        expect(find.text('决断之路'), findsWidgets);

        // 3. 验证选项卡切换
        expect(find.text('快照内容'), findsOneWidget);
        expect(find.text('设定差异 (Diff)'), findsOneWidget);

        // 切换到设定差异 (Diff) 选项卡
        await tester.tap(find.text('设定差异 (Diff)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 验证差异标签
        expect(find.textContaining('人设小传长文本行级对比'), findsOneWidget);

        // 4. 点击“恢复为此版本”呼出选择性恢复确认弹窗
        final restoreBtn = find.text('恢复为此版本');
        expect(restoreBtn, findsOneWidget);
        await tester.tap(restoreBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 验证选择性恢复弹窗元素
        expect(find.text('选择性安全恢复历史设定'), findsOneWidget);
        expect(find.textContaining('人设小传正文 (Description)'), findsOneWidget);
        expect(find.textContaining('基本信息 (姓名、性别、年龄、立绘)'), findsOneWidget);
        expect(find.text('确认并安全恢复'), findsOneWidget);

        // 关闭弹窗清理
        await tester.tap(find.text('取消'));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
