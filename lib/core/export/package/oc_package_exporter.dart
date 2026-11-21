import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../../data/database/app_database.dart';
import '../../storage/image_storage_service.dart';
import '../models/export_bundle.dart';

/// Handles exporting world or characters into a packaged .ocpkg archive.
class OcPackageExporter {
  final AppDatabase db;

  OcPackageExporter(this.db);

  /// Exports an entire world and all its characters/galleries/events into a single .ocpkg archive
  Future<void> exportWorldPackage({
    required int worldId,
    required String outputPath,
  }) async {
    final world = await (db.select(
      db.worlds,
    )..where((t) => t.id.equals(worldId))).getSingleOrNull();
    if (world == null) throw Exception('World not found with ID: $worldId');

    final characters = await (db.select(
      db.characters,
    )..where((t) => t.worldId.equals(worldId))).get();
    final characterIds = characters.map((c) => c.id).toSet();

    await _exportBundleInternal(
      outputPath: outputPath,
      packageType: 'world',
      title: world.name,
      description: world.description,
      world: world,
      characters: characters,
      characterIds: characterIds,
      worldId: worldId,
    );
  }

  /// Exports selected characters into an independent .ocpkg archive
  Future<void> exportCharactersPackage({
    required List<int> characterIds,
    required String title,
    required String outputPath,
    String? description,
  }) async {
    final characters = await (db.select(
      db.characters,
    )..where((t) => t.id.isIn(characterIds))).get();
    if (characters.isEmpty) {
      throw Exception('No characters selected for export');
    }

    await _exportBundleInternal(
      outputPath: outputPath,
      packageType: 'character',
      title: title,
      description: description,
      world: null,
      characters: characters,
      characterIds: characters.map((c) => c.id).toSet(),
      worldId: null,
    );
  }

  Future<void> _exportBundleInternal({
    required String outputPath,
    required String packageType,
    required String title,
    String? description,
    required World? world,
    required List<Character> characters,
    required Set<int> characterIds,
    required int? worldId,
  }) async {
    final archive = Archive();
    final imageService = ImageStorageService.instance;

    // 1. Gather auxiliary data
    final fields = await (db.select(
      db.characterFields,
    )..where((t) => t.characterId.isIn(characterIds))).get();
    final stats = await (db.select(
      db.characterStats,
    )..where((t) => t.characterId.isIn(characterIds))).get();
    final galleries = await (db.select(
      db.characterGalleries,
    )..where((t) => t.characterId.isIn(characterIds))).get();
    final charGroups = await (db.select(
      db.characterGroups,
    )..where((t) => t.characterId.isIn(characterIds))).get();
    final groupIds = charGroups.map((cg) => cg.groupId).toSet();
    final groups = groupIds.isNotEmpty
        ? await (db.select(db.groups)..where((t) => t.id.isIn(groupIds))).get()
        : <Group>[];

    final charTags = await (db.select(
      db.characterTags,
    )..where((t) => t.characterId.isIn(characterIds))).get();
    final tagIds = charTags.map((ct) => ct.tagId).toSet();
    final tags = tagIds.isNotEmpty
        ? await (db.select(db.tags)..where((t) => t.id.isIn(tagIds))).get()
        : <Tag>[];

    // Relations between exported characters
    final allRelations = await db.select(db.relations).get();
    final relations = allRelations
        .where(
          (r) =>
              characterIds.contains(r.fromCharacterId) &&
              characterIds.contains(r.toCharacterId),
        )
        .toList();

    // Timeline events
    List<TimelineEvent> timelineEvents = [];
    if (worldId != null) {
      timelineEvents = await (db.select(
        db.timelineEvents,
      )..where((t) => t.worldId.equals(worldId))).get();
    } else {
      timelineEvents = await (db.select(
        db.timelineEvents,
      )..where((t) => t.characterId.isIn(characterIds))).get();
    }

    // 2. Package media files into media/ folder in zip
    final avatarMediaMap = <int, String>{}; // charId -> 'media/avatar_xxx.png'
    for (final c in characters) {
      if (c.avatarPath != null) {
        final file = await imageService.resolveImageFile(c.avatarPath);
        if (file != null && await file.exists()) {
          final ext = p.extension(file.path);
          final zipName = 'media/avatar_${c.id}$ext';
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(zipName, bytes.length, bytes));
          avatarMediaMap[c.id] = zipName;
        }
      }
    }

    final galleryMediaMap =
        <int, String>{}; // galleryId -> 'media/gallery_xxx.png'
    for (final g in galleries) {
      final file = await imageService.resolveImageFile(g.imagePath);
      if (file != null && await file.exists()) {
        final ext = p.extension(file.path);
        final zipName = 'media/gallery_${g.id}$ext';
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(zipName, bytes.length, bytes));
        galleryMediaMap[g.id] = zipName;
      }
    }

    // 3. Build Manifest
    final manifest = PackageManifest(
      format: 'ocpkg',
      version: '1.0',
      appVersion: '1.8.0',
      exportDate: DateTime.now().toUtc().toIso8601String(),
      packageType: packageType,
      title: title,
      description: description,
      entityCounts: {
        'worlds': world != null ? 1 : 0,
        'characters': characters.length,
        'stats': stats.length,
        'galleries': galleries.length,
        'timelineEvents': timelineEvents.length,
        'relations': relations.length,
        'groups': groups.length,
        'mediaFiles': archive.files.length,
      },
    );

    // 4. Build Bundle JSON with mapped media paths
    final bundle = OcPackageBundle(
      manifest: manifest,
      world: world != null
          ? {
              'id': world.id,
              'name': world.name,
              'description': world.description,
              'isLocked': world.isLocked,
              'createdAt': world.createdAt.toIso8601String(),
              'updatedAt': world.updatedAt.toIso8601String(),
            }
          : null,
      characters: characters
          .map(
            (c) => {
              'id': c.id,
              'worldId': c.worldId,
              'name': c.name,
              'avatarPath': avatarMediaMap[c.id] ?? c.avatarPath,
              'gender': c.gender,
              'description': c.description,
              'status': c.status,
              'isFavorite': c.isFavorite,
              'isPinned': c.isPinned,
              'createdAt': c.createdAt.toIso8601String(),
              'updatedAt': c.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      characterFields: fields
          .map(
            (f) => {
              'id': f.id,
              'characterId': f.characterId,
              'fieldName': f.fieldName,
              'fieldType': f.fieldType,
              'value': f.value,
            },
          )
          .toList(),
      characterStats: stats
          .map(
            (s) => {
              'id': s.id,
              'characterId': s.characterId,
              'label': s.label,
              'value': s.value,
              'maxValue': s.maxValue,
              'sortOrder': s.sortOrder,
            },
          )
          .toList(),
      characterGalleries: galleries
          .map(
            (g) => {
              'id': g.id,
              'characterId': g.characterId,
              'imagePath': galleryMediaMap[g.id] ?? g.imagePath,
              'caption': g.caption,
              'isPrimary': g.isPrimary,
              'sortOrder': g.sortOrder,
              'createdAt': g.createdAt.toIso8601String(),
            },
          )
          .toList(),
      relations: relations
          .map(
            (r) => {
              'id': r.id,
              'fromCharacterId': r.fromCharacterId,
              'toCharacterId': r.toCharacterId,
              'relationType': r.relationType,
              'isBidirectional': r.isBidirectional,
              'note': r.note,
              'relationGroupId': r.relationGroupId,
            },
          )
          .toList(),
      groups: groups
          .map(
            (g) => {
              'id': g.id,
              'worldId': g.worldId,
              'name': g.name,
              'sortOrder': g.sortOrder,
              'createdAt': g.createdAt.toIso8601String(),
            },
          )
          .toList(),
      characterGroups: charGroups
          .map(
            (cg) => {
              'id': cg.id,
              'characterId': cg.characterId,
              'groupId': cg.groupId,
            },
          )
          .toList(),
      tags: tags
          .map((t) => {'id': t.id, 'name': t.name, 'color': t.color})
          .toList(),
      characterTags: charTags
          .map((ct) => {'characterId': ct.characterId, 'tagId': ct.tagId})
          .toList(),
      timelineEvents: timelineEvents
          .map(
            (e) => {
              'id': e.id,
              'worldId': e.worldId,
              'characterId': e.characterId,
              'year': e.year,
              'sortOrder': e.sortOrder,
              'title': e.title,
              'description': e.description,
              'category': e.category,
              'importance': e.importance,
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );

    // 5. Add manifest.json and data.json to archive
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final dataBytes = utf8.encode(bundle.serialize());
    archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));

    // 6. Encode and write out
    final zipEncoder = ZipEncoder();
    final outputBytes = zipEncoder.encode(archive);
    final outFile = File(outputPath);
    if (!outFile.parent.existsSync()) {
      await outFile.parent.create(recursive: true);
    }
    await outFile.writeAsBytes(outputBytes);
  }
}
