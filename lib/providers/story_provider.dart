import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../data/database/app_database.dart';
import '../data/database/daos/story_dao.dart';
import 'database_provider.dart';

export '../data/database/daos/story_dao.dart';

// ========================================================
// 1. Providers
// ========================================================

final worksByWorldProvider = StreamProvider.family<List<StoryWork>, int>((
  ref,
  worldId,
) {
  return ref.watch(storyDaoProvider).watchWorksByWorld(worldId);
});

final chaptersByWorkProvider = StreamProvider.family<List<StoryChapter>, int>((
  ref,
  workId,
) {
  return ref.watch(storyDaoProvider).watchChaptersByWork(workId);
});

final scenesByChapterProvider = StreamProvider.family<List<StoryScene>, int>((
  ref,
  chapterId,
) {
  return ref.watch(storyDaoProvider).watchScenesByChapter(chapterId);
});

final sceneDetailsByChapterProvider =
    FutureProvider.family<List<StorySceneDetail>, int>((ref, chapterId) {
      return ref.watch(storyDaoProvider).getSceneDetailsByChapter(chapterId);
    });

final workStatsProvider =
    FutureProvider.family<
      ({int chapterCount, int sceneCount, int totalWords}),
      int
    >((ref, workId) {
      return ref.watch(storyDaoProvider).getWorkStats(workId);
    });

final storyActionsProvider = Provider((ref) => StoryActions(ref));

// ========================================================
// 2. StoryActions (STORY-001 & STORY-002)
// ========================================================

class StoryActions {
  final Ref _ref;

  StoryActions(this._ref);

  StoryDao get _dao => _ref.read(storyDaoProvider);

  // --- 作品 (Work) ---

  Future<int> createWork({
    required int worldId,
    required String title,
    String type = '小说',
    String summary = '',
    String status = '策划中',
    String? coverImagePath,
  }) async {
    final id = await _dao.createWork(
      StoryWorksCompanion.insert(
        worldId: worldId,
        title: title,
        type: drift.Value(type),
        summary: drift.Value(summary),
        status: drift.Value(status),
        coverImagePath: drift.Value(coverImagePath),
      ),
    );
    _ref.invalidate(worksByWorldProvider(worldId));
    return id;
  }

  Future<void> updateWork({
    required int id,
    required int worldId,
    required String title,
    String type = '小说',
    String summary = '',
    String status = '策划中',
    String? coverImagePath,
  }) async {
    await _dao.updateWork(
      StoryWorksCompanion(
        id: drift.Value(id),
        worldId: drift.Value(worldId),
        title: drift.Value(title),
        type: drift.Value(type),
        summary: drift.Value(summary),
        status: drift.Value(status),
        coverImagePath: drift.Value(coverImagePath),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    _ref.invalidate(worksByWorldProvider(worldId));
    _ref.invalidate(workStatsProvider(id));
  }

  Future<void> deleteWork(int id, int worldId) async {
    await _dao.deleteWork(id);
    _ref.invalidate(worksByWorldProvider(worldId));
    _ref.invalidate(workStatsProvider(id));
  }

  // --- 章节 (Chapter) ---

  Future<int> createChapter({
    required int workId,
    required String title,
    String arcName = '正卷',
    String summary = '',
    String status = '大纲',
    int sortOrder = 0,
    int wordCount = 0,
  }) async {
    final id = await _dao.createChapter(
      StoryChaptersCompanion.insert(
        workId: workId,
        title: title,
        arcName: drift.Value(arcName),
        summary: drift.Value(summary),
        status: drift.Value(status),
        sortOrder: drift.Value(sortOrder),
        wordCount: drift.Value(wordCount),
      ),
    );
    _ref.invalidate(chaptersByWorkProvider(workId));
    _ref.invalidate(workStatsProvider(workId));
    return id;
  }

  Future<void> updateChapter({
    required int id,
    required int workId,
    required String title,
    String arcName = '正卷',
    String summary = '',
    String status = '大纲',
    int sortOrder = 0,
    int wordCount = 0,
  }) async {
    await _dao.updateChapter(
      StoryChaptersCompanion(
        id: drift.Value(id),
        workId: drift.Value(workId),
        title: drift.Value(title),
        arcName: drift.Value(arcName),
        summary: drift.Value(summary),
        status: drift.Value(status),
        sortOrder: drift.Value(sortOrder),
        wordCount: drift.Value(wordCount),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    _ref.invalidate(chaptersByWorkProvider(workId));
    _ref.invalidate(workStatsProvider(workId));
  }

  Future<void> deleteChapter(int id, int workId) async {
    await _dao.deleteChapter(id);
    _ref.invalidate(chaptersByWorkProvider(workId));
    _ref.invalidate(workStatsProvider(workId));
  }

  // --- 场景 (Scene) ---

  Future<int> createScene({
    required int chapterId,
    required String title,
    String summary = '',
    String content = '',
    int? povCharacterId,
    int? locationId,
    String locationName = '',
    String timelineTime = '',
    String mood = '',
    List<int> characterIds = const [],
    int sortOrder = 0,
  }) async {
    final id = await _dao.createScene(
      StoryScenesCompanion.insert(
        chapterId: chapterId,
        title: title,
        summary: drift.Value(summary),
        content: drift.Value(content),
        povCharacterId: drift.Value(povCharacterId),
        locationId: drift.Value(locationId),
        locationName: drift.Value(locationName),
        timelineTime: drift.Value(timelineTime),
        mood: drift.Value(mood),
        characterIds: drift.Value(jsonEncode(characterIds)),
        sortOrder: drift.Value(sortOrder),
      ),
    );
    _ref.invalidate(scenesByChapterProvider(chapterId));
    _ref.invalidate(sceneDetailsByChapterProvider(chapterId));
    return id;
  }

  Future<void> updateScene({
    required int id,
    required int chapterId,
    required String title,
    String summary = '',
    String content = '',
    int? povCharacterId,
    int? locationId,
    String locationName = '',
    String timelineTime = '',
    String mood = '',
    List<int> characterIds = const [],
    int sortOrder = 0,
  }) async {
    await _dao.updateScene(
      StoryScenesCompanion(
        id: drift.Value(id),
        chapterId: drift.Value(chapterId),
        title: drift.Value(title),
        summary: drift.Value(summary),
        content: drift.Value(content),
        povCharacterId: drift.Value(povCharacterId),
        locationId: drift.Value(locationId),
        locationName: drift.Value(locationName),
        timelineTime: drift.Value(timelineTime),
        mood: drift.Value(mood),
        characterIds: drift.Value(jsonEncode(characterIds)),
        sortOrder: drift.Value(sortOrder),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    _ref.invalidate(scenesByChapterProvider(chapterId));
    _ref.invalidate(sceneDetailsByChapterProvider(chapterId));
  }

  Future<void> deleteScene(int id, int chapterId) async {
    await _dao.deleteScene(id);
    _ref.invalidate(scenesByChapterProvider(chapterId));
    _ref.invalidate(sceneDetailsByChapterProvider(chapterId));
  }
}
