import '../../data/database/app_database.dart';
import 'models/export_bundle.dart';
import 'package/oc_package_exporter.dart';
import 'package/oc_package_importer.dart';

export 'package/oc_package_exporter.dart';
export 'package/oc_package_importer.dart';

/// Inspection summary shown to the user before confirming import.
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

/// Statistics reported after import completes.
class ImportResult {
  final int importedCharacters;
  final int importedTimelineEvents;
  final int importedRelations;
  final int importedGalleries;
  final int importedGroups;
  final int importedFields;
  final int importedTags;
  final List<String> createdCharacterNames;
  final List<String> skippedCharacterNames;

  const ImportResult({
    required this.importedCharacters,
    required this.importedTimelineEvents,
    required this.importedRelations,
    required this.importedGalleries,
    required this.importedGroups,
    this.importedFields = 0,
    this.importedTags = 0,
    required this.createdCharacterNames,
    required this.skippedCharacterNames,
  });
}

/// Service handling packaging (.ocpkg export) and importing with conflict resolution.
class OcPackageService {
  final AppDatabase db;
  late final OcPackageExporter _exporter;
  late final OcPackageImporter _importer;

  static const int maxPackageFileCount = OcPackageImporter.maxPackageFileCount;
  static const int maxSingleFileSizeBytes =
      OcPackageImporter.maxSingleFileSizeBytes;
  static const int maxTotalUncompressedBytes =
      OcPackageImporter.maxTotalUncompressedBytes;

  OcPackageService(this.db) {
    _exporter = OcPackageExporter(db);
    _importer = OcPackageImporter(db);
  }

  /// Exports an entire world and all its characters/galleries/events into a single .ocpkg archive.
  Future<void> exportWorldPackage({
    required int worldId,
    required String outputPath,
  }) => _exporter.exportWorldPackage(worldId: worldId, outputPath: outputPath);

  /// Exports selected characters into an independent .ocpkg archive.
  Future<void> exportCharactersPackage({
    required List<int> characterIds,
    required String title,
    required String outputPath,
    String? description,
  }) => _exporter.exportCharactersPackage(
    characterIds: characterIds,
    title: title,
    outputPath: outputPath,
    description: description,
  );

  /// Reads and inspects an .ocpkg file without modifying database.
  Future<PackageInspectionResult> inspectPackage(
    String packagePath, {
    int? targetWorldId,
  }) => _importer.inspectPackage(packagePath, targetWorldId: targetWorldId);

  /// Imports an .ocpkg into database following specified [conflictPolicy].
  Future<ImportResult> importPackage({
    required String packagePath,
    required ConflictPolicy conflictPolicy,
    int? targetWorldId,
  }) => _importer.importPackage(
    packagePath: packagePath,
    conflictPolicy: conflictPolicy,
    targetWorldId: targetWorldId,
  );
}
