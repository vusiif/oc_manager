import 'dart:convert';

/// Conflict handling strategies when importing packages
enum ConflictPolicy {
  /// Create a new copy with "(Imported)" suffix and re-map all relations and foreign keys
  renameCopy,

  /// Overwrite existing characters/worlds if same name exists
  overwrite,

  /// Skip characters/worlds if same name already exists in target
  skip,
}

/// Supported export formats for Booklet
enum BookletFormat {
  /// Standalone HTML booklet styled for viewing and A4 PDF printing
  html,

  /// Markdown documentation tree zipped for Obsidian / Notion / Logseq
  markdownZip,
}

/// Metadata header stored in manifest.json inside .ocpkg
class PackageManifest {
  final String format;
  final String version;
  final String appVersion;
  final String exportDate;
  final String packageType; // 'world' or 'character'
  final String title;
  final String? description;
  final Map<String, int> entityCounts;

  const PackageManifest({
    this.format = 'ocpkg',
    this.version = '1.0',
    this.appVersion = '1.5.0',
    required this.exportDate,
    required this.packageType,
    required this.title,
    this.description,
    required this.entityCounts,
  });

  Map<String, dynamic> toJson() => {
        'format': format,
        'version': version,
        'appVersion': appVersion,
        'exportDate': exportDate,
        'packageType': packageType,
        'title': title,
        if (description != null) 'description': description,
        'entityCounts': entityCounts,
      };

  factory PackageManifest.fromJson(Map<String, dynamic> json) {
    return PackageManifest(
      format: json['format'] as String? ?? 'ocpkg',
      version: json['version'] as String? ?? '1.0',
      appVersion: json['appVersion'] as String? ?? '1.5.0',
      exportDate: json['exportDate'] as String? ?? DateTime.now().toIso8601String(),
      packageType: json['packageType'] as String? ?? 'world',
      title: json['title'] as String? ?? 'Untitled Package',
      description: json['description'] as String?,
      entityCounts: (json['entityCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
    );
  }
}

/// Complete bundle data exported into data.json
class OcPackageBundle {
  final PackageManifest manifest;
  final Map<String, dynamic>? world;
  final List<Map<String, dynamic>> characters;
  final List<Map<String, dynamic>> characterFields;
  final List<Map<String, dynamic>> characterStats;
  final List<Map<String, dynamic>> characterGalleries;
  final List<Map<String, dynamic>> relations;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> characterGroups;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> characterTags;
  final List<Map<String, dynamic>> timelineEvents;

  const OcPackageBundle({
    required this.manifest,
    this.world,
    this.characters = const [],
    this.characterFields = const [],
    this.characterStats = const [],
    this.characterGalleries = const [],
    this.relations = const [],
    this.groups = const [],
    this.characterGroups = const [],
    this.tags = const [],
    this.characterTags = const [],
    this.timelineEvents = const [],
  });

  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        if (world != null) 'world': world,
        'characters': characters,
        'characterFields': characterFields,
        'characterStats': characterStats,
        'characterGalleries': characterGalleries,
        'relations': relations,
        'groups': groups,
        'characterGroups': characterGroups,
        'tags': tags,
        'characterTags': characterTags,
        'timelineEvents': timelineEvents,
      };

  factory OcPackageBundle.fromJson(Map<String, dynamic> json) {
    final manifestJson = json['manifest'] as Map<String, dynamic>? ?? {};
    return OcPackageBundle(
      manifest: PackageManifest.fromJson(manifestJson),
      world: json['world'] as Map<String, dynamic>?,
      characters: (json['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      characterFields: (json['characterFields'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      characterStats: (json['characterStats'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      characterGalleries: (json['characterGalleries'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      relations: (json['relations'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      groups: (json['groups'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      characterGroups: (json['characterGroups'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      tags: (json['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      characterTags: (json['characterTags'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      timelineEvents: (json['timelineEvents'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  String serialize() => jsonEncode(toJson());
}
