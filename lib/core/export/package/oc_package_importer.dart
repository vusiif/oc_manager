import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../data/database/app_database.dart';
import '../../storage/image_storage_service.dart';
import '../models/export_bundle.dart';
import '../oc_package_service.dart';

/// Handles inspecting, unpacking, verifying, and atomically importing .ocpkg archives into database.
class OcPackageImporter {
  final AppDatabase db;

  static const int maxPackageFileCount = 2000;
  static const int maxSingleFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxTotalUncompressedBytes = 500 * 1024 * 1024; // 500MB

  OcPackageImporter(this.db);

  /// Reads and inspects an .ocpkg file without modifying database
  Future<PackageInspectionResult> inspectPackage(
    String packagePath, {
    int? targetWorldId,
  }) async {
    final file = File(packagePath);
    if (!await file.exists()) {
      throw Exception('Package file does not exist: $packagePath');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    if (archive.files.length > maxPackageFileCount) {
      throw Exception(
        '数据包文件数量超出安全限制 (${archive.files.length} > $maxPackageFileCount)',
      );
    }

    // Read manifest.json
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw Exception('Invalid .ocpkg package: missing manifest.json');
    }
    final manifestJson = jsonDecode(
      utf8.decode(manifestFile.content as List<int>),
    );
    final manifest = PackageManifest.fromJson(
      manifestJson as Map<String, dynamic>,
    );

    // Read data.json
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw Exception('Invalid .ocpkg package: missing data.json');
    }
    final bundleJson = jsonDecode(utf8.decode(dataFile.content as List<int>));
    final bundle = OcPackageBundle.fromJson(bundleJson as Map<String, dynamic>);

    final charNames = bundle.characters
        .map((c) => (c['name'] as String?) ?? '未命名')
        .toList();

    // Check conflicts against existing database scoped to target world
    bool hasWorldConflict = false;
    int? effectiveCheckWorldId = targetWorldId;

    if (bundle.world != null) {
      final worldName = bundle.world!['name'] as String?;
      if (worldName != null) {
        final existingWorlds = await db.select(db.worlds).get();
        final duplicateWorld = existingWorlds
            .where((w) => w.name == worldName)
            .firstOrNull;
        if (duplicateWorld != null) {
          hasWorldConflict = true;
          effectiveCheckWorldId ??= duplicateWorld.id;
        }
      }
    }

    final Set<String> existingNames;
    if (effectiveCheckWorldId != null) {
      final existingChars = await (db.select(
        db.characters,
      )..where((c) => c.worldId.equals(effectiveCheckWorldId!))).get();
      existingNames = existingChars.map((c) => c.name).toSet();
    } else {
      // In a brand new world import, there are no existing characters
      existingNames = <String>{};
    }

    final conflicts = charNames
        .where((n) => existingNames.contains(n))
        .toList();

    final mediaCount = archive.files
        .where((f) => f.name.startsWith('media/') && !f.name.endsWith('/'))
        .length;

    return PackageInspectionResult(
      manifest: manifest,
      characterNames: charNames,
      mediaCount: mediaCount,
      fileSizeBytes: bytes.length,
      existingConflictedCharacters: conflicts,
      hasWorldConflict: hasWorldConflict,
    );
  }

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

    // Safety checks on archive files count and size (prevent Zip bombs / DoS)
    if (archive.files.length > maxPackageFileCount) {
      throw Exception(
        '数据包文件数量超出安全限制 (${archive.files.length} > $maxPackageFileCount)',
      );
    }

    int totalBytes = 0;
    for (final f in archive.files) {
      final size = f.size;
      if (size > maxSingleFileSizeBytes) {
        throw Exception(
          '包内单文件 [${f.name}] 体积过大 (${(size / 1024 / 1024).toStringAsFixed(1)} MB > 50 MB)',
        );
      }
      totalBytes += size;
      if (totalBytes > maxTotalUncompressedBytes) {
        throw Exception('数据包解压总体积超出安全上限 (超过 500 MB)');
      }
    }

    // 1. Controlled staging area for media files
    final imageService = ImageStorageService.instance;
    final mediaMap = <String, String>{}; // zipPath -> local relative path
    final writtenSandboxFiles = <String>[];
    final stagingDir = Directory.systemTemp.createTempSync(
      'oc_staging_${DateTime.now().millisecondsSinceEpoch}_',
    );

    try {
      for (final f in archive.files) {
        if (f.name.startsWith('media/') && !f.name.endsWith('/')) {
          final ext = p.extension(f.name).toLowerCase();
          if (!ImageStorageService.validImageExtensions.contains(ext)) {
            continue;
          }
          final content = f.content as List<int>;
          final tempFile = File(p.join(stagingDir.path, p.basename(f.name)));
          tempFile.writeAsBytesSync(content);

          // Store into avatar or gallery directory
          if (f.name.contains('avatar')) {
            final savedPath = await imageService.saveAvatarImage(
              sourcePath: tempFile.path,
            );
            mediaMap[f.name] = savedPath;
            writtenSandboxFiles.add(savedPath);
          } else {
            final savedPath = await imageService.saveGalleryImage(
              sourcePath: tempFile.path,
              characterId: 0,
            );
            mediaMap[f.name] = savedPath;
            writtenSandboxFiles.add(savedPath);
          }
        }
      }

      // 2. Perform atomic database import
      return await db.transaction(() async {
        int finalWorldId = targetWorldId ?? 1;

        // Handle World import
        if (bundle.world != null && targetWorldId == null) {
          final rawWorldName = bundle.world!['name'] as String? ?? '导入世界观';
          final rawDesc = bundle.world!['description'] as String?;
          final existingWorlds = await db.select(db.worlds).get();
          final duplicateWorld = existingWorlds
              .where((w) => w.name == rawWorldName)
              .firstOrNull;

          if (duplicateWorld != null &&
              conflictPolicy == ConflictPolicy.renameCopy) {
            final newName = _resolveRenameCopy(
              rawWorldName,
              existingWorlds.map((w) => w.name).toSet(),
            );
            final newId = await db
                .into(db.worlds)
                .insert(
                  WorldsCompanion.insert(
                    name: newName,
                    description: Value(rawDesc),
                  ),
                );
            finalWorldId = newId;
          } else if (duplicateWorld != null &&
              conflictPolicy == ConflictPolicy.overwrite) {
            finalWorldId = duplicateWorld.id;
            await (db.update(
              db.worlds,
            )..where((w) => w.id.equals(finalWorldId))).write(
              WorldsCompanion(
                description: Value(rawDesc),
                updatedAt: Value(DateTime.now()),
              ),
            );
          } else if (duplicateWorld != null &&
              conflictPolicy == ConflictPolicy.skip) {
            finalWorldId = duplicateWorld.id;
          } else {
            final newId = await db
                .into(db.worlds)
                .insert(
                  WorldsCompanion.insert(
                    name: rawWorldName,
                    description: Value(rawDesc),
                  ),
                );
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

          final newGid = await db
              .into(db.groups)
              .insert(
                GroupsCompanion.insert(
                  worldId: finalWorldId,
                  name: gName,
                  sortOrder: Value(sortOrder),
                ),
              );
          oldGroupIdToNew[oldGid] = newGid;
          importedGroupsCount++;
        }

        // Handle Characters import (strictly isolated to finalWorldId)
        final oldCharIdToNew = <int, int>{};
        final createdNames = <String>[];
        final skippedNames = <String>[];
        final existingChars = await (db.select(
          db.characters,
        )..where((c) => c.worldId.equals(finalWorldId))).get();
        final existingCharMap = {for (final c in existingChars) c.name: c};
        final takenNames = existingChars.map((c) => c.name).toSet();

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
            await (db.update(
              db.characters,
            )..where((t) => t.id.equals(existing.id))).write(
              CharactersCompanion(
                gender: Value(gender),
                description: Value(description),
                status: Value(status),
                isFavorite: Value(isFav),
                isPinned: Value(isPin),
                avatarPath: localAvatar != null
                    ? Value(localAvatar)
                    : const Value.absent(),
                updatedAt: Value(DateTime.now()),
              ),
            );
            oldCharIdToNew[oldId] = existing.id;
            createdNames.add(rawName);
          } else {
            // renameCopy or brand new character
            final String charName;
            if (existing != null &&
                conflictPolicy == ConflictPolicy.renameCopy) {
              charName = _resolveRenameCopy(rawName, takenNames);
            } else if (takenNames.contains(rawName)) {
              // Disambiguate duplicate names in the same imported batch
              charName = _resolveRenameCopy(rawName, takenNames);
            } else {
              charName = rawName;
            }

            takenNames.add(charName);

            final newCharId = await db
                .into(db.characters)
                .insert(
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

        // Handle Character Fields
        int importedFieldsCount = 0;
        for (final fJson in bundle.characterFields) {
          final oldCharId = (fJson['characterId'] as num).toInt();
          final newCharId = oldCharIdToNew[oldCharId];
          if (newCharId != null) {
            await db
                .into(db.characterFields)
                .insert(
                  CharacterFieldsCompanion.insert(
                    characterId: newCharId,
                    fieldName: fJson['fieldName'] as String? ?? '',
                    fieldType: fJson['fieldType'] as String? ?? 'text',
                    value: Value(fJson['value'] as String?),
                  ),
                );
            importedFieldsCount++;
          }
        }

        // Handle Character Stats
        for (final sJson in bundle.characterStats) {
          final oldCharId = (sJson['characterId'] as num).toInt();
          final newCharId = oldCharIdToNew[oldCharId];
          if (newCharId != null) {
            await db
                .into(db.characterStats)
                .insert(
                  CharacterStatsCompanion.insert(
                    characterId: newCharId,
                    label: sJson['label'] as String? ?? '',
                    value: Value((sJson['value'] as num?)?.toDouble() ?? 0.0),
                    maxValue: Value(
                      (sJson['maxValue'] as num?)?.toDouble() ?? 100.0,
                    ),
                    sortOrder: Value(
                      (sJson['sortOrder'] as num?)?.toInt() ?? 0,
                    ),
                  ),
                );
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
            await db
                .into(db.characterGalleries)
                .insert(
                  CharacterGalleriesCompanion.insert(
                    characterId: newCharId,
                    imagePath: localImg,
                    caption: Value(gJson['caption'] as String? ?? ''),
                    isPrimary: Value(gJson['isPrimary'] as bool? ?? false),
                    sortOrder: Value(
                      (gJson['sortOrder'] as num?)?.toInt() ?? 0,
                    ),
                  ),
                );
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
            await db
                .into(db.characterGroups)
                .insert(
                  CharacterGroupsCompanion.insert(
                    characterId: newCharId,
                    groupId: newGid,
                  ),
                );
          }
        }

        // Handle Timeline Events
        int importedTimelineCount = 0;
        for (final evJson in bundle.timelineEvents) {
          final oldCharId = (evJson['characterId'] as num?)?.toInt();
          final newCharId = oldCharId != null
              ? oldCharIdToNew[oldCharId]
              : null;
          await db
              .into(db.timelineEvents)
              .insert(
                TimelineEventsCompanion.insert(
                  worldId: finalWorldId,
                  characterId: Value(newCharId),
                  year: evJson['year'] as String? ?? '未知纪年',
                  title: evJson['title'] as String? ?? '未命名事件',
                  description: Value(evJson['description'] as String? ?? ''),
                  category: Value(evJson['category'] as String? ?? 'general'),
                  importance: Value(
                    (evJson['importance'] as num?)?.toInt() ?? 1,
                  ),
                  sortOrder: Value(
                    (evJson['sortOrder'] as num?)?.toDouble() ?? 0.0,
                  ),
                ),
              );
          importedTimelineCount++;
        }

        // Handle Relations (preserve & remap relationGroupId to maintain family group semantics)
        int importedRelationsCount = 0;
        final oldRelGroupIdToNew = <String, String>{};
        for (final rJson in bundle.relations) {
          final oldFrom = (rJson['fromCharacterId'] as num).toInt();
          final oldTo = (rJson['toCharacterId'] as num).toInt();
          final newFrom = oldCharIdToNew[oldFrom];
          final newTo = oldCharIdToNew[oldTo];
          if (newFrom != null && newTo != null) {
            final rawRelGroupId = rJson['relationGroupId'] as String?;
            String? mappedRelGroupId;
            if (rawRelGroupId != null && rawRelGroupId.trim().isNotEmpty) {
              mappedRelGroupId = oldRelGroupIdToNew.putIfAbsent(
                rawRelGroupId,
                () =>
                    'relgrp_${DateTime.now().millisecondsSinceEpoch}_${oldRelGroupIdToNew.length + 1}',
              );
            }

            await db
                .into(db.relations)
                .insert(
                  RelationsCompanion.insert(
                    fromCharacterId: newFrom,
                    toCharacterId: newTo,
                    relationType: rJson['relationType'] as String? ?? '关联',
                    isBidirectional: Value(
                      rJson['isBidirectional'] as bool? ?? true,
                    ),
                    note: Value(rJson['note'] as String?),
                    relationGroupId: Value(mappedRelGroupId),
                  ),
                );
            importedRelationsCount++;
          }
        }

        // Handle Tags & Character Tags
        final oldTagIdToNew = <int, int>{};
        int importedTagsCount = 0;
        final existingTags = await db.select(db.tags).get();
        final existingTagMap = {for (final t in existingTags) t.name: t.id};

        for (final tJson in bundle.tags) {
          final oldTagId = (tJson['id'] as num).toInt();
          final tagName = tJson['name'] as String? ?? '未命名标签';
          final tagColor = tJson['color'] as String? ?? '#6366F1';

          if (existingTagMap.containsKey(tagName)) {
            oldTagIdToNew[oldTagId] = existingTagMap[tagName]!;
          } else {
            final newTagId = await db
                .into(db.tags)
                .insert(TagsCompanion.insert(name: tagName, color: tagColor));
            existingTagMap[tagName] = newTagId;
            oldTagIdToNew[oldTagId] = newTagId;
            importedTagsCount++;
          }
        }

        for (final ctJson in bundle.characterTags) {
          final oldCharId = (ctJson['characterId'] as num).toInt();
          final oldTagId = (ctJson['tagId'] as num).toInt();
          final newCharId = oldCharIdToNew[oldCharId];
          final newTagId = oldTagIdToNew[oldTagId];
          if (newCharId != null && newTagId != null) {
            await db
                .into(db.characterTags)
                .insertOnConflictUpdate(
                  CharacterTagsCompanion.insert(
                    characterId: newCharId,
                    tagId: newTagId,
                  ),
                );
          }
        }

        return ImportResult(
          importedCharacters: createdNames.length,
          importedTimelineEvents: importedTimelineCount,
          importedRelations: importedRelationsCount,
          importedGalleries: importedGalleriesCount,
          importedGroups: importedGroupsCount,
          importedFields: importedFieldsCount,
          importedTags: importedTagsCount,
          createdCharacterNames: createdNames,
          skippedCharacterNames: skippedNames,
        );
      });
    } catch (e) {
      // Transaction failed: purge all newly copied sandbox media files so no orphans remain
      for (final relativePath in writtenSandboxFiles) {
        try {
          await imageService.deleteImage(relativePath);
        } catch (_) {}
      }
      rethrow;
    } finally {
      try {
        if (stagingDir.existsSync()) {
          stagingDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Resolves non-colliding names for renameCopy policy or batch duplicates
  static String _resolveRenameCopy(String rawName, Set<String> takenNames) {
    final candidate = '$rawName (导入)';
    if (!takenNames.contains(candidate)) {
      return candidate;
    }
    int index = 2;
    while (takenNames.contains('$rawName (导入 $index)')) {
      index++;
    }
    return '$rawName (导入 $index)';
  }
}
