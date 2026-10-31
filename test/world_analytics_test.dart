import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/analytics/world_analytics_engine.dart';
import 'package:oc_manager/core/design/components/donut_chart.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/relation_provider.dart';
import 'package:oc_manager/providers/group_provider.dart';
import 'package:oc_manager/features/world/world_analytics_dialog.dart';

void main() {
  group('WorldAnalytics & Network Centrality Tests (Milestone 3.2)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    final charA = Character(
      id: 1,
      worldId: 10,
      name: '亚瑟王',
      avatarPath: null,
      gender: '男',
      description: '圆桌骑士之首',
      status: 2, // 已定稿
      isFavorite: true,
      isPinned: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final charB = Character(
      id: 2,
      worldId: 10,
      name: '梅林',
      avatarPath: null,
      gender: '男',
      description: '大魔法师与王国先知',
      status: 2, // 已定稿
      isFavorite: true,
      isPinned: false,
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    );

    final charC = Character(
      id: 3,
      worldId: 10,
      name: '莫甘娜',
      avatarPath: null,
      gender: '女',
      description: '命运多舛的暗黑魔女',
      status: 0, // 细化中
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    );

    final charD = Character(
      id: 4,
      worldId: 10,
      name: '兰斯洛特',
      avatarPath: null,
      gender: '男',
      description: '湖上骑士',
      status: 1, // 草稿
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    );

    final groupRoundTable = Group(
      id: 100,
      worldId: 10,
      name: '卡美洛圆桌骑士团',
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('WorldAnalyticsEngine calculates statistics and network centrality', () {
      final characters = [charA, charB, charC, charD];

      // 关系网络构建：
      // 亚瑟王(A) 与 梅林(B) 双向互为挚友
      // 亚瑟王(A) 与 莫甘娜(C) 单向宿敌
      // 亚瑟王(A) 与 兰斯洛特(D) 双向主从
      // 梅林(B) 与 莫甘娜(C) 单向同门
      final relations = [
        const Relation(
          id: 1,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '挚友',
          isBidirectional: true,
        ),
        const Relation(
          id: 2,
          fromCharacterId: 1,
          toCharacterId: 3,
          relationType: '宿敌',
          isBidirectional: false,
        ),
        const Relation(
          id: 3,
          fromCharacterId: 1,
          toCharacterId: 4,
          relationType: '君臣',
          isBidirectional: true,
        ),
        const Relation(
          id: 4,
          fromCharacterId: 2,
          toCharacterId: 3,
          relationType: '同门',
          isBidirectional: false,
        ),
      ];

      final groupMap = {
        1: [100], // 亚瑟属于圆桌骑士团
        4: [100], // 兰斯洛特属于圆桌骑士团
        // 梅林和莫甘娜未归属阵营
      };

      final data = WorldAnalyticsEngine.analyze(
        characters: characters,
        relations: relations,
        groups: [groupRoundTable],
        characterGroupMap: groupMap,
      );

      // 1. 基础指标断言
      expect(data.totalCharacters, equals(4));
      expect(data.totalRelations, equals(4));
      // 定稿率：4 人中有 2 人定稿 (A & B) -> 50%
      expect(data.finalizedRate, closeTo(50.0, 0.01));

      // 2. 性别比例断言：男 3 人 (75%), 女 1 人 (25%)
      expect(data.genderStats.length, equals(2));
      final male = data.genderStats.firstWhere((s) => s.label == '男');
      final female = data.genderStats.firstWhere((s) => s.label == '女');
      expect(male.count, equals(3));
      expect(female.count, equals(1));
      expect(male.ratio, closeTo(0.75, 0.01));

      // 3. 组织阵营断言
      expect(data.groupStats.length, equals(2));
      final roundTableSlice =
          data.groupStats.firstWhere((s) => s.label == '卡美洛圆桌骑士团');
      final unassignedSlice =
          data.groupStats.firstWhere((s) => s.label == '未归属阵营');
      expect(roundTableSlice.count, equals(2));
      expect(unassignedSlice.count, equals(2));

      // 4. 关系网络中心性排名断言：
      // 亚瑟(A) 连接了 B, C, D 共 3 位邻居 -> 第一名 Top 1 Hub！
      expect(data.centralityRanking.isNotEmpty, isTrue);
      final top1 = data.centralityRanking.first;
      expect(top1.character.id, equals(1));
      expect(top1.character.name, equals('亚瑟王'));
      expect(top1.totalDegree, equals(3));
      expect(top1.centralityScore, equals(1.0)); // 归一化满分

      // 网络密度断言：N=4 时最大边数 = 4*3/2 = 6, 实际 4 条边 -> 4/6 ≈ 0.667
      expect(data.networkDensity, closeTo(4 / 6, 0.01));
    });

    test('WorldAnalyticsEngine handles empty world gracefully', () {
      final data = WorldAnalyticsEngine.analyze(
        characters: const [],
        relations: const [],
        groups: const [],
        characterGroupMap: const {},
      );

      expect(data.isEmpty, isTrue);
      expect(data.totalCharacters, equals(0));
      expect(data.finalizedRate, equals(0.0));
      expect(data.networkDensity, equals(0.0));
      expect(data.centralityRanking, isEmpty);
    });

    testWidgets('DonutChart and DonutLegend render slices correctly',
        (tester) async {
      const slices = [
        CategorySlice(
          label: '已定稿',
          count: 6,
          ratio: 0.6,
          color: Colors.green,
        ),
        CategorySlice(
          label: '构思中',
          count: 4,
          ratio: 0.4,
          color: Colors.blue,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                DonutChart(
                  slices: slices,
                  centerValue: '10',
                  centerTitle: '总计',
                ),
                DonutLegend(slices: slices),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证中心数值与标题
      expect(find.text('10'), findsOneWidget);
      expect(find.text('总计'), findsOneWidget);

      // 验证图例文本与百分比
      expect(find.textContaining('已定稿'), findsOneWidget);
      expect(find.textContaining('构思中'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldAnalyticsDialog renders full dashboard and centrality list',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final characters = [charA, charB, charC, charD];
      const relations = [
        Relation(
          id: 1,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '挚友',
          isBidirectional: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            charactersByWorldProvider(10)
                .overrideWith((ref) => Stream.value(characters)),
            relationsByWorldProvider(10)
                .overrideWith((ref) => Future.value(relations)),
            groupsByWorldProvider(10)
                .overrideWith((ref) => Stream.value([groupRoundTable])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorldAnalyticsDialog(
                worldId: 10,
                worldName: '亚瑟王传奇',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证大盘标题
      expect(find.textContaining('亚瑟王传奇 · 全景数据大盘与人际网络分析'), findsOneWidget);

      // 验证核心大盘指标卡片
      expect(find.text('人物总数'), findsOneWidget);
      expect(find.text('人际纽带'), findsOneWidget);
      expect(find.text('设定定稿率'), findsOneWidget);
      expect(find.text('网络紧密度'), findsOneWidget);

      // 验证图表卡片
      expect(find.text('创作阶段分布'), findsOneWidget);
      expect(find.text('角色性别构成'), findsOneWidget);
      expect(find.text('阵营与组织势力规模'), findsOneWidget);
      expect(find.text('人际网络核心纽带人物 (Top Hubs)'), findsOneWidget);

      // 验证核心纽带人物榜上出现人物
      expect(find.text('亚瑟王'), findsWidgets);
      expect(find.text('梅林'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
