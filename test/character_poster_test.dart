import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/features/character/character_poster_dialog.dart';

void main() {
  group('CharacterPoster Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    final testCharacter = Character(
      id: 1,
      worldId: 10,
      name: '极光骑士罗兰',
      avatarPath: null,
      gender: '男',
      description: '“只要极光仍在天穹闪烁，正义便永不熄灭。”\n罗兰出生于极光圣堂，是帝国第七骑士团的统领。',
      status: 0,
      isFavorite: true,
      isPinned: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('PosterThemeType enumeration integrity', () {
      expect(PosterThemeType.values.length, equals(4));
      expect(PosterThemeType.magazine.label, equals('现代杂志风'));
      expect(PosterThemeType.parchment.label, equals('古典传奇风'));
      expect(PosterThemeType.cyber.label, equals('赛博霓虹风'));
      expect(PosterThemeType.dossier.label, equals('绝密档案风'));
    });

    testWidgets('CharacterPosterCard renders in all 4 visual themes without overflow',
        (WidgetTester tester) async {
      // 插入测试世界
      await db.worldDao.createWorld(
        const WorldsCompanion(id: Value(10), name: Value('极光圣域')),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CharacterPosterDialog(
                character: testCharacter,
                worldId: 10,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证标题与基本信息渲染
      expect(find.textContaining('极光骑士罗兰'), findsWidgets);
      expect(find.text('导出 PNG 海报'), findsOneWidget);
      expect(find.text('排版视觉风格'), findsOneWidget);

      // 切换风格并验证
      await tester.tap(find.text('古典传奇风'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('赛博霓虹风'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('绝密档案风'));
      await tester.pumpAndSettle();

      // 卸载 Widget 树
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

