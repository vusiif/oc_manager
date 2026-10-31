// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_dao.dart';

// ignore_for_file: type=lint
mixin _$CharacterDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $CharactersTable get characters => attachedDatabase.characters;
  $CharacterFieldsTable get characterFields => attachedDatabase.characterFields;
  $CharacterStatsTable get characterStats => attachedDatabase.characterStats;
  CharacterDaoManager get managers => CharacterDaoManager(this);
}

class CharacterDaoManager {
  final _$CharacterDaoMixin _db;
  CharacterDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$CharacterFieldsTableTableManager get characterFields =>
      $$CharacterFieldsTableTableManager(
        _db.attachedDatabase,
        _db.characterFields,
      );
  $$CharacterStatsTableTableManager get characterStats =>
      $$CharacterStatsTableTableManager(
        _db.attachedDatabase,
        _db.characterStats,
      );
}
