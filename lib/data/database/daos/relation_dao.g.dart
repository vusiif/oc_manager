// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relation_dao.dart';

// ignore_for_file: type=lint
mixin _$RelationDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $CharactersTable get characters => attachedDatabase.characters;
  $RelationsTable get relations => attachedDatabase.relations;
  RelationDaoManager get managers => RelationDaoManager(this);
}

class RelationDaoManager {
  final _$RelationDaoMixin _db;
  RelationDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$RelationsTableTableManager get relations =>
      $$RelationsTableTableManager(_db.attachedDatabase, _db.relations);
}
