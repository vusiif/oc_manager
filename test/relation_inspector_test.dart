import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/widgets/relation_connection_helper.dart';
import 'package:oc_manager/features/relation/widgets/relation_inspector_panel.dart';

void main() {
  group('RelationInspectorPanel Widget Tests', () {
    final charA = Character(
      id: 1,
      worldId: 10,
      name: '陆长歌',
      gender: '男',
      description: '',
      status: 2,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final charB = Character(
      id: 2,
      worldId: 10,
      name: '林挽月',
      gender: '女',
      description: '',
      status: 2,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final testRel = Relation(
      id: 99,
      fromCharacterId: 1,
      toCharacterId: 2,
      relationType: '朋友',
      isBidirectional: true,
      note: '青梅竹马',
      relationGroupId: null,
    );

    testWidgets('renders relation details, endpoints, quick types, and note', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationInspectorPanel(
              relation: testRel,
              fromCharacter: charA,
              toCharacter: charB,
              onClose: () {},
              onOpenFullDialog: () {},
              onUpdateRelation: (rel, desc) {},
              onDeleteRelation: () {},
            ),
          ),
        ),
      );

      // Verify title and chips
      expect(find.text('朋友'), findsWidgets);
      expect(find.text('双向'), findsOneWidget);
      expect(find.text('陆长歌'), findsOneWidget);
      expect(find.text('林挽月'), findsOneWidget);
      expect(find.text('青梅竹马'), findsOneWidget);

      // Verify quick type options
      expect(find.text('恋人'), findsOneWidget);
      expect(find.text('敌对'), findsOneWidget);
      expect(find.text('师徒'), findsOneWidget);
    });

    testWidgets(
      'tapping quick type chip triggers onUpdateRelation with new type',
      (tester) async {
        Relation? updatedRelation;
        String? updateDesc;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RelationInspectorPanel(
                relation: testRel,
                fromCharacter: charA,
                toCharacter: charB,
                onClose: () {},
                onOpenFullDialog: () {},
                onUpdateRelation: (newRel, desc) {
                  updatedRelation = newRel;
                  updateDesc = desc;
                },
                onDeleteRelation: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('恋人'));
        await tester.pumpAndSettle();

        expect(updatedRelation, isNotNull);
        expect(updatedRelation!.relationType, equals('恋人'));
        expect(updateDesc, contains('恋人'));
      },
    );

    testWidgets('direction button toggles bidirectional to directed', (
      tester,
    ) async {
      Relation? updatedRelation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationInspectorPanel(
              relation: testRel,
              fromCharacter: charA,
              toCharacter: charB,
              onClose: () {},
              onOpenFullDialog: () {},
              onUpdateRelation: (newRel, _) {
                updatedRelation = newRel;
              },
              onDeleteRelation: () {},
            ),
          ),
        ),
      );

      // Tap direction icon (swap_horiz)
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(updatedRelation, isNotNull);
      expect(updatedRelation!.isBidirectional, isFalse);
    });

    testWidgets('close and delete triggers appropriate callbacks', (
      tester,
    ) async {
      bool closed = false;
      bool deleted = false;
      bool fullOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelationInspectorPanel(
              relation: testRel,
              fromCharacter: charA,
              toCharacter: charB,
              onClose: () => closed = true,
              onOpenFullDialog: () => fullOpened = true,
              onUpdateRelation: (rel, desc) {},
              onDeleteRelation: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);

      await tester.tap(find.byIcon(Icons.tune));
      expect(fullOpened, isTrue);
    });

    test(
      'RelationConnectionHelper.hitTestRelation detects label and line segment',
      () {
        final relations = [testRel];
        final positions = {
          1: const Offset(100, 100),
          2: const Offset(300, 100),
        };

        // Tap midpoint (200, 100) on the line segment
        final hitId = RelationConnectionHelper.hitTestRelation(
          tapPos: const Offset(200, 104),
          relations: relations,
          positions: positions,
        );

        expect(hitId, equals(99));

        // Tap far away (200, 400)
        final missId = RelationConnectionHelper.hitTestRelation(
          tapPos: const Offset(200, 400),
          relations: relations,
          positions: positions,
        );

        expect(missId, isNull);
      },
    );
  });
}
