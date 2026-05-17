// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_dao.dart';

// ignore_for_file: type=lint
mixin _$WorldDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  WorldDaoManager get managers => WorldDaoManager(this);
}

class WorldDaoManager {
  final _$WorldDaoMixin _db;
  WorldDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
}
