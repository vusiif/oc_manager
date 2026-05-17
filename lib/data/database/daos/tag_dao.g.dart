// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dao.dart';

// ignore_for_file: type=lint
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $WorldsTable get worlds => attachedDatabase.worlds;
  $CharactersTable get characters => attachedDatabase.characters;
  $CharacterTagsTable get characterTags => attachedDatabase.characterTags;
  TagDaoManager get managers => TagDaoManager(this);
}

class TagDaoManager {
  final _$TagDaoMixin _db;
  TagDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$CharacterTagsTableTableManager get characterTags =>
      $$CharacterTagsTableTableManager(_db.attachedDatabase, _db.characterTags);
}
