import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/lore_provider.dart';
import 'package:oc_manager/providers/relation_provider.dart';
import 'package:oc_manager/providers/timeline_provider.dart';
import 'package:oc_manager/features/world/knowledge_network/knowledge_network_layout_engine.dart';
import 'package:oc_manager/features/world/knowledge_network/knowledge_network_painter.dart';
import 'package:oc_manager/features/world/knowledge_network/knowledge_network_provider.dart';
import 'package:oc_manager/features/world/knowledge_network/knowledge_network_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    // 1. Seed World
    await db
        .into(db.worlds)
        .insert(
          WorldsCompanion.insert(
            id: const drift.Value(1),
            name: '艾泽拉斯',
            description: const drift.Value('奇幻史诗宏大世界'),
          ),
        );

    // 2. Seed Characters
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(101),
            worldId: 1,
            name: '阿尔萨斯',
            gender: const drift.Value('男'),
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: const drift.Value(102),
            worldId: 1,
            name: '吉安娜',
            gender: const drift.Value('女'),
          ),
        );

    // 3. Seed Relations (Social)
    await db
        .into(db.relations)
        .insert(
          RelationsCompanion.insert(
            fromCharacterId: 101,
            toCharacterId: 102,
            relationType: '恋人',
            isBidirectional: const drift.Value(true),
          ),
        );

    // 4. Seed Lore Entities (Faction, Location, Item)
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(201),
            worldId: 1,
            entityType: 'faction',
            name: '白银之手骑士团',
            summary: const drift.Value('高贵的圣骑士组织'),
            content: const drift.Value(''),
            tags: const drift.Value('骑士, 圣光'),
          ),
        );
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(202),
            worldId: 1,
            entityType: 'location',
            name: '洛丹伦王城',
            summary: const drift.Value('人类主城'),
            content: const drift.Value(''),
            tags: const drift.Value('都城'),
          ),
        );
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(203),
            worldId: 1,
            entityType: 'location',
            parentId: const drift.Value(202), // 空间层级从属
            name: '王宫大厅',
            summary: const drift.Value('王城核心议事厅'),
            content: const drift.Value(''),
            tags: const drift.Value('宫殿'),
          ),
        );
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(204),
            worldId: 1,
            entityType: 'item',
            name: '霜之哀伤',
            summary: const drift.Value('诅咒魔剑'),
            content: const drift.Value(''),
            tags: const drift.Value('符文剑, 神器'),
          ),
        );
    await db
        .into(db.loreEntities)
        .insert(
          LoreEntitiesCompanion.insert(
            id: const drift.Value(205),
            worldId: 1,
            entityType: 'faction',
            name: '达拉然肯瑞托',
            summary: const drift.Value('法师议会组织'),
            content: const drift.Value(''),
            tags: const drift.Value('法师, 议会'),
          ),
        );

    // 5. Seed Lore Relations (Character to Lore: membership, residence, ownership)
    await db
        .into(db.loreRelations)
        .insert(
          LoreRelationsCompanion.insert(
            worldId: 1,
            characterId: 101,
            loreId: 201, // 白银之手
            role: const drift.Value('圣骑士核心成员'),
          ),
        );
    await db
        .into(db.loreRelations)
        .insert(
          LoreRelationsCompanion.insert(
            worldId: 1,
            characterId: 101,
            loreId: 204, // 霜之哀伤
            role: const drift.Value('持有者'),
          ),
        );

    // 6. Seed Lore Entity Relations (Entity to Entity: diplomacy / alliance)
    await db
        .into(db.loreEntityRelations)
        .insert(
          LoreEntityRelationsCompanion.insert(
            worldId: 1,
            fromLoreId: 201,
            toLoreId: 202,
            relationType: const drift.Value('驻守卫戍'),
            isBidirectional: const drift.Value(true),
          ),
        );
    await db
        .into(db.loreEntityRelations)
        .insert(
          LoreEntityRelationsCompanion.insert(
            worldId: 1,
            fromLoreId: 201,
            toLoreId: 205, // faction <-> faction = diplomacy
            relationType: const drift.Value('同盟互助'),
            isBidirectional: const drift.Value(true),
          ),
        );

    // 7. Seed Timeline Event (Event)
    await db
        .into(db.timelineEvents)
        .insert(
          TimelineEventsCompanion.insert(
            id: const drift.Value(301),
            worldId: 1,
            characterId: const drift.Value(101),
            year: '黑暗之门 20年',
            title: '斯坦索姆抉择',
            description: const drift.Value('命运的转折点'),
            category: const drift.Value('重大战役'),
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Knowledge Network Models & Filter Tests (LORE-007)', () {
    test('KnowledgeNetworkFilterState toggle and copyWith', () {
      const state = KnowledgeNetworkFilterState();
      expect(state.enabledNodeTypes.length, NetworkNodeType.values.length);
      expect(state.enabledEdgeTypes.length, NetworkEdgeType.values.length);
      expect(state.searchQuery, isEmpty);
      expect(state.focusedNodeId, isNull);

      final next = state.copyWith(
        enabledNodeTypes: {NetworkNodeType.character, NetworkNodeType.faction},
        searchQuery: '阿尔萨斯',
        focusedNodeId: 'c_101',
      );
      expect(next.enabledNodeTypes.length, 2);
      expect(next.searchQuery, '阿尔萨斯');
      expect(next.focusedNodeId, 'c_101');

      final cleared = next.copyWith(clearFocusedNode: true);
      expect(cleared.focusedNodeId, isNull);
    });

    test('KnowledgeNetworkGraphData filtering and ego-network focus', () {
      final node1 = NetworkNode(
        id: 'c_101',
        rawId: 101,
        type: NetworkNodeType.character,
        label: '阿尔萨斯',
      );
      final node2 = NetworkNode(
        id: 'c_102',
        rawId: 102,
        type: NetworkNodeType.character,
        label: '吉安娜',
      );
      final node3 = NetworkNode(
        id: 'l_201',
        rawId: 201,
        type: NetworkNodeType.faction,
        label: '白银之手',
      );
      final node4 = NetworkNode(
        id: 'l_204',
        rawId: 204,
        type: NetworkNodeType.item,
        label: '霜之哀伤',
      );

      final edge1 = const NetworkEdge(
        id: 'e1',
        fromId: 'c_101',
        toId: 'c_102',
        label: '恋人',
        type: NetworkEdgeType.social,
      );
      final edge2 = const NetworkEdge(
        id: 'e2',
        fromId: 'c_101',
        toId: 'l_201',
        label: '成员',
        type: NetworkEdgeType.membership,
      );
      final edge3 = const NetworkEdge(
        id: 'e3',
        fromId: 'c_101',
        toId: 'l_204',
        label: '持有',
        type: NetworkEdgeType.ownership,
      );

      final graph = KnowledgeNetworkGraphData(
        nodes: {
          node1.id: node1,
          node2.id: node2,
          node3.id: node3,
          node4.id: node4,
        },
        edges: [edge1, edge2, edge3],
      );

      // 1. 全量不过滤
      final all = graph.filter(const KnowledgeNetworkFilterState());
      expect(all.visibleNodes.length, 4);
      expect(all.visibleEdges.length, 3);
      expect(all.neighborNodeIds, isEmpty);

      // 2. 实体类型过滤 (仅保留人物)
      final onlyChar = graph.filter(
        const KnowledgeNetworkFilterState(
          enabledNodeTypes: {NetworkNodeType.character},
        ),
      );
      expect(onlyChar.visibleNodes.length, 2);
      expect(onlyChar.visibleEdges.length, 1); // 仅有人物间的 social 边

      // 3. 关联类型过滤 (排除 ownership)
      final noOwnership = graph.filter(
        const KnowledgeNetworkFilterState(
          enabledEdgeTypes: {
            NetworkEdgeType.social,
            NetworkEdgeType.membership,
          },
        ),
      );
      expect(noOwnership.visibleEdges.length, 2);

      // 4. 搜索关键字过滤
      final searchFiltered = graph.filter(
        const KnowledgeNetworkFilterState(searchQuery: '霜之'),
      );
      expect(searchFiltered.visibleNodes.length, 1);
      expect(searchFiltered.visibleNodes.containsKey('l_204'), isTrue);

      // 5. Ego-network 聚焦高亮 (聚焦 c_101，应提取 c_101, c_102, l_201, l_204)
      final focused = graph.filter(
        const KnowledgeNetworkFilterState(focusedNodeId: 'c_101'),
      );
      expect(focused.neighborNodeIds.contains('c_101'), isTrue);
      expect(focused.neighborNodeIds.contains('c_102'), isTrue);
      expect(focused.neighborNodeIds.contains('l_201'), isTrue);
      expect(focused.neighborNodeIds.contains('l_204'), isTrue);
    });
  });

  group('Knowledge Network Layout Engine Tests (LORE-007)', () {
    test('Boundary cases: empty and single node', () {
      final emptyLayout = KnowledgeNetworkLayoutEngine.computeLayout(
        mode: NetworkLayoutMode.galaxy,
        nodes: [],
        edges: [],
      );
      expect(emptyLayout, isEmpty);

      final singleNode = NetworkNode(
        id: 'c_1',
        rawId: 1,
        type: NetworkNodeType.character,
        label: '独行侠',
      );
      final singleLayout = KnowledgeNetworkLayoutEngine.computeLayout(
        mode: NetworkLayoutMode.galaxy,
        nodes: [singleNode],
        edges: [],
        center: const Offset(500, 500),
      );
      expect(singleLayout['c_1'], const Offset(500, 500));
    });

    test('Galaxy, Force and Radial layouts produce valid coordinates', () {
      final nodes = [
        NetworkNode(
          id: 'l_1',
          rawId: 1,
          type: NetworkNodeType.faction,
          label: '联盟',
        ),
        NetworkNode(
          id: 'l_2',
          rawId: 2,
          type: NetworkNodeType.location,
          label: '暴风城',
        ),
        NetworkNode(
          id: 'c_1',
          rawId: 3,
          type: NetworkNodeType.character,
          label: '瓦里安',
        ),
        NetworkNode(
          id: 'l_3',
          rawId: 4,
          type: NetworkNodeType.item,
          label: '萨拉迈尼',
        ),
        NetworkNode(
          id: 'e_1',
          rawId: 5,
          type: NetworkNodeType.event,
          label: '大灾变',
        ),
      ];
      final edges = [
        const NetworkEdge(
          id: 'ed1',
          fromId: 'c_1',
          toId: 'l_1',
          label: '领袖',
          type: NetworkEdgeType.membership,
        ),
      ];

      for (final mode in NetworkLayoutMode.values) {
        final posMap = KnowledgeNetworkLayoutEngine.computeLayout(
          mode: mode,
          nodes: nodes,
          edges: edges,
        );
        expect(posMap.length, 5);
        for (final pos in posMap.values) {
          expect(pos.dx.isFinite, isTrue);
          expect(pos.dy.isFinite, isTrue);
          expect(pos.dx.isNaN, isFalse);
          expect(pos.dy.isNaN, isFalse);
        }
      }
    });
  });

  group('Knowledge Network Painter Tests (LORE-007)', () {
    test('CustomPainter paints correctly with LOD and culling', () {
      final nodes = {
        'c_1': NetworkNode(
          id: 'c_1',
          rawId: 1,
          type: NetworkNodeType.character,
          label: '角色1',
        ),
        'c_2': NetworkNode(
          id: 'c_2',
          rawId: 2,
          type: NetworkNodeType.character,
          label: '角色2',
        ),
      };
      final edges = [
        const NetworkEdge(
          id: 'ed_1',
          fromId: 'c_1',
          toId: 'c_2',
          label: '好友',
          type: NetworkEdgeType.social,
        ),
      ];
      final positions = {
        'c_1': const Offset(100, 100),
        'c_2': const Offset(200, 200),
      };

      final painter = KnowledgeNetworkPainter(
        edges: edges,
        positions: positions,
        nodes: nodes,
        scale: 1.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(1000, 1000));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);

      // 验证聚焦态与视口裁剪
      final culledPainter = KnowledgeNetworkPainter(
        edges: edges,
        positions: positions,
        nodes: nodes,
        scale: 0.3, // LOD: scale < 0.45
        focusedNodeId: 'c_1',
        neighborNodeIds: {'c_1', 'c_2'},
        visibleRect: const Rect.fromLTWH(0, 0, 500, 500),
      );
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);
      culledPainter.paint(canvas2, const Size(1000, 1000));
      final picture2 = recorder2.endRecording();
      expect(picture2, isNotNull);
    });
  });

  group('Knowledge Network Full Graph Provider Tests (LORE-007)', () {
    test('Aggregates full knowledge graph from SQLite database', () async {
      // 等待 provider 流式数据加载就绪
      await container.read(charactersByWorldProvider(1).future);
      await container.read(relationsByWorldProvider(1).future);
      await container.read(loreEntitiesByWorldProvider(1).future);
      await container.read(worldLoreRelationsProvider(1).future);
      await container.read(worldLoreEntityRelationsProvider(1).future);
      await container.read(worldTimelineEventsProvider(1).future);

      container.listen(knowledgeNetworkGraphProvider(1), (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final graphAsync = container.read(knowledgeNetworkGraphProvider(1));
      expect(graphAsync.hasValue, isTrue);

      final graphData = graphAsync.value!;

      // 1. 验证节点生成与统一 ID
      // 角色 2 个: c_101, c_102
      // 百科条目 5 个: l_201, l_202, l_203, l_204, l_205
      // 历史事件 1 个: e_301
      expect(graphData.nodes.length, 8);
      expect(graphData.nodes.containsKey('c_101'), isTrue);
      expect(graphData.nodes.containsKey('c_102'), isTrue);
      expect(graphData.nodes.containsKey('l_201'), isTrue);
      expect(graphData.nodes.containsKey('l_202'), isTrue);
      expect(graphData.nodes.containsKey('l_203'), isTrue);
      expect(graphData.nodes.containsKey('l_204'), isTrue);
      expect(graphData.nodes.containsKey('l_205'), isTrue);
      expect(graphData.nodes.containsKey('e_301'), isTrue);

      // 2. 验证多维关联边生成
      // - 社交关系: c_101 <-> c_102 (恋人)
      // - 组织职务: c_101 -> l_201 (白银之手)
      // - 装备持有: c_101 -> l_204 (霜之哀伤)
      // - 空间层级: l_202 -> l_203 (洛丹伦王城 -> 王宫大厅)
      // - 势力/地缘: l_201 <-> l_202 (白银之手 <-> 洛丹伦王城)
      // - 外交同盟: l_201 <-> l_205 (白银之手 <-> 达拉然肯瑞托)
      // - 亲历事件: c_101 -> e_301 (斯坦索姆抉择)
      expect(graphData.edges.length, 7);

      final edgeTypes = graphData.edges.map((e) => e.type).toSet();
      expect(edgeTypes.contains(NetworkEdgeType.social), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.membership), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.ownership), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.hierarchy), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.residence), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.diplomacy), isTrue);
      expect(edgeTypes.contains(NetworkEdgeType.eventTie), isTrue);

      // 3. 验证节点度数统计
      // c_101 参与了 4 条边 (恋人、白银之手、霜之哀伤、亲历事件)
      final arthasNode = graphData.nodes['c_101']!;
      expect(arthasNode.degree, 4);
    });
  });

  group('Knowledge Network Widget Page Tests (LORE-007)', () {
    testWidgets(
      'Renders KnowledgeNetworkPage with top bar, nodes and inspector card',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));

        await container.read(charactersByWorldProvider(1).future);
        await container.read(relationsByWorldProvider(1).future);
        await container.read(loreEntitiesByWorldProvider(1).future);
        await container.read(worldLoreRelationsProvider(1).future);
        await container.read(worldLoreEntityRelationsProvider(1).future);
        await container.read(worldTimelineEventsProvider(1).future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: KnowledgeNetworkPage(worldId: 1)),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 1. 验证顶部控制工具栏与标题
        expect(find.text('知识网络 · 全景图谱'), findsOneWidget);
        expect(find.text('艾泽拉斯'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // 2. 验证渲染了节点名称
        expect(find.text('阿尔萨斯'), findsOneWidget);
        expect(find.text('吉安娜'), findsOneWidget);
        expect(find.text('白银之手骑士团'), findsOneWidget);

        // 3. 点击节点弹出详情卡片 (Inspector Card)
        final arthasNodeFinder = find.text('阿尔萨斯');
        await tester.tap(arthasNodeFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // 验证卡片内展示度数与操作按钮
        expect(find.text('聚焦网络'), findsOneWidget);
        expect(find.text('详情卡片'), findsOneWidget);
        expect(find.textContaining('关联脉络'), findsOneWidget);

        // 4. 点击“聚焦网络”触发聚焦模式
        await tester.tap(find.text('聚焦网络'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('取消聚焦'), findsOneWidget);

        // 5. 点击过滤器按钮弹出弹窗
        final filterButton = find.byTooltip('图谱维度过滤');
        await tester.tap(filterButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('网络维度过滤'), findsOneWidget);
        expect(find.text('实体类型 (Nodes)'), findsOneWidget);
        expect(find.text('关联类型 (Edges)'), findsOneWidget);

        // 关闭弹窗
        await tester.tap(find.text('完成'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 善后清理 pending timers
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
