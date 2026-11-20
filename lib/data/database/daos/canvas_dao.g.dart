// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_dao.dart';

// ignore_for_file: type=lint
mixin _$CanvasDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $GraphCanvasesTable get graphCanvases => attachedDatabase.graphCanvases;
  $GraphLayoutsTable get graphLayouts => attachedDatabase.graphLayouts;
  CanvasDaoManager get managers => CanvasDaoManager(this);
}

class CanvasDaoManager {
  final _$CanvasDaoMixin _db;
  CanvasDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$GraphCanvasesTableTableManager get graphCanvases =>
      $$GraphCanvasesTableTableManager(_db.attachedDatabase, _db.graphCanvases);
  $$GraphLayoutsTableTableManager get graphLayouts =>
      $$GraphLayoutsTableTableManager(_db.attachedDatabase, _db.graphLayouts);
}
