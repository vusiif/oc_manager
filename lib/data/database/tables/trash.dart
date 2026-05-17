import 'package:drift/drift.dart';

class Trash extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemType => text().withLength(min: 1, max: 20)(); // world / character
  IntColumn get itemId => integer()();
  TextColumn get itemData => text()(); // JSON
  DateTimeColumn get deletedAt => dateTime().withDefault(currentDateAndTime)();
}

class Backups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get filePath => text()();
}

class GraphLayouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer()();
  IntColumn get characterId => integer()();
  RealColumn get x => real().withDefault(const Constant(0))();
  RealColumn get y => real().withDefault(const Constant(0))();
}
