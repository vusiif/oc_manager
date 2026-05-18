import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final trashListProvider = FutureProvider<List<TrashData>>((ref) {
  ref.watch(trashRefreshProvider);
  return ref.watch(trashDaoProvider).getAllTrash();
});

/// 用于触发回收站刷新
final trashRefreshProvider = StateProvider<int>((ref) => 0);

final trashActionsProvider = Provider((ref) => TrashActions(ref));

class TrashActions {
  final Ref _ref;

  TrashActions(this._ref);

  /// 软删除人物：存入回收站后硬删除
  Future<void> deleteCharacter(Character character) async {
    final data = jsonEncode({
      'id': character.id,
      'worldId': character.worldId,
      'name': character.name,
      'avatarPath': character.avatarPath,
      'gender': character.gender,
      'description': character.description,
      'status': character.status,
      'isFavorite': character.isFavorite,
      'isPinned': character.isPinned,
      'createdAt': character.createdAt.toIso8601String(),
    });
    await _ref.read(trashDaoProvider).addToTrash(
          TrashCompanion(
            itemType: const Value('character'),
            itemId: Value(character.id),
            itemData: Value(data),
          ),
        );
    await _ref.read(characterDaoProvider).deleteCharacter(character.id);
    _refresh();
  }

  /// 软删除世界观：存入回收站后硬删除
  Future<void> deleteWorld(World world) async {
    final data = jsonEncode({
      'id': world.id,
      'name': world.name,
      'description': world.description,
      'isLocked': world.isLocked,
      'createdAt': world.createdAt.toIso8601String(),
    });
    await _ref.read(trashDaoProvider).addToTrash(
          TrashCompanion(
            itemType: const Value('world'),
            itemId: Value(world.id),
            itemData: Value(data),
          ),
        );
    await _ref.read(worldDaoProvider).deleteWorld(world.id);
    _refresh();
  }

  /// 恢复人物
  Future<void> restoreCharacter(TrashData trashItem) async {
    final data = jsonDecode(trashItem.itemData) as Map<String, dynamic>;
    await _ref.read(characterDaoProvider).createCharacter(
          CharactersCompanion(
            id: Value(data['id'] as int),
            worldId: Value(data['worldId'] as int),
            name: Value(data['name'] as String),
            avatarPath: Value(data['avatarPath'] as String?),
            gender: Value(data['gender'] as String? ?? ''),
            description: Value(data['description'] as String? ?? ''),
            status: Value(data['status'] as int),
            isFavorite: Value(data['isFavorite'] as bool),
            isPinned: Value(data['isPinned'] as bool),
            createdAt: Value(DateTime.parse(data['createdAt'] as String)),
          ),
        );
    await _ref.read(trashDaoProvider).removeFromTrash(trashItem.id);
    _refresh();
  }

  /// 恢复世界观
  Future<void> restoreWorld(TrashData trashItem) async {
    final data = jsonDecode(trashItem.itemData) as Map<String, dynamic>;
    await _ref.read(worldDaoProvider).createWorld(
          WorldsCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
            description: Value(data['description'] as String?),
            isLocked: Value(data['isLocked'] as bool),
            createdAt: Value(DateTime.parse(data['createdAt'] as String)),
          ),
        );
    await _ref.read(trashDaoProvider).removeFromTrash(trashItem.id);
    _refresh();
  }

  /// 永久删除
  Future<void> permanentDelete(int trashId) async {
    await _ref.read(trashDaoProvider).removeFromTrash(trashId);
    _refresh();
  }

  /// 清空回收站
  Future<void> emptyTrash() async {
    await _ref.read(trashDaoProvider).cleanOldTrash(DateTime(2100));
    _refresh();
  }

  void _refresh() {
    _ref.read(trashRefreshProvider.notifier).state++;
  }
}
