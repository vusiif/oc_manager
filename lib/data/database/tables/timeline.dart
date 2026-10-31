import 'package:drift/drift.dart';
import 'worlds.dart';
import 'characters.dart';

/// 编年史与生平时间线事件表
class TimelineEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  IntColumn get characterId => integer().nullable().references(Characters, #id)();
  TextColumn get year => text().withLength(min: 1, max: 50)();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withLength(min: 1, max: 30).withDefault(const Constant('general'))();
  IntColumn get importance => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
