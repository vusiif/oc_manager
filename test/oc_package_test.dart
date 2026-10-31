import 'dart:io';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/export/models/export_bundle.dart';
import 'package:oc_manager/core/export/oc_package_service.dart';
import 'package:oc_manager/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  group('OcPackageService Tests (Milestone 4.2)', () {
    late AppDatabase db;
    late OcPackageService service;
    late Directory tempDir;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = OcPackageService(db);
      tempDir = Directory.systemTemp.createTempSync('oc_pkg_test_');

      // Populate source world & characters
      await db.into(db.worlds).insert(WorldsCompanion.insert(
            id: const drift.Value(1),
            name: '赛博纪元',
            description: const drift.Value('近未来高科技低生活世界'),
          ));

      await db.into(db.characters).insert(CharactersCompanion.insert(
            id: const drift.Value(101),
            worldId: 1,
            name: 'V',
            gender: const drift.Value('男'),
            description: const drift.Value('夜之城雇佣兵'),
            status: const drift.Value(2),
            isFavorite: const drift.Value(true),
          ));

      await db.into(db.characters).insert(CharactersCompanion.insert(
            id: const drift.Value(102),
            worldId: 1,
            name: '强尼·银手',
            gender: const drift.Value('男'),
            description: const drift.Value('摇滚叛客与精神寄生体'),
            status: const drift.Value(2),
          ));

      await db.into(db.characterStats).insert(CharacterStatsCompanion.insert(
            characterId: 101,
            label: '肉体',
            value: const drift.Value(80.0),
            maxValue: const drift.Value(100.0),
          ));

      await db.into(db.characterGalleries).insert(CharacterGalleriesCompanion.insert(
            characterId: 101,
            imagePath: 'avatars/v_mock.png',
            caption: const drift.Value('荒坂塔突袭特写'),
          ));

      await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
            worldId: 1,
            characterId: const drift.Value(101),
            year: '2077 年',
            title: '荒坂塔潜入行动',
            importance: const drift.Value(3),
            description: const drift.Value('偷取 Relic 生物芯片'),
          ));

      await db.into(db.relations).insert(RelationsCompanion.insert(
            fromCharacterId: 101,
            toCharacterId: 102,
            relationType: '共生寄宿',
            isBidirectional: const drift.Value(true),
            note: const drift.Value('一体双魂'),
          ));

      await db.into(db.groups).insert(GroupsCompanion.insert(
            id: const drift.Value(201),
            worldId: 1,
            name: '夜之城来生佣兵',
          ));
      await db.into(db.characterGroups).insert(CharacterGroupsCompanion.insert(
            characterId: 101,
            groupId: 201,
          ));

      await db.into(db.characterFields).insert(CharacterFieldsCompanion.insert(
            characterId: 101,
            fieldName: '所属流派',
            fieldType: 'text',
            value: const drift.Value('独狼黑客'),
          ));

      await db.into(db.tags).insert(TagsCompanion.insert(
            id: const drift.Value(301),
            name: '赛博义体',
            color: '#00F0FF',
          ));
      await db.into(db.characterTags).insert(CharacterTagsCompanion.insert(
            characterId: 101,
            tagId: 301,
          ));
    });

    tearDown(() async {
      await db.close();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('should export .ocpkg bundle and allow inspection without modifications', () async {
      final pkgPath = '${tempDir.path}/cyberpunk.ocpkg';

      // 1. Export
      await service.exportWorldPackage(worldId: 1, outputPath: pkgPath);
      expect(File(pkgPath).existsSync(), isTrue);

      // 2. Inspect
      final inspection = await service.inspectPackage(pkgPath);
      expect(inspection.manifest.title, equals('赛博纪元'));
      expect(inspection.manifest.packageType, equals('world'));
      expect(inspection.characterNames, containsAll(['V', '强尼·银手']));
      expect(inspection.manifest.entityCounts['characters'], equals(2));
      expect(inspection.manifest.entityCounts['timelineEvents'], equals(1));
      expect(inspection.manifest.entityCounts['relations'], equals(1));

      // In current database, 'V' and '强尼·银手' already exist
      expect(inspection.existingConflictedCharacters, containsAll(['V', '强尼·银手']));
      expect(inspection.hasWorldConflict, isTrue);
    });

    test('should import .ocpkg into a clean database successfully', () async {
      final pkgPath = '${tempDir.path}/cyberpunk.ocpkg';
      await service.exportWorldPackage(worldId: 1, outputPath: pkgPath);

      // Create a secondary clean database
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final targetService = OcPackageService(targetDb);

      try {
        final result = await targetService.importPackage(
          packagePath: pkgPath,
          conflictPolicy: ConflictPolicy.renameCopy,
        );

        expect(result.importedCharacters, equals(2));
        expect(result.importedTimelineEvents, equals(1));
        expect(result.importedRelations, equals(1));
        expect(result.createdCharacterNames, containsAll(['V', '强尼·银手']));

        // Verify entities inserted into targetDb
        final importedWorlds = await targetDb.select(targetDb.worlds).get();
        expect(importedWorlds.length, equals(1));
        expect(importedWorlds.first.name, equals('赛博纪元'));

        final importedChars = await targetDb.select(targetDb.characters).get();
        expect(importedChars.length, equals(2));

        final importedRels = await targetDb.select(targetDb.relations).get();
        expect(importedRels.length, equals(1));
        expect(importedRels.first.relationType, equals('共生寄宿'));

        // Verify foreign keys correctly mapped
        final vChar = importedChars.firstWhere((c) => c.name == 'V');
        final johnnyChar = importedChars.firstWhere((c) => c.name == '强尼·银手');
        expect(importedRels.first.fromCharacterId, equals(vChar.id));
        expect(importedRels.first.toCharacterId, equals(johnnyChar.id));

        // Verify fields and tags are completely restored (P0 regression check)
        final importedFields = await targetDb.select(targetDb.characterFields).get();
        expect(importedFields.length, equals(1));
        expect(importedFields.first.fieldName, equals('所属流派'));
        expect(importedFields.first.value, equals('独狼黑客'));
        expect(importedFields.first.characterId, equals(vChar.id));

        final importedTags = await targetDb.select(targetDb.tags).get();
        expect(importedTags.length, equals(1));
        expect(importedTags.first.name, equals('赛博义体'));

        final importedCharTags = await targetDb.select(targetDb.characterTags).get();
        expect(importedCharTags.length, equals(1));
        expect(importedCharTags.first.characterId, equals(vChar.id));
      } finally {
        await targetDb.close();
      }
    });

    test('should handle ConflictPolicy.renameCopy by renaming and re-mapping relations', () async {
      final pkgPath = '${tempDir.path}/cyberpunk.ocpkg';
      await service.exportWorldPackage(worldId: 1, outputPath: pkgPath);

      // Import back into the same database (where V and 强尼·银手 exist)
      final result = await service.importPackage(
        packagePath: pkgPath,
        conflictPolicy: ConflictPolicy.renameCopy,
      );

      expect(result.importedCharacters, equals(2));
      expect(result.createdCharacterNames, containsAll(['V (导入)', '强尼·银手 (导入)']));

      // Total characters should now be 4
      final allChars = await db.select(db.characters).get();
      expect(allChars.length, equals(4));

      final importedV = allChars.firstWhere((c) => c.name == 'V (导入)');
      final importedJohnny = allChars.firstWhere((c) => c.name == '强尼·银手 (导入)');

      // Relations check: should now have 2 relations (original 101<->102 and new importedV<->importedJohnny)
      final allRels = await db.select(db.relations).get();
      expect(allRels.length, equals(2));

      final newRel = allRels.firstWhere((r) => r.fromCharacterId == importedV.id);
      expect(newRel.toCharacterId, equals(importedJohnny.id));
      expect(newRel.relationType, equals('共生寄宿'));
    });

    test('should handle ConflictPolicy.skip by skipping existing characters', () async {
      final pkgPath = '${tempDir.path}/cyberpunk.ocpkg';
      await service.exportWorldPackage(worldId: 1, outputPath: pkgPath);

      // Import with skip policy into the same database
      final result = await service.importPackage(
        packagePath: pkgPath,
        conflictPolicy: ConflictPolicy.skip,
      );

      expect(result.importedCharacters, equals(0));
      expect(result.skippedCharacterNames, containsAll(['V', '强尼·银手']));

      // Total characters should remain 2
      final allChars = await db.select(db.characters).get();
      expect(allChars.length, equals(2));
    });

    test('should handle ConflictPolicy.overwrite by updating existing characters', () async {
      final pkgPath = '${tempDir.path}/cyberpunk.ocpkg';
      await service.exportWorldPackage(worldId: 1, outputPath: pkgPath);

      // Modify existing V in DB
      await (db.update(db.characters)..where((c) => c.id.equals(101))).write(
        const CharactersCompanion(
          description: drift.Value('临时修改的描述'),
        ),
      );

      // Import with overwrite
      final result = await service.importPackage(
        packagePath: pkgPath,
        conflictPolicy: ConflictPolicy.overwrite,
      );

      expect(result.importedCharacters, equals(2));

      // Description should be reverted back to package content
      final char = await (db.select(db.characters)..where((c) => c.id.equals(101))).getSingle();
      expect(char.description, equals('夜之城雇佣兵'));
    });
  });
}
