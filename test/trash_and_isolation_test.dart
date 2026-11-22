import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('World Isolation Tests (B-02)', () {
    test('Cross-world character group assignment should be rejected', () async {
      // 1. 创建世界观 1 与分组 1
      final world1Id = await db
          .into(db.worlds)
          .insert(WorldsCompanion.insert(name: '世界观 A'));
      final group1Id = await db
          .into(db.groups)
          .insert(GroupsCompanion.insert(worldId: world1Id, name: '王国骑士团'));

      // 2. 创建世界观 2 与角色 2
      final world2Id = await db
          .into(db.worlds)
          .insert(WorldsCompanion.insert(name: '世界观 B'));
      final char2Id = await db
          .into(db.characters)
          .insert(CharactersCompanion.insert(worldId: world2Id, name: '跨界旅人'));

      // 3. 尝试将世界观 2 的角色添加到世界观 1 的分组
      expect(
        () => db.groupDao.addCharacterToGroup(char2Id, group1Id),
        throwsA(isA<ArgumentError>()),
      );

      // 4. 正确情况：世界观 1 的角色添加到世界观 1 的分组
      final char1Id = await db
          .into(db.characters)
          .insert(CharactersCompanion.insert(worldId: world1Id, name: '本地骑士'));
      await db.groupDao.addCharacterToGroup(char1Id, group1Id);
      final memberIds = await db.groupDao.getCharacterIdsByGroup(group1Id);
      expect(memberIds, contains(char1Id));
    });
  });

  group('Full Relational Trash Tests (D-02)', () {
    test(
      'Soft delete character and restore with fields, tags, and groups intact',
      () async {
        final trashActions = container.read(trashActionsProvider);

        // 1. 准备基础数据：世界观、分组、标签
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '奇幻大陆'));
        final groupId = await db
            .into(db.groups)
            .insert(GroupsCompanion.insert(worldId: worldId, name: '主角队'));
        final tagId = await db
            .into(db.tags)
            .insert(TagsCompanion.insert(name: '法师', color: 'blue'));

        // 2. 创建角色
        final charId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(
                worldId: worldId,
                name: '艾丽娅',
                gender: const Value('女'),
                description: const Value('天才魔法使'),
              ),
            );

        // 3. 添加自定义字段、分组与标签
        await db
            .into(db.characterFields)
            .insert(
              CharacterFieldsCompanion.insert(
                characterId: charId,
                fieldName: '魔力值',
                fieldType: '数字',
                value: const Value('9999'),
              ),
            );
        await db.groupDao.addCharacterToGroup(charId, groupId);
        await db
            .into(db.characterTags)
            .insert(
              CharacterTagsCompanion.insert(characterId: charId, tagId: tagId),
            );
        await db
            .into(db.graphLayouts)
            .insert(
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
        final remainingChars = await db.characterDao.getCharactersByWorld(
          worldId,
        );
        expect(remainingChars, isEmpty);
        final remainingFields = await db.characterDao.getCharacterFields(
          charId,
        );
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
        final restoredFields = await db.characterDao.getCharacterFields(charId);
        expect(restoredFields.length, equals(1));
        expect(restoredFields.first.fieldName, equals('魔力值'));
        expect(restoredFields.first.value, equals('9999'));

        // 验证所属分组等价恢复
        final restoredGroupIds = await db.groupDao.getGroupIdsByCharacter(
          charId,
        );
        expect(restoredGroupIds, contains(groupId));

        // 验证画布坐标等价恢复
        final restoredLayout = await (db.select(
          db.graphLayouts,
        )..where((l) => l.characterId.equals(charId))).getSingle();
        expect(restoredLayout.x, equals(120.0));
        expect(restoredLayout.y, equals(240.0));

        // 验证回收站已被清空
        final emptyTrashList = await db.trashDao.getAllTrash();
        expect(emptyTrashList, isEmpty);
      },
    );

    test(
      'toggleFavorite and togglePin should NEVER erase gender or description',
      () async {
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '测试世界观'));
        final charId = await db
            .into(db.characters)
            .insert(
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
        expect(
          updated.gender,
          equals('男'),
          reason: 'Gender must not be wiped by toggleFavorite',
        );
        expect(
          updated.description,
          equals('背负拯救世界的命运'),
          reason: 'Description must not be wiped by toggleFavorite',
        );

        // 切换置顶
        await charActions.togglePin(updated);
        updated = await db.characterDao.getCharacterById(charId);
        expect(updated.isPinned, isTrue);
        expect(
          updated.gender,
          equals('男'),
          reason: 'Gender must not be wiped by togglePin',
        );
        expect(
          updated.description,
          equals('背负拯救世界的命运'),
          reason: 'Description must not be wiped by togglePin',
        );
      },
    );

    test(
      'deleteCharacter succeeds even when multiple legacy duplicate layout rows exist',
      () async {
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '布局测试世界'));
        final charId = await db
            .into(db.characters)
            .insert(CharactersCompanion.insert(worldId: worldId, name: '旅行者'));

        // 模拟历史上遗留的多个重复布局行
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: worldId,
                characterId: charId,
                x: const Value(10.0),
                y: const Value(20.0),
              ),
            );
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: worldId,
                characterId: charId,
                x: const Value(15.0),
                y: const Value(25.0),
              ),
            );
        await db
            .into(db.graphLayouts)
            .insert(
              GraphLayoutsCompanion.insert(
                worldId: worldId,
                characterId: charId,
                x: const Value(30.0),
                y: const Value(40.0),
              ),
            );

        final char = await db.characterDao.getCharacterById(charId);
        final trashActions = container.read(trashActionsProvider);

        // 软删除该角色：不会因 getSingleOrNull 触发 StateError: Too many elements
        await trashActions.deleteCharacter(char);

        final trashList = await db.trashDao.getAllTrash();
        expect(trashList.length, equals(1));
      },
    );

    test('saveLayout is strictly idempotent and deduplicates rows', () async {
      final worldId = await db
          .into(db.worlds)
          .insert(WorldsCompanion.insert(name: '幂等世界'));
      final charId = 888;

      final trashDao = container.read(trashDaoProvider);

      // 连续保存 3 次坐标（模拟连续拖拽）
      await trashDao.saveLayout(
        GraphLayoutsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          x: const Value(100.0),
          y: const Value(200.0),
        ),
      );
      await trashDao.saveLayout(
        GraphLayoutsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          x: const Value(150.0),
          y: const Value(250.0),
        ),
      );
      await trashDao.saveLayout(
        GraphLayoutsCompanion(
          worldId: Value(worldId),
          characterId: Value(charId),
          x: const Value(300.0),
          y: const Value(400.0),
        ),
      );

      // 验证数据库中仅有 1 行记录，且值为最新坐标
      final rows = await (db.select(
        db.graphLayouts,
      )..where((l) => l.characterId.equals(charId))).get();
      expect(rows.length, equals(1));
      expect(rows.first.x, equals(300.0));
      expect(rows.first.y, equals(400.0));
    });

    test(
      'restoreCharacter succeeds gracefully without FOREIGN KEY crash even if original world is deleted',
      () async {
        // 1. 创建世界与人物
        final origWorldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '即将覆灭的古纪元'));
        final charId = await db
            .into(db.characters)
            .insert(
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
        await (db.delete(
          db.worlds,
        )..where((w) => w.id.equals(origWorldId))).go();

        // 4. 尝试恢复该孤儿角色：绝不应抛出 SQLite FOREIGN KEY 崩溃！
        await expectLater(
          trashActions.restoreCharacter(trashRows.first),
          completes,
        );

        // 5. 验证角色已成功复活并自动降级收纳到了新分配的世界
        final restoredChar = await (db.select(
          db.characters,
        )..where((c) => c.id.equals(charId))).getSingle();
        expect(restoredChar.name, equals('流浪遗民'));
        expect(restoredChar.worldId, isNot(equals(origWorldId)));
      },
    );

    test(
      'P0-03: Soft delete character snapshots relations and self-heals connections upon restore',
      () async {
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '关系恢复世界'));

        final charAId = await db
            .into(db.characters)
            .insert(CharactersCompanion.insert(worldId: worldId, name: '英雄 A'));
        final charBId = await db
            .into(db.characters)
            .insert(CharactersCompanion.insert(worldId: worldId, name: '劲敌 B'));
        final charCId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(worldId: worldId, name: '契约者 C'),
            );

        // Create relations
        await db
            .into(db.relations)
            .insert(
              RelationsCompanion.insert(
                fromCharacterId: charAId,
                toCharacterId: charBId,
                relationType: '宿敌',
                note: const Value('宿命对决'),
                isBidirectional: const Value(true),
              ),
            );

        await db
            .into(db.relations)
            .insert(
              RelationsCompanion.insert(
                fromCharacterId: charCId,
                toCharacterId: charAId,
                relationType: '守护契约',
                note: const Value('生命守护'),
                isBidirectional: const Value(false),
                relationGroupId: const Value('relgrp_guard_007'),
              ),
            );

        final charA = await db.characterDao.getCharacterById(charAId);
        final trashActions = container.read(trashActionsProvider);

        // 1. Soft delete character A
        await trashActions.deleteCharacter(charA);

        // Verify character A is removed and relations are purged from active DB
        final activeChars = await db.characterDao.getCharactersByWorld(worldId);
        expect(activeChars.any((c) => c.id == charAId), isFalse);

        final activeRels = await db.relationDao.getRelationsByWorld(worldId);
        expect(
          activeRels,
          isEmpty,
          reason:
              'All active relations involving A must be removed upon soft-delete',
        );

        // Verify trash snapshot has relations recorded
        final trashRows = await db.trashDao.getAllTrash();
        expect(trashRows.length, equals(1));

        // 2. Restore character A
        await trashActions.restoreCharacter(trashRows.first);

        // Verify character A restored
        final restoredA = await db.characterDao.getCharacterById(charAId);
        expect(restoredA.name, equals('英雄 A'));

        // Verify relations are self-healed and restored with full fidelity
        final restoredRels = await db.relationDao.getRelationsByWorld(worldId);
        expect(restoredRels.length, equals(2));

        final abRel = restoredRels.firstWhere(
          (r) => r.fromCharacterId == charAId && r.toCharacterId == charBId,
        );
        expect(abRel.relationType, equals('宿敌'));
        expect(abRel.note, equals('宿命对决'));
        expect(abRel.isBidirectional, isTrue);

        final caRel = restoredRels.firstWhere(
          (r) => r.fromCharacterId == charCId && r.toCharacterId == charAId,
        );
        expect(caRel.relationType, equals('守护契约'));
        expect(caRel.note, equals('生命守护'));
        expect(caRel.isBidirectional, isFalse);
        expect(caRel.relationGroupId, equals('relgrp_guard_007'));
      },
    );

    test(
      'P0-03: Restoring character gracefully skips relations if peer character has been permanently removed',
      () async {
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '孤儿关系容错世界'));

        final charAId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(worldId: worldId, name: '幸存者 A'),
            );
        final charBId = await db
            .into(db.characters)
            .insert(
              CharactersCompanion.insert(worldId: worldId, name: '已逝同伴 B'),
            );

        await db
            .into(db.relations)
            .insert(
              RelationsCompanion.insert(
                fromCharacterId: charAId,
                toCharacterId: charBId,
                relationType: '同伴',
                note: const Value('生死相托'),
              ),
            );

        final charA = await db.characterDao.getCharacterById(charAId);
        final trashActions = container.read(trashActionsProvider);

        // 1. Soft delete character A
        await trashActions.deleteCharacter(charA);
        final trashRows = await db.trashDao.getAllTrash();
        expect(trashRows.length, equals(1));

        // 2. Permanently delete peer character B from database
        await (db.delete(
          db.characters,
        )..where((c) => c.id.equals(charBId))).go();

        // 3. Restore character A: must complete without foreign key exception!
        await expectLater(
          trashActions.restoreCharacter(trashRows.first),
          completes,
        );

        // Verify character A is alive and dead relation was skipped
        final restoredA = await db.characterDao.getCharacterById(charAId);
        expect(restoredA.name, equals('幸存者 A'));

        final rels = await db.relationDao.getRelationsByWorld(worldId);
        expect(
          rels,
          isEmpty,
          reason:
              'Dead relation to permanently deleted peer B must be skipped safely',
        );
      },
    );

    test(
      'Soft delete world cascades lore entities and revisions, and restores them completely (COR-01)',
      () async {
        final trashActions = container.read(trashActionsProvider);

        // 1. Setup world, lore, and revision
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '神话纪元'));
        final loreId = await db
            .into(db.loreEntities)
            .insert(
              LoreEntitiesCompanion.insert(
                worldId: worldId,
                name: '世界之树',
                entityType: 'location',
                summary: const Value('贯通九界的巨树'),
                content: const Value('位于世界中枢的核心圣地。'),
              ),
            );
        await db
            .into(db.entityRevisions)
            .insert(
              EntityRevisionsCompanion.insert(
                worldId: worldId,
                entityType: 'lore',
                entityId: loreId,
                title: const Value('初始神话草案'),
                content: '最初的设定记载',
              ),
            );

        final world = await db.worldDao.getWorldById(worldId);

        // 2. Soft delete world
        await trashActions.deleteWorld(world);

        // 3. Verify database tables are completely clean (no orphan lores or revisions!)
        final remainingLores = await db.loreDao.getEntitiesByWorld(worldId);
        final remainingRevs = await (db.select(
          db.entityRevisions,
        )..where((r) => r.worldId.equals(worldId))).get();
        final remainingWorlds = await db.worldDao.getAllWorlds();

        expect(
          remainingLores,
          isEmpty,
          reason:
              'All lore entities must be cleaned from active table on soft delete',
        );
        expect(
          remainingRevs,
          isEmpty,
          reason:
              'All revisions must be cleaned from active table on soft delete',
        );
        expect(remainingWorlds.where((w) => w.id == worldId), isEmpty);

        // 4. Verify trash entry contains full snapshot
        final trashList = await db.trashDao.getAllTrash();
        expect(trashList.length, equals(1));
        expect(trashList.first.itemType, equals('world'));

        // 5. Restore world from trash
        await trashActions.restoreWorld(trashList.first);

        // 6. Verify restored world, lore entities, and revisions
        final restoredWorld = await db.worldDao.getWorldById(worldId);
        expect(restoredWorld.name, equals('神话纪元'));

        final restoredLores = await db.loreDao.getEntitiesByWorld(worldId);
        expect(restoredLores.length, equals(1));
        expect(restoredLores.first.name, equals('世界之树'));
        expect(restoredLores.first.summary, equals('贯通九界的巨树'));

        final restoredRevs = await (db.select(
          db.entityRevisions,
        )..where((r) => r.worldId.equals(worldId))).get();
        expect(restoredRevs.length, equals(1));
        expect(restoredRevs.first.title, equals('初始神话草案'));
        expect(restoredRevs.first.content, equals('最初的设定记载'));
      },
    );

    test(
      'Soft delete character safeguards story scenes povCharacterId and restores it',
      () async {
        final trashActions = container.read(trashActionsProvider);

        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '艾泽拉斯'));
        final charId = await db
            .into(db.characters)
            .insert(CharactersCompanion.insert(worldId: worldId, name: '阿尔萨斯'));
        final character = await db.characterDao.getCharacterById(charId);

        final workId = await db
            .into(db.storyWorks)
            .insert(
              StoryWorksCompanion.insert(worldId: worldId, title: '巫妖王之怒'),
            );
        final chapterId = await db
            .into(db.storyChapters)
            .insert(
              StoryChaptersCompanion.insert(workId: workId, title: '第一章 斯坦索姆'),
            );
        final sceneId = await db
            .into(db.storyScenes)
            .insert(
              StoryScenesCompanion.insert(
                chapterId: chapterId,
                title: '净化抉择',
                povCharacterId: Value(charId),
              ),
            );

        // 1. Soft delete character
        await trashActions.deleteCharacter(character);

        // 2. Character is deleted, scene's povCharacterId is safely nulled out (no FK violation!)
        final remainingChars = await db.characterDao.getCharactersByWorld(
          worldId,
        );
        expect(remainingChars, isEmpty);

        final sceneAfterDelete = await (db.select(
          db.storyScenes,
        )..where((s) => s.id.equals(sceneId))).getSingle();
        expect(sceneAfterDelete.povCharacterId, isNull);

        // 3. Restore character from trash
        final trashList = await db.trashDao.getAllTrash();
        expect(trashList.length, equals(1));
        await trashActions.restoreCharacter(trashList.first);

        // 4. Character is restored, and scene's povCharacterId is safely restored
        final restoredChar = await db.characterDao.getCharacterById(charId);
        expect(restoredChar, isNotNull);
        expect(restoredChar.name, equals('阿尔萨斯'));

        final sceneAfterRestore = await (db.select(
          db.storyScenes,
        )..where((s) => s.id.equals(sceneId))).getSingle();
        expect(sceneAfterRestore.povCharacterId, equals(charId));
      },
    );

    test('Delete lore entity safeguards story scenes locationId', () async {
      final worldId = await db
          .into(db.worlds)
          .insert(WorldsCompanion.insert(name: '艾泽拉斯'));
      final loreId = await db.loreDao.createEntity(
        LoreEntitiesCompanion.insert(
          worldId: worldId,
          entityType: 'location',
          name: '斯坦索姆',
          summary: const Value('北地重镇'),
        ),
      );

      final workId = await db
          .into(db.storyWorks)
          .insert(
            StoryWorksCompanion.insert(worldId: worldId, title: '洛丹伦的沦陷'),
          );
      final chapterId = await db
          .into(db.storyChapters)
          .insert(StoryChaptersCompanion.insert(workId: workId, title: '决裂之刻'));
      final sceneId = await db
          .into(db.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              chapterId: chapterId,
              title: '大门前',
              locationId: Value(loreId),
            ),
          );

      // 1. Delete lore entity directly
      await db.loreDao.deleteEntity(loreId);

      // 2. Lore entity is deleted and scene's locationId is safely nulled out
      final lore = await db.loreDao.getEntityById(loreId);
      expect(lore, isNull);

      final scene = await (db.select(
        db.storyScenes,
      )..where((s) => s.id.equals(sceneId))).getSingle();
      expect(scene.locationId, isNull);
    });

    test(
      'Soft delete world cascades story works, chapters, and scenes, and restores them completely',
      () async {
        final trashActions = container.read(trashActionsProvider);

        // 1. Setup full world with character, lore location, and story hierarchy
        final worldId = await db
            .into(db.worlds)
            .insert(WorldsCompanion.insert(name: '星际争霸'));
        final charId = await db
            .into(db.characters)
            .insert(CharactersCompanion.insert(worldId: worldId, name: '雷诺'));
        final loreId = await db.loreDao.createEntity(
          LoreEntitiesCompanion.insert(
            worldId: worldId,
            entityType: 'location',
            name: '玛·萨拉',
            summary: const Value('边境荒凉行星'),
          ),
        );

        final workId = await db
            .into(db.storyWorks)
            .insert(
              StoryWorksCompanion.insert(
                worldId: worldId,
                title: '自由之翼',
                type: const Value('剧本'),
                summary: const Value('游骑兵的反抗物语'),
              ),
            );
        final chapterId = await db
            .into(db.storyChapters)
            .insert(
              StoryChaptersCompanion.insert(
                workId: workId,
                title: '第一幕 玛·萨拉荒原',
                arcName: const Value('反抗卷'),
                summary: const Value('起义的号角'),
              ),
            );
        final sceneId = await db
            .into(db.storyScenes)
            .insert(
              StoryScenesCompanion.insert(
                chapterId: chapterId,
                title: '酒吧重逢',
                summary: const Value('吉姆·雷诺与泰克斯重逢'),
                povCharacterId: Value(charId),
                locationId: Value(loreId),
                locationName: const Value('乔伊·雷酒吧'),
                mood: const Value('沧桑'),
              ),
            );

        final world = await db.worldDao.getWorldById(worldId);

        // 2. Soft delete world
        await trashActions.deleteWorld(world);

        // 3. Verify all active story tables are cleaned
        final remainingWorks = await db.storyDao.getWorksByWorld(worldId);
        final remainingChapters = await (db.select(
          db.storyChapters,
        )..where((c) => c.workId.equals(workId))).get();
        final remainingScenes = await (db.select(
          db.storyScenes,
        )..where((s) => s.id.equals(sceneId))).get();
        expect(remainingWorks, isEmpty);
        expect(remainingChapters, isEmpty);
        expect(remainingScenes, isEmpty);

        // 4. Verify trash entry exists
        final trashList = await db.trashDao.getAllTrash();
        expect(trashList.length, equals(1));
        expect(trashList.first.itemType, equals('world'));

        // 5. Restore world from trash
        await trashActions.restoreWorld(trashList.first);

        // 6. Verify restored world and full story hierarchy
        final restoredWorld = await db.worldDao.getWorldById(worldId);
        expect(restoredWorld.name, equals('星际争霸'));

        final restoredWorks = await db.storyDao.getWorksByWorld(worldId);
        expect(restoredWorks.length, equals(1));
        final rw = restoredWorks.first;
        expect(rw.title, equals('自由之翼'));
        expect(rw.type, equals('剧本'));
        expect(rw.summary, equals('游骑兵的反抗物语'));

        final restoredChapters = await db.storyDao.getChaptersByWork(rw.id);
        expect(restoredChapters.length, equals(1));
        final rc = restoredChapters.first;
        expect(rc.title, equals('第一幕 玛·萨拉荒原'));
        expect(rc.arcName, equals('反抗卷'));

        final restoredScenes = await db.storyDao.getScenesByChapter(rc.id);
        expect(restoredScenes.length, equals(1));
        final rs = restoredScenes.first;
        expect(rs.title, equals('酒吧重逢'));
        expect(rs.summary, equals('吉姆·雷诺与泰克斯重逢'));
        expect(rs.povCharacterId, equals(charId));
        expect(rs.locationId, equals(loreId));
        expect(rs.locationName, equals('乔伊·雷酒吧'));
        expect(rs.mood, equals('沧桑'));
      },
    );
  });
}
