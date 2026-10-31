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

  /// Returns the directory where character gallery/costume images are stored.
  Future<Directory> getGalleryDir() async {
    final base = await getBaseDir();
    final galleryDir = Directory(p.join(base.path, 'gallery'));
    if (!galleryDir.existsSync()) {
      await galleryDir.create(recursive: true);
    }
    return galleryDir;
  }

  /// Copies an image from [sourcePath] into the app's gallery directory.
  /// Returns a portable relative path, e.g. "gallery/char_1_1697481234.png".
  Future<String> saveGalleryImage({
    required String sourcePath,
    required int characterId,
  }) async {
    final galleryDir = await getGalleryDir();
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'char_${characterId}_$timestamp$ext';
    final targetPath = p.join(galleryDir.path, fileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);

    return p.join('gallery', fileName).replaceAll(r'\', '/');
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
  /// Enforces sandbox boundary for relative paths and validates image extensions.
  /// Returns null if the file does not exist or violates security constraints.
  Future<File?> resolveImageFile(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) return null;

    final trimmed = storedPath.trim();
    final base = await getBaseDir();
    final baseCanonical = p.canonicalize(base.path);
    const validExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'};

    // 1. If absolute, verify existence and ensure it is an image file
    if (p.isAbsolute(trimmed)) {
      final absCanonical = p.canonicalize(trimmed);
      final absFile = File(absCanonical);
      if (absFile.existsSync()) {
        final ext = p.extension(absCanonical).toLowerCase();
        if (validExtensions.contains(ext)) {
          return absFile;
        }
      }
      return null;
    }

    // 2. Relative path must stay strictly inside oc_manager sandbox (prevent Path Traversal)
    final targetPath = p.join(base.path, trimmed);
    final targetCanonical = p.canonicalize(targetPath);
    if (!p.isWithin(baseCanonical, targetCanonical) && targetCanonical != baseCanonical) {
      return null;
    }

    final resolvedFile = File(targetCanonical);
    return resolvedFile.existsSync() ? resolvedFile : null;
  }

  /// Synchronously checks if a path exists within sandbox (fast fallback).
  static File? tryResolveSync(String? storedPath, String? baseDirPath) {
    if (storedPath == null || storedPath.trim().isEmpty) return null;
    final trimmed = storedPath.trim();
    const validExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'};

    if (p.isAbsolute(trimmed)) {
      final absCanonical = p.canonicalize(trimmed);
      final absFile = File(absCanonical);
      if (absFile.existsSync()) {
        final ext = p.extension(absCanonical).toLowerCase();
        if (validExtensions.contains(ext)) return absFile;
      }
      return null;
    }

    if (baseDirPath != null) {
      final baseCanonical = p.canonicalize(baseDirPath);
      final targetCanonical = p.canonicalize(p.join(baseDirPath, trimmed));
      if (!p.isWithin(baseCanonical, targetCanonical) && targetCanonical != baseCanonical) {
        return null;
      }
      final relFile = File(targetCanonical);
      if (relFile.existsSync()) return relFile;
    }
    return null;
  }
}
