import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/database/app_database.dart';
import '../storage/image_storage_service.dart';
import 'models/export_bundle.dart';

/// Inspection summary shown to the user before confirming import
class PackageInspectionResult {
  final PackageManifest manifest;
  final List<String> characterNames;
  final int mediaCount;
  final int fileSizeBytes;
  final List<String> existingConflictedCharacters;
  final bool hasWorldConflict;

  const PackageInspectionResult({
    required this.manifest,
    required this.characterNames,
    required this.mediaCount,
    required this.fileSizeBytes,
    required this.existingConflictedCharacters,
    required this.hasWorldConflict,
  });
}

/// Statistics reported after import completes
class ImportResult {
  final int importedCharacters;
  final int importedTimelineEvents;
  final int importedRelations;
  final int importedGalleries;
  final int importedGroups;
  final List<String> createdCharacterNames;
  final List<String> skippedCharacterNames;

  const ImportResult({
    required this.importedCharacters,
    required this.importedTimelineEvents,
    required this.importedRelations,
    required this.importedGalleries,
    required this.importedGroups,
    required this.createdCharacterNames,
    required this.skippedCharacterNames,
  });
}

/// Service handling packaging (.ocpkg export) and importing with conflict resolution
class OcPackageService {
  final AppDatabase db;

  OcPackageService(this.db);

  // ==========================================
  // Export .ocpkg
  // ==========================================

  /// Exports an entire world and all its characters/galleries/events into a single .ocpkg archive
  Future<void> exportWorldPackage({
    required int worldId,
    required String outputPath,
  }) async {
    final world = await (db.select(db.worlds)..where((t) => t.id.equals(worldId))).getSingleOrNull();
    if (world == null) throw Exception('World not found with ID: $worldId');

    final characters = await (db.select(db.characters)..where((t) => t.worldId.equals(worldId))).get();
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
    final characters = await (db.select(db.characters)..where((t) => t.id.isIn(characterIds))).get();
    if (characters.isEmpty) throw Exception('No characters selected for export');

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
    final fields = await (db.select(db.characterFields)..where((t) => t.characterId.isIn(characterIds))).get();
    final stats = await (db.select(db.characterStats)..where((t) => t.characterId.isIn(characterIds))).get();
    final galleries = await (db.select(db.characterGalleries)..where((t) => t.characterId.isIn(characterIds))).get();
    final charGroups = await (db.select(db.characterGroups)..where((t) => t.characterId.isIn(characterIds))).get();
    final groupIds = charGroups.map((cg) => cg.groupId).toSet();
    final groups = groupIds.isNotEmpty
        ? await (db.select(db.groups)..where((t) => t.id.isIn(groupIds))).get()
        : <Group>[];

    final charTags = await (db.select(db.characterTags)..where((t) => t.characterId.isIn(characterIds))).get();
    final tagIds = charTags.map((ct) => ct.tagId).toSet();
    final tags = tagIds.isNotEmpty
        ? await (db.select(db.tags)..where((t) => t.id.isIn(tagIds))).get()
        : <Tag>[];

    // Relations between exported characters
    final allRelations = await db.select(db.relations).get();
    final relations = allRelations
        .where((r) => characterIds.contains(r.fromCharacterId) && characterIds.contains(r.toCharacterId))
        .toList();

    // Timeline events
    List<TimelineEvent> timelineEvents = [];
    if (worldId != null) {
      timelineEvents = await (db.select(db.timelineEvents)..where((t) => t.worldId.equals(worldId))).get();
    } else {
      timelineEvents = await (db.select(db.timelineEvents)..where((t) => t.characterId.isIn(characterIds))).get();
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

    final galleryMediaMap = <int, String>{}; // galleryId -> 'media/gallery_xxx.png'
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
      appVersion: '1.5.0',
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
          .map((c) => {
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
              })
          .toList(),
      characterFields: fields
          .map((f) => {
                'id': f.id,
                'characterId': f.characterId,
                'fieldName': f.fieldName,
                'fieldType': f.fieldType,
                'value': f.value,
              })
          .toList(),
      characterStats: stats
          .map((s) => {
                'id': s.id,
                'characterId': s.characterId,
                'label': s.label,
                'value': s.value,
                'maxValue': s.maxValue,
                'sortOrder': s.sortOrder,
              })
          .toList(),
      characterGalleries: galleries
          .map((g) => {
                'id': g.id,
                'characterId': g.characterId,
                'imagePath': galleryMediaMap[g.id] ?? g.imagePath,
                'caption': g.caption,
                'isPrimary': g.isPrimary,
                'sortOrder': g.sortOrder,
                'createdAt': g.createdAt.toIso8601String(),
              })
          .toList(),
      relations: relations
          .map((r) => {
                'id': r.id,
                'fromCharacterId': r.fromCharacterId,
                'toCharacterId': r.toCharacterId,
                'relationType': r.relationType,
                'isBidirectional': r.isBidirectional,
                'note': r.note,
                'relationGroupId': r.relationGroupId,
              })
          .toList(),
      groups: groups
          .map((g) => {
                'id': g.id,
                'worldId': g.worldId,
                'name': g.name,
                'sortOrder': g.sortOrder,
                'createdAt': g.createdAt.toIso8601String(),
              })
          .toList(),
      characterGroups: charGroups
          .map((cg) => {
                'id': cg.id,
                'characterId': cg.characterId,
                'groupId': cg.groupId,
              })
          .toList(),
      tags: tags
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'color': t.color,
              })
          .toList(),
      characterTags: charTags
          .map((ct) => {
                'characterId': ct.characterId,
                'tagId': ct.tagId,
              })
          .toList(),
      timelineEvents: timelineEvents
          .map((e) => {
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
              })
          .toList(),
    );

    // 5. Add manifest.json and data.json to archive
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

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

  // ==========================================
  // Inspect .ocpkg
  // ==========================================

  /// Reads and inspects an .ocpkg file without modifying database
  Future<PackageInspectionResult> inspectPackage(String packagePath) async {
    final file = File(packagePath);
    if (!await file.exists()) {
      throw Exception('Package file does not exist: $packagePath');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Read manifest.json
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw Exception('Invalid .ocpkg package: missing manifest.json');
    }
    final manifestJson = jsonDecode(utf8.decode(manifestFile.content as List<int>));
    final manifest = PackageManifest.fromJson(manifestJson as Map<String, dynamic>);

    // Read data.json
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw Exception('Invalid .ocpkg package: missing data.json');
    }
    final bundleJson = jsonDecode(utf8.decode(dataFile.content as List<int>));
    final bundle = OcPackageBundle.fromJson(bundleJson as Map<String, dynamic>);

    final charNames = bundle.characters.map((c) => (c['name'] as String?) ?? '未命名').toList();

    // Check conflicts against existing database
    final existingChars = await db.select(db.characters).get();
    final existingNames = existingChars.map((c) => c.name).toSet();
    final conflicts = charNames.where((n) => existingNames.contains(n)).toList();

    bool hasWorldConflict = false;
    if (bundle.world != null) {
      final worldName = bundle.world!['name'] as String?;
      if (worldName != null) {
        final existingWorlds = await db.select(db.worlds).get();
        hasWorldConflict = existingWorlds.any((w) => w.name == worldName);
      }
    }

    final mediaCount = archive.files.where((f) => f.name.startsWith('media/') && !f.name.endsWith('/')).length;

    return PackageInspectionResult(
      manifest: manifest,
      characterNames: charNames,
      mediaCount: mediaCount,
      fileSizeBytes: bytes.length,
      existingConflictedCharacters: conflicts,
      hasWorldConflict: hasWorldConflict,
    );
  }

  // ==========================================
  // Import .ocpkg
  // ==========================================

  /// Imports an .ocpkg into database following specified [conflictPolicy]
  Future<ImportResult> importPackage({
    required String packagePath,
    required ConflictPolicy conflictPolicy,
    int? targetWorldId,
  }) async {
    final file = File(packagePath);
    if (!await file.exists()) {
      throw Exception('Package file does not exist: $packagePath');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw Exception('Invalid .ocpkg: missing data.json');
    }

    final bundleJson = jsonDecode(utf8.decode(dataFile.content as List<int>));
    final bundle = OcPackageBundle.fromJson(bundleJson as Map<String, dynamic>);

    // 1. Unpack and cache media files locally
    final imageService = ImageStorageService.instance;
    final mediaMap = <String, String>{}; // zipPath -> local relative path
    for (final f in archive.files) {
      if (f.name.startsWith('media/') && !f.name.endsWith('/')) {
        final content = f.content as List<int>;
        final tempDir = Directory.systemTemp.createTempSync('oc_import_');
        final tempFile = File(p.join(tempDir.path, p.basename(f.name)));
        tempFile.writeAsBytesSync(content);

        // Store into avatar or gallery directory
        if (f.name.contains('avatar')) {
          final savedPath = await imageService.saveAvatarImage(sourcePath: tempFile.path);
          mediaMap[f.name] = savedPath;
        } else {
          final savedPath = await imageService.saveGalleryImage(sourcePath: tempFile.path, characterId: 0);
          mediaMap[f.name] = savedPath;
        }

        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }

    // 2. Perform atomic database import
    return await db.transaction(() async {
      int finalWorldId = targetWorldId ?? 1;

      // Handle World import
      if (bundle.world != null) {
        final rawWorldName = bundle.world!['name'] as String? ?? '导入世界观';
        final rawDesc = bundle.world!['description'] as String?;
        final existingWorlds = await db.select(db.worlds).get();
        final duplicateWorld = existingWorlds.where((w) => w.name == rawWorldName).firstOrNull;

        if (duplicateWorld != null && conflictPolicy == ConflictPolicy.renameCopy) {
          final newName = '$rawWorldName (导入)';
          final newId = await db.into(db.worlds).insert(WorldsCompanion.insert(
                name: newName,
                description: Value(rawDesc),
              ));
          finalWorldId = newId;
        } else if (duplicateWorld != null && conflictPolicy == ConflictPolicy.overwrite) {
          finalWorldId = duplicateWorld.id;
          await (db.update(db.worlds)..where((w) => w.id.equals(finalWorldId))).write(
            WorldsCompanion(
              description: Value(rawDesc),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } else if (duplicateWorld != null && conflictPolicy == ConflictPolicy.skip) {
          finalWorldId = duplicateWorld.id;
        } else {
          final newId = await db.into(db.worlds).insert(WorldsCompanion.insert(
                name: rawWorldName,
                description: Value(rawDesc),
              ));
          finalWorldId = newId;
        }
      }

      // Handle Groups import
      final oldGroupIdToNew = <int, int>{};
      int importedGroupsCount = 0;
      for (final g in bundle.groups) {
        final oldGid = (g['id'] as num).toInt();
        final gName = g['name'] as String? ?? '未命名组织';
        final sortOrder = (g['sortOrder'] as num?)?.toInt() ?? 0;

        final newGid = await db.into(db.groups).insert(GroupsCompanion.insert(
              worldId: finalWorldId,
              name: gName,
              sortOrder: Value(sortOrder),
            ));
        oldGroupIdToNew[oldGid] = newGid;
        importedGroupsCount++;
      }

      // Handle Characters import
      final oldCharIdToNew = <int, int>{};
      final createdNames = <String>[];
      final skippedNames = <String>[];
      final existingChars = await db.select(db.characters).get();
      final existingCharMap = {for (final c in existingChars) c.name: c};

      for (final cJson in bundle.characters) {
        final oldId = (cJson['id'] as num).toInt();
        final rawName = cJson['name'] as String? ?? '未命名角色';
        final rawAvatar = cJson['avatarPath'] as String?;
        final localAvatar = mediaMap[rawAvatar] ?? rawAvatar;
        final gender = cJson['gender'] as String? ?? '';
        final description = cJson['description'] as String? ?? '';
        final status = (cJson['status'] as num?)?.toInt() ?? 0;
        final isFav = cJson['isFavorite'] as bool? ?? false;
        final isPin = cJson['isPinned'] as bool? ?? false;

        final existing = existingCharMap[rawName];

        if (existing != null && conflictPolicy == ConflictPolicy.skip) {
          skippedNames.add(rawName);
          oldCharIdToNew[oldId] = existing.id;
          continue;
        }

        if (existing != null && conflictPolicy == ConflictPolicy.overwrite) {
          await (db.update(db.characters)..where((t) => t.id.equals(existing.id))).write(
            CharactersCompanion(
              gender: Value(gender),
              description: Value(description),
              status: Value(status),
              isFavorite: Value(isFav),
              isPinned: Value(isPin),
              avatarPath: localAvatar != null ? Value(localAvatar) : const Value.absent(),
              updatedAt: Value(DateTime.now()),
            ),
          );
          oldCharIdToNew[oldId] = existing.id;
          createdNames.add(rawName);
        } else {
          // renameCopy or brand new character
          final charName = (existing != null && conflictPolicy == ConflictPolicy.renameCopy)
              ? '$rawName (导入)'
              : rawName;

          final newCharId = await db.into(db.characters).insert(
                CharactersCompanion.insert(
                  worldId: finalWorldId,
                  name: charName,
                  gender: Value(gender),
                  description: Value(description),
                  status: Value(status),
                  isFavorite: Value(isFav),
                  isPinned: Value(isPin),
                  avatarPath: Value(localAvatar),
                ),
              );

          oldCharIdToNew[oldId] = newCharId;
          createdNames.add(charName);
        }
      }

      // Handle Character Stats
      for (final sJson in bundle.characterStats) {
        final oldCharId = (sJson['characterId'] as num).toInt();
        final newCharId = oldCharIdToNew[oldCharId];
        if (newCharId != null) {
          await db.into(db.characterStats).insert(CharacterStatsCompanion.insert(
                characterId: newCharId,
                label: sJson['label'] as String? ?? '',
                value: Value((sJson['value'] as num?)?.toDouble() ?? 0.0),
                maxValue: Value((sJson['maxValue'] as num?)?.toDouble() ?? 100.0),
                sortOrder: Value((sJson['sortOrder'] as num?)?.toInt() ?? 0),
              ));
        }
      }

      // Handle Galleries
      int importedGalleriesCount = 0;
      for (final gJson in bundle.characterGalleries) {
        final oldCharId = (gJson['characterId'] as num).toInt();
        final newCharId = oldCharIdToNew[oldCharId];
        if (newCharId != null) {
          final rawImg = gJson['imagePath'] as String? ?? '';
          final localImg = mediaMap[rawImg] ?? rawImg;
          await db.into(db.characterGalleries).insert(CharacterGalleriesCompanion.insert(
                characterId: newCharId,
                imagePath: localImg,
                caption: Value(gJson['caption'] as String? ?? ''),
                isPrimary: Value(gJson['isPrimary'] as bool? ?? false),
                sortOrder: Value((gJson['sortOrder'] as num?)?.toInt() ?? 0),
              ));
          importedGalleriesCount++;
        }
      }

      // Handle Character Groups
      for (final cgJson in bundle.characterGroups) {
        final oldCharId = (cgJson['characterId'] as num).toInt();
        final oldGid = (cgJson['groupId'] as num).toInt();
        final newCharId = oldCharIdToNew[oldCharId];
        final newGid = oldGroupIdToNew[oldGid];
        if (newCharId != null && newGid != null) {
          await db.into(db.characterGroups).insert(CharacterGroupsCompanion.insert(
                characterId: newCharId,
                groupId: newGid,
              ));
        }
      }

      // Handle Timeline Events
      int importedTimelineCount = 0;
      for (final evJson in bundle.timelineEvents) {
        final oldCharId = (evJson['characterId'] as num?)?.toInt();
        final newCharId = oldCharId != null ? oldCharIdToNew[oldCharId] : null;
        await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
              worldId: finalWorldId,
              characterId: Value(newCharId),
              year: evJson['year'] as String? ?? '未知纪年',
              title: evJson['title'] as String? ?? '未命名事件',
              description: Value(evJson['description'] as String? ?? ''),
              category: Value(evJson['category'] as String? ?? 'general'),
              importance: Value((evJson['importance'] as num?)?.toInt() ?? 1),
              sortOrder: Value((evJson['sortOrder'] as num?)?.toDouble() ?? 0.0),
            ));
        importedTimelineCount++;
      }

      // Handle Relations
      int importedRelationsCount = 0;
      for (final rJson in bundle.relations) {
        final oldFrom = (rJson['fromCharacterId'] as num).toInt();
        final oldTo = (rJson['toCharacterId'] as num).toInt();
        final newFrom = oldCharIdToNew[oldFrom];
        final newTo = oldCharIdToNew[oldTo];
        if (newFrom != null && newTo != null) {
          await db.into(db.relations).insert(RelationsCompanion.insert(
                fromCharacterId: newFrom,
                toCharacterId: newTo,
                relationType: rJson['relationType'] as String? ?? '关联',
                isBidirectional: Value(rJson['isBidirectional'] as bool? ?? true),
                note: Value(rJson['note'] as String?),
              ));
          importedRelationsCount++;
        }
      }

      return ImportResult(
        importedCharacters: createdNames.length,
        importedTimelineEvents: importedTimelineCount,
        importedRelations: importedRelationsCount,
        importedGalleries: importedGalleriesCount,
        importedGroups: importedGroupsCount,
        createdCharacterNames: createdNames,
        skippedCharacterNames: skippedNames,
      );
    });
  }
}
