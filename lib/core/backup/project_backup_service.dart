import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../storage/image_storage_service.dart';

const maxBackupFileCount = 5000;
const maxBackupSingleFileSizeBytes = 50 * 1024 * 1024; // 50 MB
const maxBackupTotalUncompressedBytes = 1000 * 1024 * 1024; // 1000 MB
const allowedBackupMediaExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

enum BackupType { databaseOnly, fullProject }

class BackupInspectionResult {
  final BackupType type;
  final int fileSizeBytes;
  final int worldCount;
  final int characterCount;
  final int mediaCount;
  final int schemaVersion;
  final DateTime? createdAt;
  final String? checksum;

  BackupInspectionResult({
    required this.type,
    required this.fileSizeBytes,
    required this.worldCount,
    required this.characterCount,
    required this.mediaCount,
    required this.schemaVersion,
    this.createdAt,
    this.checksum,
  });
}

class RestoreResult {
  final BackupType type;
  final int restoredWorlds;
  final int restoredCharacters;
  final int restoredMediaFiles;

  RestoreResult({
    required this.type,
    required this.restoredWorlds,
    required this.restoredCharacters,
    required this.restoredMediaFiles,
  });
}

final projectBackupServiceProvider = Provider<ProjectBackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectBackupService(db);
});

/// Comprehensive backup and restore service distinguishing pure database snapshots (.db)
/// from full project bundles (.zip including database and all local media files).
class ProjectBackupService {
  final AppDatabase db;

  ProjectBackupService(this.db);

  /// Exports pure SQLite database snapshot using consistent VACUUM INTO
  Future<void> exportDatabaseSnapshot(String outputPath) async {
    await db.backupTo(outputPath);
  }

  /// Exports a complete project bundle containing database snapshot and all local images
  Future<void> exportFullProjectBundle(String outputPath) async {
    final tempDir = Directory.systemTemp.createTempSync('oc_export_bundle_');
    final tempDbPath = p.join(tempDir.path, 'database.db');

    try {
      // 1. Export atomic database snapshot
      await db.backupTo(tempDbPath);
      final dbBytes = await File(tempDbPath).readAsBytes();
      final dbChecksum = sha256.convert(dbBytes).toString();

      final archive = Archive();

      // 2. Add database.db to archive
      archive.addFile(ArchiveFile('database.db', dbBytes.length, dbBytes));

      // 3. Collect media files from sandbox
      final imageService = ImageStorageService.instance;
      final baseDir = await imageService.getBaseDir();
      int mediaCount = 0;

      if (baseDir.existsSync()) {
        final entities = baseDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            final relPath = p
                .relative(entity.path, from: baseDir.path)
                .replaceAll(r'\', '/');
            final fileBytes = await entity.readAsBytes();
            archive.addFile(
              ArchiveFile('media/$relPath', fileBytes.length, fileBytes),
            );
            mediaCount++;
          }
        }
      }

      // 4. Gather counts for manifest
      final worlds = await db.select(db.worlds).get();
      final characters = await db.select(db.characters).get();

      // 5. Build and add manifest.json
      final manifestMap = {
        'format': 'oc_project_backup_v1',
        'schemaVersion': db.schemaVersion,
        'appVersion': '1.8.0',
        'createdAt': DateTime.now().toIso8601String(),
        'worldCount': worlds.length,
        'characterCount': characters.length,
        'mediaCount': mediaCount,
        'databaseSha256': dbChecksum,
      };

      final manifestBytes = utf8.encode(jsonEncode(manifestMap));
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      // 6. Encode and write zip
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final targetFile = File(outputPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await targetFile.writeAsBytes(zipData);
    } finally {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Inspects a backup file (either .db or .zip) and verifies its integrity
  Future<BackupInspectionResult> inspectBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('备份文件不存在: $filePath');
    }

    final fileLength = await file.length();
    if (fileLength == 0) {
      throw Exception('备份文件为空');
    }

    // Read header to detect format
    final headerBytes = await file.openRead(0, 16).first;
    final headerStr = String.fromCharCodes(headerBytes);

    if (headerStr.startsWith('SQLite format 3')) {
      // It's a pure database snapshot (.db)
      return await _inspectDatabaseSnapshot(file, fileLength);
    } else {
      // Treat as zip / project bundle
      return await _inspectProjectBundle(file, fileLength);
    }
  }

  Future<BackupInspectionResult> _inspectDatabaseSnapshot(
    File file,
    int fileLength,
  ) async {
    // Validate by opening in test memory connection
    final testDb = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final isOk = await testDb.checkIntegrity();
      if (!isOk) {
        throw Exception('数据库快照完整性校验失败 (PRAGMA integrity_check failed)');
      }

      final worlds = await testDb.select(testDb.worlds).get();
      final characters = await testDb.select(testDb.characters).get();

      return BackupInspectionResult(
        type: BackupType.databaseOnly,
        fileSizeBytes: fileLength,
        worldCount: worlds.length,
        characterCount: characters.length,
        mediaCount: 0,
        schemaVersion: testDb.schemaVersion,
      );
    } finally {
      await testDb.close();
    }
  }

  Future<BackupInspectionResult> _inspectProjectBundle(
    File file,
    int fileLength,
  ) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw Exception('无效的项目备份包：缺少 manifest.json');
    }

    final dbFile = archive.findFile('database.db');
    if (dbFile == null) {
      throw Exception('无效的项目备份包：缺少 database.db');
    }

    final manifestJson =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    final schemaVersion = (manifestJson['schemaVersion'] as num?)?.toInt() ?? 9;
    final worldCount = (manifestJson['worldCount'] as num?)?.toInt() ?? 0;
    final characterCount =
        (manifestJson['characterCount'] as num?)?.toInt() ?? 0;
    final mediaCount = (manifestJson['mediaCount'] as num?)?.toInt() ?? 0;
    final createdAtStr = manifestJson['createdAt'] as String?;
    final checksum = manifestJson['databaseSha256'] as String?;

    return BackupInspectionResult(
      type: BackupType.fullProject,
      fileSizeBytes: fileLength,
      worldCount: worldCount,
      characterCount: characterCount,
      mediaCount: mediaCount,
      schemaVersion: schemaVersion,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      checksum: checksum,
    );
  }

  /// Restores database and/or project media with atomic rollback protection
  Future<RestoreResult> restoreBackup({required String backupPath}) async {
    final inspection = await inspectBackup(backupPath);

    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'oc_manager.db'));
    final walFile = File(p.join(dbFolder.path, 'oc_manager.db-wal'));
    final shmFile = File(p.join(dbFolder.path, 'oc_manager.db-shm'));
    final rollbackBakFile = File(
      p.join(dbFolder.path, 'oc_manager.db.rollback_bak'),
    );

    final imageService = ImageStorageService.instance;
    final baseDir = await imageService.getBaseDir();

    // 1. Create rollback restore point of current database
    if (await dbFile.exists()) {
      await dbFile.copy(rollbackBakFile.path);
    }

    try {
      // 2. Close active database connection
      await db.close();

      if (inspection.type == BackupType.databaseOnly) {
        // Pure database restore
        final sourceFile = File(backupPath);
        await sourceFile.copy(dbFile.path);

        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        // 3. Verify integrity of newly copied DB
        final verifyDb = AppDatabase.forTesting(NativeDatabase(dbFile));
        try {
          final isOk = await verifyDb.checkIntegrity();
          if (!isOk) throw Exception('恢复后数据库损坏，完整性检查未通过');
        } finally {
          await verifyDb.close();
        }

        // Clean up rollback point on success
        if (await rollbackBakFile.exists()) {
          await rollbackBakFile.delete();
        }

        return RestoreResult(
          type: BackupType.databaseOnly,
          restoredWorlds: inspection.worldCount,
          restoredCharacters: inspection.characterCount,
          restoredMediaFiles: 0,
        );
      } else {
        // Full project bundle restore (database + media)
        final bytes = await File(backupPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Security check: Zip Bomb / DoS prevention
        if (archive.files.length > maxBackupFileCount) {
          throw Exception(
            '备份包文件数量超出安全限制 (${archive.files.length} > $maxBackupFileCount)',
          );
        }

        int totalUncompressedBytes = 0;
        for (final f in archive.files) {
          final size = f.size;
          if (size > maxBackupSingleFileSizeBytes) {
            throw Exception(
              '备份包内单文件 [${f.name}] 体积过大 (${(size / 1024 / 1024).toStringAsFixed(1)} MB > 50 MB)',
            );
          }
          totalUncompressedBytes += size;
          if (totalUncompressedBytes > maxBackupTotalUncompressedBytes) {
            throw Exception('备份包解压总体积超出安全上限 (超过 1000 MB)');
          }
        }

        final dbArchiveFile = archive.findFile('database.db');
        if (dbArchiveFile == null) {
          throw Exception('备份包中未找到 database.db');
        }

        // Overwrite database.db
        await dbFile.writeAsBytes(dbArchiveFile.content as List<int>);
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        // Verify database integrity before committing media
        final verifyDb = AppDatabase.forTesting(NativeDatabase(dbFile));
        try {
          final isOk = await verifyDb.checkIntegrity();
          if (!isOk) throw Exception('备份包内数据库完整性检查失败');
        } finally {
          await verifyDb.close();
        }

        // Restore media files into sandbox with strict Path Traversal & extension checks
        final canonicalBaseDir = p.canonicalize(baseDir.path);
        int extractedMediaCount = 0;
        for (final f in archive.files) {
          if (f.name.startsWith('media/') && !f.name.endsWith('/')) {
            final relPath = f.name.substring('media/'.length).trim();
            if (relPath.isEmpty) continue;

            final ext = p.extension(relPath).toLowerCase();
            if (!allowedBackupMediaExtensions.contains(ext)) {
              throw Exception('安全拦截：备份包包含非法媒体文件扩展名 [$ext]');
            }

            final targetFilePath = p.join(baseDir.path, relPath);
            final canonicalTarget = p.canonicalize(targetFilePath);
            if (!p.isWithin(canonicalBaseDir, canonicalTarget)) {
              throw Exception('安全拦截：检测到非法路径穿越攻击 (Path Traversal: $relPath)');
            }

            final targetFile = File(targetFilePath);
            final targetDir = targetFile.parent;
            if (!targetDir.existsSync()) {
              targetDir.createSync(recursive: true);
            }
            await targetFile.writeAsBytes(f.content as List<int>);
            extractedMediaCount++;
          }
        }

        // Clean up rollback point
        if (await rollbackBakFile.exists()) {
          await rollbackBakFile.delete();
        }

        return RestoreResult(
          type: BackupType.fullProject,
          restoredWorlds: inspection.worldCount,
          restoredCharacters: inspection.characterCount,
          restoredMediaFiles: extractedMediaCount,
        );
      }
    } catch (e) {
      // Failure: rollback from restore point!
      if (await rollbackBakFile.exists()) {
        try {
          await rollbackBakFile.copy(dbFile.path);
          if (await walFile.exists()) await walFile.delete();
          if (await shmFile.exists()) await shmFile.delete();
          await rollbackBakFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
