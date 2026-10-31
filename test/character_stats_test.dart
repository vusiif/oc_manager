import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/providers/database_provider.dart';
import 'package:oc_manager/providers/trash_provider.dart';
import 'package:oc_manager/core/design/components/radar_chart.dart';

void main() {
  group('CharacterStats & RadarChart Tests', () {
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

    test('RadarStatItem ratio calculation and clamping', () {
      const normal = RadarStatItem(label: '力量', value: 75.0, maxValue: 100.0);
      expect(normal.ratio, closeTo(0.75, 0.001));

      const overflow = RadarStatItem(label: '敏捷', value: 150.0, maxValue: 100.0);
      expect(overflow.ratio, equals(1.0));

      const negative = RadarStatItem(label: '智力', value: -20.0, maxValue: 100.0);
      expect(negative.ratio, equals(0.0));

      const zeroMax = RadarStatItem(label: '幸运', value: 10.0, maxValue: 0.0);
      expect(zeroMax.ratio, equals(1.0));
    });

    test('Built-in presets integrity', () {
      final presets = StatPreset.builtInPresets;
      expect(presets.length, greaterThanOrEqualTo(4));

      final dnd = presets.firstWhere((p) => p.id == 'dnd_classic');
      expect(dnd.dimensions.length, equals(6));
      expect(dnd.maxValue, equals(20.0));
      expect(dnd.dimensions.contains('力量 (STR)'), isTrue);

      final anime = presets.firstWhere((p) => p.id == 'anime_battle');
      expect(anime.dimensions.length, equals(6));
      expect(anime.maxValue, equals(100.0));

      final coc = presets.firstWhere((p) => p.id == 'coc_investigator');
      expect(coc.dimensions.length, equals(8));

      final personality = presets.firstWhere((p) => p.id == 'personality_compass');
      expect(personality.dimensions.length, equals(6));
    });

    test('Character stats CRUD & setCharacterStats transaction', () async {
      // 1. 创建世界观和角色
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('属性测试世界')),
      );
      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: Value('勇者亚瑟'),
          gender: const Value('男'),
        ),
      );

      // 2. 批量套用预设
      final dndPreset = StatPreset.builtInPresets.firstWhere((p) => p.id == 'dnd_classic');
      final companions = [
        for (var i = 0; i < dndPreset.dimensions.length; i++)
          CharacterStatsCompanion.insert(
            characterId: charId,
            label: dndPreset.dimensions[i],
            value: Value(dndPreset.defaultValues?[dndPreset.dimensions[i]] ?? 10.0),
            maxValue: Value(dndPreset.maxValue),
            sortOrder: Value(i),
          ),
      ];

      await db.characterDao.setCharacterStats(charId, companions);

      var stats = await db.characterDao.getCharacterStats(charId);
      expect(stats.length, equals(6));
      expect(stats[0].label, equals('力量 (STR)'));
      expect(stats[0].value, equals(14.0));
      expect(stats[0].maxValue, equals(20.0));

      // 3. 更新单项数值
      await db.characterDao.updateCharacterStat(
        CharacterStatsCompanion(
          id: Value(stats[0].id),
          characterId: Value(charId),
          label: Value(stats[0].label),
          value: const Value(18.0),
          maxValue: Value(stats[0].maxValue),
          sortOrder: Value(stats[0].sortOrder),
        ),
      );

      stats = await db.characterDao.getCharacterStats(charId);
      expect(stats[0].value, equals(18.0));

      // 4. 添加新自定义维度
      await db.characterDao.createCharacterStat(
        CharacterStatsCompanion.insert(
          characterId: charId,
          label: '神圣共鸣',
          value: const Value(16.0),
          maxValue: const Value(20.0),
          sortOrder: const Value(6),
        ),
      );

      stats = await db.characterDao.getCharacterStats(charId);
      expect(stats.length, equals(7));
      expect(stats.last.label, equals('神圣共鸣'));

      // 5. 删除单项
      await db.characterDao.deleteCharacterStat(stats.last.id);
      stats = await db.characterDao.getCharacterStats(charId);
      expect(stats.length, equals(6));
    });

    test('Trash cascade snapshot & restore preserves all character stats', () async {
      // 1. 初始化世界观与带属性角色
      final worldId = await db.worldDao.createWorld(
        const WorldsCompanion(name: Value('回收站测试世界')),
      );
      final charId = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: Value('战神奎托斯'),
          gender: const Value('男'),
        ),
      );

      final animePreset = StatPreset.builtInPresets.firstWhere((p) => p.id == 'anime_battle');
      final companions = [
        for (var i = 0; i < animePreset.dimensions.length; i++)
          CharacterStatsCompanion.insert(
            characterId: charId,
            label: animePreset.dimensions[i],
            value: Value(animePreset.defaultValues?[animePreset.dimensions[i]] ?? 80.0),
            maxValue: Value(animePreset.maxValue),
            sortOrder: Value(i),
          ),
      ];
      await db.characterDao.setCharacterStats(charId, companions);

      final character = await db.characterDao.getCharacterById(charId);
      final beforeDeleteStats = await db.characterDao.getCharacterStats(charId);
      expect(beforeDeleteStats.length, equals(6));

      // 2. 软删除角色到回收站
      final trashActions = container.read(trashActionsProvider);
      await trashActions.deleteCharacter(character);

      // 验证主表和属性表均已清除
      final afterDeleteStats = await db.characterDao.getCharacterStats(charId);
      expect(afterDeleteStats.isEmpty, isTrue);

      final trashList = await db.trashDao.getAllTrash();
      expect(trashList.length, equals(1));
      final trashItem = trashList.first;
      expect(trashItem.itemType, equals('character'));
      expect(trashItem.itemData.contains('"stats"'), isTrue);
      expect(trashItem.itemData.contains('力量'), isTrue);

      // 3. 从回收站恢复角色
      await trashActions.restoreCharacter(trashItem);

      // 验证角色和其 6 维属性 100% 等价恢复
      final restoredChar = await db.characterDao.getCharacterById(charId);
      expect(restoredChar.name, equals('战神奎托斯'));

      final restoredStats = await db.characterDao.getCharacterStats(charId);
      expect(restoredStats.length, equals(6));
      expect(restoredStats.map((s) => s.label).toList(), equals(beforeDeleteStats.map((s) => s.label).toList()));
      for (var i = 0; i < 6; i++) {
        expect(restoredStats[i].value, equals(beforeDeleteStats[i].value));
        expect(restoredStats[i].maxValue, equals(beforeDeleteStats[i].maxValue));
      }
    });
  });
}
