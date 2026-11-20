// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_dao.dart';

// ignore_for_file: type=lint
mixin _$StoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorldsTable get worlds => attachedDatabase.worlds;
  $StoryWorksTable get storyWorks => attachedDatabase.storyWorks;
  $StoryChaptersTable get storyChapters => attachedDatabase.storyChapters;
  $CharactersTable get characters => attachedDatabase.characters;
  $LoreEntitiesTable get loreEntities => attachedDatabase.loreEntities;
  $StoryScenesTable get storyScenes => attachedDatabase.storyScenes;
  StoryDaoManager get managers => StoryDaoManager(this);
}

class StoryDaoManager {
  final _$StoryDaoMixin _db;
  StoryDaoManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db.attachedDatabase, _db.worlds);
  $$StoryWorksTableTableManager get storyWorks =>
      $$StoryWorksTableTableManager(_db.attachedDatabase, _db.storyWorks);
  $$StoryChaptersTableTableManager get storyChapters =>
      $$StoryChaptersTableTableManager(_db.attachedDatabase, _db.storyChapters);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$LoreEntitiesTableTableManager get loreEntities =>
      $$LoreEntitiesTableTableManager(_db.attachedDatabase, _db.loreEntities);
  $$StoryScenesTableTableManager get storyScenes =>
      $$StoryScenesTableTableManager(_db.attachedDatabase, _db.storyScenes);
}
