import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/backup/project_backup_service.dart';
import 'package:oc_manager/core/storage/image_storage_service.dart';
import 'package:oc_manager/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tempDir = Directory.systemTemp.createTempSync('project_backup_test_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ProjectBackupService Tests (P1-02)', () {
    late AppDatabase db;
    late ProjectBackupService backupService;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      backupService = ProjectBackupService(db);

      // Populate initial data
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '备份测试世界',
              description: const drift.Value('用于验证双轨备份'),
            ),
          );

      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: '阿尔托莉雅',
              gender: const drift.Value('女'),
              description: const drift.Value('骑士王'),
            ),
          );

      // Create a dummy image in sandbox
      final dummyImg = File('${tempDir.path}/test_source.png');
      await dummyImg.writeAsBytes([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]); // PNG magic bytes
      await ImageStorageService.instance.saveAvatarImage(
        sourcePath: dummyImg.path,
        characterId: 101,
      );
      await ImageStorageService.instance.saveGalleryImage(
        sourcePath: dummyImg.path,
        characterId: 101,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'should export database snapshot (.db) and inspect correctly',
      () async {
        final dbSnapshotPath = '${tempDir.path}/snapshot.db';
        await backupService.exportDatabaseSnapshot(dbSnapshotPath);

        expect(File(dbSnapshotPath).existsSync(), isTrue);

        final inspection = await backupService.inspectBackup(dbSnapshotPath);
        expect(inspection.type, equals(BackupType.databaseOnly));
        expect(inspection.worldCount, equals(1));
        expect(inspection.characterCount, equals(1));
        expect(inspection.mediaCount, equals(0));
        expect(inspection.schemaVersion, equals(db.schemaVersion));
      },
    );

    test(
      'should export full project bundle (.zip) with manifest, database, and media, and inspect correctly',
      () async {
        final projectZipPath = '${tempDir.path}/full_project.zip';
        await backupService.exportFullProjectBundle(projectZipPath);

        expect(File(projectZipPath).existsSync(), isTrue);

        final inspection = await backupService.inspectBackup(projectZipPath);
        expect(inspection.type, equals(BackupType.fullProject));
        expect(inspection.worldCount, equals(1));
        expect(inspection.characterCount, equals(1));
        expect(inspection.mediaCount, greaterThanOrEqualTo(2));
        expect(inspection.checksum, isNotNull);
        expect(inspection.schemaVersion, equals(db.schemaVersion));
      },
    );

    test(
      'should reject corrupted or invalid files early during inspection',
      () async {
        final badFilePath = '${tempDir.path}/corrupt.bin';
        await File(badFilePath).writeAsString('NOT A VALID SQLITE OR ZIP FILE');

        expect(
          () => backupService.inspectBackup(badFilePath),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'should reject backup bundles with path traversal or illegal extension during restore',
      () async {
        final dbSnapshotPath = '${tempDir.path}/clean.db';
        await backupService.exportDatabaseSnapshot(dbSnapshotPath);
        final dbBytes = await File(dbSnapshotPath).readAsBytes();

        // 1. Test path traversal archive
        final evilArchive = Archive();
        evilArchive.addFile(
          ArchiveFile('database.db', dbBytes.length, dbBytes),
        );
        final manifestBytes = utf8.encode(
          jsonEncode({'schemaVersion': db.schemaVersion}),
        );
        evilArchive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
        );
        final dummyPng = [1, 2, 3];
        evilArchive.addFile(
          ArchiveFile('media/../../evil.png', dummyPng.length, dummyPng),
        );

        final evilZipPath = '${tempDir.path}/evil_traversal.zip';
        await File(evilZipPath).writeAsBytes(ZipEncoder().encode(evilArchive));

        expect(
          () => backupService.restoreBackup(backupPath: evilZipPath),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('路径穿越') ||
                  e.toString().contains('Path Traversal'),
            ),
          ),
        );

        // 2. Test illegal extension
        final badExtArchive = Archive();
        badExtArchive.addFile(
          ArchiveFile('database.db', dbBytes.length, dbBytes),
        );
        badExtArchive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
        );
        final dummyExe = [77, 90]; // MZ
        badExtArchive.addFile(
          ArchiveFile('media/payload.exe', dummyExe.length, dummyExe),
        );

        final badExtZipPath = '${tempDir.path}/bad_ext.zip';
        await File(
          badExtZipPath,
        ).writeAsBytes(ZipEncoder().encode(badExtArchive));

        expect(
          () => backupService.restoreBackup(backupPath: badExtZipPath),
          throwsA(predicate((e) => e.toString().contains('非法媒体文件扩展名'))),
        );
      },
    );
  });
}
