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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oc_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
