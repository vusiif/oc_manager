import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/timeline.dart';

part 'timeline_dao.g.dart';

@DriftAccessor(tables: [TimelineEvents])
class TimelineDao extends DatabaseAccessor<AppDatabase>
    with _$TimelineDaoMixin {
  TimelineDao(super.db);

  /// 获取该世界观下的所有事件（按排序权重与创建时间保序）
  Future<List<TimelineEvent>> getEventsByWorld(int worldId) =>
      (select(timelineEvents)
            ..where((t) => t.worldId.equals(worldId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .get();

  /// 监听该世界观下的所有事件
  Stream<List<TimelineEvent>> watchEventsByWorld(int worldId) =>
      (select(timelineEvents)
            ..where((t) => t.worldId.equals(worldId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 获取某角色的个人生平事件
  Future<List<TimelineEvent>> getEventsByCharacter(int characterId) =>
      (select(timelineEvents)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .get();

  /// 监听某角色的个人生平事件
  Stream<List<TimelineEvent>> watchEventsByCharacter(int characterId) =>
      (select(timelineEvents)
            ..where((t) => t.characterId.equals(characterId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<int> createEvent(TimelineEventsCompanion entry) =>
      into(timelineEvents).insert(entry);

  Future<void> updateEvent(TimelineEventsCompanion entry) =>
      update(timelineEvents).replace(entry);

  Future<int> deleteEvent(int id) =>
      (delete(timelineEvents)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllEventsByCharacter(int characterId) =>
      (delete(timelineEvents)
            ..where((t) => t.characterId.equals(characterId)))
          .go();

  Future<void> deleteAllEventsByWorld(int worldId) =>
      (delete(timelineEvents)
            ..where((t) => t.worldId.equals(worldId)))
          .go();
}
