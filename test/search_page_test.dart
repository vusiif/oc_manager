import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/search/search_page.dart';
import 'package:oc_manager/providers/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Search Tests (P1-03)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // World 1
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(id: const drift.Value(1), name: '赛博纪元'),
          );

      // World 2
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(id: const drift.Value(2), name: '魔法异界'),
          );

      // Characters
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: 'V',
              description: const drift.Value('夜之城最顶尖的传奇独狼佣兵'),
              status: const drift.Value(2), // 已定稿
            ),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(102),
              worldId: 1,
              name: '强尼·银手',
              description: const drift.Value('武侍乐队主唱'),
              status: const drift.Value(1), // 构思草稿
            ),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(201),
              worldId: 2,
              name: '梅林',
              description: const drift.Value('古代最伟大的魔法使'),
              status: const drift.Value(2), // 已定稿
            ),
          );

      // Custom fields
      await db
          .into(db.characterFields)
          .insert(
            CharacterFieldsCompanion.insert(
              characterId: 101,
              fieldName: '所属流派',
              fieldType: 'text',
              value: const drift.Value('潜行黑客'),
            ),
          );

      // Tags
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: const drift.Value(1),
              name: '斯安威斯坦',
              color: '#FF0000',
            ),
          );
      await db
          .into(db.characterTags)
          .insert(CharacterTagsCompanion.insert(characterId: 101, tagId: 1));

      // Groups
      await db
          .into(db.groups)
          .insert(
            GroupsCompanion.insert(
              id: const drift.Value(1),
              worldId: 1,
              name: '来生来客',
            ),
          );
      await db
          .into(db.characterGroups)
          .insert(
            CharacterGroupsCompanion.insert(characterId: 102, groupId: 1),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'searchCharactersDeep matches by name, description, custom field, tag, and group',
      () async {
        // 1. Match by name
        final nameResults = await db.characterDao.searchCharactersDeep('梅林');
        expect(nameResults.length, equals(1));
        expect(nameResults.first.character.id, equals(201));
        expect(nameResults.first.matchedField, equals('角色姓名'));

        // 2. Match by description
        final descResults = await db.characterDao.searchCharactersDeep('独狼佣兵');
        expect(descResults.length, equals(1));
        expect(descResults.first.character.id, equals(101));
        expect(descResults.first.matchedField, equals('人设小传'));

        // 3. Match by custom field
        final fieldResults = await db.characterDao.searchCharactersDeep('潜行黑客');
        expect(fieldResults.length, equals(1));
        expect(fieldResults.first.character.id, equals(101));
        expect(fieldResults.first.matchedField, contains('所属流派'));

        // 4. Match by tag
        final tagResults = await db.characterDao.searchCharactersDeep('斯安威斯坦');
        expect(tagResults.length, equals(1));
        expect(tagResults.first.character.id, equals(101));
        expect(tagResults.first.matchedField, equals('所属标签'));

        // 5. Match by group
        final groupResults = await db.characterDao.searchCharactersDeep('来生来客');
        expect(groupResults.length, equals(1));
        expect(groupResults.first.character.id, equals(102));
        expect(groupResults.first.matchedField, equals('组织阵营'));
      },
    );

    test(
      'searchCharactersDeep filters by worldId and status correctly',
      () async {
        // Search '已定稿' status in World 1
        final w1FinalResults = await db.characterDao.searchCharactersDeep(
          '的',
          worldId: 1,
          status: 2, // 已定稿
        );
        // V is status 2 in World 1; Johnny is status 1 in World 1; Merlin is status 2 in World 2.
        expect(w1FinalResults.length, equals(1));
        expect(w1FinalResults.first.character.name, equals('V'));

        // Search '已定稿' status in World 2
        final w2FinalResults = await db.characterDao.searchCharactersDeep(
          '的',
          worldId: 2,
          status: 2,
        );
        expect(w2FinalResults.length, equals(1));
        expect(w2FinalResults.first.character.name, equals('梅林'));
      },
    );

    testWidgets('SearchPage renders input, filter chips and updates results', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search input exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('世界观：'), findsOneWidget);
      expect(find.text('状态：'), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byType(TextField), '梅林');

      // Wait for debounce timer (250ms)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify search result appears
      final resultTile = find.byType(ListTile);
      expect(resultTile, findsOneWidget);
      expect(
        find.descendant(of: resultTile, matching: find.text('魔法异界')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: resultTile, matching: find.text('角色姓名')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: resultTile, matching: find.text('已定稿')),
        findsOneWidget,
      );
    });
  });
}
