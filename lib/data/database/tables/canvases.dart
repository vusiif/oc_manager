import 'package:drift/drift.dart';
import 'worlds.dart';

/// Table representing multiple named canvases per world in the relation graph
@DataClassName('GraphCanvas')
class GraphCanvases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  RealColumn get viewportX => real().withDefault(const Constant(0.0))();
  RealColumn get viewportY => real().withDefault(const Constant(0.0))();
  RealColumn get zoomScale => real().withDefault(const Constant(1.0))();
  TextColumn get filterConfig => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
