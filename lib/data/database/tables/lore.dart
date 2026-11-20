import 'package:drift/drift.dart';
import 'characters.dart';
import 'worlds.dart';

class LoreEntities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  IntColumn get parentId => integer().nullable().references(
    LoreEntities,
    #id,
  )(); // 父级实体ID (层级地理/上下级派系)
  TextColumn get entityType => text().withLength(
    min: 1,
    max: 30,
  )(); // location, faction, race, item, ability, other
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get coverImagePath => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get customFields => text().withDefault(
    const Constant('{}'),
  )(); // JSON for type-specific properties
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 百科实体与角色的稳定 ID 关联表 (LORE-002 & LORE-003: 成员/领袖/常驻/关联)
class LoreRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  IntColumn get loreId => integer().references(LoreEntities, #id)();
  IntColumn get characterId => integer().references(Characters, #id)();
  TextColumn get role =>
      text().withLength(min: 1, max: 50).withDefault(const Constant('成员'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 百科实体之间的相互关系表 (LORE-003: 势力间同盟/敌对/从属/贸易，以及地缘连接等)
class LoreEntityRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get worldId => integer().references(Worlds, #id)();
  IntColumn get fromLoreId => integer().references(LoreEntities, #id)();
  IntColumn get toLoreId => integer().references(LoreEntities, #id)();
  TextColumn get relationType =>
      text().withLength(min: 1, max: 50).withDefault(const Constant('同盟'))();
  BoolColumn get isBidirectional =>
      boolean().withDefault(const Constant(true))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
