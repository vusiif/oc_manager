import 'package:drift/drift.dart';
import 'characters.dart';

class Relations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromCharacterId => integer().references(Characters, #id)();
  IntColumn get toCharacterId => integer().references(Characters, #id)();
  TextColumn get relationType => text().withLength(min: 1, max: 50)();
  BoolColumn get isBidirectional => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
}
