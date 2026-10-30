import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing local avatar and portrait images.
/// Stores files in an application sandbox directory and returns portable relative paths.
class ImageStorageService {
  static final ImageStorageService instance = ImageStorageService._();
  ImageStorageService._();

  Directory? _baseDir;

  /// Returns the base directory for oc_manager user files.
  Future<Directory> getBaseDir() async {
    if (_baseDir != null) return _baseDir!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocDir.path, 'oc_manager'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _baseDir = dir;
    return dir;
  }

  /// Returns the directory where character avatars are stored.
  Future<Directory> getAvatarsDir() async {
    final base = await getBaseDir();
    final avatarsDir = Directory(p.join(base.path, 'avatars'));
    if (!avatarsDir.existsSync()) {
      await avatarsDir.create(recursive: true);
    }
    return avatarsDir;
  }

  /// Copies an image from [sourcePath] into the app's avatars directory.
  /// Returns a portable relative path, e.g. "avatars/char_1_1697481234.png".
  Future<String> saveAvatarImage({
    required String sourcePath,
    int? characterId,
  }) async {
    final avatarsDir = await getAvatarsDir();
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = characterId != null ? 'char_$characterId' : 'avatar';
    final fileName = '${prefix}_$timestamp$ext';
    final targetPath = p.join(avatarsDir.path, fileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);

    // Return portable relative path
    return p.join('avatars', fileName).replaceAll(r'\', '/');
  }

  /// Resolves a stored path (relative or absolute) to a concrete [File].
  /// Returns null if the file does not exist.
  Future<File?> resolveImageFile(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) return null;

    final trimmed = storedPath.trim();

    // 1. If absolute and exists
    final absFile = File(trimmed);
    if (absFile.isAbsolute && absFile.existsSync()) {
      return absFile;
    }

    // 2. Resolve relative path against oc_manager base directory
    final base = await getBaseDir();
    final resolvedFile = File(p.join(base.path, trimmed));
    if (resolvedFile.existsSync()) {
      return resolvedFile;
    }

    return null;
  }

  /// Synchronously checks if an absolute path exists (fast fallback).
  static File? tryResolveSync(String? storedPath, String? baseDirPath) {
    if (storedPath == null || storedPath.trim().isEmpty) return null;
    final trimmed = storedPath.trim();
    final absFile = File(trimmed);
    if (absFile.isAbsolute && absFile.existsSync()) return absFile;

    if (baseDirPath != null) {
      final relFile = File(p.join(baseDirPath, trimmed));
      if (relFile.existsSync()) return relFile;
    }
    return null;
  }
}
