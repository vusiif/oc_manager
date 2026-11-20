import 'dart:convert';
import '../../../data/database/app_database.dart';

/// 编年史大事件与生平事件版本历史快照模型 (HISTORY-004)
class EventSnapshot {
  final int schemaVersion;
  final String source; // 'manual', 'auto', 'restore_backup'
  final bool isMilestone;
  final String? note;
  final String title;
  final String year;
  final String category;
  final String description;
  final int importance;
  final int? characterId;
  final DateTime timestamp;

  const EventSnapshot({
    this.schemaVersion = 1,
    this.source = 'manual',
    this.isMilestone = false,
    this.note,
    required this.title,
    required this.year,
    required this.category,
    required this.description,
    required this.importance,
    this.characterId,
    required this.timestamp,
  });

  factory EventSnapshot.fromEntity(
    TimelineEvent event, {
    String source = 'manual',
    bool isMilestone = false,
    String? note,
  }) {
    return EventSnapshot(
      schemaVersion: 1,
      source: source,
      isMilestone: isMilestone,
      note: note,
      title: event.title,
      year: event.year,
      category: event.category,
      description: event.description,
      importance: event.importance,
      characterId: event.characterId,
      timestamp: DateTime.now(),
    );
  }

  String toJsonString() {
    final map = {
      '_snapshot_type': 'event_v1',
      'schemaVersion': schemaVersion,
      'source': source,
      'isMilestone': isMilestone,
      'note': note,
      'title': title,
      'year': year,
      'category': category,
      'description': description,
      'importance': importance,
      'characterId': characterId,
      'timestamp': timestamp.toIso8601String(),
    };
    return jsonEncode(map);
  }

  factory EventSnapshot.parse(
    String rawContent, {
    String defaultTitle = '',
    DateTime? defaultTimestamp,
  }) {
    final clean = rawContent.trim();
    if (clean.startsWith('{') && clean.contains('"_snapshot_type"')) {
      try {
        final Map<String, dynamic> map = jsonDecode(clean);
        return EventSnapshot(
          schemaVersion: map['schemaVersion'] as int? ?? 1,
          source: map['source'] as String? ?? 'auto',
          isMilestone: map['isMilestone'] as bool? ?? false,
          note: map['note'] as String?,
          title: map['title'] as String? ?? defaultTitle,
          year: map['year'] as String? ?? '',
          category: map['category'] as String? ?? 'normal',
          description: map['description'] as String? ?? '',
          importance: map['importance'] as int? ?? 1,
          characterId: map['characterId'] as int?,
          timestamp: map['timestamp'] != null
              ? DateTime.tryParse(map['timestamp']) ??
                    defaultTimestamp ??
                    DateTime.now()
              : defaultTimestamp ?? DateTime.now(),
        );
      } catch (_) {}
    }

    // 向上兼容旧版纯描述文本
    return EventSnapshot(
      schemaVersion: 0,
      source: 'legacy',
      isMilestone: false,
      title: defaultTitle,
      year: '',
      category: 'normal',
      description: clean,
      importance: 1,
      timestamp: defaultTimestamp ?? DateTime.now(),
    );
  }
}
