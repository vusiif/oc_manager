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
import 'daos/world_dao.dart';
import 'daos/character_dao.dart';
import 'daos/relation_dao.dart';
import 'daos/template_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/trash_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/group_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Worlds,
  Characters,
  CharacterFields,
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
], daos: [
  WorldDao,
  CharacterDao,
  RelationDao,
  TemplateDao,
  TagDao,
  TrashDao,
  SettingsDao,
  GroupDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(relations, relations.relationGroupId);
          }
          if (from < 3) {
            await m.addColumn(characters, characters.gender);
          }
          if (from < 4) {
            await m.addColumn(characters, characters.description);
          }
          if (from < 5) {
            await m.createTable(settings);
            await m.createTable(basicInfoFields);
          }
          if (from < 6) {
            await m.createTable(groups);
            await m.createTable(characterGroups);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oc_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
