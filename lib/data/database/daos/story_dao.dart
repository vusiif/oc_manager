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
}
