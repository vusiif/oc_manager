import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/world_provider.dart';

/// Seeds a self-contained sample world with characters, stats, relations,
/// and a pre-arranged graph canvas so new users can explore immediately.
class SampleWorldService {
  static const String baseWorldName = '星海边境（示例）';

  /// Creates a sample world inside a single SQLite transaction and returns its ID.
  static Future<int> createSampleWorld(AppDatabase db) async {
    return db.transaction(() async {
      final existingWorlds = await db.worldDao.getAllWorlds();
      final occupied = existingWorlds.map((w) => w.name).toSet();
      final worldName = _resolveUniqueName(baseWorldName, occupied);

      final worldId = await db.worldDao.createWorld(
        WorldsCompanion(
          name: Value(worldName),
          description: const Value(
            '官方示例世界观：近未来星际拓荒时代，包含核心角色小传、维基双链、雷达属性与可视化关系图谱。',
          ),
        ),
      );

      final char1 = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('林零'),
          gender: const Value('男'),
          description: const Value(
            '第七舰队领航员，性格冷静果断。与搭档 [[艾琳]] 在“黎明行动”中并肩作战，视导师 [[雷恩]] 为精神支柱。',
          ),
          status: const Value(0),
          isPinned: const Value(true),
          isFavorite: const Value(true),
        ),
      );
      final char2 = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('艾琳'),
          gender: const Value('女'),
          description: const Value(
            '天才机械师与情报分析官，总是能修好最棘手的跃迁引擎。和 [[林零]] 拥有无需言语的默契。',
          ),
          status: const Value(0),
          isFavorite: const Value(true),
        ),
      );
      final char3 = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('雷恩'),
          gender: const Value('男'),
          description: const Value(
            '退役老练舰长，[[林零]] 的引路人。十年前曾与 [[卡修斯]] 爆发过决定边境格局的决战。',
          ),
          status: const Value(0),
        ),
      );
      final char4 = await db.characterDao.createCharacter(
        CharactersCompanion(
          worldId: Value(worldId),
          name: const Value('卡修斯'),
          gender: const Value('其他'),
          description: const Value('神秘星盗联盟的幕后首领，行事莫测，将 [[雷恩]] 与第七舰队视作必须跨越的障碍。'),
          status: const Value(0),
        ),
      );

      await _seedStats(db, char1, [85, 78, 90, 72, 80, 65]);
      await _seedStats(db, char2, [55, 82, 95, 68, 88, 76]);
      await _seedStats(db, char3, [88, 70, 86, 92, 74, 60]);
      await _seedStats(db, char4, [92, 88, 91, 80, 65, 72]);

      await db.relationDao.createRelation(
        RelationsCompanion(
          fromCharacterId: Value(char1),
          toCharacterId: Value(char2),
          relationType: const Value('恋人'),
          isBidirectional: const Value(true),
          note: const Value('星海拓荒时期的生死搭档'),
        ),
      );
      await db.relationDao.createRelation(
        RelationsCompanion(
          fromCharacterId: Value(char3),
          toCharacterId: Value(char1),
          relationType: const Value('师徒'),
          isBidirectional: const Value(false),
          note: const Value('一手提拔并传授星图航线技术'),
        ),
      );
      await db.relationDao.createRelation(
        RelationsCompanion(
          fromCharacterId: Value(char3),
          toCharacterId: Value(char4),
          relationType: const Value('宿敌'),
          isBidirectional: const Value(true),
          note: const Value('十年前星门战役的对决双方'),
        ),
      );
      await db.relationDao.createRelation(
        RelationsCompanion(
          fromCharacterId: Value(char4),
          toCharacterId: Value(char1),
          relationType: const Value('敌对'),
          isBidirectional: const Value(false),
          note: const Value('试图阻断第七舰队补给线'),
        ),
      );

      final canvasId = await db.canvasDao.createCanvas(
        GraphCanvasesCompanion(
          worldId: Value(worldId),
          name: const Value('主关系图'),
          description: const Value('示例世界核心人物关系网络'),
          isDefault: const Value(true),
        ),
      );
      await db.canvasDao.batchSavePositions(worldId, canvasId, {
        char1: const Offset(420, 260),
        char2: const Offset(660, 260),
        char3: const Offset(420, 460),
        char4: const Offset(660, 460),
      });

      return worldId;
    });
  }

  /// Creates a sample world using Riverpod [ref] and refreshes world list state.
  static Future<int> createAndRefresh(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final worldId = await createSampleWorld(db);
    ref.invalidate(worldsProvider);
    return worldId;
  }

  static Future<void> _seedStats(
    AppDatabase db,
    int characterId,
    List<double> values,
  ) async {
    const labels = ['武力', '敏捷', '智力', '体质', '魅力', '幸运'];
    for (var i = 0; i < labels.length; i++) {
      await db.characterDao.createCharacterStat(
        CharacterStatsCompanion(
          characterId: Value(characterId),
          label: Value(labels[i]),
          value: Value(values[i]),
          maxValue: const Value(100),
          sortOrder: Value(i),
        ),
      );
    }
  }

  static String _resolveUniqueName(String base, Set<String> occupied) {
    if (!occupied.contains(base)) return base;
    var index = 2;
    while (true) {
      final candidate = '星海边境（示例 $index）';
      if (!occupied.contains(candidate)) return candidate;
      index++;
    }
  }
}
