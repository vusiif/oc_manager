import 'package:drift/drift.dart';
import 'worlds.dart';

/// 设定版本历史与内容快照表
class EntityRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  TextColumn get entityType =>
      text().withLength(min: 1, max: 30)(); // 'character', 'lore'
  IntColumn get entityId => integer()();
  TextColumn get title =>
      text().withLength(min: 0, max: 100).withDefault(const Constant(''))();
  TextColumn get content => text()();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
