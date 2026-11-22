import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';

/// Helper for cascading snapshot and safe restoration of StoryWorks, StoryChapters, and StoryScenes.
class WorldStoryTrashHelper {
  final AppDatabase db;

  const WorldStoryTrashHelper(this.db);

  /// Snapshots all story works, chapters, and scenes under a world.
  Future<List<Map<String, dynamic>>> snapshot(int worldId) async {
    final works = await db.storyDao.getWorksByWorld(worldId);
    final snapshots = <Map<String, dynamic>>[];

    for (final w in works) {
      final chapters = await db.storyDao.getChaptersByWork(w.id);
      final chapterSnapshots = <Map<String, dynamic>>[];

      for (final c in chapters) {
        final scenes = await (db.select(
          db.storyScenes,
        )..where((s) => s.chapterId.equals(c.id))).get();

        chapterSnapshots.add({
          'chapter': {
            'id': c.id,
            'workId': c.workId,
            'arcName': c.arcName,
            'title': c.title,
            'summary': c.summary,
            'status': c.status,
            'sortOrder': c.sortOrder,
            'wordCount': c.wordCount,
            'createdAt': c.createdAt.toIso8601String(),
            'updatedAt': c.updatedAt.toIso8601String(),
          },
          'scenes': [
            for (final s in scenes)
              {
                'id': s.id,
                'chapterId': s.chapterId,
                'title': s.title,
                'summary': s.summary,
                'content': s.content,
                'povCharacterId': s.povCharacterId,
                'locationId': s.locationId,
                'locationName': s.locationName,
                'timelineTime': s.timelineTime,
                'mood': s.mood,
                'characterIds': s.characterIds,
                'sortOrder': s.sortOrder,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt.toIso8601String(),
              },
          ],
        });
      }

      snapshots.add({
        'work': {
          'id': w.id,
          'worldId': w.worldId,
          'title': w.title,
          'type': w.type,
          'summary': w.summary,
          'status': w.status,
          'coverImagePath': w.coverImagePath,
          'sortOrder': w.sortOrder,
          'createdAt': w.createdAt.toIso8601String(),
          'updatedAt': w.updatedAt.toIso8601String(),
        },
        'chapters': chapterSnapshots,
      });
    }

    return snapshots;
  }

  /// Restores all snapshotted story works, chapters, and scenes.
  Future<void> restore(int worldId, List<dynamic> storiesData) async {
    for (final s in storiesData) {
      final sm = s as Map<String, dynamic>;
      final wm = sm['work'] as Map<String, dynamic>;
      final wId = wm['id'] as int;

      await db
          .into(db.storyWorks)
          .insertOnConflictUpdate(
            StoryWorksCompanion(
              id: Value(wId),
              worldId: Value(worldId),
              title: Value(wm['title'] as String),
              type: Value(wm['type'] as String? ?? '小说'),
              summary: Value(wm['summary'] as String? ?? ''),
              status: Value(wm['status'] as String? ?? '策划中'),
              coverImagePath: Value(wm['coverImagePath'] as String?),
              sortOrder: Value(wm['sortOrder'] as int? ?? 0),
              createdAt: Value(DateTime.parse(wm['createdAt'] as String)),
              updatedAt: Value(DateTime.parse(wm['updatedAt'] as String)),
            ),
          );

      final chaptersData = (sm['chapters'] as List<dynamic>?) ?? [];
      for (final cd in chaptersData) {
        final cdm = cd as Map<String, dynamic>;
        final cm = cdm['chapter'] as Map<String, dynamic>;
        final cId = cm['id'] as int;

        await db
            .into(db.storyChapters)
            .insertOnConflictUpdate(
              StoryChaptersCompanion(
                id: Value(cId),
                workId: Value(wId),
                arcName: Value(cm['arcName'] as String? ?? '正卷'),
                title: Value(cm['title'] as String),
                summary: Value(cm['summary'] as String? ?? ''),
                status: Value(cm['status'] as String? ?? '大纲'),
                sortOrder: Value(cm['sortOrder'] as int? ?? 0),
                wordCount: Value(cm['wordCount'] as int? ?? 0),
                createdAt: Value(DateTime.parse(cm['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(cm['updatedAt'] as String)),
              ),
            );

        final scenesData = (cdm['scenes'] as List<dynamic>?) ?? [];
        for (final sc in scenesData) {
          final scm = sc as Map<String, dynamic>;
          await db
              .into(db.storyScenes)
              .insertOnConflictUpdate(
                StoryScenesCompanion(
                  id: Value(scm['id'] as int),
                  chapterId: Value(cId),
                  title: Value(scm['title'] as String),
                  summary: Value(scm['summary'] as String? ?? ''),
                  content: Value(scm['content'] as String? ?? ''),
                  povCharacterId: Value(scm['povCharacterId'] as int?),
                  locationId: Value(scm['locationId'] as int?),
                  locationName: Value(scm['locationName'] as String? ?? ''),
                  timelineTime: Value(scm['timelineTime'] as String? ?? ''),
                  mood: Value(scm['mood'] as String? ?? ''),
                  characterIds: Value(scm['characterIds'] as String? ?? '[]'),
                  sortOrder: Value(scm['sortOrder'] as int? ?? 0),
                  createdAt: Value(DateTime.parse(scm['createdAt'] as String)),
                  updatedAt: Value(DateTime.parse(scm['updatedAt'] as String)),
                ),
              );
        }
      }
    }
  }
}
