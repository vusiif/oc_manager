import 'dart:convert';

/// 人设版本历史快照模型 (HISTORY-001)
class CharacterSnapshot {
  final int schemaVersion;
  final String source; // 'manual', 'auto', 'restore_backup'
  final bool isMilestone;
  final String? note;
  final String name;
  final String? gender;
  final String? age;
  final String? avatarPath;
  final String description;
  final Map<String, String> customFields;
  final List<String> tags;
  final DateTime timestamp;

  const CharacterSnapshot({
    this.schemaVersion = 1,
    this.source = 'manual',
    this.isMilestone = false,
    this.note,
    required this.name,
    this.gender,
    this.age,
    this.avatarPath,
    required this.description,
    this.customFields = const {},
    this.tags = const [],
    required this.timestamp,
  });

  /// 序列化为 JSON 字符串以便存入 EntityRevisions.content
  String toJsonString() {
    final map = {
      '_snapshot_type': 'character_v1',
      'schemaVersion': schemaVersion,
      'source': source,
      'isMilestone': isMilestone,
      'note': note,
      'name': name,
      'gender': gender,
      'age': age,
      'avatarPath': avatarPath,
      'description': description,
      'customFields': customFields,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
    };
    return jsonEncode(map);
  }

  /// 从字符串解析。如果是 JSON 格式则解析为结构化快照，否则作为旧版纯小传兼容
  factory CharacterSnapshot.parse(
    String rawContent, {
    String defaultName = '',
    DateTime? defaultTimestamp,
  }) {
    final clean = rawContent.trim();
    if (clean.startsWith('{') && clean.contains('"_snapshot_type"')) {
      try {
        final Map<String, dynamic> map = jsonDecode(clean);
        return CharacterSnapshot(
          schemaVersion: map['schemaVersion'] as int? ?? 1,
          source: map['source'] as String? ?? 'auto',
          isMilestone: map['isMilestone'] as bool? ?? false,
          note: map['note'] as String?,
          name: map['name'] as String? ?? defaultName,
          gender: map['gender'] as String?,
          age: map['age'] as String?,
          avatarPath: map['avatarPath'] as String?,
          description: map['description'] as String? ?? '',
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

    // 向上兼容旧版纯小传文本快照
    return CharacterSnapshot(
      schemaVersion: 0,
      source: 'legacy',
      isMilestone: false,
      name: defaultName,
      description: clean,
      timestamp: defaultTimestamp ?? DateTime.now(),
    );
  }

  CharacterSnapshot copyWith({
    int? schemaVersion,
    String? source,
    bool? isMilestone,
    String? note,
    String? name,
    String? gender,
    String? age,
    String? avatarPath,
    String? description,
    Map<String, String>? customFields,
    List<String>? tags,
    DateTime? timestamp,
  }) {
    return CharacterSnapshot(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      source: source ?? this.source,
      isMilestone: isMilestone ?? this.isMilestone,
      note: note ?? this.note,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      customFields: customFields ?? this.customFields,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
