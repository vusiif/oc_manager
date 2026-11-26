import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/services/recent_items_service.dart';
import 'package:oc_manager/features/shell/workspace_recent_section.dart';

class _FakeRecentItemsNotifier extends RecentItemsNotifier {
  _FakeRecentItemsNotifier(super.ref, List<RecentItem> initial) {
    state = initial;
  }
}

void main() {
  final now = DateTime(2026, 1, 1);

  group('RecentItemsLogic Unit Tests', () {
    test('upsertItem deduplicates, moves to front, and preserves pin', () {
      final initial = [
        RecentItem(
          type: RecentItemType.world,
          id: 1,
          worldId: 1,
          title: '世界A',
          isPinned: true,
          accessedAt: now,
        ),
        RecentItem(
          type: RecentItemType.character,
          id: 10,
          worldId: 1,
          title: '角色X',
          accessedAt: now,
        ),
      ];

      final next = RecentItemsLogic.upsertItem(
        initial,
        RecentItem(
          type: RecentItemType.world,
          id: 1,
          worldId: 1,
          title: '世界A-改名',
          accessedAt: now.add(const Duration(minutes: 5)),
        ),
      );

      expect(next.length, 2);
      expect(next.first.title, '世界A-改名');
      expect(next.first.isPinned, isTrue);
    });

    test(
      'evicts oldest unpinned items beyond maxUnpinned while keeping pinned',
      () {
        var list = <RecentItem>[
          RecentItem(
            type: RecentItemType.world,
            id: 99,
            worldId: 99,
            title: '置顶世界',
            isPinned: true,
            accessedAt: now,
          ),
        ];

        for (var i = 1; i <= 5; i++) {
          list = RecentItemsLogic.upsertItem(
            list,
            RecentItem(
              type: RecentItemType.character,
              id: i,
              worldId: 99,
              title: '角色$i',
              accessedAt: now.add(Duration(minutes: i)),
            ),
            maxUnpinned: 3,
          );
        }

        expect(list.length, 4);
        expect(list.first.id, 99);
        expect(list.skip(1).map((e) => e.id).toList(), [5, 4, 3]);
      },
    );

    test('encode & decode roundtrip and ignores malformed json', () {
      final items = [
        RecentItem(
          type: RecentItemType.character,
          id: 7,
          worldId: 2,
          title: '艾琳',
          subtitle: '星海纪元',
          isPinned: true,
          accessedAt: now,
        ),
      ];

      final raw = RecentItemsLogic.encode(items);
      final decoded = RecentItemsLogic.decode(raw);
      expect(decoded.length, 1);
      expect(decoded.first.title, '艾琳');
      expect(decoded.first.isPinned, isTrue);

      expect(RecentItemsLogic.decode('invalid json'), isEmpty);
    });
  });

  group('WorkspaceRecentSection & RecentQuickSwitchButton Widget Tests', () {
    testWidgets('renders pinned and recent sections and handles tap & pin', (
      tester,
    ) async {
      RecentItem? opened;
      final items = [
        RecentItem(
          type: RecentItemType.world,
          id: 1,
          worldId: 1,
          title: '赛博新京',
          subtitle: '世界观',
          isPinned: true,
          accessedAt: now,
        ),
        RecentItem(
          type: RecentItemType.character,
          id: 2,
          worldId: 1,
          title: '林零',
          subtitle: '赛博新京',
          accessedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentItemsProvider.overrideWith(
              (ref) => _FakeRecentItemsNotifier(ref, items),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  RecentQuickSwitchButton(onOpenItem: (item) => opened = item),
                ],
              ),
              body: SingleChildScrollView(
                child: WorkspaceRecentSection(
                  onOpenItem: (item) => opened = item,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('固定收藏'), findsOneWidget);
      expect(find.text('最近访问'), findsOneWidget);
      expect(find.text('赛博新京'), findsNWidgets(2));
      expect(find.text('林零'), findsOneWidget);

      await tester.tap(find.text('林零'));
      expect(opened?.id, 2);

      await tester.tap(find.byTooltip('最近访问与快速切换'));
      await tester.pumpAndSettle();
      expect(find.text('赛博新京'), findsWidgets);
    });
  });
}
