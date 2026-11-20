import 'package:drift/drift.dart';
import 'worlds.dart';
import 'characters.dart';
import 'lore.dart';

/// 作品与项目表 (STORY-001)
class StoryWorks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get type =>
      text().withLength(min: 1, max: 30).withDefault(const Constant('小说'))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get status =>
      text().withLength(min: 1, max: 30).withDefault(const Constant('策划中'))();
  TextColumn get coverImagePath => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 章节与故事分卷表 (STORY-002)
class StoryChapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workId => integer().references(StoryWorks, #id)();
  TextColumn get arcName =>
      text().withLength(min: 0, max: 50).withDefault(const Constant('正卷'))();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get status =>
      text().withLength(min: 1, max: 30).withDefault(const Constant('大纲'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 场景分镜表 (STORY-002)
class StoryScenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().references(StoryChapters, #id)();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get povCharacterId =>
      integer().nullable().references(Characters, #id)();
  IntColumn get locationId =>
      integer().nullable().references(LoreEntities, #id)();
  TextColumn get locationName =>
      text().withLength(min: 0, max: 100).withDefault(const Constant(''))();
  TextColumn get timelineTime =>
      text().withLength(min: 0, max: 100).withDefault(const Constant(''))();
  TextColumn get mood =>
      text().withLength(min: 0, max: 50).withDefault(const Constant(''))();
  TextColumn get characterIds =>
      text().withDefault(const Constant('[]'))(); // JSON Array of int
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
