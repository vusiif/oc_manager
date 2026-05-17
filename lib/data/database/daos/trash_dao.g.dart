// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_dao.dart';

// ignore_for_file: type=lint
mixin _$TrashDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrashTable get trash => attachedDatabase.trash;
  $BackupsTable get backups => attachedDatabase.backups;
  $GraphLayoutsTable get graphLayouts => attachedDatabase.graphLayouts;
  TrashDaoManager get managers => TrashDaoManager(this);
}

class TrashDaoManager {
  final _$TrashDaoMixin _db;
  TrashDaoManager(this._db);
  $$TrashTableTableManager get trash =>
      $$TrashTableTableManager(_db.attachedDatabase, _db.trash);
  $$BackupsTableTableManager get backups =>
      $$BackupsTableTableManager(_db.attachedDatabase, _db.backups);
  $$GraphLayoutsTableTableManager get graphLayouts =>
      $$GraphLayoutsTableTableManager(_db.attachedDatabase, _db.graphLayouts);
}
