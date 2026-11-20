import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/stories.dart';

part 'story_dao.g.dart';

/// 场景聚合数据结构（带出场角色与地点名称等）
class StorySceneDetail {
  final StoryScene scene;
  final Character? povCharacter;
  final LoreEntity? location;
  final List<int> characterIds;

  const StorySceneDetail({
    required this.scene,
    this.povCharacter,
    this.location,
    required this.characterIds,
  });
}

/// 角色在单个场景中的出场记录明细 (STORY-003)
class CharacterAppearanceItem {
  final StoryWork work;
  final StoryChapter chapter;
  final StoryScene scene;
  final bool isPov;

  const CharacterAppearanceItem({
    required this.work,
    required this.chapter,
    required this.scene,
    required this.isPov,
  });
}

/// 角色的整体出场统计与首次/末次出场汇总 (STORY-003)
class CharacterAppearanceSummary {
  final int characterId;
  final int totalScenes;
  final int totalChapters;
  final int totalPovScenes;
  final CharacterAppearanceItem? firstAppearance;
  final CharacterAppearanceItem? lastAppearance;
  final List<CharacterAppearanceItem> appearances;
  final Map<int, int> scenesCountByWork;

  const CharacterAppearanceSummary({
    required this.characterId,
    required this.totalScenes,
    required this.totalChapters,
    required this.totalPovScenes,
    this.firstAppearance,
    this.lastAppearance,
    required this.appearances,
    required this.scenesCountByWork,
  });

  static const empty = CharacterAppearanceSummary(
    characterId: 0,
    totalScenes: 0,
    totalChapters: 0,
    totalPovScenes: 0,
    appearances: [],
    scenesCountByWork: {},
  );
}

/// 作品登场角色演职统计项 (STORY-003)
class WorkCastMemberStats {
  final Character character;
  final int sceneCount;
  final int chapterCount;
  final int povCount;
  final CharacterAppearanceItem? firstAppearance;

  const WorkCastMemberStats({
    required this.character,
    required this.sceneCount,
    required this.chapterCount,
    required this.povCount,
    this.firstAppearance,
  });
}

/// 故事与章节场景数据访问对象 (STORY-001 & STORY-002)
@DriftAccessor(tables: [StoryWorks, StoryChapters, StoryScenes])
class StoryDao extends DatabaseAccessor<AppDatabase> with _$StoryDaoMixin {
  StoryDao(super.db);

  // ========================================================
  // 1. 作品管理 (StoryWorks · STORY-001)
  // ========================================================

  Future<List<StoryWork>> getWorksByWorld(int worldId) {
    return (select(storyWorks)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  Stream<List<StoryWork>> watchWorksByWorld(int worldId) {
    return (select(storyWorks)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Future<StoryWork?> getWorkById(int id) =>
      (select(storyWorks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createWork(StoryWorksCompanion entry) =>
      into(storyWorks).insert(entry);

  Future<bool> updateWork(StoryWorksCompanion entry) =>
      update(storyWorks).replace(entry);

  Future<int> updateWorkPartial(int id, StoryWorksCompanion entry) =>
      (update(storyWorks)..where((t) => t.id.equals(id))).write(entry);

  Future<void> deleteWork(int id) {
    return transaction(() async {
      // 级联删除该作品下的所有场景与章节
      final chapters = await (select(
        storyChapters,
      )..where((t) => t.workId.equals(id))).get();
      final chapterIds = chapters.map((c) => c.id).toList();

      if (chapterIds.isNotEmpty) {
        await (delete(
          storyScenes,
        )..where((t) => t.chapterId.isIn(chapterIds))).go();
      }
      await (delete(storyChapters)..where((t) => t.workId.equals(id))).go();
      await (delete(storyWorks)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> deleteWorksByWorld(int worldId) {
    return transaction(() async {
      final works = await (select(
        storyWorks,
      )..where((t) => t.worldId.equals(worldId))).get();
      for (final w in works) {
        await deleteWork(w.id);
      }
    });
  }

  // ========================================================
  // 2. 章节管理 (StoryChapters · STORY-002)
  // ========================================================

  Future<List<StoryChapter>> getChaptersByWork(int workId) {
    return (select(storyChapters)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<StoryChapter>> getChaptersByWorks(List<int> workIds) {
    if (workIds.isEmpty) return Future.value([]);
    return (select(storyChapters)
          ..where((t) => t.workId.isIn(workIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Stream<List<StoryChapter>> watchChaptersByWork(int workId) {
    return (select(storyChapters)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<StoryChapter?> getChapterById(int id) =>
      (select(storyChapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createChapter(StoryChaptersCompanion entry) =>
      into(storyChapters).insert(entry);

  Future<bool> updateChapter(StoryChaptersCompanion entry) =>
      update(storyChapters).replace(entry);

  Future<void> deleteChapter(int id) {
    return transaction(() async {
      await (delete(storyScenes)..where((t) => t.chapterId.equals(id))).go();
      await (delete(storyChapters)..where((t) => t.id.equals(id))).go();
    });
  }

  // ========================================================
  // 3. 场景管理 (StoryScenes · STORY-002)
  // ========================================================

  Future<List<StoryScene>> getScenesByChapter(int chapterId) {
    return (select(storyScenes)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<StoryScene>> getScenesByChapters(List<int> chapterIds) {
    if (chapterIds.isEmpty) return Future.value([]);
    return (select(storyScenes)
          ..where((t) => t.chapterId.isIn(chapterIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Stream<List<StoryScene>> watchScenesByChapter(int chapterId) {
    return (select(storyScenes)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<StoryScene?> getSceneById(int id) =>
      (select(storyScenes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createScene(StoryScenesCompanion entry) =>
      into(storyScenes).insert(entry);

  Future<bool> updateScene(StoryScenesCompanion entry) =>
      update(storyScenes).replace(entry);

  Future<int> deleteScene(int id) =>
      (delete(storyScenes)..where((t) => t.id.equals(id))).go();

  /// 获取指定章节的所有场景详细信息（包含 POV 视点人物和地点实体）
  Future<List<StorySceneDetail>> getSceneDetailsByChapter(int chapterId) async {
    final rawScenes = await getScenesByChapter(chapterId);
    if (rawScenes.isEmpty) return [];

    final povCharIds = rawScenes
        .map((s) => s.povCharacterId)
        .whereType<int>()
        .toSet();
    final locationIds = rawScenes
        .map((s) => s.locationId)
        .whereType<int>()
        .toSet();

    final characters = povCharIds.isNotEmpty
        ? await db.characterDao.getCharactersByIds(povCharIds.toList())
        : <Character>[];
    final charMap = {for (final c in characters) c.id: c};

    final locations = locationIds.isNotEmpty
        ? await (db.select(
            db.loreEntities,
          )..where((t) => t.id.isIn(locationIds.toList()))).get()
        : <LoreEntity>[];
    final locMap = {for (final l in locations) l.id: l};

    return rawScenes.map((s) {
      final List<int> charIds = [];
      try {
        final dynamic parsed = jsonDecode(s.characterIds);
        if (parsed is List) {
          charIds.addAll(
            parsed
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .where((id) => id > 0),
          );
        }
      } catch (_) {}

      return StorySceneDetail(
        scene: s,
        povCharacter: s.povCharacterId != null
            ? charMap[s.povCharacterId]
            : null,
        location: s.locationId != null ? locMap[s.locationId] : null,
        characterIds: charIds,
      );
    }).toList();
  }

  /// 统计某作品下的章节数与场景总数
  Future<({int chapterCount, int sceneCount, int totalWords})> getWorkStats(
    int workId,
  ) async {
    final chapters = await getChaptersByWork(workId);
    if (chapters.isEmpty) {
      return (chapterCount: 0, sceneCount: 0, totalWords: 0);
    }
    final chapterIds = chapters.map((c) => c.id).toList();
    final scenes = await (select(
      storyScenes,
    )..where((t) => t.chapterId.isIn(chapterIds))).get();
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);

    return (
      chapterCount: chapters.length,
      sceneCount: scenes.length,
      totalWords: totalWords,
    );
  }

  // ========================================================
  // 4. 人物出场记录与演职统计 (STORY-003)
  // ========================================================

  /// 辅助判断角色是否在该场景中出场（POV 视点或出场人物列表）
  bool _characterAppearsInScene(StoryScene scene, int characterId) {
    if (scene.povCharacterId == characterId) return true;
    try {
      final dynamic parsed = jsonDecode(scene.characterIds);
      if (parsed is List) {
        return parsed.any(
          (id) => (int.tryParse(id.toString()) ?? -1) == characterId,
        );
      }
    } catch (_) {}
    return false;
  }

  /// 获取指定角色的完整出场记录与摘要统计（首次出场、末次出场、覆盖章节、POV 场次等）
  Future<CharacterAppearanceSummary> getCharacterAppearanceSummary(
    int characterId, {
    int? worldId,
  }) async {
    // 1. 若未显式传入 worldId，则由角色数据查出所在世界观
    int? targetWorldId = worldId;
    if (targetWorldId == null) {
      final char = await (select(
        db.characters,
      )..where((t) => t.id.equals(characterId))).getSingleOrNull();
      if (char == null) return CharacterAppearanceSummary.empty;
      targetWorldId = char.worldId;
    }

    // 2. 查询该世界观下的所有作品，按作品排序升序，相同时按创建时间升序
    final works =
        await (select(storyWorks)
              ..where((t) => t.worldId.equals(targetWorldId!))
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    if (works.isEmpty) {
      return CharacterAppearanceSummary(
        characterId: characterId,
        totalScenes: 0,
        totalChapters: 0,
        totalPovScenes: 0,
        appearances: const [],
        scenesCountByWork: const {},
      );
    }
    final workMap = {for (final w in works) w.id: w};
    final workOrderMap = {
      for (int i = 0; i < works.length; i++) works[i].id: i,
    };
    final workIds = works.map((w) => w.id).toList();

    // 3. 查询所有章节，确保严格遵循：所属作品顺序 -> 章节序号 -> 章节ID
    final chapters = await (select(
      storyChapters,
    )..where((t) => t.workId.isIn(workIds))).get();
    if (chapters.isEmpty) {
      return CharacterAppearanceSummary(
        characterId: characterId,
        totalScenes: 0,
        totalChapters: 0,
        totalPovScenes: 0,
        appearances: const [],
        scenesCountByWork: const {},
      );
    }

    chapters.sort((a, b) {
      final wA = workOrderMap[a.workId] ?? 0;
      final wB = workOrderMap[b.workId] ?? 0;
      if (wA != wB) return wA.compareTo(wB);
      final sortCmp = a.sortOrder.compareTo(b.sortOrder);
      if (sortCmp != 0) return sortCmp;
      return a.id.compareTo(b.id);
    });

    final chapterMap = {for (final c in chapters) c.id: c};
    final chapterOrderMap = {
      for (int i = 0; i < chapters.length; i++) chapters[i].id: i,
    };
    final chapterIds = chapters.map((c) => c.id).toList();

    // 4. 查询所有场景，按章节时序与分镜序号升序
    final scenes = await (select(
      storyScenes,
    )..where((t) => t.chapterId.isIn(chapterIds))).get();

    // 确保场景严格按照：所属章节顺序 -> 场景分镜序号 -> 场景自增 ID 排序
    scenes.sort((a, b) {
      final chOrderA = chapterOrderMap[a.chapterId] ?? 0;
      final chOrderB = chapterOrderMap[b.chapterId] ?? 0;
      if (chOrderA != chOrderB) return chOrderA.compareTo(chOrderB);
      final sortOrderCmp = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderCmp != 0) return sortOrderCmp;
      return a.id.compareTo(b.id);
    });

    // 5. 过滤并构建角色出场记录
    final appearances = <CharacterAppearanceItem>[];
    final scenesCountByWork = <int, int>{};

    for (final scene in scenes) {
      if (_characterAppearsInScene(scene, characterId)) {
        final chapter = chapterMap[scene.chapterId];
        if (chapter == null) continue;
        final work = workMap[chapter.workId];
        if (work == null) continue;

        final isPov = scene.povCharacterId == characterId;
        appearances.add(
          CharacterAppearanceItem(
            work: work,
            chapter: chapter,
            scene: scene,
            isPov: isPov,
          ),
        );
        scenesCountByWork[work.id] = (scenesCountByWork[work.id] ?? 0) + 1;
      }
    }

    final uniqueChapterIds = appearances.map((a) => a.chapter.id).toSet();
    final totalPovScenes = appearances.where((a) => a.isPov).length;

    return CharacterAppearanceSummary(
      characterId: characterId,
      totalScenes: appearances.length,
      totalChapters: uniqueChapterIds.length,
      totalPovScenes: totalPovScenes,
      firstAppearance: appearances.firstOrNull,
      lastAppearance: appearances.lastOrNull,
      appearances: appearances,
      scenesCountByWork: scenesCountByWork,
    );
  }

  /// 获取指定作品中所有出场角色的演职统计（按出场频次从高到低排序）
  Future<List<WorkCastMemberStats>> getWorkCharacterCastStats(
    int workId,
  ) async {
    final chapters = await getChaptersByWork(workId);
    if (chapters.isEmpty) return const [];

    final chapterMap = {for (final c in chapters) c.id: c};
    final chapterOrderMap = {
      for (int i = 0; i < chapters.length; i++) chapters[i].id: i,
    };
    final chapterIds = chapters.map((c) => c.id).toList();

    final scenes = await (select(
      storyScenes,
    )..where((t) => t.chapterId.isIn(chapterIds))).get();
    if (scenes.isEmpty) return const [];

    scenes.sort((a, b) {
      final chOrderA = chapterOrderMap[a.chapterId] ?? 0;
      final chOrderB = chapterOrderMap[b.chapterId] ?? 0;
      if (chOrderA != chOrderB) return chOrderA.compareTo(chOrderB);
      final sortOrderCmp = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderCmp != 0) return sortOrderCmp;
      return a.id.compareTo(b.id);
    });

    final work = await getWorkById(workId);
    if (work == null) return const [];

    // 统计各角色的出场场次、章节集合、POV 场次与首次出场
    final sceneCounts = <int, int>{};
    final chapterSets = <int, Set<int>>{};
    final povCounts = <int, int>{};
    final firstAppearances = <int, CharacterAppearanceItem>{};

    for (final scene in scenes) {
      final chapter = chapterMap[scene.chapterId];
      if (chapter == null) continue;

      final sceneCharIds = <int>{};
      if (scene.povCharacterId != null) {
        sceneCharIds.add(scene.povCharacterId!);
      }
      try {
        final dynamic parsed = jsonDecode(scene.characterIds);
        if (parsed is List) {
          for (final item in parsed) {
            final id = int.tryParse(item.toString());
            if (id != null && id > 0) sceneCharIds.add(id);
          }
        }
      } catch (_) {}

      for (final charId in sceneCharIds) {
        sceneCounts[charId] = (sceneCounts[charId] ?? 0) + 1;
        chapterSets.putIfAbsent(charId, () => <int>{}).add(chapter.id);
        final isPov = scene.povCharacterId == charId;
        if (isPov) {
          povCounts[charId] = (povCounts[charId] ?? 0) + 1;
        }
        if (!firstAppearances.containsKey(charId)) {
          firstAppearances[charId] = CharacterAppearanceItem(
            work: work,
            chapter: chapter,
            scene: scene,
            isPov: isPov,
          );
        }
      }
    }

    if (sceneCounts.isEmpty) return const [];

    final characters = await db.characterDao.getCharactersByIds(
      sceneCounts.keys.toList(),
    );
    final charMap = {for (final c in characters) c.id: c};

    final statsList = <WorkCastMemberStats>[];
    for (final charId in sceneCounts.keys) {
      final character = charMap[charId];
      if (character == null) continue;

      statsList.add(
        WorkCastMemberStats(
          character: character,
          sceneCount: sceneCounts[charId] ?? 0,
          chapterCount: chapterSets[charId]?.length ?? 0,
          povCount: povCounts[charId] ?? 0,
          firstAppearance: firstAppearances[charId],
        ),
      );
    }

    // 按出场场景数倒序；若相同则按 POV 倒序；再按章节数倒序
    statsList.sort((a, b) {
      final cmp = b.sceneCount.compareTo(a.sceneCount);
      if (cmp != 0) return cmp;
      final povCmp = b.povCount.compareTo(a.povCount);
      if (povCmp != 0) return povCmp;
      return b.chapterCount.compareTo(a.chapterCount);
    });

    return statsList;
  }
}
