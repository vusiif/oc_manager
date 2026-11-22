import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'character_provider.dart';
import 'database_provider.dart';
import 'group_provider.dart';
import 'lore_provider.dart';
import 'relation_provider.dart';
import 'story_provider.dart';
import 'timeline_provider.dart';
import 'trash/character_trash_handler.dart';
import 'trash/world_trash_handler.dart';
import 'world_provider.dart';

final trashListProvider = FutureProvider<List<TrashData>>((ref) {
  ref.watch(trashRefreshProvider);
  return ref.watch(trashDaoProvider).getAllTrash();
});

/// 用于触发回收站刷新
final trashRefreshProvider = StateProvider<int>((ref) => 0);

final trashActionsProvider = Provider((ref) => TrashActions(ref));

class TrashActions {
  final Ref _ref;
  late final CharacterTrashHandler _characterHandler;
  late final WorldTrashHandler _worldHandler;

  TrashActions(this._ref) {
    _characterHandler = CharacterTrashHandler(
      db: _db,
      onInvalidate: _invalidateRelated,
    );
    _worldHandler = WorldTrashHandler(
      db: _db,
      onInvalidate: _invalidateRelated,
    );
  }

  AppDatabase get _db => _ref.read(databaseProvider);

  /// 软删除人物：完整快照（包含字段、标签、分组与关系图坐标）后事务删除
  Future<void> deleteCharacter(Character character) =>
      _characterHandler.deleteCharacter(character);

  /// 软删除世界观：包含该世界观下所有角色、分组、关系和布局的完整快照
  Future<void> deleteWorld(World world) => _worldHandler.deleteWorld(world);

  /// 恢复人物（事务原子还原角色及字段、标签、分组映射与布局）
  Future<void> restoreCharacter(TrashData trashItem) =>
      _characterHandler.restoreCharacter(trashItem);

  /// 恢复世界观
  Future<void> restoreWorld(TrashData trashItem) =>
      _worldHandler.restoreWorld(trashItem);

  /// 永久删除
  Future<void> permanentDelete(int trashId) async {
    await _db.trashDao.removeFromTrash(trashId);
    _refresh();
  }

  /// 清空回收站
  Future<void> emptyTrash() async {
    await _db.trashDao.cleanOldTrash(DateTime(2100));
    _refresh();
  }

  void _invalidateRelated(int worldId) {
    _ref.invalidate(worldsProvider);
    _ref.invalidate(worldByIdProvider(worldId));
    _ref.invalidate(charactersByWorldProvider(worldId));
    _ref.invalidate(groupsByWorldProvider(worldId));
    _ref.invalidate(relationsByWorldProvider(worldId));
    _ref.invalidate(graphLayoutsProvider(worldId));
    _ref.invalidate(worldTimelineEventsProvider(worldId));
    _ref.invalidate(loreEntitiesByWorldProvider(worldId));
    _ref.invalidate(worksByWorldProvider(worldId));
    _refresh();
  }

  void _refresh() {
    _ref.read(trashRefreshProvider.notifier).state++;
  }
}
