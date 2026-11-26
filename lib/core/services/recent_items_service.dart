import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/character_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/world_provider.dart';

/// Entity kind tracked by [RecentItemsNotifier].
enum RecentItemType { world, character }

/// Represents a recently accessed or pinned workspace item.
class RecentItem {
  final RecentItemType type;
  final int id;
  final int worldId;
  final String title;
  final String subtitle;
  final bool isPinned;
  final DateTime accessedAt;

  const RecentItem({
    required this.type,
    required this.id,
    required this.worldId,
    required this.title,
    this.subtitle = '',
    this.isPinned = false,
    required this.accessedAt,
  });

  String get uniqueKey => '${type.name}:$id';

  RecentItem copyWith({
    String? title,
    String? subtitle,
    bool? isPinned,
    DateTime? accessedAt,
  }) {
    return RecentItem(
      type: type,
      id: id,
      worldId: worldId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isPinned: isPinned ?? this.isPinned,
      accessedAt: accessedAt ?? this.accessedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'worldId': worldId,
    'title': title,
    'subtitle': subtitle,
    'isPinned': isPinned,
    'accessedAt': accessedAt.toIso8601String(),
  };

  static RecentItem? fromJson(Map<String, dynamic> map) {
    final typeName = map['type'] as String?;
    final id = map['id'] as int?;
    final worldId = map['worldId'] as int?;
    final title = map['title'] as String?;
    if (typeName == null || id == null || worldId == null || title == null) {
      return null;
    }
    final type = RecentItemType.values
        .where((e) => e.name == typeName)
        .firstOrNull;
    if (type == null) return null;

    final rawDate = map['accessedAt'] as String?;
    final accessedAt =
        (rawDate != null ? DateTime.tryParse(rawDate) : null) ?? DateTime.now();

    return RecentItem(
      type: type,
      id: id,
      worldId: worldId,
      title: title,
      subtitle: (map['subtitle'] as String?) ?? '',
      isPinned: (map['isPinned'] as bool?) ?? false,
      accessedAt: accessedAt,
    );
  }
}

/// Pure helpers for managing recent & pinned workspace items.
class RecentItemsLogic {
  static const int defaultMaxUnpinned = 12;

  /// Inserts or updates [item] at the top while preserving pinned state.
  static List<RecentItem> upsertItem(
    List<RecentItem> current,
    RecentItem item, {
    int maxUnpinned = defaultMaxUnpinned,
  }) {
    final existing = current
        .where((e) => e.uniqueKey == item.uniqueKey)
        .firstOrNull;
    final merged = item.copyWith(
      isPinned: item.isPinned || (existing?.isPinned ?? false),
    );

    final filtered = current
        .where((e) => e.uniqueKey != item.uniqueKey)
        .toList();
    final updated = [merged, ...filtered];

    final pinned = updated.where((e) => e.isPinned).toList();
    final unpinned = updated
        .where((e) => !e.isPinned)
        .take(maxUnpinned)
        .toList();
    return [...pinned, ...unpinned];
  }

  /// Toggles pin status for an item identified by [uniqueKey].
  static List<RecentItem> togglePin(
    List<RecentItem> current,
    String uniqueKey,
  ) {
    final updated = current.map((e) {
      if (e.uniqueKey == uniqueKey) {
        return e.copyWith(isPinned: !e.isPinned);
      }
      return e;
    }).toList();
    final pinned = updated.where((e) => e.isPinned).toList();
    final unpinned = updated.where((e) => !e.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  /// Serializes items into JSON string.
  static String encode(List<RecentItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  /// Decodes JSON string defensively, ignoring malformed entries.
  static List<RecentItem> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final result = <RecentItem>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final parsed = RecentItem.fromJson(entry);
          if (parsed != null) result.add(parsed);
        } else if (entry is Map) {
          final parsed = RecentItem.fromJson(Map<String, dynamic>.from(entry));
          if (parsed != null) result.add(parsed);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}

/// Riverpod notifier persisting recent & pinned items in SettingsDao.
class RecentItemsNotifier extends StateNotifier<List<RecentItem>> {
  static const _settingsKey = 'recent_items_v1';
  final Ref _ref;

  RecentItemsNotifier(this._ref) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _ref.read(settingsDaoProvider).getValue(_settingsKey);
      if (!mounted) return;
      state = RecentItemsLogic.decode(raw);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await _ref
          .read(settingsDaoProvider)
          .setValue(_settingsKey, RecentItemsLogic.encode(state));
    } catch (_) {}
  }

  Future<void> recordWorld({
    required int worldId,
    required String worldName,
  }) async {
    state = RecentItemsLogic.upsertItem(
      state,
      RecentItem(
        type: RecentItemType.world,
        id: worldId,
        worldId: worldId,
        title: worldName,
        subtitle: '世界观',
        accessedAt: DateTime.now(),
      ),
    );
    await _persist();
  }

  Future<void> recordCharacter({
    required int characterId,
    required int worldId,
    required String characterName,
    String worldName = '',
  }) async {
    state = RecentItemsLogic.upsertItem(
      state,
      RecentItem(
        type: RecentItemType.character,
        id: characterId,
        worldId: worldId,
        title: characterName,
        subtitle: worldName.isNotEmpty ? worldName : '人物档案',
        accessedAt: DateTime.now(),
      ),
    );
    await _persist();
  }

  Future<void> togglePin(String uniqueKey) async {
    state = RecentItemsLogic.togglePin(state, uniqueKey);
    await _persist();
  }

  Future<void> removeItem(String uniqueKey) async {
    state = state.where((e) => e.uniqueKey != uniqueKey).toList();
    await _persist();
  }

  Future<void> clearUnpinned() async {
    state = state.where((e) => e.isPinned).toList();
    await _persist();
  }

  /// Resolves world name from provider and records access.
  Future<void> recordWorldById(int worldId) async {
    try {
      final world = await _ref.read(worldByIdProvider(worldId).future);
      if (!mounted) return;
      await recordWorld(worldId: world.id, worldName: world.name);
    } catch (_) {}
  }

  /// Resolves character & world names from providers and records access.
  Future<void> recordCharacterById(int worldId, int characterId) async {
    try {
      final char = await _ref.read(characterByIdProvider(characterId).future);
      final world = await _ref.read(worldByIdProvider(worldId).future);
      if (!mounted) return;
      await recordCharacter(
        characterId: char.id,
        worldId: worldId,
        characterName: char.name,
        worldName: world.name,
      );
    } catch (_) {}
  }
}

final recentItemsProvider =
    StateNotifierProvider<RecentItemsNotifier, List<RecentItem>>((ref) {
      return RecentItemsNotifier(ref);
    });
