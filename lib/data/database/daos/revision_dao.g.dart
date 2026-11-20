// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revision_dao.dart';

// ignore_for_file: type=lint
mixin _$RevisionDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $EntityRevisionsTable get entityRevisions => attachedDatabase.entityRevisions;
  RevisionDaoManager get managers => RevisionDaoManager(this);
}

class RevisionDaoManager {
  final _$RevisionDaoMixin _db;
  RevisionDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$EntityRevisionsTableTableManager get entityRevisions =>
      $$EntityRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.entityRevisions,
      );
}
