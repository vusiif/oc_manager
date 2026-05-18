import 'package:drift/drift.dart';
import 'worlds.dart';

class Characters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get gender => text().withLength(min: 0, max: 20).withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CharacterFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get characterId => integer().references(Characters, #id)();
  TextColumn get fieldName => text().withLength(min: 1, max: 50)();
  TextColumn get fieldType => text().withLength(min: 1, max: 20)();
  TextColumn get value => text().nullable()();
}
