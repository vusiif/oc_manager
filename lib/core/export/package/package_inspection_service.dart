import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

import '../../../data/database/app_database.dart';
import '../models/export_bundle.dart';
import '../oc_package_service.dart';

/// Service responsible for safely inspecting and validating .ocpkg packages without modifying database.
class PackageInspectionService {
  final AppDatabase db;

  static const int maxPackageFileCount = 2000;

  PackageInspectionService(this.db);

  /// Reads and inspects an .ocpkg file without modifying database.
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
}
