import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/data/database/daos/settings_dao.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SettingsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao & Theme Defaults', () {
    test('Default value for theme_mode is null and resolves to system', () async {
      final value = await dao.getValue('theme_mode');
      expect(value, isNull);

      final themeMode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      expect(themeMode, equals(ThemeMode.system));
    });

    test('setValue updates in-place and does not create duplicate rows', () async {
      await dao.setValue('theme_mode', 'system');
      var allRows = await db.select(db.settings).get();
      expect(allRows.length, equals(1));
      expect(allRows.first.value, equals('system'));

      await dao.setValue('theme_mode', 'dark');
      allRows = await db.select(db.settings).get();
      expect(allRows.length, equals(1));
      expect(allRows.first.value, equals('dark'));

      final value = await dao.getValue('theme_mode');
      expect(value, equals('dark'));
    });

    test('getValue returns latest entry when legacy duplicate rows exist', () async {
      // Simulate historical duplicate rows created by buggy insertOnConflictUpdate
      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: 'theme_mode',
              value: 'light',
            ),
          );
      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: 'theme_mode',
              value: 'system',
            ),
          );

      // Verify getValue gets the latest entry (system) instead of row 1 (light)
      final value = await dao.getValue('theme_mode');
      expect(value, equals('system'));

      // setValue cleans up duplicates and retains single source of truth
      await dao.setValue('theme_mode', 'system');
      final allRows = await db.select(db.settings).get();
      expect(allRows.length, equals(1));
      expect(allRows.first.value, equals('system'));
    });
  });
}
