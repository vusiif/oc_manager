import 'package:drift/drift.dart';
import 'worlds.dart';
import 'characters.dart';

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CharacterGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get characterId => integer().references(Characters, #id)();
  IntColumn get groupId => integer().references(Groups, #id)();
}
