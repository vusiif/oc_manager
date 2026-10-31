import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/trash_provider.dart';
import 'package:oc_manager/providers/timeline_provider.dart';
import 'package:oc_manager/providers/world_provider.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/features/character/character_timeline_section.dart';
import 'package:oc_manager/features/world/chronicle_page.dart';

void main() {
  group('Timeline & Chronicle Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('TimelineDao CRUD and sorting order', () async {
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('艾尔登世界')),
      );

      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('梅琳娜'),
        ),
      );

      // 1. 创建世界事件与角色事件
      final evWorld = await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          year: const Value('神圣历 1 年'),
          sortOrder: const Value(1.0),
          title: const Value('黄金树诞生'),
          description: const Value('伟大的意志降临交界地'),
          category: const Value('origin'),
          importance: const Value(3),
        ),
      );

      final evChar1 = await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          year: const Value('神圣历 200 年'),
          sortOrder: const Value(2.0),
          title: const Value('与褪色者相遇'),
          description: const Value('在风暴山丘的篝火旁结下契约'),
          category: const Value('turning_point'),
          importance: const Value(2),
        ),
      );

      final evChar2 = await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          year: const Value('神圣历 201 年'),
          sortOrder: const Value(1.5), // 排序权重更前
          title: const Value('抵达王城罗德尔'),
          category: const Value('achievement'),
          importance: const Value(2),
        ),
      );

      // 2. 按世界查询
      final worldEvents = await db.timelineDao.getEventsByWorld(worldId);
      expect(worldEvents.length, equals(3));
      // 验证按 sortOrder 排序：1.0 (黄金树诞生) -> 1.5 (抵达王城) -> 2.0 (相遇)
      expect(worldEvents[0].id, equals(evWorld));
      expect(worldEvents[1].id, equals(evChar2));
      expect(worldEvents[2].id, equals(evChar1));

      // 3. 按角色查询
      final charEvents = await db.timelineDao.getEventsByCharacter(charId);
      expect(charEvents.length, equals(2));
      expect(charEvents[0].title, equals('抵达王城罗德尔'));
      expect(charEvents[1].title, equals('与褪色者相遇'));

      // 4. 更新事件
      await db.timelineDao.updateEvent(
        TimelineEventsCompanion(
          id: Value(evChar1),
          worldId: Value(worldId),
          characterId: Value(charId),
          year: const Value('神圣历 200 年初冬'),
          sortOrder: const Value(2.0),
          title: const Value('与褪色者结下命运誓约'),
          description: const Value('成为他的指引'),
          category: const Value('turning_point'),
          importance: const Value(3),
        ),
      );

      final updatedCharEvents =
          await db.timelineDao.getEventsByCharacter(charId);
      final updatedEv =
          updatedCharEvents.firstWhere((e) => e.id == evChar1);
      expect(updatedEv.title, equals('与褪色者结下命运誓约'));
      expect(updatedEv.year, equals('神圣历 200 年初冬'));
      expect(updatedEv.importance, equals(3));

      // 5. 删除单条事件
      await db.timelineDao.deleteEvent(evChar2);
      final afterDelete = await db.timelineDao.getEventsByCharacter(charId);
      expect(afterDelete.length, equals(1));
      expect(afterDelete.first.id, equals(evChar1));
    });

    test('Trash: soft-delete character cascades timeline and restores fully',
        () async {
      final trashActions = container.read(trashActionsProvider);

      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('赛博都市')),
      );

      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('V'),
        ),
      );

      final char = await db.characterDao.getCharacterById(charId);

      // 创建该角色的生平事件
      await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          year: const Value('2077 年'),
          title: const Value('潜入绀碧大厦'),
          description: const Value('盗取 Relic 芯片'),
          category: const Value('crisis'),
          importance: const Value(3),
        ),
      );

      // 确认当前存在 1 条事件
      final beforeDelete = await db.timelineDao.getEventsByCharacter(charId);
      expect(beforeDelete.length, equals(1));

      // 软删除角色
      await trashActions.deleteCharacter(char);

      // 角色被删除，生平事件应被清空
      final afterDelete = await db.timelineDao.getEventsByCharacter(charId);
      expect(afterDelete, isEmpty);

      // 从回收站恢复
      final trashItems = await db.trashDao.getAllTrash();
      expect(trashItems.length, equals(1));
      await trashActions.restoreCharacter(trashItems.first);

      // 恢复后验证事件完整还原
      final restoredEvents = await db.timelineDao.getEventsByCharacter(charId);
      expect(restoredEvents.length, equals(1));
      expect(restoredEvents.first.title, equals('潜入绀碧大厦'));
      expect(restoredEvents.first.year, equals('2077 年'));
      expect(restoredEvents.first.category, equals('crisis'));
      expect(restoredEvents.first.importance, equals(3));
    });

    test('Trash: soft-delete world cascades all timeline events and restores fully',
        () async {
      final trashActions = container.read(trashActionsProvider);

      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('星际联邦')),
      );
      final world = await db.worldDao.getWorldById(worldId);

      // 世界事件与角色事件
      await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          year: const Value('星历 0 年'),
          title: const Value('超光速跃迁引擎发明'),
          category: const Value('origin'),
        ),
      );

      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('柯克舰长'),
        ),
      );

      await db.timelineDao.createEvent(
        TimelineEventsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          year: const Value('星历 2265 年'),
          title: const Value('五年探索任务启航'),
          category: const Value('achievement'),
        ),
      );

      expect((await db.timelineDao.getEventsByWorld(worldId)).length, equals(2));

      // 软删除世界
      await trashActions.deleteWorld(world);
      expect((await db.timelineDao.getEventsByWorld(worldId)).length, equals(0));

      // 还原世界
      final trashItems = await db.trashDao.getAllTrash();
      expect(trashItems.length, equals(1));
      await trashActions.restoreWorld(trashItems.first);

      // 还原后验证
      final restoredWorldEvents =
          await db.timelineDao.getEventsByWorld(worldId);
      expect(restoredWorldEvents.length, equals(2));
      final titles = restoredWorldEvents.map((e) => e.title).toSet();
      expect(titles.contains('超光速跃迁引擎发明'), isTrue);
      expect(titles.contains('五年探索任务启航'), isTrue);
    });

    test('TimelineCategoryConfig enumeration and fallback', () {
      expect(TimelineCategoryConfig.all.length, equals(6));
      expect(TimelineCategoryConfig.find('origin').label, equals('起源 / 诞生'));
      expect(TimelineCategoryConfig.find('battle').label, equals('战役 / 冲突'));
      expect(TimelineCategoryConfig.find('unknown').label, equals('纪事 / 日常'));
    });

    testWidgets('CharacterTimelineSection renders empty state', (tester) async {
      const worldId = 100;
      const charId = 200;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            characterTimelineEventsProvider(charId)
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CharacterTimelineSection(
                worldId: worldId,
                characterId: charId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('生平大事记与时间线'), findsOneWidget);
      expect(find.text('暂无生平纪事记录'), findsOneWidget);
      expect(find.text('记录生平'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('CharacterTimelineSection renders event list', (tester) async {
      const worldId = 100;
      const charId = 200;

      final testEvent = TimelineEvent(
        id: 1,
        worldId: worldId,
        characterId: charId,
        year: 'X784 年',
        sortOrder: 1.0,
        title: '天狼岛巨变',
        description: '黑龙阿库诺洛基亚降临',
        category: 'battle',
        importance: 3,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            characterTimelineEventsProvider(charId)
                .overrideWith((ref) => Stream.value([testEvent])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CharacterTimelineSection(
                worldId: worldId,
                characterId: charId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('天狼岛巨变'), findsOneWidget);
      expect(find.text('X784 年'), findsOneWidget);
      expect(find.text('黑龙阿库诺洛基亚降临'), findsOneWidget);
      expect(find.text('1 个纪元节点'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ChroniclePage renders full chronicle view and empty state',
        (tester) async {
      const worldId = 50;

      final testWorld = World(
        id: worldId,
        name: '亚特兰蒂斯',
        description: '深海失落王国',
        isLocked: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final testCharacter = Character(
        id: 501,
        worldId: worldId,
        name: '海皇亚瑟',
        avatarPath: null,
        gender: '男',
        description: '七海统御者',
        status: 0,
        isFavorite: true,
        isPinned: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final testEvent1 = TimelineEvent(
        id: 1,
        worldId: worldId,
        characterId: null,
        year: '沉没前 100 年',
        sortOrder: 1.0,
        title: '水晶能源矩阵建成',
        description: '帝国黄金鼎盛时代',
        category: 'origin',
        importance: 2,
        createdAt: DateTime(2026, 1, 1),
      );

      final testEvent2 = TimelineEvent(
        id: 2,
        worldId: worldId,
        characterId: 501,
        year: '海渊纪元 1 年',
        sortOrder: 2.0,
        title: '加冕海皇王座',
        description: '手持三叉戟平息深渊海啸',
        category: 'achievement',
        importance: 3,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            worldByIdProvider(worldId)
                .overrideWith((ref) => Future.value(testWorld)),
            charactersByWorldProvider(worldId)
                .overrideWith((ref) => Stream.value([testCharacter])),
            worldTimelineEventsProvider(worldId)
                .overrideWith((ref) => Stream.value([testEvent1, testEvent2])),
          ],
          child: const MaterialApp(
            home: ChroniclePage(worldId: worldId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证世界名与标题
      expect(find.text('亚特兰蒂斯 · 编年史大事件'), findsOneWidget);
      // 验证筛选栏
      expect(find.text('全部类型'), findsOneWidget);
      expect(find.text('起源 / 诞生'), findsWidgets);
      // 验证事件卡片
      expect(find.text('水晶能源矩阵建成'), findsOneWidget);
      expect(find.text('世界宏观纪事'), findsOneWidget);
      expect(find.text('加冕海皇王座'), findsOneWidget);
      expect(find.text('海皇亚瑟'), findsOneWidget);
      expect(find.text('新撰纪事'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
