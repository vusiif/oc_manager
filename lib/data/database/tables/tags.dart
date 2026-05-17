import 'package:drift/drift.dart';
import 'characters.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withLength(min: 1, max: 20)();
}

class CharacterTags extends Table {
  IntColumn get characterId => integer().references(Characters, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {characterId, tagId};
}
