// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lore_dao.dart';

// ignore_for_file: type=lint
mixin _$LoreDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $LoreEntitiesTable get loreEntities => attachedDatabase.loreEntities;
  $CharactersTable get characters => attachedDatabase.characters;
  $LoreRelationsTable get loreRelations => attachedDatabase.loreRelations;
  $LoreEntityRelationsTable get loreEntityRelations =>
      attachedDatabase.loreEntityRelations;
  LoreDaoManager get managers => LoreDaoManager(this);
}

class LoreDaoManager {
  final _$LoreDaoMixin _db;
  LoreDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$LoreEntitiesTableTableManager get loreEntities =>
      $$LoreEntitiesTableTableManager(_db.attachedDatabase, _db.loreEntities);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$LoreRelationsTableTableManager get loreRelations =>
      $$LoreRelationsTableTableManager(_db.attachedDatabase, _db.loreRelations);
  $$LoreEntityRelationsTableTableManager get loreEntityRelations =>
      $$LoreEntityRelationsTableTableManager(
        _db.attachedDatabase,
        _db.loreEntityRelations,
      );
}
