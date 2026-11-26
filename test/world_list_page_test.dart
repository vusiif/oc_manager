import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/design/components/empty_state.dart';
import 'package:oc_manager/core/design/components/world_card.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/world/world_detail_page.dart';
import 'package:oc_manager/features/world/world_list_page.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/group_provider.dart';
import 'package:oc_manager/providers/world_provider.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  World makeWorld({
    required int id,
    required String name,
    String? description,
    bool isLocked = false,
  }) {
    return World(
      id: id,
      name: name,
      description: description,
      isLocked: isLocked,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('WorldListPage & WorldCard UI Tests', () {
    testWidgets('renders EmptyStateView when no worlds exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [worldsProvider.overrideWith((ref) => Stream.value([]))],
          child: const MaterialApp(home: WorldListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('还没有世界观'), findsOneWidget);
      expect(find.text('创建世界观'), findsOneWidget);
    });

    testWidgets('renders responsive WorldCard grid with lock indicator', (
      tester,
    ) async {
      final worlds = [
        makeWorld(
          id: 1,
          name: '赛博新京',
          description: '霓虹与义体交织的未来都市',
          isLocked: true,
        ),
        makeWorld(id: 2, name: '星海纪元'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            worldsProvider.overrideWith((ref) => Stream.value(worlds)),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 1100, height: 800, child: WorldListPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorldCard), findsNWidgets(2));
      expect(find.text('赛博新京'), findsOneWidget);
      expect(find.text('星海纪元'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('WorldCard delete button triggers confirmation dialog', (
      tester,
    ) async {
      final worlds = [makeWorld(id: 1, name: '旧日遗迹')];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            worldsProvider.overrideWith((ref) => Stream.value(worlds)),
          ],
          child: const MaterialApp(home: WorldListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('删除世界观'));
      await tester.pumpAndSettle();

      expect(find.text('删除世界观'), findsOneWidget);
      expect(find.textContaining('旧日遗迹'), findsWidgets);
    });

    testWidgets(
      'WorldDetailPage folds secondary navigation into tools menu on narrow screens',
      (tester) async {
        tester.view.physicalSize = const Size(420, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final world = makeWorld(id: 1, name: '窄屏测试世界');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              worldByIdProvider(1).overrideWith((ref) => Future.value(world)),
              charactersByWorldProvider(
                1,
              ).overrideWith((ref) => Stream.value([])),
              groupsByWorldProvider(1).overrideWith((ref) => Stream.value([])),
            ],
            child: const MaterialApp(home: WorldDetailPage(worldId: 1)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('工具与更多操作'), findsOneWidget);
        await tester.tap(find.byTooltip('工具与更多操作'));
        await tester.pumpAndSettle();

        expect(find.text('编年史大事件'), findsOneWidget);
        expect(find.text('世界百科 (Lore)'), findsOneWidget);
        expect(find.text('全景数据大盘'), findsOneWidget);
      },
    );
  });
}
