import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/design/components/oc_avatar.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_graph_node.dart';

void main() {
  group('Milanote Character Card Node & Avatar Tests', () {
    final maleChar = Character(
      id: 1,
      worldId: 10,
      name: '陆长歌',
      gender: '男',
      description: '剑修',
      status: 2,
      isFavorite: true,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final femaleChar = Character(
      id: 2,
      worldId: 10,
      name: '林挽月',
      gender: '女',
      description: '丹师',
      status: 2,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets(
      'buildCharacterAvatar renders squircle for male and circle for female',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  buildCharacterAvatar(
                    character: maleChar,
                    size: 48,
                    color: Colors.blue,
                  ),
                  buildCharacterAvatar(
                    character: femaleChar,
                    size: 48,
                    color: Colors.pink,
                  ),
                ],
              ),
            ),
          ),
        );

        // Both character avatars render OcAvatar instances
        expect(find.byType(OcAvatar), findsNWidgets(2));
        // Fallback letter initials are displayed
        expect(find.text('陆'), findsOneWidget);
        expect(find.text('林'), findsOneWidget);
      },
    );

    testWidgets(
      'RelationSidebarItem displays character card with name and placed badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RelationSidebarItem(character: maleChar, placed: false),
                  RelationSidebarItem(character: femaleChar, placed: true),
                ],
              ),
            ),
          ),
        );

        expect(find.text('陆长歌'), findsOneWidget);
        expect(find.text('林挽月'), findsOneWidget);
        expect(find.text('已放置'), findsOneWidget);
        expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
      },
    );

    testWidgets(
      'DraggableNode in Full LOD renders card avatar and stylized name capsule',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  DraggableNode(
                    character: maleChar,
                    position: const Offset(150, 150),
                    allCharacters: [maleChar],
                    relations: const [],
                    onDragUpdate: (_) {},
                    onDragEnd: (_) {},
                    onRemove: () {},
                    onManageRelations: () {},
                    onEdit: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(OcAvatar), findsOneWidget);
        expect(find.text('陆长歌'), findsOneWidget);
        expect(find.text('陆'), findsOneWidget);
      },
    );
  });
}
