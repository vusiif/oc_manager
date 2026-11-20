import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/command_palette/command_palette_model.dart';
import 'package:oc_manager/features/command_palette/command_palette_service.dart';
import 'package:oc_manager/features/command_palette/command_palette_dialog.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/world_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandPaletteItem Unit Tests', () {
    test('matchScore computes accurate scores based on relevance', () {
      final item = CommandPaletteItem(
        id: 'test_1',
        title: '新建世界观',
        subtitle: '创建全新的设定舞台',
        category: CommandPaletteCategory.command,
        icon: Icons.add,
        keywords: ['world', 'create', 'new'],
        onExecute: (ctx, ref) {},
      );

      // Empty query returns 1
      expect(item.matchScore(''), equals(1));
      expect(item.matchScore('   '), equals(1));

      // Exact title match
      expect(item.matchScore('新建世界观'), equals(100));

      // Prefix match
      expect(item.matchScore('新建'), equals(85));

      // Substring match
      expect(item.matchScore('世界'), equals(65));

      // Keyword match
      expect(item.matchScore('world'), equals(75));
      expect(item.matchScore('cre'), equals(60));

      // Subtitle match
      expect(item.matchScore('舞台'), equals(30));

      // No match
      expect(item.matchScore('魔法'), equals(0));
    });
  });

  group('CommandPaletteService Search Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // World 1
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '赛博纪元',
              description: const drift.Value('高科技低生活的近未来世界'),
            ),
          );

      // World 2
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(2),
              name: '艾泽拉斯',
              description: const drift.Value('魔兽争霸史诗奇幻'),
            ),
          );

      // Characters
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: 'V',
              description: const drift.Value('夜之城传奇佣兵'),
              status: const drift.Value(2),
            ),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(201),
              worldId: 2,
              name: '阿尔萨斯',
              description: const drift.Value('洛丹伦王子与巫妖王'),
              status: const drift.Value(2),
            ),
          );

      // Lore Entity
      await db
          .into(db.loreEntities)
          .insert(
            LoreEntitiesCompanion.insert(
              id: const drift.Value(301),
              worldId: 1,
              entityType: 'location',
              name: '来生来生酒吧',
              summary: const drift.Value('佣兵汇聚的著名地下酒吧'),
              content: const drift.Value(''),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'searchItems with empty query returns static commands and existing worlds',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );

        final dummyRef = _DummyWidgetRef(container);
        final items = await CommandPaletteService.searchItems(dummyRef, '');

        expect(items.isNotEmpty, isTrue);
        // Contains static commands like new world, new character, etc.
        expect(items.any((i) => i.id == 'cmd_new_world'), isTrue);
        expect(items.any((i) => i.id == 'cmd_new_character'), isTrue);
        // Contains worlds
        expect(items.any((i) => i.title == '赛博纪元'), isTrue);
        expect(items.any((i) => i.title == '艾泽拉斯'), isTrue);
        // Contains characters
        expect(items.any((i) => i.title == 'V'), isTrue);
        expect(items.any((i) => i.title == '阿尔萨斯'), isTrue);
      },
    );

    test(
      'searchItems with specific keyword filters and ranks results',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );

        final dummyRef = _DummyWidgetRef(container);

        // Search for character '阿尔萨斯'
        final charResults = await CommandPaletteService.searchItems(
          dummyRef,
          '阿尔萨斯',
        );
        expect(charResults.isNotEmpty, isTrue);
        expect(charResults.first.title, equals('阿尔萨斯'));
        expect(
          charResults.first.category,
          equals(CommandPaletteCategory.character),
        );

        // Search for world '赛博'
        final worldResults = await CommandPaletteService.searchItems(
          dummyRef,
          '赛博',
        );
        expect(worldResults.isNotEmpty, isTrue);
        expect(worldResults.any((i) => i.title == '赛博纪元'), isTrue);

        // Search for lore '酒吧'
        final loreResults = await CommandPaletteService.searchItems(
          dummyRef,
          '酒吧',
        );
        expect(loreResults.isNotEmpty, isTrue);
        expect(loreResults.any((i) => i.title == '来生来生酒吧'), isTrue);

        // Search for command '编年史'
        final cmdResults = await CommandPaletteService.searchItems(
          dummyRef,
          '编年史',
        );
        expect(cmdResults.isNotEmpty, isTrue);
        expect(cmdResults.any((i) => i.id == 'cmd_open_chronicle'), isTrue);
      },
    );
  });

  group('CommandPaletteDialog Widget Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '虚空世界',
              description: const drift.Value('无边宇宙'),
            ),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: '星辰守望者',
              description: const drift.Value('守护星光的英雄'),
              status: const drift.Value(2),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Renders search input, category chips and keyboard navigation',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            activeWorldIdProvider.overrideWith((ref) => 1),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: CommandPaletteDialog()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify header and filter chips render
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byKey(const Key('chip_cat_all')), findsOneWidget);
        expect(find.byKey(const Key('chip_cat_command')), findsOneWidget);
        expect(find.byKey(const Key('chip_cat_world')), findsOneWidget);
        expect(find.byKey(const Key('chip_cat_character')), findsOneWidget);
        expect(find.byKey(const Key('chip_cat_lore')), findsOneWidget);

        // Verify initial items list rendered
        expect(find.text('新建世界观'), findsOneWidget);

        // Test category filter chip tap
        await tester.tap(find.byKey(const Key('chip_cat_world')));
        await tester.pumpAndSettle();

        // Only world items should be displayed
        expect(find.text('虚空世界'), findsOneWidget);
        expect(find.text('新建世界观'), findsNothing);

        // Switch back to all
        await tester.tap(find.byKey(const Key('chip_cat_all')));
        await tester.pumpAndSettle();

        // Test text input search
        await tester.enterText(find.byType(TextField), '星辰');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('星辰守望者'), findsOneWidget);

        // Test empty query result
        await tester.enterText(find.byType(TextField), 'xyznonexistent123');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('未找到匹配的命令或项目'), findsOneWidget);
      },
    );

    testWidgets('ArrowDown, ArrowUp and Escape keys function properly', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeWorldIdProvider.overrideWith((ref) => 1),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showCommandPalette(ctx),
                    child: const Text('Open Palette'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to open palette dialog
      await tester.tap(find.text('Open Palette'));
      await tester.pumpAndSettle();

      expect(find.byType(CommandPaletteDialog), findsOneWidget);

      // Send ArrowDown key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Send ArrowUp key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Send Escape key -> should close dialog
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(CommandPaletteDialog), findsNothing);
    });
  });
}

/// Lightweight mock ref for calling service functions in headless tests
class _DummyWidgetRef implements WidgetRef {
  final ProviderContainer _container;
  _DummyWidgetRef(this._container);

  @override
  BuildContext get context => throw UnimplementedError();

  @override
  bool exists(ProviderBase<Object?> provider) => _container.exists(provider);

  @override
  void invalidate(ProviderOrFamily provider) => _container.invalidate(provider);

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) => _container.listen(provider, listener, onError: onError);

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) => _container.listen(
    provider,
    listener,
    onError: onError,
    fireImmediately: fireImmediately,
  );

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  T refresh<T>(Refreshable<T> provider) => _container.refresh(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => _container.read(provider);
}
