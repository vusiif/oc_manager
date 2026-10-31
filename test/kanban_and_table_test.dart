import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/constants/character_status.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/world_provider.dart';
import 'package:oc_manager/providers/group_provider.dart';
import 'package:oc_manager/features/world/views/world_kanban_view.dart';
import 'package:oc_manager/features/world/views/world_table_view.dart';
import 'package:oc_manager/features/world/world_detail_page.dart';

void main() {
  group('Kanban & Table Views Tests (Milestone 3.1)', () {
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

    final testWorld = World(
      id: 10,
      name: '瓦罗兰特',
      description: '未来战术射击世界',
      isLocked: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final char1 = Character(
      id: 101,
      worldId: 10,
      name: '捷风 Jett',
      avatarPath: null,
      gender: '女',
      description: '来自首尔的决斗者，掌握敏捷的风之力量。',
      status: 2, // 已定稿
      isFavorite: true,
      isPinned: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final char2 = Character(
      id: 102,
      worldId: 10,
      name: '零 Cypher',
      avatarPath: null,
      gender: '男',
      description: '情报贩子，监控之王。',
      status: 0, // 细化中
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    );

    final char3 = Character(
      id: 103,
      worldId: 10,
      name: '幽影 Omen',
      avatarPath: null,
      gender: '未知',
      description: '幻影刺客与暗影行者。',
      status: 1, // 草稿
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    test('CharacterCreationStatus metadata and find fallback', () {
      expect(CharacterCreationStatus.all.length, equals(4));
      expect(CharacterCreationStatus.find(0).label, equals('细化中'));
      expect(CharacterCreationStatus.find(1).label, equals('构思草稿'));
      expect(CharacterCreationStatus.find(2).label, equals('已定稿'));
      expect(CharacterCreationStatus.find(3).label, equals('历史归档'));
      expect(CharacterCreationStatus.find(999).label, equals('细化中')); // 默认回退
    });

    test('CharacterActions.updateStatus updates database state', () async {
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('测试世界')),
      );

      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('初始人物'),
          status: const Value(1), // 初始为草稿
        ),
      );

      final initialChar = await db.characterDao.getCharacterById(charId);
      expect(initialChar.status, equals(1));

      // 更新状态为已定稿 (2)
      await container.read(characterActionsProvider).updateStatus(charId, 2);

      final updatedChar = await db.characterDao.getCharacterById(charId);
      expect(updatedChar.status, equals(2));
    });

    testWidgets('WorldKanbanView renders status columns and character cards',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WorldKanbanView(
                worldId: 10,
                characters: [char1, char2, char3],
                groups: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证看板维度控制条
      expect(find.text('按创作状态'), findsOneWidget);
      expect(find.text('按阵营组织'), findsOneWidget);

      // 验证 4 列标题
      expect(find.text('构思草稿'), findsWidgets);
      expect(find.text('细化中'), findsWidgets);
      expect(find.text('已定稿'), findsWidgets);
      expect(find.text('历史归档'), findsWidgets);

      // 验证各个角色在对应列的卡片渲染
      expect(find.text('捷风 Jett'), findsOneWidget);
      expect(find.text('零 Cypher'), findsOneWidget);
      expect(find.text('幽影 Omen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldTableView renders columns, filters and sorts correctly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WorldTableView(
                worldId: 10,
                characters: [char1, char2, char3],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证表格表头
      expect(find.text('姓名'), findsOneWidget);
      expect(find.text('创作阶段'), findsOneWidget);
      expect(find.text('最近更新'), findsOneWidget);

      // 验证角色行
      expect(find.text('捷风 Jett'), findsOneWidget);
      expect(find.text('零 Cypher'), findsOneWidget);
      expect(find.text('幽影 Omen'), findsOneWidget);

      // 测试搜索过滤：输入“捷风”
      await tester.enterText(find.byType(TextField), '捷风');
      await tester.pumpAndSettle();

      expect(find.text('捷风 Jett'), findsOneWidget);
      expect(find.text('零 Cypher'), findsNothing);
      expect(find.text('幽影 Omen'), findsNothing);

      // 清空搜索
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('零 Cypher'), findsOneWidget);

      // 测试仅收藏过滤
      await tester.tap(find.text('仅收藏'));
      await tester.pumpAndSettle();

      expect(find.text('捷风 Jett'), findsOneWidget); // char1 isFavorite = true
      expect(find.text('零 Cypher'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldDetailPage switches between cards, kanban and table views',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            worldByIdProvider(10)
                .overrideWith((ref) => Future.value(testWorld)),
            charactersByWorldProvider(10)
                .overrideWith((ref) => Stream.value([char1, char2, char3])),
            groupsByWorldProvider(10)
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: WorldDetailPage(worldId: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 默认是卡片流视图
      expect(find.text('瓦罗兰特'), findsOneWidget);
      expect(find.byType(SegmentedButton<WorldViewMode>), findsOneWidget);

      // 切换到看板视图
      await tester.tap(find.byIcon(Icons.view_kanban_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(WorldKanbanView), findsOneWidget);
      expect(find.text('构思草稿'), findsWidgets);

      // 切换到表格视图
      await tester.tap(find.byIcon(Icons.table_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(WorldTableView), findsOneWidget);

      // 切换回卡片视图
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(WorldTableView), findsNothing);
      expect(find.byType(WorldKanbanView), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
