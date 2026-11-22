import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';

class _SimulatedV6User extends QueryExecutorUser {
  @override
  final int schemaVersion = 6;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}

void main() {
  test('Database Migration from v6 with existing parent_id succeeds seamlessly', () async {
    final tempDir = await Directory.systemTemp.createTemp('migration_test_');
    final dbFile = File('${tempDir.path}/test_v6.db');

    // 1. Create a simulated v6 database directly with NativeDatabase
    final rawDb = NativeDatabase(dbFile);
    await rawDb.ensureOpen(_SimulatedV6User());

    await rawDb.runCustom(
      'CREATE TABLE worlds (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, is_locked INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);',
    );
    await rawDb.runCustom(
      'CREATE TABLE characters (id INTEGER PRIMARY KEY AUTOINCREMENT, world_id INTEGER NOT NULL, name TEXT NOT NULL, avatar_path TEXT, gender TEXT NOT NULL DEFAULT \'\', description TEXT NOT NULL DEFAULT \'\', status INTEGER NOT NULL DEFAULT 0, is_favorite INTEGER NOT NULL DEFAULT 0, is_pinned INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);',
    );
    await rawDb.runCustom(
      'CREATE TABLE relations (id INTEGER PRIMARY KEY AUTOINCREMENT, world_id INTEGER NOT NULL, source_character_id INTEGER NOT NULL, target_character_id INTEGER NOT NULL, relation_type TEXT NOT NULL, description TEXT, is_bidirectional INTEGER NOT NULL DEFAULT 1, relation_group_id INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);',
    );
    await rawDb.runCustom(
      'CREATE TABLE graph_layouts (id INTEGER PRIMARY KEY AUTOINCREMENT, world_id INTEGER NOT NULL, character_id INTEGER NOT NULL, x REAL NOT NULL DEFAULT 0, y REAL NOT NULL DEFAULT 0);',
    );
    // Notice: lore_entities with parent_id already present (the exact trigger of the user bug)
    await rawDb.runCustom(
      'CREATE TABLE lore_entities (id INTEGER PRIMARY KEY AUTOINCREMENT, world_id INTEGER NOT NULL, parent_id INTEGER, entity_type TEXT NOT NULL, name TEXT NOT NULL, summary TEXT NOT NULL, content TEXT NOT NULL, cover_image_path TEXT, tags TEXT NOT NULL, custom_fields TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);',
    );
    await rawDb.close();

    // 2. Open the database using AppDatabase which has schemaVersion = 15
    final appDb = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Force initialization and migration
    final versionResult = await appDb.customSelect('PRAGMA user_version;').getSingle();
    final newVersion = versionResult.data.values.first;

    expect(newVersion, 15);

    // Verify tables exist
    final tablesResult = await appDb.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table';",
    ).get();
    final tableNames = tablesResult.map((r) => r.data['name'] as String).toSet();

    expect(tableNames.contains('story_works'), isTrue);
    expect(tableNames.contains('story_chapters'), isTrue);
    expect(tableNames.contains('story_scenes'), isTrue);
    expect(tableNames.contains('lore_relations'), isTrue);
    expect(tableNames.contains('lore_entity_relations'), isTrue);

    // Verify parent_id column exists on lore_entities
    final colsResult = await appDb.customSelect('PRAGMA table_info("lore_entities");').get();
    final colNames = colsResult.map((r) => r.data['name'] as String).toSet();
    expect(colNames.contains('parent_id'), isTrue);

    await appDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Migration succeeds on real user database copy without errors', () async {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) return;
    final userDbFile = File('$userProfile/Documents/oc_manager.db');
    if (!await userDbFile.exists()) return;

    final tempDir = await Directory.systemTemp.createTemp('user_db_migration_');
    final copyFile = File('${tempDir.path}/test_copy.db');
    await userDbFile.copy(copyFile.path);

    final appDb = AppDatabase.forTesting(NativeDatabase(copyFile));
    final versionResult = await appDb.customSelect('PRAGMA user_version;').getSingle();
    final newVersion = versionResult.data.values.first;

    expect(newVersion, 15);

    // Verify all tables exist
    final tablesResult = await appDb.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table';",
    ).get();
    final tableNames = tablesResult.map((r) => r.data['name'] as String).toSet();
    expect(tableNames.contains('worlds'), isTrue);
    expect(tableNames.contains('characters'), isTrue);
    expect(tableNames.contains('lore_entities'), isTrue);
    expect(tableNames.contains('story_works'), isTrue);
    expect(tableNames.contains('story_chapters'), isTrue);
    expect(tableNames.contains('story_scenes'), isTrue);

    await appDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
}
