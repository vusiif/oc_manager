import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/worlds.dart';
import 'tables/characters.dart';
import 'tables/relations.dart';
import 'tables/templates.dart';
import 'tables/tags.dart';
import 'tables/trash.dart';
import 'tables/settings.dart';
import 'tables/groups.dart';
import 'tables/timeline.dart';
import 'tables/lore.dart';
import 'tables/revisions.dart';
import 'tables/canvases.dart';
import 'tables/stories.dart';
import 'daos/world_dao.dart';
import 'daos/character_dao.dart';
import 'daos/relation_dao.dart';
import 'daos/template_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/trash_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/group_dao.dart';
import 'daos/timeline_dao.dart';
import 'daos/lore_dao.dart';
import 'daos/revision_dao.dart';
import 'daos/canvas_dao.dart';
import 'daos/story_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Worlds,
    Characters,
    CharacterFields,
    CharacterStats,
    CharacterGalleries,
    Relations,
    Templates,
    TemplateFields,
    Tags,
    CharacterTags,
    Trash,
    Backups,
    GraphLayouts,
    Settings,
    BasicInfoFields,
    Groups,
    CharacterGroups,
    TimelineEvents,
    LoreEntities,
    LoreRelations,
    LoreEntityRelations,
    EntityRevisions,
    GraphCanvases,
    StoryWorks,
    StoryChapters,
    StoryScenes,
  ],
  daos: [
    WorldDao,
    CharacterDao,
    RelationDao,
    TemplateDao,
    TagDao,
    TrashDao,
    SettingsDao,
    GroupDao,
    TimelineDao,
    LoreDao,
    RevisionDao,
    CanvasDao,
    StoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      Future<void> safeAddColumn(
        TableInfo table,
        GeneratedColumn column,
      ) async {
        try {
          final rows = await customSelect(
            'PRAGMA table_info("${table.actualTableName}");',
          ).get();
          final exists = rows.any((r) => r.data['name'] == column.$name);
          if (!exists) {
            await m.addColumn(table, column);
          }
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) {
            rethrow;
          }
        }
      }

      Future<void> safeCreateTable(TableInfo table) async {
        try {
          final rows = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='${table.actualTableName}';",
          ).get();
          if (rows.isEmpty) {
            await m.createTable(table);
          }
        } catch (e) {
          if (!e.toString().contains('already exists')) {
            rethrow;
          }
        }
      }

      if (from < 2) {
        await safeAddColumn(relations, relations.relationGroupId);
      }
      if (from < 3) {
        await safeAddColumn(characters, characters.gender);
      }
      if (from < 4) {
        await safeAddColumn(characters, characters.description);
      }
      if (from < 5) {
        await safeCreateTable(settings);
        await safeCreateTable(basicInfoFields);
      }
      if (from < 6) {
        await safeCreateTable(groups);
        await safeCreateTable(characterGroups);
      }
      if (from < 7) {
        await safeCreateTable(characterStats);
      }
      if (from < 8) {
        await safeCreateTable(characterGalleries);
      }
      if (from < 9) {
        await safeCreateTable(timelineEvents);
      }
      if (from < 10) {
        await safeCreateTable(loreEntities);
      }
      if (from < 11) {
        await safeCreateTable(entityRevisions);
      }
      if (from < 12) {
        await safeCreateTable(graphCanvases);
        await safeAddColumn(graphLayouts, graphLayouts.canvasId);
      }
      if (from < 13) {
        await safeAddColumn(loreEntities, loreEntities.parentId);
        await safeCreateTable(loreRelations);
      }
      if (from < 14) {
        await safeCreateTable(loreEntityRelations);
      }
      if (from < 15) {
        await safeCreateTable(storyWorks);
        await safeCreateTable(storyChapters);
        await safeCreateTable(storyScenes);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  Future<void> backupTo(String targetPath) async {
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    final escapedPath = targetPath.replaceAll("'", "''");
    await customStatement('PRAGMA wal_checkpoint(FULL);');
    await customStatement("VACUUM INTO '$escapedPath';");
  }

  Future<bool> checkIntegrity() async {
    final result = await customSelect('PRAGMA integrity_check;').getSingle();
    final status = result.data.values.firstOrNull?.toString();
    return status == 'ok';
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oc_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
