import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/trash_provider.dart';
import 'package:oc_manager/providers/character_provider.dart';

void main() {
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

  group('World Isolation Tests (B-02)', () {
    test('Cross-world character group assignment should be rejected', () async {
      // 1. 创建世界观 1 与分组 1
      final world1Id = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '世界观 A'),
          );
      final group1Id = await db.into(db.groups).insert(
            GroupsCompanion.insert(worldId: world1Id, name: '王国骑士团'),
          );

      // 2. 创建世界观 2 与角色 2
      final world2Id = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '世界观 B'),
          );
      final char2Id = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: world2Id,
              name: '跨界旅人',
            ),
          );

      // 3. 尝试将世界观 2 的角色添加到世界观 1 的分组
      expect(
        () => db.groupDao.addCharacterToGroup(char2Id, group1Id),
        throwsA(isA<ArgumentError>()),
      );

      // 4. 正确情况：世界观 1 的角色添加到世界观 1 的分组
      final char1Id = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: world1Id,
              name: '本地骑士',
            ),
          );
      await db.groupDao.addCharacterToGroup(char1Id, group1Id);
      final memberIds = await db.groupDao.getCharacterIdsByGroup(group1Id);
      expect(memberIds, contains(char1Id));
    });
  });

  group('Full Relational Trash Tests (D-02)', () {
    test('Soft delete character and restore with fields, tags, and groups intact',
        () async {
      final trashActions = container.read(trashActionsProvider);

      // 1. 准备基础数据：世界观、分组、标签
      final worldId = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '奇幻大陆'),
          );
      final groupId = await db.into(db.groups).insert(
            GroupsCompanion.insert(worldId: worldId, name: '主角队'),
          );
      final tagId = await db.into(db.tags).insert(
            TagsCompanion.insert(name: '法师', color: 'blue'),
          );

      // 2. 创建角色
      final charId = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: worldId,
              name: '艾丽娅',
              gender: const Value('女'),
              description: const Value('天才魔法使'),
            ),
          );

      // 3. 添加自定义字段、分组与标签
      await db.into(db.characterFields).insert(
            CharacterFieldsCompanion.insert(
              characterId: charId,
              fieldName: '魔力值',
              fieldType: '数字',
              value: const Value('9999'),
            ),
          );
      await db.groupDao.addCharacterToGroup(charId, groupId);
      await db.into(db.characterTags).insert(
            CharacterTagsCompanion.insert(
              characterId: charId,
              tagId: tagId,
            ),
          );
      await db.into(db.graphLayouts).insert(
            GraphLayoutsCompanion.insert(
              worldId: worldId,
              characterId: charId,
              x: const Value(120.0),
              y: const Value(240.0),
            ),
          );

      // 4. 获取创建好的完整角色对象
      final character = await db.characterDao.getCharacterById(charId);

      // 5. 软删除角色存入回收站
      await trashActions.deleteCharacter(character);

      // 验证原表中该角色与子表关联均已被安全清理
      final remainingChars =
          await db.characterDao.getCharactersByWorld(worldId);
      expect(remainingChars, isEmpty);
      final remainingFields =
          await db.characterDao.getCharacterFields(charId);
      expect(remainingFields, isEmpty);

      // 验证回收站中有 1 项记录
      final trashList = await db.trashDao.getAllTrash();
      expect(trashList.length, equals(1));
      expect(trashList.first.itemType, equals('character'));

      // 6. 从回收站恢复该角色
      await trashActions.restoreCharacter(trashList.first);

      // 7. 断言恢复后所有数据完整性
      final restoredChar = await db.characterDao.getCharacterById(charId);
      expect(restoredChar.name, equals('艾丽娅'));
      expect(restoredChar.gender, equals('女'));
      expect(restoredChar.description, equals('天才魔法使'));

      // 验证自定义字段完全等价恢复
      final restoredFields =
          await db.characterDao.getCharacterFields(charId);
      expect(restoredFields.length, equals(1));
      expect(restoredFields.first.fieldName, equals('魔力值'));
      expect(restoredFields.first.value, equals('9999'));

      // 验证所属分组等价恢复
      final restoredGroupIds =
          await db.groupDao.getGroupIdsByCharacter(charId);
      expect(restoredGroupIds, contains(groupId));

      // 验证画布坐标等价恢复
      final restoredLayout = await (db.select(db.graphLayouts)
            ..where((l) => l.characterId.equals(charId)))
          .getSingle();
      expect(restoredLayout.x, equals(120.0));
      expect(restoredLayout.y, equals(240.0));

      // 验证回收站已被清空
      final emptyTrashList = await db.trashDao.getAllTrash();
      expect(emptyTrashList, isEmpty);
    });

    test('toggleFavorite and togglePin should NEVER erase gender or description', () async {
      final worldId = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '测试世界观'),
          );
      final charId = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: worldId,
              name: '英雄',
              gender: const Value('男'),
              description: const Value('背负拯救世界的命运'),
              isFavorite: const Value(false),
              isPinned: const Value(false),
            ),
          );

      final char = await db.characterDao.getCharacterById(charId);
      final charActions = container.read(characterActionsProvider);

      // 切换收藏
      await charActions.toggleFavorite(char);
      var updated = await db.characterDao.getCharacterById(charId);
      expect(updated.isFavorite, isTrue);
      expect(updated.gender, equals('男'), reason: 'Gender must not be wiped by toggleFavorite');
      expect(updated.description, equals('背负拯救世界的命运'), reason: 'Description must not be wiped by toggleFavorite');

      // 切换置顶
      await charActions.togglePin(updated);
      updated = await db.characterDao.getCharacterById(charId);
      expect(updated.isPinned, isTrue);
      expect(updated.gender, equals('男'), reason: 'Gender must not be wiped by togglePin');
      expect(updated.description, equals('背负拯救世界的命运'), reason: 'Description must not be wiped by togglePin');
    });

    test('deleteCharacter succeeds even when multiple legacy duplicate layout rows exist', () async {
      final worldId = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '布局测试世界'),
          );
      final charId = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: worldId,
              name: '旅行者',
            ),
          );

      // 模拟历史上遗留的多个重复布局行
      await db.into(db.graphLayouts).insert(
            GraphLayoutsCompanion.insert(worldId: worldId, characterId: charId, x: const Value(10.0), y: const Value(20.0)),
          );
      await db.into(db.graphLayouts).insert(
            GraphLayoutsCompanion.insert(worldId: worldId, characterId: charId, x: const Value(15.0), y: const Value(25.0)),
          );
      await db.into(db.graphLayouts).insert(
            GraphLayoutsCompanion.insert(worldId: worldId, characterId: charId, x: const Value(30.0), y: const Value(40.0)),
          );

      final char = await db.characterDao.getCharacterById(charId);
      final trashActions = container.read(trashActionsProvider);

      // 软删除该角色：不会因 getSingleOrNull 触发 StateError: Too many elements
      await trashActions.deleteCharacter(char);

      final trashList = await db.trashDao.getAllTrash();
      expect(trashList.length, equals(1));
    });

    test('saveLayout is strictly idempotent and deduplicates rows', () async {
      final worldId = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '幂等世界'),
          );
      final charId = 888;

      final trashDao = container.read(trashDaoProvider);

      // 连续保存 3 次坐标（模拟连续拖拽）
      await trashDao.saveLayout(GraphLayoutsCompanion(
        worldId: Value(worldId),
        characterId: Value(charId),
        x: const Value(100.0),
        y: const Value(200.0),
      ));
      await trashDao.saveLayout(GraphLayoutsCompanion(
        worldId: Value(worldId),
        characterId: Value(charId),
        x: const Value(150.0),
        y: const Value(250.0),
      ));
      await trashDao.saveLayout(GraphLayoutsCompanion(
        worldId: Value(worldId),
        characterId: Value(charId),
        x: const Value(300.0),
        y: const Value(400.0),
      ));

      // 验证数据库中仅有 1 行记录，且值为最新坐标
      final rows = await (db.select(db.graphLayouts)
            ..where((l) => l.characterId.equals(charId)))
          .get();
      expect(rows.length, equals(1));
      expect(rows.first.x, equals(300.0));
      expect(rows.first.y, equals(400.0));
    });

    test('restoreCharacter succeeds gracefully without FOREIGN KEY crash even if original world is deleted', () async {
      // 1. 创建世界与人物
      final origWorldId = await db.into(db.worlds).insert(
            WorldsCompanion.insert(name: '即将覆灭的古纪元'),
          );
      final charId = await db.into(db.characters).insert(
            CharactersCompanion.insert(
              worldId: origWorldId,
              name: '流浪遗民',
              gender: const Value('男'),
            ),
          );

      final character = await db.characterDao.getCharacterById(charId);
      final trashActions = container.read(trashActionsProvider);

      // 2. 软删除该角色
      await trashActions.deleteCharacter(character);
      final trashRows = await db.trashDao.getAllTrash();
      expect(trashRows.length, equals(1));

      // 3. 模拟极端情况：将原世界彻底从数据库物理删除
      await (db.delete(db.worlds)..where((w) => w.id.equals(origWorldId))).go();

      // 4. 尝试恢复该孤儿角色：绝不应抛出 SQLite FOREIGN KEY 崩溃！
      await expectLater(trashActions.restoreCharacter(trashRows.first), completes);

      // 5. 验证角色已成功复活并自动降级收纳到了新分配的世界
      final restoredChar = await (db.select(db.characters)..where((c) => c.id.equals(charId))).getSingle();
      expect(restoredChar.name, equals('流浪遗民'));
      expect(restoredChar.worldId, isNot(equals(origWorldId)));
    });
  });
}
