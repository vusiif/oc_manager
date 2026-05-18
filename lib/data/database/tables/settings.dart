import 'package:drift/drift.dart';

class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().withLength(min: 1, max: 50)();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BasicInfoFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fieldName => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
}