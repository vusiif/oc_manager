import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/trash_provider.dart';
import 'package:oc_manager/core/util/color_palette_extractor.dart';

void main() {
  group('CharacterGallery & PaletteExtractor Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('PaletteExtractor toHex formatting', () {
      expect(
        PaletteExtractor.toHex(const Color.fromARGB(255, 255, 0, 128)),
        equals('#FF0080'),
      );
      expect(
        PaletteExtractor.toHex(const Color.fromARGB(255, 0, 255, 0)),
        equals('#00FF00'),
      );
      expect(
        PaletteExtractor.toHex(const Color.fromARGB(255, 46, 64, 87)),
        equals('#2E4057'),
      );
    });

    test('PaletteExtractor handles corrupt or empty bytes gracefully', () async {
      final empty = await PaletteExtractor.extractFromBytes(Uint8List(0));
      expect(empty, isEmpty);

      final corrupt = await PaletteExtractor.extractFromBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(corrupt, isEmpty);
    });

    test('Gallery CRUD & primary avatar synchronization', () async {
      // 1. 创建世界与初始角色
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('画廊测试世界')),
      );
      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: Value('艾丽娅'),
          avatarPath: const Value('avatars/default.png'),
        ),
      );

      // 2. 添加多张立绘差分
      final g1 = await db.characterDao.addGalleryImage(
        CharacterGalleriesCompanion.insert(
          characterId: charId,
          imagePath: 'gallery/char_1_casual.png',
          caption: const Value('常服'),
          sortOrder: const Value(0),
        ),
      );
      final g2 = await db.characterDao.addGalleryImage(
        CharacterGalleriesCompanion.insert(
          characterId: charId,
          imagePath: 'gallery/char_1_battle.png',
          caption: const Value('战斗形态'),
          sortOrder: const Value(1),
        ),
      );
      final g3 = await db.characterDao.addGalleryImage(
        CharacterGalleriesCompanion.insert(
          characterId: charId,
          imagePath: 'gallery/char_1_dress.png',
          caption: const Value('晚礼服'),
          sortOrder: const Value(2),
        ),
      );

      var galleries = await db.characterDao.getCharacterGalleries(charId);
      expect(galleries.length, equals(3));
      expect(galleries[0].caption, equals('常服'));
      expect(galleries[1].caption, equals('战斗形态'));
      expect(galleries[2].caption, equals('晚礼服'));

      // 3. 设 g2（战斗形态）为主立绘
      await db.characterDao.setPrimaryGalleryImage(charId, g2);

      // 验证 g2 为 primary，其他均为 false
      galleries = await db.characterDao.getCharacterGalleries(charId);
      final item1 = galleries.firstWhere((g) => g.id == g1);
      final item2 = galleries.firstWhere((g) => g.id == g2);
      final item3 = galleries.firstWhere((g) => g.id == g3);

      expect(item1.isPrimary, isFalse);
      expect(item2.isPrimary, isTrue);
      expect(item3.isPrimary, isFalse);

      // 验证人物主表 avatarPath 同步变更为战斗形态立绘
      final character = await db.characterDao.getCharacterById(charId);
      expect(character.avatarPath, equals('gallery/char_1_battle.png'));

      // 4. 更新备注与删除单项
      await db.characterDao.updateGalleryImage(
        item3.toCompanion(true).copyWith(caption: const Value('皇家典雅礼服')),
      );
      galleries = await db.characterDao.getCharacterGalleries(charId);
      expect(galleries.firstWhere((g) => g.id == g3).caption, equals('皇家典雅礼服'));

      await db.characterDao.deleteGalleryImage(g1);
      galleries = await db.characterDao.getCharacterGalleries(charId);
      expect(galleries.length, equals(2));
      expect(galleries.any((g) => g.id == g1), isFalse);
    });

    test('Trash cascade snapshot & restore preserves all gallery items', () async {
      // 1. 创建世界与带画廊立绘的角色
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('回收站画廊世界')),
      );
      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: Value('法师梅林'),
        ),
      );

      await db.characterDao.addGalleryImage(
        CharacterGalleriesCompanion.insert(
          characterId: charId,
          imagePath: 'gallery/char_merlin_robe.png',
          caption: const Value('法师长袍'),
          isPrimary: const Value(true),
        ),
      );
      await db.characterDao.addGalleryImage(
        CharacterGalleriesCompanion.insert(
          characterId: charId,
          imagePath: 'gallery/char_merlin_young.png',
          caption: const Value('青年时期'),
          isPrimary: const Value(false),
        ),
      );

      final character = await db.characterDao.getCharacterById(charId);
      final beforeDeleteGalleries = await db.characterDao.getCharacterGalleries(charId);
      expect(beforeDeleteGalleries.length, equals(2));

      // 2. 软删除角色到回收站
      final trashActions = container.read(trashActionsProvider);
      await trashActions.deleteCharacter(character);

      // 验证画廊子表已清空
      final afterDeleteGalleries = await db.characterDao.getCharacterGalleries(charId);
      expect(afterDeleteGalleries.isEmpty, isTrue);

      final trashList = await db.trashDao.getAllTrash();
      expect(trashList.length, equals(1));
      final trashItem = trashList.first;
      expect(trashItem.itemData.contains('"galleries"'), isTrue);
      expect(trashItem.itemData.contains('法师长袍'), isTrue);
      expect(trashItem.itemData.contains('青年时期'), isTrue);

      // 3. 从回收站恢复角色
      await trashActions.restoreCharacter(trashItem);

      // 验证画廊立绘全部 100% 等价恢复
      final restoredGalleries = await db.characterDao.getCharacterGalleries(charId);
      expect(restoredGalleries.length, equals(2));
      expect(restoredGalleries[0].imagePath, equals(beforeDeleteGalleries[0].imagePath));
      expect(restoredGalleries[0].caption, equals(beforeDeleteGalleries[0].caption));
      expect(restoredGalleries[0].isPrimary, equals(beforeDeleteGalleries[0].isPrimary));

      expect(restoredGalleries[1].imagePath, equals(beforeDeleteGalleries[1].imagePath));
      expect(restoredGalleries[1].caption, equals(beforeDeleteGalleries[1].caption));
      expect(restoredGalleries[1].isPrimary, equals(beforeDeleteGalleries[1].isPrimary));
    });
  });
}
