import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/revision_provider.dart';
import 'package:oc_manager/core/history/models/lore_snapshot.dart';
import 'package:oc_manager/core/history/diff/lore_revision_diff.dart';
import 'package:oc_manager/core/history/models/event_snapshot.dart';
import 'package:oc_manager/core/history/diff/event_revision_diff.dart';
import 'package:oc_manager/features/world/revision_history_dialog.dart';

void main() {
  group('HISTORY-004 Other Entities Revision History Tests (Lore & Timeline)', () {
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
              name: '艾泽拉斯世界',
              description: const drift.Value('宏大奇幻大陆'),
            ),
          );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'LoreSnapshot serialization, deserialization and legacy plain text fallback',
      () {
        final snapshot = LoreSnapshot(
          schemaVersion: 1,
          source: 'manual',
          isMilestone: true,
          note: '第三纪元重修版',
          name: '秘银圣殿',
          entityType: 'location',
          summary: '群山之下的古老要塞',
          content: '建造于第二纪元的矮人坚城，深邃且坚不可摧。',
          coverImagePath: 'images/temple.png',
          parentId: 42,
          customFields: {'防御等级': '神圣级', '驻军规模': '5000'},
          tags: ['要塞', '古遗迹'],
          timestamp: DateTime(2026, 1, 1),
        );

        final jsonStr = snapshot.toJsonString();
        expect(jsonStr, contains('"_snapshot_type":"lore_v1"'));
        expect(jsonStr, contains('秘银圣殿'));

        final parsed = LoreSnapshot.parse(jsonStr);
        expect(parsed.schemaVersion, equals(1));
        expect(parsed.name, equals('秘银圣殿'));
        expect(parsed.entityType, equals('location'));
        expect(parsed.summary, equals('群山之下的古老要塞'));
        expect(parsed.isMilestone, isTrue);
        expect(parsed.parentId, equals(42));
        expect(parsed.customFields['防御等级'], equals('神圣级'));
        expect(parsed.tags, contains('古遗迹'));

        // Legacy fallback
        const legacyRaw = '纯文本旧格式世界观设定内容';
        final legacyParsed = LoreSnapshot.parse(
          legacyRaw,
          defaultName: '默认词条名',
        );
        expect(legacyParsed.schemaVersion, equals(0));
        expect(legacyParsed.source, equals('legacy'));
        expect(legacyParsed.content, equals(legacyRaw));
        expect(legacyParsed.name, equals('默认词条名'));
      },
    );

    test('LoreRevisionDiffEngine computes full multidimensional diffs', () {
      final base = LoreSnapshot(
        name: '银月之手骑士团',
        entityType: 'organization',
        summary: '旧时代的圣骑士结社',
        content: '第一行内容\n第二行内容\n第三行内容',
        customFields: {'团长': '乌瑟尔', '总部': '斯坦索姆'},
        tags: ['圣光', '正义'],
        timestamp: DateTime(2026, 1, 1),
      );

      final current = LoreSnapshot(
        name: '白银之手骑士团', // Name modified
        entityType: 'organization',
        summary: '重铸后的圣光先锋团', // Summary modified
        content: '第一行内容\n第二行内容修改\n第三行内容\n第四行新内容', // Line added and modified
        customFields: {
          '团长': '提里奥·弗丁',
          '法器': '灰烬使者',
        }, // Modified + removed + added
        tags: ['圣光', '远征军'], // Tag modified
        timestamp: DateTime(2026, 1, 2),
      );

      final diff = LoreRevisionDiffEngine.compare(base: base, current: current);

      expect(diff.hasAnyChanges, isTrue);
      expect(diff.hasBasicInfoChanges, isTrue);
      expect(
        diff.basicFieldDiffs.firstWhere((f) => f.key == 'name').hasChanged,
        isTrue,
      );
      expect(diff.hasSummaryChanges, isTrue);
      expect(diff.hasCustomFieldChanges, isTrue);
      expect(diff.hasTagChanges, isTrue);
      expect(diff.hasContentChanges, isTrue);

      final options = LoreSelectiveRestoreOptions(
        restoreBasicInfo: false,
        restoreSummary: true,
        restoreContent: true,
        restoreCustomFields: true,
        restoreTags: true,
      );
      final affected = diff.countAffectedFields(options);
      expect(affected, greaterThan(0));
    });

    test('Lore snapshot recording and milestone pruning protection', () async {
      final actions = container.read(revisionActionsProvider);

      final loreId = await db.loreDao.createEntity(
        LoreEntitiesCompanion.insert(
          worldId: 1,
          entityType: 'item',
          name: '灰烬使者',
          summary: drift.Value('传奇神剑'),
          content: drift.Value('最初版本剑身描述'),
        ),
      );

      final lore = await db.loreDao.getEntityById(loreId);
      expect(lore, isNotNull);

      // Snapshot 1: Normal
      final id1 = await actions.recordLoreSnapshot(
        lore: lore!,
        title: '初始锻造',
        isMilestone: false,
      );
      expect(id1, isNotNull);

      // Snapshot 2: Milestone
      final id2 = await actions.recordLoreSnapshot(
        lore: lore.copyWith(content: '注入光明水晶重铸'),
        title: '光明重铸里程碑',
        isMilestone: true,
        note: '击退天灾的关键节点',
      );
      expect(id2, isNotNull);

      // Snapshot 3: Normal, with maxRetain = 2 to trigger pruning
      await actions.recordLoreSnapshot(
        lore: lore.copyWith(content: '大领主弗丁最终继承'),
        title: '弗丁继承草案',
        isMilestone: false,
        maxRetain: 2,
      );

      // Pruning verification: snapshot 1 is pruned, snapshot 2 (milestone) is protected!
      final revisions = await db.revisionDao.getRevisions('lore', loreId);
      expect(revisions.length, equals(2));
      expect(revisions.any((r) => r.id == id2), isTrue);
      expect(revisions.any((r) => r.id == id1), isFalse);
    });

    test(
      'Lore selective restore with pre-rollback automated safety backup',
      () async {
        final actions = container.read(revisionActionsProvider);

        final loreId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'location',
            name: '达拉然浮空城',
            summary: drift.Value('肯瑞托议会领地'),
            content: drift.Value('坐落于洛丹米尔湖畔'),
            customFields: drift.Value('{"领袖":"安东尼达斯"}'),
            tags: drift.Value('["奥术","主城"]'),
          ),
        );

        final originalLore = await db.loreDao.getEntityById(loreId);

        // 1. Record snapshot 1
        final revId1 = await actions.recordLoreSnapshot(
          lore: originalLore!,
          title: '浮空前原始基准',
        );

        // 2. Modify lore entity
        await db.loreDao.updateEntity(
          LoreEntitiesCompanion(
            id: drift.Value(loreId),
            worldId: const drift.Value(1),
            entityType: const drift.Value('location'),
            name: const drift.Value('新达拉然·晶歌森林'), // Name modified
            summary: const drift.Value('飞升至诺森德上空'), // Summary modified
            content: const drift.Value('防御巫妖王天灾的前沿要塞'), // Content modified
            customFields: const drift.Value('{"领袖":"罗宁","防御结界":"紫罗兰"}'),
            tags: const drift.Value('["诺森德","要塞"]'),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

        final currentLore = (await db.loreDao.getEntityById(loreId))!;

        // 3. Selective restore: Revert summary, content, customFields, tags, but keep current Name!
        final options = LoreSelectiveRestoreOptions(
          restoreBasicInfo: false, // Keep new name
          restoreSummary: true,
          restoreContent: true,
          restoreCustomFields: true,
          restoreTags: true,
        );

        final success = await actions.restoreLoreSelective(
          revisionId: revId1!,
          currentLore: currentLore,
          options: options,
        );

        expect(success, isTrue);

        final restoredLore = (await db.loreDao.getEntityById(loreId))!;
        // Name kept modified
        expect(restoredLore.name, equals('新达拉然·晶歌森林'));
        // Summary, content, customFields restored to snapshot 1
        expect(restoredLore.summary, equals('肯瑞托议会领地'));
        expect(restoredLore.content, equals('坐落于洛丹米尔湖畔'));
        expect(restoredLore.customFields, contains('安东尼达斯'));
        expect(restoredLore.tags, contains('主城'));

        // Check pre-rollback automated safety backup was created!
        final allRevisions = await db.revisionDao.getRevisions('lore', loreId);
        final safetyBackup = allRevisions
            .where((r) => r.content.contains('restore_backup'))
            .toList();
        expect(safetyBackup.isNotEmpty, isTrue);
        expect(safetyBackup.first.title, contains('回滚前自动归档'));
      },
    );

    test(
      'EventSnapshot serialization, EventRevisionDiffEngine and safe restore',
      () async {
        final actions = container.read(revisionActionsProvider);

        final eventId = await db.timelineDao.createEvent(
          TimelineEventsCompanion.insert(
            worldId: 1,
            year: '黑暗之门 20年',
            title: '海加尔山战役',
            category: const drift.Value('battle'),
            description: const drift.Value('联军在世界之树下抵御阿克蒙德'),
            importance: const drift.Value(3),
          ),
        );

        final event = (await db.timelineDao.getEventById(eventId))!;

        // Serialization test
        final snapshot = EventSnapshot.fromEntity(
          event,
          isMilestone: true,
          note: '史诗会战',
        );
        final jsonStr = snapshot.toJsonString();
        expect(jsonStr, contains('"_snapshot_type":"event_v1"'));
        expect(jsonStr, contains('海加尔山战役'));

        final parsed = EventSnapshot.parse(jsonStr);
        expect(parsed.title, equals('海加尔山战役'));
        expect(parsed.year, equals('黑暗之门 20年'));
        expect(parsed.importance, equals(3));
        expect(parsed.isMilestone, isTrue);

        // Diff test
        final modifiedEvent = event.copyWith(
          year: '黑暗之门 21年',
          description: '世界之树诺达希尔自爆，阿克蒙德灰飞烟灭',
          importance: 2,
        );
        final modifiedSnapshot = EventSnapshot.fromEntity(modifiedEvent);
        final diff = EventRevisionDiffEngine.compare(
          base: snapshot,
          current: modifiedSnapshot,
        );
        expect(diff.hasAnyChanges, isTrue);
        expect(diff.hasFieldChanges, isTrue);

        // Record snapshot 1
        final revId = await actions.recordEventSnapshot(
          event: event,
          title: '初稿',
        );
        expect(revId, isNotNull);

        // Update event in DB
        await db.timelineDao.updateEvent(
          TimelineEventsCompanion(
            id: drift.Value(eventId),
            worldId: const drift.Value(1),
            year: const drift.Value('黑暗之门 25年'),
            title: const drift.Value('海加尔山战役 (改版)'),
            category: const drift.Value('crisis'),
            description: const drift.Value('剧情大幅变动'),
            sortOrder: const drift.Value(0.0),
            importance: const drift.Value(1),
          ),
        );

        final currentDbEvent = (await db.timelineDao.getEventById(eventId))!;
        expect(currentDbEvent.year, equals('黑暗之门 25年'));

        // Restore event
        final restored = await actions.restoreEvent(
          revisionId: revId!,
          currentEvent: currentDbEvent,
        );
        expect(restored, isTrue);

        final finalDbEvent = (await db.timelineDao.getEventById(eventId))!;
        expect(finalDbEvent.year, equals('黑暗之门 20年'));
        expect(finalDbEvent.title, equals('海加尔山战役'));
        expect(finalDbEvent.importance, equals(3));

        // Safety backup created
        final eventRevisions = await db.revisionDao.getRevisions(
          'event',
          eventId,
        );
        expect(
          eventRevisions.any((r) => r.content.contains('restore_backup')),
          isTrue,
        );
      },
    );

    testWidgets(
      'RevisionHistoryDialog renders for lore entities and timeline events',
      (tester) async {
        final actions = container.read(revisionActionsProvider);

        final loreId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: 1,
            entityType: 'race',
            name: '卡多雷暗夜精灵',
            summary: drift.Value('古老长生种族'),
            content: drift.Value('信奉月之女神艾露恩'),
            customFields: drift.Value('{"平均寿命":"上万年"}'),
            tags: drift.Value('["长生","自然"]'),
          ),
        );

        final lore = (await db.loreDao.getEntityById(loreId))!;
        await actions.recordLoreSnapshot(lore: lore, title: '远古设定初稿');

        // Test Lore UI rendering
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      RevisionHistoryDialog.show(
                        context,
                        worldId: 1,
                        entityType: 'lore',
                        entityId: lore.id,
                        entityName: lore.name,
                        currentContent: lore.content,
                        lore: lore,
                      );
                    },
                    child: const Text('打开词条历史'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('打开词条历史'));
        await tester.pumpAndSettle();

        // Check dialog rendered
        expect(find.text('设定版本历史与快照恢复'), findsOneWidget);
        expect(find.text('词条差异 (Diff)'), findsOneWidget);
        expect(find.text('快照内容'), findsOneWidget);
        expect(find.text('远古设定初稿'), findsNWidgets(2));

        // Close dialog
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Test Event UI rendering
        final eventId = await db.timelineDao.createEvent(
          TimelineEventsCompanion.insert(
            worldId: 1,
            year: '神话纪元',
            title: '永恒之井诞生',
            description: const drift.Value('奥术能量之泉涌现'),
            category: const drift.Value('origin'),
          ),
        );
        final event = (await db.timelineDao.getEventById(eventId))!;
        await actions.recordEventSnapshot(event: event, title: '创世史快照');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      RevisionHistoryDialog.show(
                        context,
                        worldId: 1,
                        entityType: 'event',
                        entityId: event.id,
                        entityName: event.title,
                        currentContent: event.description,
                        event: event,
                      );
                    },
                    child: const Text('打开事件历史'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('打开事件历史'));
        await tester.pumpAndSettle();

        expect(find.text('设定版本历史与快照恢复'), findsOneWidget);
        expect(find.text('事件差异 (Diff)'), findsOneWidget);
        expect(find.text('创世史快照'), findsNWidgets(2));
      },
    );
  });
}
