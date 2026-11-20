import 'dart:convert';
import '../../../data/database/app_database.dart';

/// 世界观百科实体（地点、组织、物品、种族、能力规则等）版本历史快照模型 (HISTORY-004)
class LoreSnapshot {
  final int schemaVersion;
  final String source; // 'manual', 'auto', 'restore_backup', 'legacy'
  final bool isMilestone;
  final String? note;
  final String name;
  final String
  entityType; // 'location', 'organization', 'item', 'race', 'rule', 'concept'
  final String summary;
  final String content;
  final String? coverImagePath;
  final int? parentId;
  final Map<String, String> customFields;
  final List<String> tags;
  final DateTime timestamp;

  const LoreSnapshot({
    this.schemaVersion = 1,
    this.source = 'manual',
    this.isMilestone = false,
    this.note,
    required this.name,
    required this.entityType,
    this.summary = '',
    required this.content,
    this.coverImagePath,
    this.parentId,
    this.customFields = const {},
    this.tags = const [],
    required this.timestamp,
  });

  /// 从当前数据库实体构建快照
  factory LoreSnapshot.fromEntity(
    LoreEntity entity, {
    String source = 'manual',
    bool isMilestone = false,
    String? note,
  }) {
    // 解析 tags
    List<String> parsedTags = [];
    if (entity.tags.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(entity.tags);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    // 解析 customFields
    Map<String, String> parsedFields = {};
    if (entity.customFields.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(entity.customFields);
        if (decoded is Map) {
          parsedFields = decoded.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }
      } catch (_) {}
    }

    return LoreSnapshot(
      schemaVersion: 1,
      source: source,
      isMilestone: isMilestone,
      note: note,
      name: entity.name,
      entityType: entity.entityType,
      summary: entity.summary,
      content: entity.content,
      coverImagePath: entity.coverImagePath,
      parentId: entity.parentId,
      customFields: parsedFields,
      tags: parsedTags,
      timestamp: DateTime.now(),
    );
  }

  /// 序列化为 JSON 字符串以便存入 EntityRevisions.content
  String toJsonString() {
    final map = {
      '_snapshot_type': 'lore_v1',
      'schemaVersion': schemaVersion,
      'source': source,
      'isMilestone': isMilestone,
      'note': note,
      'name': name,
      'entityType': entityType,
      'summary': summary,
      'content': content,
      'coverImagePath': coverImagePath,
      'parentId': parentId,
      'customFields': customFields,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
    };
    return jsonEncode(map);
  }

  /// 从字符串解析。若是 JSON 则解析为结构化快照，否则降级为旧版纯文本正文快照
  factory LoreSnapshot.parse(
    String rawContent, {
    String defaultName = '',
    String defaultType = 'location',
    DateTime? defaultTimestamp,
  }) {
    final clean = rawContent.trim();
    if (clean.startsWith('{') && clean.contains('"_snapshot_type"')) {
      try {
        final Map<String, dynamic> map = jsonDecode(clean);
        return LoreSnapshot(
          schemaVersion: map['schemaVersion'] as int? ?? 1,
          source: map['source'] as String? ?? 'auto',
          isMilestone: map['isMilestone'] as bool? ?? false,
          note: map['note'] as String?,
          name: map['name'] as String? ?? defaultName,
          entityType: map['entityType'] as String? ?? defaultType,
          summary: map['summary'] as String? ?? '',
          content: map['content'] as String? ?? '',
          coverImagePath: map['coverImagePath'] as String?,
          parentId: map['parentId'] as int?,
          customFields:
              (map['customFields'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v.toString()),
              ) ??
              const {},
          tags:
              (map['tags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          timestamp: map['timestamp'] != null
              ? DateTime.tryParse(map['timestamp']) ??
                    defaultTimestamp ??
                    DateTime.now()
              : defaultTimestamp ?? DateTime.now(),
        );
      } catch (_) {
        // Fallback to legacy plain text
      }
    }

    // 向上兼容旧版纯正文文本快照
    return LoreSnapshot(
      schemaVersion: 0,
      source: 'legacy',
      isMilestone: false,
      name: defaultName,
      entityType: defaultType,
      summary: '',
      content: clean,
      timestamp: defaultTimestamp ?? DateTime.now(),
    );
  }

  LoreSnapshot copyWith({
    int? schemaVersion,
    String? source,
    bool? isMilestone,
    String? note,
    String? name,
    String? entityType,
    String? summary,
    String? content,
    String? coverImagePath,
    int? parentId,
    Map<String, String>? customFields,
    List<String>? tags,
    DateTime? timestamp,
  }) {
    return LoreSnapshot(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      source: source ?? this.source,
      isMilestone: isMilestone ?? this.isMilestone,
      note: note ?? this.note,
      name: name ?? this.name,
      entityType: entityType ?? this.entityType,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      parentId: parentId ?? this.parentId,
      customFields: customFields ?? this.customFields,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
