import 'package:drift/drift.dart';
import 'worlds.dart';

class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get worldId => integer().nullable().references(Worlds, #id)();
}

class TemplateFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(Templates, #id)();
  TextColumn get fieldName => text().withLength(min: 1, max: 50)();
  TextColumn get fieldType => text().withLength(min: 1, max: 20)();
  TextColumn get defaultValue => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
