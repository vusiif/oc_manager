import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/revisions.dart';
import '../../../core/history/models/character_snapshot.dart';

part 'revision_dao.g.dart';

@DriftAccessor(tables: [EntityRevisions])
class RevisionDao extends DatabaseAccessor<AppDatabase>
    with _$RevisionDaoMixin {
  RevisionDao(super.db);

  /// 获取指定实体的历史版本列表（最新在前）
  Future<List<EntityRevision>> getRevisions(String entityType, int entityId) {
    return (select(entityRevisions)
          ..where(
            (t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// 监听指定实体的历史版本列表
  Stream<List<EntityRevision>> watchRevisions(String entityType, int entityId) {
    return (select(entityRevisions)
          ..where(
            (t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// 获取某世界观下的所有快照数量
  Future<int> countRevisionsByWorld(int worldId) async {
    final countExp = entityRevisions.id.count();
    final query = selectOnly(entityRevisions)
      ..where(entityRevisions.worldId.equals(worldId))
      ..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// 记录一条新快照（如果与最新一条内容一致则跳过，超过 maxRetain 自动修剪最早记录）
  Future<int?> recordRevision({
    required int worldId,
    required String entityType,
    required int entityId,
    required String content,
    String? title,
    int maxRetain = 30,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return null;

    final existing =
        await (select(entityRevisions)
              ..where(
                (t) =>
                    t.entityType.equals(entityType) &
                    t.entityId.equals(entityId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .get();

    // 如果与最新一条快照内容完全相同，无需重复打快照
    if (existing.isNotEmpty && existing.first.content.trim() == cleanContent) {
      return existing.first.id;
    }

    final autoTitle =
        title ??
        '快照 · ${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final id = await into(entityRevisions).insert(
      EntityRevisionsCompanion.insert(
        worldId: worldId,
        entityType: entityType,
        entityId: entityId,
        title: Value(autoTitle),
        content: cleanContent,
        charCount: Value(cleanContent.length),
      ),
    );

    // 自动修剪超过 maxRetain 的老记录
    final all =
        await (select(entityRevisions)
              ..where(
                (t) =>
                    t.entityType.equals(entityType) &
                    t.entityId.equals(entityId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)]))
            .get();

    // 自动修剪超过 maxRetain 的老记录 (HISTORY-001 保留策略: 里程碑快照受保护跳过，仅淘汰普通记录)
    if (all.length > maxRetain) {
      final candidates = all.sublist(maxRetain);
      final toDeleteIds = <int>[];
      for (final rev in candidates) {
        if (!rev.content.contains('"isMilestone":true')) {
          toDeleteIds.add(rev.id);
        }
      }
      if (toDeleteIds.isNotEmpty) {
        await (delete(
          entityRevisions,
        )..where((t) => t.id.isIn(toDeleteIds))).go();
      }
    }

    return id;
  }

  /// 切换快照的里程碑标记 (HISTORY-001)
  Future<bool> toggleMilestone(int revisionId, bool isMilestone) async {
    final rev = await getRevisionById(revisionId);
    if (rev == null) return false;

    String newContent = rev.content;
    if (newContent.startsWith('{') && newContent.contains('"_snapshot_type"')) {
      try {
        final Map<String, dynamic> map = jsonDecode(newContent);
        map['isMilestone'] = isMilestone;
        newContent = jsonEncode(map);
      } catch (_) {}
    } else {
      final snapshot = CharacterSnapshot(
        description: rev.content,
        name: rev.title,
        isMilestone: isMilestone,
        timestamp: rev.createdAt,
      );
      newContent = snapshot.toJsonString();
    }

    await (update(entityRevisions)..where((t) => t.id.equals(revisionId)))
        .write(EntityRevisionsCompanion(content: Value(newContent)));
    return true;
  }

  Future<EntityRevision?> getRevisionById(int id) => (select(
    entityRevisions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteRevision(int id) =>
      (delete(entityRevisions)..where((t) => t.id.equals(id))).go();

  Future<int> deleteRevisions(String entityType, int entityId) =>
      (delete(entityRevisions)..where(
            (t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          ))
          .go();

  Future<int> deleteRevisionsByWorld(int worldId) =>
      (delete(entityRevisions)..where((t) => t.worldId.equals(worldId))).go();
}
