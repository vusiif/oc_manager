import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/core/util/wiki_link_parser.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/character_provider.dart';
import 'package:oc_manager/providers/backlink_provider.dart';
import 'package:oc_manager/features/character/character_description_section.dart';

void main() {
  group('WikiLinkParser & Backlinks Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    final charAlice = Character(
      id: 1,
      worldId: 10,
      name: '艾莉丝',
      avatarPath: null,
      gender: '女',
      description: '曾与 [[罗兰]] 一同在极光圣堂受训。',
      status: 0,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final charBob = Character(
      id: 2,
      worldId: 10,
      name: '博尔特',
      avatarPath: null,
      gender: '男',
      description: '追随导师 [[艾莉丝]] 学习魔法，并视 [[罗兰]] 为宿命之敌。',
      status: 0,
      isFavorite: false,
      isPinned: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final charRoland = Character(
      id: 3,
      worldId: 10,
      name: '罗兰',
      avatarPath: null,
      gender: '男',
      description: '孤独的极光圣殿守护者。',
      status: 0,
      isFavorite: true,
      isPinned: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('WikiLinkParser extractTargetNames and hasReferenceTo', () {
      const text =
          '幼年与 [[ 艾莉丝 ]] 和 [[罗兰]] 结伴，后来遇到 [[艾莉丝]] 与 [[  ]] 以及普通文本。';
      final names = WikiLinkParser.extractTargetNames(text);
      expect(names.length, equals(2));
      expect(names, contains('艾莉丝'));
      expect(names, contains('罗兰'));

      expect(WikiLinkParser.hasReferenceTo(text, '艾莉丝'), isTrue);
      expect(WikiLinkParser.hasReferenceTo(text, '罗兰'), isTrue);
      expect(WikiLinkParser.hasReferenceTo(text, '博尔特'), isFalse);
    });

    test('WikiLinkParser extractContextSnippets extracts matching line', () {
      const story = '第一章：启程之日。\n'
          '在风暴席卷之夜，他遇到了神秘的导师 [[艾莉丝]]，两人立下不可违逆的誓约。\n'
          '随后踏上漫长旅途。';

      final snippets = WikiLinkParser.extractContextSnippets(story, '艾莉丝');
      expect(snippets.length, equals(1));
      expect(snippets.first, contains('神秘的导师 [[艾莉丝]]'));
    });

    testWidgets('WikiLinkParser buildWikiSpans creates linked and fallback spans',
        (tester) async {
      final nameMap = {'艾莉丝': charAlice, '罗兰': charRoland};
      const text = '你好 [[艾莉丝]]，还有未知的 [[神秘人]]。';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final spans = WikiLinkParser.buildWikiSpans(
                  text: text,
                  nameToCharacterMap: nameMap,
                  onCharacterTap: (_) {},
                  context: context,
                );
                return RichText(text: TextSpan(children: spans));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证已知角色“艾莉丝”与未知角色“神秘人”均有渲染
      expect(find.text('艾莉丝'), findsOneWidget);
      expect(find.text('神秘人'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('characterBacklinksProvider correctly identifies reverse mentions', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          charactersByWorldProvider(10).overrideWith(
            (ref) => Stream.value([charAlice, charBob, charRoland]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 等待 Stream 发出首轮数据
      await container.read(charactersByWorldProvider(10).future);

      // 查询罗兰被谁引用
      final rolandBacklinks = container.read(
        characterBacklinksProvider(
          const BacklinkQuery(
            worldId: 10,
            characterId: 3,
            characterName: '罗兰',
          ),
        ),
      );

      // 艾莉丝（提到了罗兰）与博尔特（提到了罗兰）
      expect(rolandBacklinks.length, equals(2));
      final sourceNames =
          rolandBacklinks.map((b) => b.sourceCharacter.name).toSet();
      expect(sourceNames.contains('艾莉丝'), isTrue);
      expect(sourceNames.contains('博尔特'), isTrue);
      expect(rolandBacklinks.first.snippets.isNotEmpty, isTrue);

      // 查询艾莉丝被谁引用
      final aliceBacklinks = container.read(
        characterBacklinksProvider(
          const BacklinkQuery(
            worldId: 10,
            characterId: 1,
            characterName: '艾莉丝',
          ),
        ),
      );
      // 只有博尔特提到了艾莉丝
      expect(aliceBacklinks.length, equals(1));
      expect(aliceBacklinks.first.sourceCharacter.name, equals('博尔特'));
    });

    testWidgets('CharacterDescriptionSection renders rich text and backlinks',
        (tester) async {
      // 当前被查看的人物是罗兰（有艾莉丝和博尔特反向引用他）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            charactersByWorldProvider(10).overrideWith(
              (ref) => Stream.value([charAlice, charBob, charRoland]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CharacterDescriptionSection(
                worldId: 10,
                character: charRoland,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证标题与描述内容渲染
      expect(find.text('详细设定与小传'), findsOneWidget);
      expect(find.textContaining('孤独的极光圣殿守护者'), findsOneWidget);

      // 验证反向引用面板（被 2 位角色提及）
      expect(find.textContaining('反向引用 (Backlinks) · 被 2 位角色提及'), findsOneWidget);
      expect(find.text('艾莉丝'), findsOneWidget);
      expect(find.text('博尔特'), findsOneWidget);

      // 切换到编辑模式
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('完成'), findsOneWidget);
      expect(find.text('插入双向链接'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
