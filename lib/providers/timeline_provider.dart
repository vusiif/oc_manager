import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/timeline_dao.dart';
import 'database_provider.dart';

/// 编年史事件分类定义
class TimelineCategoryConfig {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const TimelineCategoryConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const List<TimelineCategoryConfig> all = [
    TimelineCategoryConfig(
      key: 'origin',
      label: '起源 / 诞生',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFF59E0B),
    ),
    TimelineCategoryConfig(
      key: 'turning_point',
      label: '命运转折',
      icon: Icons.explore_rounded,
      color: Color(0xFF3B82F6),
    ),
    TimelineCategoryConfig(
      key: 'battle',
      label: '战役 / 冲突',
      icon: Icons.shield_rounded,
      color: Color(0xFFEF4444),
    ),
    TimelineCategoryConfig(
      key: 'achievement',
      label: '荣耀 / 成就',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF8B5CF6),
    ),
    TimelineCategoryConfig(
      key: 'crisis',
      label: '浩劫 / 危机',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFEC4899),
    ),
    TimelineCategoryConfig(
      key: 'general',
      label: '纪事 / 日常',
      icon: Icons.history_edu_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  static TimelineCategoryConfig find(String? key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.last,
    );
  }
}

/// 监听某世界观下的全部编年史事件
final worldTimelineEventsProvider =
    StreamProvider.family<List<TimelineEvent>, int>((ref, worldId) {
  return ref.watch(timelineDaoProvider).watchEventsByWorld(worldId);
});

/// 监听某角色的个人生平事件
final characterTimelineEventsProvider =
    StreamProvider.family<List<TimelineEvent>, int>((ref, characterId) {
  return ref.watch(timelineDaoProvider).watchEventsByCharacter(characterId);
});

final timelineActionsProvider = Provider((ref) => TimelineActions(ref));

class TimelineActions {
  final Ref _ref;

  TimelineActions(this._ref);

  TimelineDao get _dao => _ref.read(timelineDaoProvider);

  /// 创建新事件
  Future<int> createEvent({
    required int worldId,
    int? characterId,
    required String year,
    double sortOrder = 0.0,
    required String title,
    String description = '',
    String category = 'general',
    int importance = 1,
  }) async {
    return _dao.createEvent(
      TimelineEventsCompanion(
        worldId: Value(worldId),
        characterId: Value(characterId),
        year: Value(year.trim()),
        sortOrder: Value(sortOrder),
        title: Value(title.trim()),
        description: Value(description.trim()),
        category: Value(category),
        importance: Value(importance.clamp(1, 3)),
      ),
    );
  }

  /// 更新事件
  Future<void> updateEvent({
    required int id,
    required int worldId,
    int? characterId,
    required String year,
    required double sortOrder,
    required String title,
    required String description,
    required String category,
    required int importance,
  }) async {
    await _dao.updateEvent(
      TimelineEventsCompanion(
        id: Value(id),
        worldId: Value(worldId),
        characterId: Value(characterId),
        year: Value(year.trim()),
        sortOrder: Value(sortOrder),
        title: Value(title.trim()),
        description: Value(description.trim()),
        category: Value(category),
        importance: Value(importance.clamp(1, 3)),
      ),
    );
  }

  /// 删除单条事件
  Future<int> deleteEvent(int id) async {
    return _dao.deleteEvent(id);
  }
}
