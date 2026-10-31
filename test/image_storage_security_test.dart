import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/storage/image_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempBaseDir;

  setUpAll(() {
    tempBaseDir = Directory.systemTemp.createTempSync('oc_security_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempBaseDir.path;
    });
  });

  tearDownAll(() {
    try {
      if (tempBaseDir.existsSync()) {
        tempBaseDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ImageStorageService Security & Sandbox Tests', () {
    test('should reject path traversal attempts (e.g., ../../evil)', () async {
      final service = ImageStorageService.instance;

      final result1 = await service.resolveImageFile('../../secret.txt');
      expect(result1, isNull);

      final result2 = await service.resolveImageFile('avatars/../../windows/system32/cmd.exe');
      expect(result2, isNull);
    });

    test('should reject non-image absolute file reads', () async {
      final service = ImageStorageService.instance;

      // Create a temporary non-image text file outside sandbox
      final secretFile = File('${Directory.systemTemp.path}/leak_me.txt');
      secretFile.writeAsStringSync('sensitive data');

      try {
        final result = await service.resolveImageFile(secretFile.path);
        // Should be blocked because it has .txt extension and not a valid image
        expect(result, isNull);
      } finally {
        if (secretFile.existsSync()) secretFile.deleteSync();
      }
    });

    test('should allow valid image inside application sandbox', () async {
      final service = ImageStorageService.instance;
      final avatarsDir = await service.getAvatarsDir();
      final validImg = File('${avatarsDir.path}/test_avatar.png');
      validImg.writeAsStringSync('dummy_png_bytes');

      try {
        final resolved = await service.resolveImageFile('avatars/test_avatar.png');
        expect(resolved, isNotNull);
        expect(resolved!.existsSync(), isTrue);
      } finally {
        if (validImg.existsSync()) validImg.deleteSync();
      }
    });
  });
}
