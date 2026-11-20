// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorldsTable extends Worlds with TableInfo<$WorldsTable, World> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    isLocked,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worlds';
  @override
  VerificationContext validateIntegrity(
    Insertable<World> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  World map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return World(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorldsTable createAlias(String alias) {
    return $WorldsTable(attachedDatabase, alias);
  }
}

class World extends DataClass implements Insertable<World> {
  final int id;
  final String name;
  final String? description;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  const World({
    required this.id,
    required this.name,
    this.description,
    required this.isLocked,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_locked'] = Variable<bool>(isLocked);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorldsCompanion toCompanion(bool nullToAbsent) {
    return WorldsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isLocked: Value(isLocked),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory World.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return World(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isLocked': serializer.toJson<bool>(isLocked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  World copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => World(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isLocked: isLocked ?? this.isLocked,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  World copyWithCompanion(WorldsCompanion data) {
    return World(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('World(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isLocked: $isLocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, isLocked, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is World &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isLocked == this.isLocked &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorldsCompanion extends UpdateCompanion<World> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isLocked;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WorldsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WorldsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<World> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isLocked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isLocked != null) 'is_locked': isLocked,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WorldsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isLocked,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WorldsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isLocked: $isLocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    name,
    avatarPath,
    gender,
    description,
    status,
    isFavorite,
    isPinned,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final int id;
  final int worldId;
  final String name;
  final String? avatarPath;
  final String gender;
  final String description;
  final int status;
  final bool isFavorite;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Character({
    required this.id,
    required this.worldId,
    required this.name,
    this.avatarPath,
    required this.gender,
    required this.description,
    required this.status,
    required this.isFavorite,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['gender'] = Variable<String>(gender);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<int>(status);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      gender: Value(gender),
      description: Value(description),
      status: Value(status),
      isFavorite: Value(isFavorite),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      gender: serializer.fromJson<String>(json['gender']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<int>(json['status']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'gender': serializer.toJson<String>(gender),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<int>(status),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Character copyWith({
    int? id,
    int? worldId,
    String? name,
    Value<String?> avatarPath = const Value.absent(),
    String? gender,
    String? description,
    int? status,
    bool? isFavorite,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Character(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    name: name ?? this.name,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    gender: gender ?? this.gender,
    description: description ?? this.description,
    status: status ?? this.status,
    isFavorite: isFavorite ?? this.isFavorite,
    isPinned: isPinned ?? this.isPinned,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      gender: data.gender.present ? data.gender.value : this.gender,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('gender: $gender, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    name,
    avatarPath,
    gender,
    description,
    status,
    isFavorite,
    isPinned,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.gender == this.gender &&
          other.description == this.description &&
          other.status == this.status &&
          other.isFavorite == this.isFavorite &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<String> gender;
  final Value<String> description;
  final Value<int> status;
  final Value<bool> isFavorite;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.gender = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CharactersCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required String name,
    this.avatarPath = const Value.absent(),
    this.gender = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : worldId = Value(worldId),
       name = Value(name);
  static Insertable<Character> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<String>? gender,
    Expression<String>? description,
    Expression<int>? status,
    Expression<bool>? isFavorite,
    Expression<bool>? isPinned,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (gender != null) 'gender': gender,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CharactersCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<String>? name,
    Value<String?>? avatarPath,
    Value<String>? gender,
    Value<String>? description,
    Value<int>? status,
    Value<bool>? isFavorite,
    Value<bool>? isPinned,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('gender: $gender, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CharacterFieldsTable extends CharacterFields
    with TableInfo<$CharacterFieldsTable, CharacterField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    fieldName,
    fieldType,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $CharacterFieldsTable createAlias(String alias) {
    return $CharacterFieldsTable(attachedDatabase, alias);
  }
}

class CharacterField extends DataClass implements Insertable<CharacterField> {
  final int id;
  final int characterId;
  final String fieldName;
  final String fieldType;
  final String? value;
  const CharacterField({
    required this.id,
    required this.characterId,
    required this.fieldName,
    required this.fieldType,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<int>(characterId);
    map['field_name'] = Variable<String>(fieldName);
    map['field_type'] = Variable<String>(fieldType);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  CharacterFieldsCompanion toCompanion(bool nullToAbsent) {
    return CharacterFieldsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      fieldName: Value(fieldName),
      fieldType: Value(fieldType),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory CharacterField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterField(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<int>(json['characterId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<int>(characterId),
      'fieldName': serializer.toJson<String>(fieldName),
      'fieldType': serializer.toJson<String>(fieldType),
      'value': serializer.toJson<String?>(value),
    };
  }

  CharacterField copyWith({
    int? id,
    int? characterId,
    String? fieldName,
    String? fieldType,
    Value<String?> value = const Value.absent(),
  }) => CharacterField(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    fieldName: fieldName ?? this.fieldName,
    fieldType: fieldType ?? this.fieldType,
    value: value.present ? value.value : this.value,
  );
  CharacterField copyWithCompanion(CharacterFieldsCompanion data) {
    return CharacterField(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterField(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldType: $fieldType, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, fieldName, fieldType, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterField &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.fieldName == this.fieldName &&
          other.fieldType == this.fieldType &&
          other.value == this.value);
}

class CharacterFieldsCompanion extends UpdateCompanion<CharacterField> {
  final Value<int> id;
  final Value<int> characterId;
  final Value<String> fieldName;
  final Value<String> fieldType;
  final Value<String?> value;
  const CharacterFieldsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.value = const Value.absent(),
  });
  CharacterFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int characterId,
    required String fieldName,
    required String fieldType,
    this.value = const Value.absent(),
  }) : characterId = Value(characterId),
       fieldName = Value(fieldName),
       fieldType = Value(fieldType);
  static Insertable<CharacterField> custom({
    Expression<int>? id,
    Expression<int>? characterId,
    Expression<String>? fieldName,
    Expression<String>? fieldType,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (fieldName != null) 'field_name': fieldName,
      if (fieldType != null) 'field_type': fieldType,
      if (value != null) 'value': value,
    });
  }

  CharacterFieldsCompanion copyWith({
    Value<int>? id,
    Value<int>? characterId,
    Value<String>? fieldName,
    Value<String>? fieldType,
    Value<String?>? value,
  }) {
    return CharacterFieldsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      fieldName: fieldName ?? this.fieldName,
      fieldType: fieldType ?? this.fieldType,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterFieldsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldType: $fieldType, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $CharacterStatsTable extends CharacterStats
    with TableInfo<$CharacterStatsTable, CharacterStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _maxValueMeta = const VerificationMeta(
    'maxValue',
  );
  @override
  late final GeneratedColumn<double> maxValue = GeneratedColumn<double>(
    'max_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100.0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    label,
    value,
    maxValue,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('max_value')) {
      context.handle(
        _maxValueMeta,
        maxValue.isAcceptableOrUnknown(data['max_value']!, _maxValueMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      maxValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_value'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CharacterStatsTable createAlias(String alias) {
    return $CharacterStatsTable(attachedDatabase, alias);
  }
}

class CharacterStat extends DataClass implements Insertable<CharacterStat> {
  final int id;
  final int characterId;
  final String label;
  final double value;
  final double maxValue;
  final int sortOrder;
  const CharacterStat({
    required this.id,
    required this.characterId,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<int>(characterId);
    map['label'] = Variable<String>(label);
    map['value'] = Variable<double>(value);
    map['max_value'] = Variable<double>(maxValue);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CharacterStatsCompanion toCompanion(bool nullToAbsent) {
    return CharacterStatsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      label: Value(label),
      value: Value(value),
      maxValue: Value(maxValue),
      sortOrder: Value(sortOrder),
    );
  }

  factory CharacterStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterStat(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<int>(json['characterId']),
      label: serializer.fromJson<String>(json['label']),
      value: serializer.fromJson<double>(json['value']),
      maxValue: serializer.fromJson<double>(json['maxValue']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<int>(characterId),
      'label': serializer.toJson<String>(label),
      'value': serializer.toJson<double>(value),
      'maxValue': serializer.toJson<double>(maxValue),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CharacterStat copyWith({
    int? id,
    int? characterId,
    String? label,
    double? value,
    double? maxValue,
    int? sortOrder,
  }) => CharacterStat(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    label: label ?? this.label,
    value: value ?? this.value,
    maxValue: maxValue ?? this.maxValue,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CharacterStat copyWithCompanion(CharacterStatsCompanion data) {
    return CharacterStat(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      label: data.label.present ? data.label.value : this.label,
      value: data.value.present ? data.value.value : this.value,
      maxValue: data.maxValue.present ? data.maxValue.value : this.maxValue,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterStat(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('maxValue: $maxValue, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, label, value, maxValue, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterStat &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.label == this.label &&
          other.value == this.value &&
          other.maxValue == this.maxValue &&
          other.sortOrder == this.sortOrder);
}

class CharacterStatsCompanion extends UpdateCompanion<CharacterStat> {
  final Value<int> id;
  final Value<int> characterId;
  final Value<String> label;
  final Value<double> value;
  final Value<double> maxValue;
  final Value<int> sortOrder;
  const CharacterStatsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.label = const Value.absent(),
    this.value = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CharacterStatsCompanion.insert({
    this.id = const Value.absent(),
    required int characterId,
    required String label,
    this.value = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : characterId = Value(characterId),
       label = Value(label);
  static Insertable<CharacterStat> custom({
    Expression<int>? id,
    Expression<int>? characterId,
    Expression<String>? label,
    Expression<double>? value,
    Expression<double>? maxValue,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      if (maxValue != null) 'max_value': maxValue,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CharacterStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? characterId,
    Value<String>? label,
    Value<double>? value,
    Value<double>? maxValue,
    Value<int>? sortOrder,
  }) {
    return CharacterStatsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      label: label ?? this.label,
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (maxValue.present) {
      map['max_value'] = Variable<double>(maxValue.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterStatsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('label: $label, ')
          ..write('value: $value, ')
          ..write('maxValue: $maxValue, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CharacterGalleriesTable extends CharacterGalleries
    with TableInfo<$CharacterGalleriesTable, CharacterGallery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterGalleriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    imagePath,
    caption,
    isPrimary,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_galleries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterGallery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterGallery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterGallery(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CharacterGalleriesTable createAlias(String alias) {
    return $CharacterGalleriesTable(attachedDatabase, alias);
  }
}

class CharacterGallery extends DataClass
    implements Insertable<CharacterGallery> {
  final int id;
  final int characterId;
  final String imagePath;
  final String caption;
  final bool isPrimary;
  final int sortOrder;
  final DateTime createdAt;
  const CharacterGallery({
    required this.id,
    required this.characterId,
    required this.imagePath,
    required this.caption,
    required this.isPrimary,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<int>(characterId);
    map['image_path'] = Variable<String>(imagePath);
    map['caption'] = Variable<String>(caption);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CharacterGalleriesCompanion toCompanion(bool nullToAbsent) {
    return CharacterGalleriesCompanion(
      id: Value(id),
      characterId: Value(characterId),
      imagePath: Value(imagePath),
      caption: Value(caption),
      isPrimary: Value(isPrimary),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CharacterGallery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterGallery(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<int>(json['characterId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      caption: serializer.fromJson<String>(json['caption']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<int>(characterId),
      'imagePath': serializer.toJson<String>(imagePath),
      'caption': serializer.toJson<String>(caption),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CharacterGallery copyWith({
    int? id,
    int? characterId,
    String? imagePath,
    String? caption,
    bool? isPrimary,
    int? sortOrder,
    DateTime? createdAt,
  }) => CharacterGallery(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    imagePath: imagePath ?? this.imagePath,
    caption: caption ?? this.caption,
    isPrimary: isPrimary ?? this.isPrimary,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CharacterGallery copyWithCompanion(CharacterGalleriesCompanion data) {
    return CharacterGallery(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGallery(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    characterId,
    imagePath,
    caption,
    isPrimary,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterGallery &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.imagePath == this.imagePath &&
          other.caption == this.caption &&
          other.isPrimary == this.isPrimary &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CharacterGalleriesCompanion extends UpdateCompanion<CharacterGallery> {
  final Value<int> id;
  final Value<int> characterId;
  final Value<String> imagePath;
  final Value<String> caption;
  final Value<bool> isPrimary;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const CharacterGalleriesCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CharacterGalleriesCompanion.insert({
    this.id = const Value.absent(),
    required int characterId,
    required String imagePath,
    this.caption = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : characterId = Value(characterId),
       imagePath = Value(imagePath);
  static Insertable<CharacterGallery> custom({
    Expression<int>? id,
    Expression<int>? characterId,
    Expression<String>? imagePath,
    Expression<String>? caption,
    Expression<bool>? isPrimary,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (imagePath != null) 'image_path': imagePath,
      if (caption != null) 'caption': caption,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CharacterGalleriesCompanion copyWith({
    Value<int>? id,
    Value<int>? characterId,
    Value<String>? imagePath,
    Value<String>? caption,
    Value<bool>? isPrimary,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return CharacterGalleriesCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      imagePath: imagePath ?? this.imagePath,
      caption: caption ?? this.caption,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGalleriesCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RelationsTable extends Relations
    with TableInfo<$RelationsTable, Relation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromCharacterIdMeta = const VerificationMeta(
    'fromCharacterId',
  );
  @override
  late final GeneratedColumn<int> fromCharacterId = GeneratedColumn<int>(
    'from_character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _toCharacterIdMeta = const VerificationMeta(
    'toCharacterId',
  );
  @override
  late final GeneratedColumn<int> toCharacterId = GeneratedColumn<int>(
    'to_character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBidirectionalMeta = const VerificationMeta(
    'isBidirectional',
  );
  @override
  late final GeneratedColumn<bool> isBidirectional = GeneratedColumn<bool>(
    'is_bidirectional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bidirectional" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationGroupIdMeta = const VerificationMeta(
    'relationGroupId',
  );
  @override
  late final GeneratedColumn<String> relationGroupId = GeneratedColumn<String>(
    'relation_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromCharacterId,
    toCharacterId,
    relationType,
    isBidirectional,
    note,
    relationGroupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Relation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_character_id')) {
      context.handle(
        _fromCharacterIdMeta,
        fromCharacterId.isAcceptableOrUnknown(
          data['from_character_id']!,
          _fromCharacterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCharacterIdMeta);
    }
    if (data.containsKey('to_character_id')) {
      context.handle(
        _toCharacterIdMeta,
        toCharacterId.isAcceptableOrUnknown(
          data['to_character_id']!,
          _toCharacterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toCharacterIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('is_bidirectional')) {
      context.handle(
        _isBidirectionalMeta,
        isBidirectional.isAcceptableOrUnknown(
          data['is_bidirectional']!,
          _isBidirectionalMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('relation_group_id')) {
      context.handle(
        _relationGroupIdMeta,
        relationGroupId.isAcceptableOrUnknown(
          data['relation_group_id']!,
          _relationGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Relation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_character_id'],
      )!,
      toCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_character_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      isBidirectional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bidirectional'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      relationGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_group_id'],
      ),
    );
  }

  @override
  $RelationsTable createAlias(String alias) {
    return $RelationsTable(attachedDatabase, alias);
  }
}

class Relation extends DataClass implements Insertable<Relation> {
  final int id;
  final int fromCharacterId;
  final int toCharacterId;
  final String relationType;
  final bool isBidirectional;
  final String? note;
  final String? relationGroupId;
  const Relation({
    required this.id,
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.relationType,
    required this.isBidirectional,
    this.note,
    this.relationGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_character_id'] = Variable<int>(fromCharacterId);
    map['to_character_id'] = Variable<int>(toCharacterId);
    map['relation_type'] = Variable<String>(relationType);
    map['is_bidirectional'] = Variable<bool>(isBidirectional);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || relationGroupId != null) {
      map['relation_group_id'] = Variable<String>(relationGroupId);
    }
    return map;
  }

  RelationsCompanion toCompanion(bool nullToAbsent) {
    return RelationsCompanion(
      id: Value(id),
      fromCharacterId: Value(fromCharacterId),
      toCharacterId: Value(toCharacterId),
      relationType: Value(relationType),
      isBidirectional: Value(isBidirectional),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      relationGroupId: relationGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(relationGroupId),
    );
  }

  factory Relation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relation(
      id: serializer.fromJson<int>(json['id']),
      fromCharacterId: serializer.fromJson<int>(json['fromCharacterId']),
      toCharacterId: serializer.fromJson<int>(json['toCharacterId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      isBidirectional: serializer.fromJson<bool>(json['isBidirectional']),
      note: serializer.fromJson<String?>(json['note']),
      relationGroupId: serializer.fromJson<String?>(json['relationGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromCharacterId': serializer.toJson<int>(fromCharacterId),
      'toCharacterId': serializer.toJson<int>(toCharacterId),
      'relationType': serializer.toJson<String>(relationType),
      'isBidirectional': serializer.toJson<bool>(isBidirectional),
      'note': serializer.toJson<String?>(note),
      'relationGroupId': serializer.toJson<String?>(relationGroupId),
    };
  }

  Relation copyWith({
    int? id,
    int? fromCharacterId,
    int? toCharacterId,
    String? relationType,
    bool? isBidirectional,
    Value<String?> note = const Value.absent(),
    Value<String?> relationGroupId = const Value.absent(),
  }) => Relation(
    id: id ?? this.id,
    fromCharacterId: fromCharacterId ?? this.fromCharacterId,
    toCharacterId: toCharacterId ?? this.toCharacterId,
    relationType: relationType ?? this.relationType,
    isBidirectional: isBidirectional ?? this.isBidirectional,
    note: note.present ? note.value : this.note,
    relationGroupId: relationGroupId.present
        ? relationGroupId.value
        : this.relationGroupId,
  );
  Relation copyWithCompanion(RelationsCompanion data) {
    return Relation(
      id: data.id.present ? data.id.value : this.id,
      fromCharacterId: data.fromCharacterId.present
          ? data.fromCharacterId.value
          : this.fromCharacterId,
      toCharacterId: data.toCharacterId.present
          ? data.toCharacterId.value
          : this.toCharacterId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      isBidirectional: data.isBidirectional.present
          ? data.isBidirectional.value
          : this.isBidirectional,
      note: data.note.present ? data.note.value : this.note,
      relationGroupId: data.relationGroupId.present
          ? data.relationGroupId.value
          : this.relationGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relation(')
          ..write('id: $id, ')
          ..write('fromCharacterId: $fromCharacterId, ')
          ..write('toCharacterId: $toCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('isBidirectional: $isBidirectional, ')
          ..write('note: $note, ')
          ..write('relationGroupId: $relationGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromCharacterId,
    toCharacterId,
    relationType,
    isBidirectional,
    note,
    relationGroupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relation &&
          other.id == this.id &&
          other.fromCharacterId == this.fromCharacterId &&
          other.toCharacterId == this.toCharacterId &&
          other.relationType == this.relationType &&
          other.isBidirectional == this.isBidirectional &&
          other.note == this.note &&
          other.relationGroupId == this.relationGroupId);
}

class RelationsCompanion extends UpdateCompanion<Relation> {
  final Value<int> id;
  final Value<int> fromCharacterId;
  final Value<int> toCharacterId;
  final Value<String> relationType;
  final Value<bool> isBidirectional;
  final Value<String?> note;
  final Value<String?> relationGroupId;
  const RelationsCompanion({
    this.id = const Value.absent(),
    this.fromCharacterId = const Value.absent(),
    this.toCharacterId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.isBidirectional = const Value.absent(),
    this.note = const Value.absent(),
    this.relationGroupId = const Value.absent(),
  });
  RelationsCompanion.insert({
    this.id = const Value.absent(),
    required int fromCharacterId,
    required int toCharacterId,
    required String relationType,
    this.isBidirectional = const Value.absent(),
    this.note = const Value.absent(),
    this.relationGroupId = const Value.absent(),
  }) : fromCharacterId = Value(fromCharacterId),
       toCharacterId = Value(toCharacterId),
       relationType = Value(relationType);
  static Insertable<Relation> custom({
    Expression<int>? id,
    Expression<int>? fromCharacterId,
    Expression<int>? toCharacterId,
    Expression<String>? relationType,
    Expression<bool>? isBidirectional,
    Expression<String>? note,
    Expression<String>? relationGroupId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromCharacterId != null) 'from_character_id': fromCharacterId,
      if (toCharacterId != null) 'to_character_id': toCharacterId,
      if (relationType != null) 'relation_type': relationType,
      if (isBidirectional != null) 'is_bidirectional': isBidirectional,
      if (note != null) 'note': note,
      if (relationGroupId != null) 'relation_group_id': relationGroupId,
    });
  }

  RelationsCompanion copyWith({
    Value<int>? id,
    Value<int>? fromCharacterId,
    Value<int>? toCharacterId,
    Value<String>? relationType,
    Value<bool>? isBidirectional,
    Value<String?>? note,
    Value<String?>? relationGroupId,
  }) {
    return RelationsCompanion(
      id: id ?? this.id,
      fromCharacterId: fromCharacterId ?? this.fromCharacterId,
      toCharacterId: toCharacterId ?? this.toCharacterId,
      relationType: relationType ?? this.relationType,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      note: note ?? this.note,
      relationGroupId: relationGroupId ?? this.relationGroupId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromCharacterId.present) {
      map['from_character_id'] = Variable<int>(fromCharacterId.value);
    }
    if (toCharacterId.present) {
      map['to_character_id'] = Variable<int>(toCharacterId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (isBidirectional.present) {
      map['is_bidirectional'] = Variable<bool>(isBidirectional.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (relationGroupId.present) {
      map['relation_group_id'] = Variable<String>(relationGroupId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationsCompanion(')
          ..write('id: $id, ')
          ..write('fromCharacterId: $fromCharacterId, ')
          ..write('toCharacterId: $toCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('isBidirectional: $isBidirectional, ')
          ..write('note: $note, ')
          ..write('relationGroupId: $relationGroupId')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, worldId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<Template> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      ),
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  final int id;
  final String name;
  final int? worldId;
  const Template({required this.id, required this.name, this.worldId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || worldId != null) {
      map['world_id'] = Variable<int>(worldId);
    }
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      worldId: worldId == null && nullToAbsent
          ? const Value.absent()
          : Value(worldId),
    );
  }

  factory Template.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      worldId: serializer.fromJson<int?>(json['worldId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'worldId': serializer.toJson<int?>(worldId),
    };
  }

  Template copyWith({
    int? id,
    String? name,
    Value<int?> worldId = const Value.absent(),
  }) => Template(
    id: id ?? this.id,
    name: name ?? this.name,
    worldId: worldId.present ? worldId.value : this.worldId,
  );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('worldId: $worldId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, worldId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.name == this.name &&
          other.worldId == this.worldId);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> worldId;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.worldId = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.worldId = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Template> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? worldId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (worldId != null) 'world_id': worldId,
    });
  }

  TemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? worldId,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      worldId: worldId ?? this.worldId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('worldId: $worldId')
          ..write(')'))
        .toString();
  }
}

class $TemplateFieldsTable extends TemplateFields
    with TableInfo<$TemplateFieldsTable, TemplateField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultValueMeta = const VerificationMeta(
    'defaultValue',
  );
  @override
  late final GeneratedColumn<String> defaultValue = GeneratedColumn<String>(
    'default_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    fieldName,
    fieldType,
    defaultValue,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('default_value')) {
      context.handle(
        _defaultValueMeta,
        defaultValue.isAcceptableOrUnknown(
          data['default_value']!,
          _defaultValueMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      defaultValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_value'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateFieldsTable createAlias(String alias) {
    return $TemplateFieldsTable(attachedDatabase, alias);
  }
}

class TemplateField extends DataClass implements Insertable<TemplateField> {
  final int id;
  final int templateId;
  final String fieldName;
  final String fieldType;
  final String? defaultValue;
  final int sortOrder;
  const TemplateField({
    required this.id,
    required this.templateId,
    required this.fieldName,
    required this.fieldType,
    this.defaultValue,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['field_name'] = Variable<String>(fieldName);
    map['field_type'] = Variable<String>(fieldType);
    if (!nullToAbsent || defaultValue != null) {
      map['default_value'] = Variable<String>(defaultValue);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateFieldsCompanion toCompanion(bool nullToAbsent) {
    return TemplateFieldsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      fieldName: Value(fieldName),
      fieldType: Value(fieldType),
      defaultValue: defaultValue == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValue),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateField(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      defaultValue: serializer.fromJson<String?>(json['defaultValue']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'fieldName': serializer.toJson<String>(fieldName),
      'fieldType': serializer.toJson<String>(fieldType),
      'defaultValue': serializer.toJson<String?>(defaultValue),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateField copyWith({
    int? id,
    int? templateId,
    String? fieldName,
    String? fieldType,
    Value<String?> defaultValue = const Value.absent(),
    int? sortOrder,
  }) => TemplateField(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    fieldName: fieldName ?? this.fieldName,
    fieldType: fieldType ?? this.fieldType,
    defaultValue: defaultValue.present ? defaultValue.value : this.defaultValue,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateField copyWithCompanion(TemplateFieldsCompanion data) {
    return TemplateField(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateField(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldType: $fieldType, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    fieldName,
    fieldType,
    defaultValue,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateField &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.fieldName == this.fieldName &&
          other.fieldType == this.fieldType &&
          other.defaultValue == this.defaultValue &&
          other.sortOrder == this.sortOrder);
}

class TemplateFieldsCompanion extends UpdateCompanion<TemplateField> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> fieldName;
  final Value<String> fieldType;
  final Value<String?> defaultValue;
  final Value<int> sortOrder;
  const TemplateFieldsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TemplateFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String fieldName,
    required String fieldType,
    this.defaultValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : templateId = Value(templateId),
       fieldName = Value(fieldName),
       fieldType = Value(fieldType);
  static Insertable<TemplateField> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? fieldName,
    Expression<String>? fieldType,
    Expression<String>? defaultValue,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (fieldName != null) 'field_name': fieldName,
      if (fieldType != null) 'field_type': fieldType,
      if (defaultValue != null) 'default_value': defaultValue,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TemplateFieldsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<String>? fieldName,
    Value<String>? fieldType,
    Value<String?>? defaultValue,
    Value<int>? sortOrder,
  }) {
    return TemplateFieldsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      fieldName: fieldName ?? this.fieldName,
      fieldType: fieldType ?? this.fieldType,
      defaultValue: defaultValue ?? this.defaultValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<String>(defaultValue.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateFieldsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('fieldName: $fieldName, ')
          ..write('fieldType: $fieldType, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final String color;
  const Tag({required this.id, required this.name, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name), color: Value(color));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
    };
  }

  Tag copyWith({int? id, String? name, String? color}) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String color,
  }) : name = Value(name),
       color = Value(color);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? color,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $CharacterTagsTable extends CharacterTags
    with TableInfo<$CharacterTagsTable, CharacterTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [characterId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId, tagId};
  @override
  CharacterTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterTag(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $CharacterTagsTable createAlias(String alias) {
    return $CharacterTagsTable(attachedDatabase, alias);
  }
}

class CharacterTag extends DataClass implements Insertable<CharacterTag> {
  final int characterId;
  final int tagId;
  const CharacterTag({required this.characterId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<int>(characterId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  CharacterTagsCompanion toCompanion(bool nullToAbsent) {
    return CharacterTagsCompanion(
      characterId: Value(characterId),
      tagId: Value(tagId),
    );
  }

  factory CharacterTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterTag(
      characterId: serializer.fromJson<int>(json['characterId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<int>(characterId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  CharacterTag copyWith({int? characterId, int? tagId}) => CharacterTag(
    characterId: characterId ?? this.characterId,
    tagId: tagId ?? this.tagId,
  );
  CharacterTag copyWithCompanion(CharacterTagsCompanion data) {
    return CharacterTag(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterTag(')
          ..write('characterId: $characterId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(characterId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterTag &&
          other.characterId == this.characterId &&
          other.tagId == this.tagId);
}

class CharacterTagsCompanion extends UpdateCompanion<CharacterTag> {
  final Value<int> characterId;
  final Value<int> tagId;
  final Value<int> rowid;
  const CharacterTagsCompanion({
    this.characterId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterTagsCompanion.insert({
    required int characterId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId),
       tagId = Value(tagId);
  static Insertable<CharacterTag> custom({
    Expression<int>? characterId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterTagsCompanion copyWith({
    Value<int>? characterId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return CharacterTagsCompanion(
      characterId: characterId ?? this.characterId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterTagsCompanion(')
          ..write('characterId: $characterId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrashTable extends Trash with TableInfo<$TrashTable, TrashData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrashTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDataMeta = const VerificationMeta(
    'itemData',
  );
  @override
  late final GeneratedColumn<String> itemData = GeneratedColumn<String>(
    'item_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemType,
    itemId,
    itemData,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trash';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrashData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_data')) {
      context.handle(
        _itemDataMeta,
        itemData.isAcceptableOrUnknown(data['item_data']!, _itemDataMeta),
      );
    } else if (isInserting) {
      context.missing(_itemDataMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrashData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrashData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      itemData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_data'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $TrashTable createAlias(String alias) {
    return $TrashTable(attachedDatabase, alias);
  }
}

class TrashData extends DataClass implements Insertable<TrashData> {
  final int id;
  final String itemType;
  final int itemId;
  final String itemData;
  final DateTime deletedAt;
  const TrashData({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.itemData,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_type'] = Variable<String>(itemType);
    map['item_id'] = Variable<int>(itemId);
    map['item_data'] = Variable<String>(itemData);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  TrashCompanion toCompanion(bool nullToAbsent) {
    return TrashCompanion(
      id: Value(id),
      itemType: Value(itemType),
      itemId: Value(itemId),
      itemData: Value(itemData),
      deletedAt: Value(deletedAt),
    );
  }

  factory TrashData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrashData(
      id: serializer.fromJson<int>(json['id']),
      itemType: serializer.fromJson<String>(json['itemType']),
      itemId: serializer.fromJson<int>(json['itemId']),
      itemData: serializer.fromJson<String>(json['itemData']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemType': serializer.toJson<String>(itemType),
      'itemId': serializer.toJson<int>(itemId),
      'itemData': serializer.toJson<String>(itemData),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  TrashData copyWith({
    int? id,
    String? itemType,
    int? itemId,
    String? itemData,
    DateTime? deletedAt,
  }) => TrashData(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    itemData: itemData ?? this.itemData,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  TrashData copyWithCompanion(TrashCompanion data) {
    return TrashData(
      id: data.id.present ? data.id.value : this.id,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemData: data.itemData.present ? data.itemData.value : this.itemData,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrashData(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('itemData: $itemData, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemType, itemId, itemData, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrashData &&
          other.id == this.id &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.itemData == this.itemData &&
          other.deletedAt == this.deletedAt);
}

class TrashCompanion extends UpdateCompanion<TrashData> {
  final Value<int> id;
  final Value<String> itemType;
  final Value<int> itemId;
  final Value<String> itemData;
  final Value<DateTime> deletedAt;
  const TrashCompanion({
    this.id = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemData = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TrashCompanion.insert({
    this.id = const Value.absent(),
    required String itemType,
    required int itemId,
    required String itemData,
    this.deletedAt = const Value.absent(),
  }) : itemType = Value(itemType),
       itemId = Value(itemId),
       itemData = Value(itemData);
  static Insertable<TrashData> custom({
    Expression<int>? id,
    Expression<String>? itemType,
    Expression<int>? itemId,
    Expression<String>? itemData,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (itemData != null) 'item_data': itemData,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TrashCompanion copyWith({
    Value<int>? id,
    Value<String>? itemType,
    Value<int>? itemId,
    Value<String>? itemData,
    Value<DateTime>? deletedAt,
  }) {
    return TrashCompanion(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      itemData: itemData ?? this.itemData,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (itemData.present) {
      map['item_data'] = Variable<String>(itemData.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrashCompanion(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('itemData: $itemData, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BackupsTable extends Backups with TableInfo<$BackupsTable, Backup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, filePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Backup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Backup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Backup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
    );
  }

  @override
  $BackupsTable createAlias(String alias) {
    return $BackupsTable(attachedDatabase, alias);
  }
}

class Backup extends DataClass implements Insertable<Backup> {
  final int id;
  final String name;
  final DateTime createdAt;
  final String filePath;
  const Backup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.filePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['file_path'] = Variable<String>(filePath);
    return map;
  }

  BackupsCompanion toCompanion(bool nullToAbsent) {
    return BackupsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      filePath: Value(filePath),
    );
  }

  factory Backup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Backup(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      filePath: serializer.fromJson<String>(json['filePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'filePath': serializer.toJson<String>(filePath),
    };
  }

  Backup copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? filePath,
  }) => Backup(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    filePath: filePath ?? this.filePath,
  );
  Backup copyWithCompanion(BackupsCompanion data) {
    return Backup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Backup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('filePath: $filePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, filePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Backup &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.filePath == this.filePath);
}

class BackupsCompanion extends UpdateCompanion<Backup> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String> filePath;
  const BackupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.filePath = const Value.absent(),
  });
  BackupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    required String filePath,
  }) : name = Value(name),
       filePath = Value(filePath);
  static Insertable<Backup> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? filePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (filePath != null) 'file_path': filePath,
    });
  }

  BackupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<String>? filePath,
  }) {
    return BackupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('filePath: $filePath')
          ..write(')'))
        .toString();
  }
}

class $GraphLayoutsTable extends GraphLayouts
    with TableInfo<$GraphLayoutsTable, GraphLayout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphLayoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _canvasIdMeta = const VerificationMeta(
    'canvasId',
  );
  @override
  late final GeneratedColumn<int> canvasId = GeneratedColumn<int>(
    'canvas_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    characterId,
    x,
    y,
    canvasId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_layouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraphLayout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('canvas_id')) {
      context.handle(
        _canvasIdMeta,
        canvasId.isAcceptableOrUnknown(data['canvas_id']!, _canvasIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GraphLayout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphLayout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      canvasId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}canvas_id'],
      ),
    );
  }

  @override
  $GraphLayoutsTable createAlias(String alias) {
    return $GraphLayoutsTable(attachedDatabase, alias);
  }
}

class GraphLayout extends DataClass implements Insertable<GraphLayout> {
  final int id;
  final int worldId;
  final int characterId;
  final double x;
  final double y;
  final int? canvasId;
  const GraphLayout({
    required this.id,
    required this.worldId,
    required this.characterId,
    required this.x,
    required this.y,
    this.canvasId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['character_id'] = Variable<int>(characterId);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    if (!nullToAbsent || canvasId != null) {
      map['canvas_id'] = Variable<int>(canvasId);
    }
    return map;
  }

  GraphLayoutsCompanion toCompanion(bool nullToAbsent) {
    return GraphLayoutsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      characterId: Value(characterId),
      x: Value(x),
      y: Value(y),
      canvasId: canvasId == null && nullToAbsent
          ? const Value.absent()
          : Value(canvasId),
    );
  }

  factory GraphLayout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphLayout(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      characterId: serializer.fromJson<int>(json['characterId']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      canvasId: serializer.fromJson<int?>(json['canvasId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'characterId': serializer.toJson<int>(characterId),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'canvasId': serializer.toJson<int?>(canvasId),
    };
  }

  GraphLayout copyWith({
    int? id,
    int? worldId,
    int? characterId,
    double? x,
    double? y,
    Value<int?> canvasId = const Value.absent(),
  }) => GraphLayout(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    characterId: characterId ?? this.characterId,
    x: x ?? this.x,
    y: y ?? this.y,
    canvasId: canvasId.present ? canvasId.value : this.canvasId,
  );
  GraphLayout copyWithCompanion(GraphLayoutsCompanion data) {
    return GraphLayout(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      canvasId: data.canvasId.present ? data.canvasId.value : this.canvasId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphLayout(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('characterId: $characterId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('canvasId: $canvasId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, characterId, x, y, canvasId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphLayout &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.characterId == this.characterId &&
          other.x == this.x &&
          other.y == this.y &&
          other.canvasId == this.canvasId);
}

class GraphLayoutsCompanion extends UpdateCompanion<GraphLayout> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<int> characterId;
  final Value<double> x;
  final Value<double> y;
  final Value<int?> canvasId;
  const GraphLayoutsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.canvasId = const Value.absent(),
  });
  GraphLayoutsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required int characterId,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.canvasId = const Value.absent(),
  }) : worldId = Value(worldId),
       characterId = Value(characterId);
  static Insertable<GraphLayout> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<int>? characterId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? canvasId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (characterId != null) 'character_id': characterId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (canvasId != null) 'canvas_id': canvasId,
    });
  }

  GraphLayoutsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<int>? characterId,
    Value<double>? x,
    Value<double>? y,
    Value<int?>? canvasId,
  }) {
    return GraphLayoutsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      characterId: characterId ?? this.characterId,
      x: x ?? this.x,
      y: y ?? this.y,
      canvasId: canvasId ?? this.canvasId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (canvasId.present) {
      map['canvas_id'] = Variable<int>(canvasId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphLayoutsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('characterId: $characterId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('canvasId: $canvasId')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String key;
  final String value;
  final DateTime updatedAt;
  const Setting({
    required this.id,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => Setting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BasicInfoFieldsTable extends BasicInfoFields
    with TableInfo<$BasicInfoFieldsTable, BasicInfoField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BasicInfoFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, fieldName, sortOrder, isVisible];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'basic_info_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<BasicInfoField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BasicInfoField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BasicInfoField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_visible'],
      )!,
    );
  }

  @override
  $BasicInfoFieldsTable createAlias(String alias) {
    return $BasicInfoFieldsTable(attachedDatabase, alias);
  }
}

class BasicInfoField extends DataClass implements Insertable<BasicInfoField> {
  final int id;
  final String fieldName;
  final int sortOrder;
  final bool isVisible;
  const BasicInfoField({
    required this.id,
    required this.fieldName,
    required this.sortOrder,
    required this.isVisible,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['field_name'] = Variable<String>(fieldName);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_visible'] = Variable<bool>(isVisible);
    return map;
  }

  BasicInfoFieldsCompanion toCompanion(bool nullToAbsent) {
    return BasicInfoFieldsCompanion(
      id: Value(id),
      fieldName: Value(fieldName),
      sortOrder: Value(sortOrder),
      isVisible: Value(isVisible),
    );
  }

  factory BasicInfoField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BasicInfoField(
      id: serializer.fromJson<int>(json['id']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fieldName': serializer.toJson<String>(fieldName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isVisible': serializer.toJson<bool>(isVisible),
    };
  }

  BasicInfoField copyWith({
    int? id,
    String? fieldName,
    int? sortOrder,
    bool? isVisible,
  }) => BasicInfoField(
    id: id ?? this.id,
    fieldName: fieldName ?? this.fieldName,
    sortOrder: sortOrder ?? this.sortOrder,
    isVisible: isVisible ?? this.isVisible,
  );
  BasicInfoField copyWithCompanion(BasicInfoFieldsCompanion data) {
    return BasicInfoField(
      id: data.id.present ? data.id.value : this.id,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BasicInfoField(')
          ..write('id: $id, ')
          ..write('fieldName: $fieldName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isVisible: $isVisible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fieldName, sortOrder, isVisible);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BasicInfoField &&
          other.id == this.id &&
          other.fieldName == this.fieldName &&
          other.sortOrder == this.sortOrder &&
          other.isVisible == this.isVisible);
}

class BasicInfoFieldsCompanion extends UpdateCompanion<BasicInfoField> {
  final Value<int> id;
  final Value<String> fieldName;
  final Value<int> sortOrder;
  final Value<bool> isVisible;
  const BasicInfoFieldsCompanion({
    this.id = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isVisible = const Value.absent(),
  });
  BasicInfoFieldsCompanion.insert({
    this.id = const Value.absent(),
    required String fieldName,
    this.sortOrder = const Value.absent(),
    this.isVisible = const Value.absent(),
  }) : fieldName = Value(fieldName);
  static Insertable<BasicInfoField> custom({
    Expression<int>? id,
    Expression<String>? fieldName,
    Expression<int>? sortOrder,
    Expression<bool>? isVisible,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldName != null) 'field_name': fieldName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isVisible != null) 'is_visible': isVisible,
    });
  }

  BasicInfoFieldsCompanion copyWith({
    Value<int>? id,
    Value<String>? fieldName,
    Value<int>? sortOrder,
    Value<bool>? isVisible,
  }) {
    return BasicInfoFieldsCompanion(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BasicInfoFieldsCompanion(')
          ..write('id: $id, ')
          ..write('fieldName: $fieldName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isVisible: $isVisible')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    name,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final int id;
  final int worldId;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  const Group({
    required this.id,
    required this.worldId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Group copyWith({
    int? id,
    int? worldId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => Group(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : worldId = Value(worldId),
       name = Value(name);
  static Insertable<Group> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GroupsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CharacterGroupsTable extends CharacterGroups
    with TableInfo<$CharacterGroupsTable, CharacterGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, characterId, groupId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
    );
  }

  @override
  $CharacterGroupsTable createAlias(String alias) {
    return $CharacterGroupsTable(attachedDatabase, alias);
  }
}

class CharacterGroup extends DataClass implements Insertable<CharacterGroup> {
  final int id;
  final int characterId;
  final int groupId;
  const CharacterGroup({
    required this.id,
    required this.characterId,
    required this.groupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character_id'] = Variable<int>(characterId);
    map['group_id'] = Variable<int>(groupId);
    return map;
  }

  CharacterGroupsCompanion toCompanion(bool nullToAbsent) {
    return CharacterGroupsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      groupId: Value(groupId),
    );
  }

  factory CharacterGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterGroup(
      id: serializer.fromJson<int>(json['id']),
      characterId: serializer.fromJson<int>(json['characterId']),
      groupId: serializer.fromJson<int>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'characterId': serializer.toJson<int>(characterId),
      'groupId': serializer.toJson<int>(groupId),
    };
  }

  CharacterGroup copyWith({int? id, int? characterId, int? groupId}) =>
      CharacterGroup(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        groupId: groupId ?? this.groupId,
      );
  CharacterGroup copyWithCompanion(CharacterGroupsCompanion data) {
    return CharacterGroup(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGroup(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, groupId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterGroup &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.groupId == this.groupId);
}

class CharacterGroupsCompanion extends UpdateCompanion<CharacterGroup> {
  final Value<int> id;
  final Value<int> characterId;
  final Value<int> groupId;
  const CharacterGroupsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.groupId = const Value.absent(),
  });
  CharacterGroupsCompanion.insert({
    this.id = const Value.absent(),
    required int characterId,
    required int groupId,
  }) : characterId = Value(characterId),
       groupId = Value(groupId);
  static Insertable<CharacterGroup> custom({
    Expression<int>? id,
    Expression<int>? characterId,
    Expression<int>? groupId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (groupId != null) 'group_id': groupId,
    });
  }

  CharacterGroupsCompanion copyWith({
    Value<int>? id,
    Value<int>? characterId,
    Value<int>? groupId,
  }) {
    return CharacterGroupsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterGroupsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }
}

class $TimelineEventsTable extends TimelineEvents
    with TableInfo<$TimelineEventsTable, TimelineEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _importanceMeta = const VerificationMeta(
    'importance',
  );
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
    'importance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    characterId,
    year,
    sortOrder,
    title,
    description,
    category,
    importance,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('importance')) {
      context.handle(
        _importanceMeta,
        importance.isAcceptableOrUnknown(data['importance']!, _importanceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_order'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      importance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importance'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TimelineEventsTable createAlias(String alias) {
    return $TimelineEventsTable(attachedDatabase, alias);
  }
}

class TimelineEvent extends DataClass implements Insertable<TimelineEvent> {
  final int id;
  final int worldId;
  final int? characterId;
  final String year;
  final double sortOrder;
  final String title;
  final String description;
  final String category;
  final int importance;
  final DateTime createdAt;
  const TimelineEvent({
    required this.id,
    required this.worldId,
    this.characterId,
    required this.year,
    required this.sortOrder,
    required this.title,
    required this.description,
    required this.category,
    required this.importance,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    if (!nullToAbsent || characterId != null) {
      map['character_id'] = Variable<int>(characterId);
    }
    map['year'] = Variable<String>(year);
    map['sort_order'] = Variable<double>(sortOrder);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['importance'] = Variable<int>(importance);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TimelineEventsCompanion toCompanion(bool nullToAbsent) {
    return TimelineEventsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      characterId: characterId == null && nullToAbsent
          ? const Value.absent()
          : Value(characterId),
      year: Value(year),
      sortOrder: Value(sortOrder),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      importance: Value(importance),
      createdAt: Value(createdAt),
    );
  }

  factory TimelineEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEvent(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      characterId: serializer.fromJson<int?>(json['characterId']),
      year: serializer.fromJson<String>(json['year']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      importance: serializer.fromJson<int>(json['importance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'characterId': serializer.toJson<int?>(characterId),
      'year': serializer.toJson<String>(year),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'importance': serializer.toJson<int>(importance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TimelineEvent copyWith({
    int? id,
    int? worldId,
    Value<int?> characterId = const Value.absent(),
    String? year,
    double? sortOrder,
    String? title,
    String? description,
    String? category,
    int? importance,
    DateTime? createdAt,
  }) => TimelineEvent(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    characterId: characterId.present ? characterId.value : this.characterId,
    year: year ?? this.year,
    sortOrder: sortOrder ?? this.sortOrder,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    importance: importance ?? this.importance,
    createdAt: createdAt ?? this.createdAt,
  );
  TimelineEvent copyWithCompanion(TimelineEventsCompanion data) {
    return TimelineEvent(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      year: data.year.present ? data.year.value : this.year,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      importance: data.importance.present
          ? data.importance.value
          : this.importance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEvent(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('characterId: $characterId, ')
          ..write('year: $year, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('importance: $importance, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    characterId,
    year,
    sortOrder,
    title,
    description,
    category,
    importance,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEvent &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.characterId == this.characterId &&
          other.year == this.year &&
          other.sortOrder == this.sortOrder &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.importance == this.importance &&
          other.createdAt == this.createdAt);
}

class TimelineEventsCompanion extends UpdateCompanion<TimelineEvent> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<int?> characterId;
  final Value<String> year;
  final Value<double> sortOrder;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<int> importance;
  final Value<DateTime> createdAt;
  const TimelineEventsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.year = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.importance = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TimelineEventsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    this.characterId = const Value.absent(),
    required String year,
    this.sortOrder = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.importance = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : worldId = Value(worldId),
       year = Value(year),
       title = Value(title);
  static Insertable<TimelineEvent> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<int>? characterId,
    Expression<String>? year,
    Expression<double>? sortOrder,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<int>? importance,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (characterId != null) 'character_id': characterId,
      if (year != null) 'year': year,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (importance != null) 'importance': importance,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TimelineEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<int?>? characterId,
    Value<String>? year,
    Value<double>? sortOrder,
    Value<String>? title,
    Value<String>? description,
    Value<String>? category,
    Value<int>? importance,
    Value<DateTime>? createdAt,
  }) {
    return TimelineEventsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      characterId: characterId ?? this.characterId,
      year: year ?? this.year,
      sortOrder: sortOrder ?? this.sortOrder,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEventsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('characterId: $characterId, ')
          ..write('year: $year, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('importance: $importance, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LoreEntitiesTable extends LoreEntities
    with TableInfo<$LoreEntitiesTable, LoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoreEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lore_entities (id)',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverImagePathMeta = const VerificationMeta(
    'coverImagePath',
  );
  @override
  late final GeneratedColumn<String> coverImagePath = GeneratedColumn<String>(
    'cover_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customFieldsMeta = const VerificationMeta(
    'customFields',
  );
  @override
  late final GeneratedColumn<String> customFields = GeneratedColumn<String>(
    'custom_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    parentId,
    entityType,
    name,
    summary,
    content,
    coverImagePath,
    tags,
    customFields,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lore_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('cover_image_path')) {
      context.handle(
        _coverImagePathMeta,
        coverImagePath.isAcceptableOrUnknown(
          data['cover_image_path']!,
          _coverImagePathMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('custom_fields')) {
      context.handle(
        _customFieldsMeta,
        customFields.isAcceptableOrUnknown(
          data['custom_fields']!,
          _customFieldsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      coverImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_path'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      customFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LoreEntitiesTable createAlias(String alias) {
    return $LoreEntitiesTable(attachedDatabase, alias);
  }
}

class LoreEntity extends DataClass implements Insertable<LoreEntity> {
  final int id;
  final int worldId;
  final int? parentId;
  final String entityType;
  final String name;
  final String summary;
  final String content;
  final String? coverImagePath;
  final String tags;
  final String customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LoreEntity({
    required this.id,
    required this.worldId,
    this.parentId,
    required this.entityType,
    required this.name,
    required this.summary,
    required this.content,
    this.coverImagePath,
    required this.tags,
    required this.customFields,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['name'] = Variable<String>(name);
    map['summary'] = Variable<String>(summary);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || coverImagePath != null) {
      map['cover_image_path'] = Variable<String>(coverImagePath);
    }
    map['tags'] = Variable<String>(tags);
    map['custom_fields'] = Variable<String>(customFields);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoreEntitiesCompanion toCompanion(bool nullToAbsent) {
    return LoreEntitiesCompanion(
      id: Value(id),
      worldId: Value(worldId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      entityType: Value(entityType),
      name: Value(name),
      summary: Value(summary),
      content: Value(content),
      coverImagePath: coverImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImagePath),
      tags: Value(tags),
      customFields: Value(customFields),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoreEntity(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      name: serializer.fromJson<String>(json['name']),
      summary: serializer.fromJson<String>(json['summary']),
      content: serializer.fromJson<String>(json['content']),
      coverImagePath: serializer.fromJson<String?>(json['coverImagePath']),
      tags: serializer.fromJson<String>(json['tags']),
      customFields: serializer.fromJson<String>(json['customFields']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'parentId': serializer.toJson<int?>(parentId),
      'entityType': serializer.toJson<String>(entityType),
      'name': serializer.toJson<String>(name),
      'summary': serializer.toJson<String>(summary),
      'content': serializer.toJson<String>(content),
      'coverImagePath': serializer.toJson<String?>(coverImagePath),
      'tags': serializer.toJson<String>(tags),
      'customFields': serializer.toJson<String>(customFields),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LoreEntity copyWith({
    int? id,
    int? worldId,
    Value<int?> parentId = const Value.absent(),
    String? entityType,
    String? name,
    String? summary,
    String? content,
    Value<String?> coverImagePath = const Value.absent(),
    String? tags,
    String? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LoreEntity(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    parentId: parentId.present ? parentId.value : this.parentId,
    entityType: entityType ?? this.entityType,
    name: name ?? this.name,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    coverImagePath: coverImagePath.present
        ? coverImagePath.value
        : this.coverImagePath,
    tags: tags ?? this.tags,
    customFields: customFields ?? this.customFields,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LoreEntity copyWithCompanion(LoreEntitiesCompanion data) {
    return LoreEntity(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      name: data.name.present ? data.name.value : this.name,
      summary: data.summary.present ? data.summary.value : this.summary,
      content: data.content.present ? data.content.value : this.content,
      coverImagePath: data.coverImagePath.present
          ? data.coverImagePath.value
          : this.coverImagePath,
      tags: data.tags.present ? data.tags.value : this.tags,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntity(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('parentId: $parentId, ')
          ..write('entityType: $entityType, ')
          ..write('name: $name, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('tags: $tags, ')
          ..write('customFields: $customFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    parentId,
    entityType,
    name,
    summary,
    content,
    coverImagePath,
    tags,
    customFields,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoreEntity &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.parentId == this.parentId &&
          other.entityType == this.entityType &&
          other.name == this.name &&
          other.summary == this.summary &&
          other.content == this.content &&
          other.coverImagePath == this.coverImagePath &&
          other.tags == this.tags &&
          other.customFields == this.customFields &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LoreEntitiesCompanion extends UpdateCompanion<LoreEntity> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<int?> parentId;
  final Value<String> entityType;
  final Value<String> name;
  final Value<String> summary;
  final Value<String> content;
  final Value<String?> coverImagePath;
  final Value<String> tags;
  final Value<String> customFields;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LoreEntitiesCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.name = const Value.absent(),
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.tags = const Value.absent(),
    this.customFields = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LoreEntitiesCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    this.parentId = const Value.absent(),
    required String entityType,
    required String name,
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.tags = const Value.absent(),
    this.customFields = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : worldId = Value(worldId),
       entityType = Value(entityType),
       name = Value(name);
  static Insertable<LoreEntity> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<int>? parentId,
    Expression<String>? entityType,
    Expression<String>? name,
    Expression<String>? summary,
    Expression<String>? content,
    Expression<String>? coverImagePath,
    Expression<String>? tags,
    Expression<String>? customFields,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (parentId != null) 'parent_id': parentId,
      if (entityType != null) 'entity_type': entityType,
      if (name != null) 'name': name,
      if (summary != null) 'summary': summary,
      if (content != null) 'content': content,
      if (coverImagePath != null) 'cover_image_path': coverImagePath,
      if (tags != null) 'tags': tags,
      if (customFields != null) 'custom_fields': customFields,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LoreEntitiesCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<int?>? parentId,
    Value<String>? entityType,
    Value<String>? name,
    Value<String>? summary,
    Value<String>? content,
    Value<String?>? coverImagePath,
    Value<String>? tags,
    Value<String>? customFields,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LoreEntitiesCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      parentId: parentId ?? this.parentId,
      entityType: entityType ?? this.entityType,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (coverImagePath.present) {
      map['cover_image_path'] = Variable<String>(coverImagePath.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(customFields.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntitiesCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('parentId: $parentId, ')
          ..write('entityType: $entityType, ')
          ..write('name: $name, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('tags: $tags, ')
          ..write('customFields: $customFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LoreRelationsTable extends LoreRelations
    with TableInfo<$LoreRelationsTable, LoreRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoreRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _loreIdMeta = const VerificationMeta('loreId');
  @override
  late final GeneratedColumn<int> loreId = GeneratedColumn<int>(
    'lore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lore_entities (id)',
    ),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<int> characterId = GeneratedColumn<int>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('成员'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    loreId,
    characterId,
    role,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lore_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoreRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('lore_id')) {
      context.handle(
        _loreIdMeta,
        loreId.isAcceptableOrUnknown(data['lore_id']!, _loreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loreIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoreRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoreRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      loreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lore_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoreRelationsTable createAlias(String alias) {
    return $LoreRelationsTable(attachedDatabase, alias);
  }
}

class LoreRelation extends DataClass implements Insertable<LoreRelation> {
  final int id;
  final int worldId;
  final int loreId;
  final int characterId;
  final String role;
  final DateTime createdAt;
  const LoreRelation({
    required this.id,
    required this.worldId,
    required this.loreId,
    required this.characterId,
    required this.role,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['lore_id'] = Variable<int>(loreId);
    map['character_id'] = Variable<int>(characterId);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoreRelationsCompanion toCompanion(bool nullToAbsent) {
    return LoreRelationsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      loreId: Value(loreId),
      characterId: Value(characterId),
      role: Value(role),
      createdAt: Value(createdAt),
    );
  }

  factory LoreRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoreRelation(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      loreId: serializer.fromJson<int>(json['loreId']),
      characterId: serializer.fromJson<int>(json['characterId']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'loreId': serializer.toJson<int>(loreId),
      'characterId': serializer.toJson<int>(characterId),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoreRelation copyWith({
    int? id,
    int? worldId,
    int? loreId,
    int? characterId,
    String? role,
    DateTime? createdAt,
  }) => LoreRelation(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    loreId: loreId ?? this.loreId,
    characterId: characterId ?? this.characterId,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
  LoreRelation copyWithCompanion(LoreRelationsCompanion data) {
    return LoreRelation(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      loreId: data.loreId.present ? data.loreId.value : this.loreId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoreRelation(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('loreId: $loreId, ')
          ..write('characterId: $characterId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, worldId, loreId, characterId, role, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoreRelation &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.loreId == this.loreId &&
          other.characterId == this.characterId &&
          other.role == this.role &&
          other.createdAt == this.createdAt);
}

class LoreRelationsCompanion extends UpdateCompanion<LoreRelation> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<int> loreId;
  final Value<int> characterId;
  final Value<String> role;
  final Value<DateTime> createdAt;
  const LoreRelationsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.loreId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LoreRelationsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required int loreId,
    required int characterId,
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : worldId = Value(worldId),
       loreId = Value(loreId),
       characterId = Value(characterId);
  static Insertable<LoreRelation> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<int>? loreId,
    Expression<int>? characterId,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (loreId != null) 'lore_id': loreId,
      if (characterId != null) 'character_id': characterId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LoreRelationsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<int>? loreId,
    Value<int>? characterId,
    Value<String>? role,
    Value<DateTime>? createdAt,
  }) {
    return LoreRelationsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      loreId: loreId ?? this.loreId,
      characterId: characterId ?? this.characterId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (loreId.present) {
      map['lore_id'] = Variable<int>(loreId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<int>(characterId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoreRelationsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('loreId: $loreId, ')
          ..write('characterId: $characterId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LoreEntityRelationsTable extends LoreEntityRelations
    with TableInfo<$LoreEntityRelationsTable, LoreEntityRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoreEntityRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _fromLoreIdMeta = const VerificationMeta(
    'fromLoreId',
  );
  @override
  late final GeneratedColumn<int> fromLoreId = GeneratedColumn<int>(
    'from_lore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lore_entities (id)',
    ),
  );
  static const VerificationMeta _toLoreIdMeta = const VerificationMeta(
    'toLoreId',
  );
  @override
  late final GeneratedColumn<int> toLoreId = GeneratedColumn<int>(
    'to_lore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lore_entities (id)',
    ),
  );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('同盟'),
  );
  static const VerificationMeta _isBidirectionalMeta = const VerificationMeta(
    'isBidirectional',
  );
  @override
  late final GeneratedColumn<bool> isBidirectional = GeneratedColumn<bool>(
    'is_bidirectional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bidirectional" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    fromLoreId,
    toLoreId,
    relationType,
    isBidirectional,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lore_entity_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoreEntityRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('from_lore_id')) {
      context.handle(
        _fromLoreIdMeta,
        fromLoreId.isAcceptableOrUnknown(
          data['from_lore_id']!,
          _fromLoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromLoreIdMeta);
    }
    if (data.containsKey('to_lore_id')) {
      context.handle(
        _toLoreIdMeta,
        toLoreId.isAcceptableOrUnknown(data['to_lore_id']!, _toLoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toLoreIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_bidirectional')) {
      context.handle(
        _isBidirectionalMeta,
        isBidirectional.isAcceptableOrUnknown(
          data['is_bidirectional']!,
          _isBidirectionalMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoreEntityRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoreEntityRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      fromLoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_lore_id'],
      )!,
      toLoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_lore_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      isBidirectional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bidirectional'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoreEntityRelationsTable createAlias(String alias) {
    return $LoreEntityRelationsTable(attachedDatabase, alias);
  }
}

class LoreEntityRelation extends DataClass
    implements Insertable<LoreEntityRelation> {
  final int id;
  final int worldId;
  final int fromLoreId;
  final int toLoreId;
  final String relationType;
  final bool isBidirectional;
  final String note;
  final DateTime createdAt;
  const LoreEntityRelation({
    required this.id,
    required this.worldId,
    required this.fromLoreId,
    required this.toLoreId,
    required this.relationType,
    required this.isBidirectional,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['from_lore_id'] = Variable<int>(fromLoreId);
    map['to_lore_id'] = Variable<int>(toLoreId);
    map['relation_type'] = Variable<String>(relationType);
    map['is_bidirectional'] = Variable<bool>(isBidirectional);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoreEntityRelationsCompanion toCompanion(bool nullToAbsent) {
    return LoreEntityRelationsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      fromLoreId: Value(fromLoreId),
      toLoreId: Value(toLoreId),
      relationType: Value(relationType),
      isBidirectional: Value(isBidirectional),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LoreEntityRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoreEntityRelation(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      fromLoreId: serializer.fromJson<int>(json['fromLoreId']),
      toLoreId: serializer.fromJson<int>(json['toLoreId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      isBidirectional: serializer.fromJson<bool>(json['isBidirectional']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'fromLoreId': serializer.toJson<int>(fromLoreId),
      'toLoreId': serializer.toJson<int>(toLoreId),
      'relationType': serializer.toJson<String>(relationType),
      'isBidirectional': serializer.toJson<bool>(isBidirectional),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoreEntityRelation copyWith({
    int? id,
    int? worldId,
    int? fromLoreId,
    int? toLoreId,
    String? relationType,
    bool? isBidirectional,
    String? note,
    DateTime? createdAt,
  }) => LoreEntityRelation(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    fromLoreId: fromLoreId ?? this.fromLoreId,
    toLoreId: toLoreId ?? this.toLoreId,
    relationType: relationType ?? this.relationType,
    isBidirectional: isBidirectional ?? this.isBidirectional,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  LoreEntityRelation copyWithCompanion(LoreEntityRelationsCompanion data) {
    return LoreEntityRelation(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      fromLoreId: data.fromLoreId.present
          ? data.fromLoreId.value
          : this.fromLoreId,
      toLoreId: data.toLoreId.present ? data.toLoreId.value : this.toLoreId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      isBidirectional: data.isBidirectional.present
          ? data.isBidirectional.value
          : this.isBidirectional,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntityRelation(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('fromLoreId: $fromLoreId, ')
          ..write('toLoreId: $toLoreId, ')
          ..write('relationType: $relationType, ')
          ..write('isBidirectional: $isBidirectional, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    fromLoreId,
    toLoreId,
    relationType,
    isBidirectional,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoreEntityRelation &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.fromLoreId == this.fromLoreId &&
          other.toLoreId == this.toLoreId &&
          other.relationType == this.relationType &&
          other.isBidirectional == this.isBidirectional &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LoreEntityRelationsCompanion extends UpdateCompanion<LoreEntityRelation> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<int> fromLoreId;
  final Value<int> toLoreId;
  final Value<String> relationType;
  final Value<bool> isBidirectional;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const LoreEntityRelationsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.fromLoreId = const Value.absent(),
    this.toLoreId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.isBidirectional = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LoreEntityRelationsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required int fromLoreId,
    required int toLoreId,
    this.relationType = const Value.absent(),
    this.isBidirectional = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : worldId = Value(worldId),
       fromLoreId = Value(fromLoreId),
       toLoreId = Value(toLoreId);
  static Insertable<LoreEntityRelation> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<int>? fromLoreId,
    Expression<int>? toLoreId,
    Expression<String>? relationType,
    Expression<bool>? isBidirectional,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (fromLoreId != null) 'from_lore_id': fromLoreId,
      if (toLoreId != null) 'to_lore_id': toLoreId,
      if (relationType != null) 'relation_type': relationType,
      if (isBidirectional != null) 'is_bidirectional': isBidirectional,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LoreEntityRelationsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<int>? fromLoreId,
    Value<int>? toLoreId,
    Value<String>? relationType,
    Value<bool>? isBidirectional,
    Value<String>? note,
    Value<DateTime>? createdAt,
  }) {
    return LoreEntityRelationsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      fromLoreId: fromLoreId ?? this.fromLoreId,
      toLoreId: toLoreId ?? this.toLoreId,
      relationType: relationType ?? this.relationType,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (fromLoreId.present) {
      map['from_lore_id'] = Variable<int>(fromLoreId.value);
    }
    if (toLoreId.present) {
      map['to_lore_id'] = Variable<int>(toLoreId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (isBidirectional.present) {
      map['is_bidirectional'] = Variable<bool>(isBidirectional.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntityRelationsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('fromLoreId: $fromLoreId, ')
          ..write('toLoreId: $toLoreId, ')
          ..write('relationType: $relationType, ')
          ..write('isBidirectional: $isBidirectional, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EntityRevisionsTable extends EntityRevisions
    with TableInfo<$EntityRevisionsTable, EntityRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntityRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charCountMeta = const VerificationMeta(
    'charCount',
  );
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
    'char_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    entityType,
    entityId,
    title,
    content,
    charCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('char_count')) {
      context.handle(
        _charCountMeta,
        charCount.isAcceptableOrUnknown(data['char_count']!, _charCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntityRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      charCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntityRevisionsTable createAlias(String alias) {
    return $EntityRevisionsTable(attachedDatabase, alias);
  }
}

class EntityRevision extends DataClass implements Insertable<EntityRevision> {
  final int id;
  final int worldId;
  final String entityType;
  final int entityId;
  final String title;
  final String content;
  final int charCount;
  final DateTime createdAt;
  const EntityRevision({
    required this.id,
    required this.worldId,
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.content,
    required this.charCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['char_count'] = Variable<int>(charCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntityRevisionsCompanion toCompanion(bool nullToAbsent) {
    return EntityRevisionsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      title: Value(title),
      content: Value(content),
      charCount: Value(charCount),
      createdAt: Value(createdAt),
    );
  }

  factory EntityRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityRevision(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      charCount: serializer.fromJson<int>(json['charCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'charCount': serializer.toJson<int>(charCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EntityRevision copyWith({
    int? id,
    int? worldId,
    String? entityType,
    int? entityId,
    String? title,
    String? content,
    int? charCount,
    DateTime? createdAt,
  }) => EntityRevision(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    title: title ?? this.title,
    content: content ?? this.content,
    charCount: charCount ?? this.charCount,
    createdAt: createdAt ?? this.createdAt,
  );
  EntityRevision copyWithCompanion(EntityRevisionsCompanion data) {
    return EntityRevision(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityRevision(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('charCount: $charCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    entityType,
    entityId,
    title,
    content,
    charCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityRevision &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.title == this.title &&
          other.content == this.content &&
          other.charCount == this.charCount &&
          other.createdAt == this.createdAt);
}

class EntityRevisionsCompanion extends UpdateCompanion<EntityRevision> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> title;
  final Value<String> content;
  final Value<int> charCount;
  final Value<DateTime> createdAt;
  const EntityRevisionsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.charCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntityRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required String entityType,
    required int entityId,
    this.title = const Value.absent(),
    required String content,
    this.charCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : worldId = Value(worldId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       content = Value(content);
  static Insertable<EntityRevision> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? charCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (charCount != null) 'char_count': charCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntityRevisionsCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<String>? entityType,
    Value<int>? entityId,
    Value<String>? title,
    Value<String>? content,
    Value<int>? charCount,
    Value<DateTime>? createdAt,
  }) {
    return EntityRevisionsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      content: content ?? this.content,
      charCount: charCount ?? this.charCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntityRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('charCount: $charCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GraphCanvasesTable extends GraphCanvases
    with TableInfo<$GraphCanvasesTable, GraphCanvas> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphCanvasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _viewportXMeta = const VerificationMeta(
    'viewportX',
  );
  @override
  late final GeneratedColumn<double> viewportX = GeneratedColumn<double>(
    'viewport_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _viewportYMeta = const VerificationMeta(
    'viewportY',
  );
  @override
  late final GeneratedColumn<double> viewportY = GeneratedColumn<double>(
    'viewport_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _zoomScaleMeta = const VerificationMeta(
    'zoomScale',
  );
  @override
  late final GeneratedColumn<double> zoomScale = GeneratedColumn<double>(
    'zoom_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _filterConfigMeta = const VerificationMeta(
    'filterConfig',
  );
  @override
  late final GeneratedColumn<String> filterConfig = GeneratedColumn<String>(
    'filter_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    name,
    description,
    isDefault,
    viewportX,
    viewportY,
    zoomScale,
    filterConfig,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_canvases';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraphCanvas> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('viewport_x')) {
      context.handle(
        _viewportXMeta,
        viewportX.isAcceptableOrUnknown(data['viewport_x']!, _viewportXMeta),
      );
    }
    if (data.containsKey('viewport_y')) {
      context.handle(
        _viewportYMeta,
        viewportY.isAcceptableOrUnknown(data['viewport_y']!, _viewportYMeta),
      );
    }
    if (data.containsKey('zoom_scale')) {
      context.handle(
        _zoomScaleMeta,
        zoomScale.isAcceptableOrUnknown(data['zoom_scale']!, _zoomScaleMeta),
      );
    }
    if (data.containsKey('filter_config')) {
      context.handle(
        _filterConfigMeta,
        filterConfig.isAcceptableOrUnknown(
          data['filter_config']!,
          _filterConfigMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GraphCanvas map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphCanvas(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      viewportX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}viewport_x'],
      )!,
      viewportY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}viewport_y'],
      )!,
      zoomScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zoom_scale'],
      )!,
      filterConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_config'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GraphCanvasesTable createAlias(String alias) {
    return $GraphCanvasesTable(attachedDatabase, alias);
  }
}

class GraphCanvas extends DataClass implements Insertable<GraphCanvas> {
  final int id;
  final int worldId;
  final String name;
  final String? description;
  final bool isDefault;
  final double viewportX;
  final double viewportY;
  final double zoomScale;
  final String? filterConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GraphCanvas({
    required this.id,
    required this.worldId,
    required this.name,
    this.description,
    required this.isDefault,
    required this.viewportX,
    required this.viewportY,
    required this.zoomScale,
    this.filterConfig,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['viewport_x'] = Variable<double>(viewportX);
    map['viewport_y'] = Variable<double>(viewportY);
    map['zoom_scale'] = Variable<double>(zoomScale);
    if (!nullToAbsent || filterConfig != null) {
      map['filter_config'] = Variable<String>(filterConfig);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GraphCanvasesCompanion toCompanion(bool nullToAbsent) {
    return GraphCanvasesCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isDefault: Value(isDefault),
      viewportX: Value(viewportX),
      viewportY: Value(viewportY),
      zoomScale: Value(zoomScale),
      filterConfig: filterConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(filterConfig),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GraphCanvas.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphCanvas(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      viewportX: serializer.fromJson<double>(json['viewportX']),
      viewportY: serializer.fromJson<double>(json['viewportY']),
      zoomScale: serializer.fromJson<double>(json['zoomScale']),
      filterConfig: serializer.fromJson<String?>(json['filterConfig']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isDefault': serializer.toJson<bool>(isDefault),
      'viewportX': serializer.toJson<double>(viewportX),
      'viewportY': serializer.toJson<double>(viewportY),
      'zoomScale': serializer.toJson<double>(zoomScale),
      'filterConfig': serializer.toJson<String?>(filterConfig),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GraphCanvas copyWith({
    int? id,
    int? worldId,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isDefault,
    double? viewportX,
    double? viewportY,
    double? zoomScale,
    Value<String?> filterConfig = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GraphCanvas(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isDefault: isDefault ?? this.isDefault,
    viewportX: viewportX ?? this.viewportX,
    viewportY: viewportY ?? this.viewportY,
    zoomScale: zoomScale ?? this.zoomScale,
    filterConfig: filterConfig.present ? filterConfig.value : this.filterConfig,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GraphCanvas copyWithCompanion(GraphCanvasesCompanion data) {
    return GraphCanvas(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      viewportX: data.viewportX.present ? data.viewportX.value : this.viewportX,
      viewportY: data.viewportY.present ? data.viewportY.value : this.viewportY,
      zoomScale: data.zoomScale.present ? data.zoomScale.value : this.zoomScale,
      filterConfig: data.filterConfig.present
          ? data.filterConfig.value
          : this.filterConfig,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphCanvas(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('viewportX: $viewportX, ')
          ..write('viewportY: $viewportY, ')
          ..write('zoomScale: $zoomScale, ')
          ..write('filterConfig: $filterConfig, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    name,
    description,
    isDefault,
    viewportX,
    viewportY,
    zoomScale,
    filterConfig,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphCanvas &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isDefault == this.isDefault &&
          other.viewportX == this.viewportX &&
          other.viewportY == this.viewportY &&
          other.zoomScale == this.zoomScale &&
          other.filterConfig == this.filterConfig &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GraphCanvasesCompanion extends UpdateCompanion<GraphCanvas> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isDefault;
  final Value<double> viewportX;
  final Value<double> viewportY;
  final Value<double> zoomScale;
  final Value<String?> filterConfig;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GraphCanvasesCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.viewportX = const Value.absent(),
    this.viewportY = const Value.absent(),
    this.zoomScale = const Value.absent(),
    this.filterConfig = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GraphCanvasesCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required String name,
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.viewportX = const Value.absent(),
    this.viewportY = const Value.absent(),
    this.zoomScale = const Value.absent(),
    this.filterConfig = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : worldId = Value(worldId),
       name = Value(name);
  static Insertable<GraphCanvas> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isDefault,
    Expression<double>? viewportX,
    Expression<double>? viewportY,
    Expression<double>? zoomScale,
    Expression<String>? filterConfig,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isDefault != null) 'is_default': isDefault,
      if (viewportX != null) 'viewport_x': viewportX,
      if (viewportY != null) 'viewport_y': viewportY,
      if (zoomScale != null) 'zoom_scale': zoomScale,
      if (filterConfig != null) 'filter_config': filterConfig,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GraphCanvasesCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isDefault,
    Value<double>? viewportX,
    Value<double>? viewportY,
    Value<double>? zoomScale,
    Value<String?>? filterConfig,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GraphCanvasesCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      viewportX: viewportX ?? this.viewportX,
      viewportY: viewportY ?? this.viewportY,
      zoomScale: zoomScale ?? this.zoomScale,
      filterConfig: filterConfig ?? this.filterConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (viewportX.present) {
      map['viewport_x'] = Variable<double>(viewportX.value);
    }
    if (viewportY.present) {
      map['viewport_y'] = Variable<double>(viewportY.value);
    }
    if (zoomScale.present) {
      map['zoom_scale'] = Variable<double>(zoomScale.value);
    }
    if (filterConfig.present) {
      map['filter_config'] = Variable<String>(filterConfig.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphCanvasesCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('viewportX: $viewportX, ')
          ..write('viewportY: $viewportY, ')
          ..write('zoomScale: $zoomScale, ')
          ..write('filterConfig: $filterConfig, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StoryWorksTable extends StoryWorks
    with TableInfo<$StoryWorksTable, StoryWork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryWorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<int> worldId = GeneratedColumn<int>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES worlds (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('小说'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('策划中'),
  );
  static const VerificationMeta _coverImagePathMeta = const VerificationMeta(
    'coverImagePath',
  );
  @override
  late final GeneratedColumn<String> coverImagePath = GeneratedColumn<String>(
    'cover_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    worldId,
    title,
    type,
    summary,
    status,
    coverImagePath,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_works';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryWork> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('cover_image_path')) {
      context.handle(
        _coverImagePathMeta,
        coverImagePath.isAcceptableOrUnknown(
          data['cover_image_path']!,
          _coverImagePathMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryWork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryWork(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}world_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      coverImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_path'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoryWorksTable createAlias(String alias) {
    return $StoryWorksTable(attachedDatabase, alias);
  }
}

class StoryWork extends DataClass implements Insertable<StoryWork> {
  final int id;
  final int worldId;
  final String title;
  final String type;
  final String summary;
  final String status;
  final String? coverImagePath;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StoryWork({
    required this.id,
    required this.worldId,
    required this.title,
    required this.type,
    required this.summary,
    required this.status,
    this.coverImagePath,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['world_id'] = Variable<int>(worldId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['summary'] = Variable<String>(summary);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || coverImagePath != null) {
      map['cover_image_path'] = Variable<String>(coverImagePath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryWorksCompanion toCompanion(bool nullToAbsent) {
    return StoryWorksCompanion(
      id: Value(id),
      worldId: Value(worldId),
      title: Value(title),
      type: Value(type),
      summary: Value(summary),
      status: Value(status),
      coverImagePath: coverImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImagePath),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryWork.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryWork(
      id: serializer.fromJson<int>(json['id']),
      worldId: serializer.fromJson<int>(json['worldId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      summary: serializer.fromJson<String>(json['summary']),
      status: serializer.fromJson<String>(json['status']),
      coverImagePath: serializer.fromJson<String?>(json['coverImagePath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'worldId': serializer.toJson<int>(worldId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'summary': serializer.toJson<String>(summary),
      'status': serializer.toJson<String>(status),
      'coverImagePath': serializer.toJson<String?>(coverImagePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryWork copyWith({
    int? id,
    int? worldId,
    String? title,
    String? type,
    String? summary,
    String? status,
    Value<String?> coverImagePath = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StoryWork(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    title: title ?? this.title,
    type: type ?? this.type,
    summary: summary ?? this.summary,
    status: status ?? this.status,
    coverImagePath: coverImagePath.present
        ? coverImagePath.value
        : this.coverImagePath,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoryWork copyWithCompanion(StoryWorksCompanion data) {
    return StoryWork(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      summary: data.summary.present ? data.summary.value : this.summary,
      status: data.status.present ? data.status.value : this.status,
      coverImagePath: data.coverImagePath.present
          ? data.coverImagePath.value
          : this.coverImagePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryWork(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    worldId,
    title,
    type,
    summary,
    status,
    coverImagePath,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryWork &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.title == this.title &&
          other.type == this.type &&
          other.summary == this.summary &&
          other.status == this.status &&
          other.coverImagePath == this.coverImagePath &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StoryWorksCompanion extends UpdateCompanion<StoryWork> {
  final Value<int> id;
  final Value<int> worldId;
  final Value<String> title;
  final Value<String> type;
  final Value<String> summary;
  final Value<String> status;
  final Value<String?> coverImagePath;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StoryWorksCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.summary = const Value.absent(),
    this.status = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StoryWorksCompanion.insert({
    this.id = const Value.absent(),
    required int worldId,
    required String title,
    this.type = const Value.absent(),
    this.summary = const Value.absent(),
    this.status = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : worldId = Value(worldId),
       title = Value(title);
  static Insertable<StoryWork> custom({
    Expression<int>? id,
    Expression<int>? worldId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? summary,
    Expression<String>? status,
    Expression<String>? coverImagePath,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (summary != null) 'summary': summary,
      if (status != null) 'status': status,
      if (coverImagePath != null) 'cover_image_path': coverImagePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StoryWorksCompanion copyWith({
    Value<int>? id,
    Value<int>? worldId,
    Value<String>? title,
    Value<String>? type,
    Value<String>? summary,
    Value<String>? status,
    Value<String?>? coverImagePath,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StoryWorksCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      title: title ?? this.title,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<int>(worldId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (coverImagePath.present) {
      map['cover_image_path'] = Variable<String>(coverImagePath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryWorksCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StoryChaptersTable extends StoryChapters
    with TableInfo<$StoryChaptersTable, StoryChapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<int> workId = GeneratedColumn<int>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES story_works (id)',
    ),
  );
  static const VerificationMeta _arcNameMeta = const VerificationMeta(
    'arcName',
  );
  @override
  late final GeneratedColumn<String> arcName = GeneratedColumn<String>(
    'arc_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('正卷'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('大纲'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workId,
    arcName,
    title,
    summary,
    status,
    sortOrder,
    wordCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryChapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('arc_name')) {
      context.handle(
        _arcNameMeta,
        arcName.isAcceptableOrUnknown(data['arc_name']!, _arcNameMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryChapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryChapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_id'],
      )!,
      arcName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arc_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoryChaptersTable createAlias(String alias) {
    return $StoryChaptersTable(attachedDatabase, alias);
  }
}

class StoryChapter extends DataClass implements Insertable<StoryChapter> {
  final int id;
  final int workId;
  final String arcName;
  final String title;
  final String summary;
  final String status;
  final int sortOrder;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StoryChapter({
    required this.id,
    required this.workId,
    required this.arcName,
    required this.title,
    required this.summary,
    required this.status,
    required this.sortOrder,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['work_id'] = Variable<int>(workId);
    map['arc_name'] = Variable<String>(arcName);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['status'] = Variable<String>(status);
    map['sort_order'] = Variable<int>(sortOrder);
    map['word_count'] = Variable<int>(wordCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryChaptersCompanion toCompanion(bool nullToAbsent) {
    return StoryChaptersCompanion(
      id: Value(id),
      workId: Value(workId),
      arcName: Value(arcName),
      title: Value(title),
      summary: Value(summary),
      status: Value(status),
      sortOrder: Value(sortOrder),
      wordCount: Value(wordCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryChapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryChapter(
      id: serializer.fromJson<int>(json['id']),
      workId: serializer.fromJson<int>(json['workId']),
      arcName: serializer.fromJson<String>(json['arcName']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      status: serializer.fromJson<String>(json['status']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workId': serializer.toJson<int>(workId),
      'arcName': serializer.toJson<String>(arcName),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'status': serializer.toJson<String>(status),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'wordCount': serializer.toJson<int>(wordCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryChapter copyWith({
    int? id,
    int? workId,
    String? arcName,
    String? title,
    String? summary,
    String? status,
    int? sortOrder,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StoryChapter(
    id: id ?? this.id,
    workId: workId ?? this.workId,
    arcName: arcName ?? this.arcName,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    status: status ?? this.status,
    sortOrder: sortOrder ?? this.sortOrder,
    wordCount: wordCount ?? this.wordCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoryChapter copyWithCompanion(StoryChaptersCompanion data) {
    return StoryChapter(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      arcName: data.arcName.present ? data.arcName.value : this.arcName,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      status: data.status.present ? data.status.value : this.status,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryChapter(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('arcName: $arcName, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('wordCount: $wordCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workId,
    arcName,
    title,
    summary,
    status,
    sortOrder,
    wordCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryChapter &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.arcName == this.arcName &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.status == this.status &&
          other.sortOrder == this.sortOrder &&
          other.wordCount == this.wordCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StoryChaptersCompanion extends UpdateCompanion<StoryChapter> {
  final Value<int> id;
  final Value<int> workId;
  final Value<String> arcName;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> status;
  final Value<int> sortOrder;
  final Value<int> wordCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StoryChaptersCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.arcName = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StoryChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int workId,
    this.arcName = const Value.absent(),
    required String title,
    this.summary = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : workId = Value(workId),
       title = Value(title);
  static Insertable<StoryChapter> custom({
    Expression<int>? id,
    Expression<int>? workId,
    Expression<String>? arcName,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? status,
    Expression<int>? sortOrder,
    Expression<int>? wordCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (arcName != null) 'arc_name': arcName,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (status != null) 'status': status,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (wordCount != null) 'word_count': wordCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StoryChaptersCompanion copyWith({
    Value<int>? id,
    Value<int>? workId,
    Value<String>? arcName,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? status,
    Value<int>? sortOrder,
    Value<int>? wordCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StoryChaptersCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      arcName: arcName ?? this.arcName,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<int>(workId.value);
    }
    if (arcName.present) {
      map['arc_name'] = Variable<String>(arcName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryChaptersCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('arcName: $arcName, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('wordCount: $wordCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StoryScenesTable extends StoryScenes
    with TableInfo<$StoryScenesTable, StoryScene> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryScenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES story_chapters (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _povCharacterIdMeta = const VerificationMeta(
    'povCharacterId',
  );
  @override
  late final GeneratedColumn<int> povCharacterId = GeneratedColumn<int>(
    'pov_character_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES characters (id)',
    ),
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lore_entities (id)',
    ),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timelineTimeMeta = const VerificationMeta(
    'timelineTime',
  );
  @override
  late final GeneratedColumn<String> timelineTime = GeneratedColumn<String>(
    'timeline_time',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _characterIdsMeta = const VerificationMeta(
    'characterIds',
  );
  @override
  late final GeneratedColumn<String> characterIds = GeneratedColumn<String>(
    'character_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    title,
    summary,
    content,
    povCharacterId,
    locationId,
    locationName,
    timelineTime,
    mood,
    characterIds,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_scenes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryScene> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('pov_character_id')) {
      context.handle(
        _povCharacterIdMeta,
        povCharacterId.isAcceptableOrUnknown(
          data['pov_character_id']!,
          _povCharacterIdMeta,
        ),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('timeline_time')) {
      context.handle(
        _timelineTimeMeta,
        timelineTime.isAcceptableOrUnknown(
          data['timeline_time']!,
          _timelineTimeMeta,
        ),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('character_ids')) {
      context.handle(
        _characterIdsMeta,
        characterIds.isAcceptableOrUnknown(
          data['character_ids']!,
          _characterIdsMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryScene map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryScene(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      povCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pov_character_id'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      timelineTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timeline_time'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      characterIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_ids'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoryScenesTable createAlias(String alias) {
    return $StoryScenesTable(attachedDatabase, alias);
  }
}

class StoryScene extends DataClass implements Insertable<StoryScene> {
  final int id;
  final int chapterId;
  final String title;
  final String summary;
  final String content;
  final int? povCharacterId;
  final int? locationId;
  final String locationName;
  final String timelineTime;
  final String mood;
  final String characterIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StoryScene({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.summary,
    required this.content,
    this.povCharacterId,
    this.locationId,
    required this.locationName,
    required this.timelineTime,
    required this.mood,
    required this.characterIds,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || povCharacterId != null) {
      map['pov_character_id'] = Variable<int>(povCharacterId);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<int>(locationId);
    }
    map['location_name'] = Variable<String>(locationName);
    map['timeline_time'] = Variable<String>(timelineTime);
    map['mood'] = Variable<String>(mood);
    map['character_ids'] = Variable<String>(characterIds);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryScenesCompanion toCompanion(bool nullToAbsent) {
    return StoryScenesCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      title: Value(title),
      summary: Value(summary),
      content: Value(content),
      povCharacterId: povCharacterId == null && nullToAbsent
          ? const Value.absent()
          : Value(povCharacterId),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      locationName: Value(locationName),
      timelineTime: Value(timelineTime),
      mood: Value(mood),
      characterIds: Value(characterIds),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryScene.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryScene(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      content: serializer.fromJson<String>(json['content']),
      povCharacterId: serializer.fromJson<int?>(json['povCharacterId']),
      locationId: serializer.fromJson<int?>(json['locationId']),
      locationName: serializer.fromJson<String>(json['locationName']),
      timelineTime: serializer.fromJson<String>(json['timelineTime']),
      mood: serializer.fromJson<String>(json['mood']),
      characterIds: serializer.fromJson<String>(json['characterIds']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'content': serializer.toJson<String>(content),
      'povCharacterId': serializer.toJson<int?>(povCharacterId),
      'locationId': serializer.toJson<int?>(locationId),
      'locationName': serializer.toJson<String>(locationName),
      'timelineTime': serializer.toJson<String>(timelineTime),
      'mood': serializer.toJson<String>(mood),
      'characterIds': serializer.toJson<String>(characterIds),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryScene copyWith({
    int? id,
    int? chapterId,
    String? title,
    String? summary,
    String? content,
    Value<int?> povCharacterId = const Value.absent(),
    Value<int?> locationId = const Value.absent(),
    String? locationName,
    String? timelineTime,
    String? mood,
    String? characterIds,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StoryScene(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    povCharacterId: povCharacterId.present
        ? povCharacterId.value
        : this.povCharacterId,
    locationId: locationId.present ? locationId.value : this.locationId,
    locationName: locationName ?? this.locationName,
    timelineTime: timelineTime ?? this.timelineTime,
    mood: mood ?? this.mood,
    characterIds: characterIds ?? this.characterIds,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoryScene copyWithCompanion(StoryScenesCompanion data) {
    return StoryScene(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      content: data.content.present ? data.content.value : this.content,
      povCharacterId: data.povCharacterId.present
          ? data.povCharacterId.value
          : this.povCharacterId,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      timelineTime: data.timelineTime.present
          ? data.timelineTime.value
          : this.timelineTime,
      mood: data.mood.present ? data.mood.value : this.mood,
      characterIds: data.characterIds.present
          ? data.characterIds.value
          : this.characterIds,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryScene(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('povCharacterId: $povCharacterId, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('timelineTime: $timelineTime, ')
          ..write('mood: $mood, ')
          ..write('characterIds: $characterIds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    title,
    summary,
    content,
    povCharacterId,
    locationId,
    locationName,
    timelineTime,
    mood,
    characterIds,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryScene &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.content == this.content &&
          other.povCharacterId == this.povCharacterId &&
          other.locationId == this.locationId &&
          other.locationName == this.locationName &&
          other.timelineTime == this.timelineTime &&
          other.mood == this.mood &&
          other.characterIds == this.characterIds &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StoryScenesCompanion extends UpdateCompanion<StoryScene> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> content;
  final Value<int?> povCharacterId;
  final Value<int?> locationId;
  final Value<String> locationName;
  final Value<String> timelineTime;
  final Value<String> mood;
  final Value<String> characterIds;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StoryScenesCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.povCharacterId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.timelineTime = const Value.absent(),
    this.mood = const Value.absent(),
    this.characterIds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StoryScenesCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required String title,
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.povCharacterId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.locationName = const Value.absent(),
    this.timelineTime = const Value.absent(),
    this.mood = const Value.absent(),
    this.characterIds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : chapterId = Value(chapterId),
       title = Value(title);
  static Insertable<StoryScene> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? content,
    Expression<int>? povCharacterId,
    Expression<int>? locationId,
    Expression<String>? locationName,
    Expression<String>? timelineTime,
    Expression<String>? mood,
    Expression<String>? characterIds,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (content != null) 'content': content,
      if (povCharacterId != null) 'pov_character_id': povCharacterId,
      if (locationId != null) 'location_id': locationId,
      if (locationName != null) 'location_name': locationName,
      if (timelineTime != null) 'timeline_time': timelineTime,
      if (mood != null) 'mood': mood,
      if (characterIds != null) 'character_ids': characterIds,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StoryScenesCompanion copyWith({
    Value<int>? id,
    Value<int>? chapterId,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? content,
    Value<int?>? povCharacterId,
    Value<int?>? locationId,
    Value<String>? locationName,
    Value<String>? timelineTime,
    Value<String>? mood,
    Value<String>? characterIds,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StoryScenesCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      povCharacterId: povCharacterId ?? this.povCharacterId,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      timelineTime: timelineTime ?? this.timelineTime,
      mood: mood ?? this.mood,
      characterIds: characterIds ?? this.characterIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (povCharacterId.present) {
      map['pov_character_id'] = Variable<int>(povCharacterId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (timelineTime.present) {
      map['timeline_time'] = Variable<String>(timelineTime.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (characterIds.present) {
      map['character_ids'] = Variable<String>(characterIds.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryScenesCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('povCharacterId: $povCharacterId, ')
          ..write('locationId: $locationId, ')
          ..write('locationName: $locationName, ')
          ..write('timelineTime: $timelineTime, ')
          ..write('mood: $mood, ')
          ..write('characterIds: $characterIds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorldsTable worlds = $WorldsTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $CharacterFieldsTable characterFields = $CharacterFieldsTable(
    this,
  );
  late final $CharacterStatsTable characterStats = $CharacterStatsTable(this);
  late final $CharacterGalleriesTable characterGalleries =
      $CharacterGalleriesTable(this);
  late final $RelationsTable relations = $RelationsTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateFieldsTable templateFields = $TemplateFieldsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $CharacterTagsTable characterTags = $CharacterTagsTable(this);
  late final $TrashTable trash = $TrashTable(this);
  late final $BackupsTable backups = $BackupsTable(this);
  late final $GraphLayoutsTable graphLayouts = $GraphLayoutsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BasicInfoFieldsTable basicInfoFields = $BasicInfoFieldsTable(
    this,
  );
  late final $GroupsTable groups = $GroupsTable(this);
  late final $CharacterGroupsTable characterGroups = $CharacterGroupsTable(
    this,
  );
  late final $TimelineEventsTable timelineEvents = $TimelineEventsTable(this);
  late final $LoreEntitiesTable loreEntities = $LoreEntitiesTable(this);
  late final $LoreRelationsTable loreRelations = $LoreRelationsTable(this);
  late final $LoreEntityRelationsTable loreEntityRelations =
      $LoreEntityRelationsTable(this);
  late final $EntityRevisionsTable entityRevisions = $EntityRevisionsTable(
    this,
  );
  late final $GraphCanvasesTable graphCanvases = $GraphCanvasesTable(this);
  late final $StoryWorksTable storyWorks = $StoryWorksTable(this);
  late final $StoryChaptersTable storyChapters = $StoryChaptersTable(this);
  late final $StoryScenesTable storyScenes = $StoryScenesTable(this);
  late final WorldDao worldDao = WorldDao(this as AppDatabase);
  late final CharacterDao characterDao = CharacterDao(this as AppDatabase);
  late final RelationDao relationDao = RelationDao(this as AppDatabase);
  late final TemplateDao templateDao = TemplateDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final TrashDao trashDao = TrashDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final GroupDao groupDao = GroupDao(this as AppDatabase);
  late final TimelineDao timelineDao = TimelineDao(this as AppDatabase);
  late final LoreDao loreDao = LoreDao(this as AppDatabase);
  late final RevisionDao revisionDao = RevisionDao(this as AppDatabase);
  late final CanvasDao canvasDao = CanvasDao(this as AppDatabase);
  late final StoryDao storyDao = StoryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    worlds,
    characters,
    characterFields,
    characterStats,
    characterGalleries,
    relations,
    templates,
    templateFields,
    tags,
    characterTags,
    trash,
    backups,
    graphLayouts,
    settings,
    basicInfoFields,
    groups,
    characterGroups,
    timelineEvents,
    loreEntities,
    loreRelations,
    loreEntityRelations,
    entityRevisions,
    graphCanvases,
    storyWorks,
    storyChapters,
    storyScenes,
  ];
}

typedef $$WorldsTableCreateCompanionBuilder =
    WorldsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<bool> isLocked,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$WorldsTableUpdateCompanionBuilder =
    WorldsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> isLocked,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$WorldsTableReferences
    extends BaseReferences<_$AppDatabase, $WorldsTable, World> {
  $$WorldsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharactersTable, List<Character>>
  _charactersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characters,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.characters.worldId),
  );

  $$CharactersTableProcessedTableManager get charactersRefs {
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_charactersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TemplatesTable, List<Template>>
  _templatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templates,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.templates.worldId),
  );

  $$TemplatesTableProcessedTableManager get templatesRefs {
    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GroupsTable, List<Group>> _groupsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.groups,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.groups.worldId),
  );

  $$GroupsTableProcessedTableManager get groupsRefs {
    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimelineEventsTable, List<TimelineEvent>>
  _timelineEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timelineEvents,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.timelineEvents.worldId),
  );

  $$TimelineEventsTableProcessedTableManager get timelineEventsRefs {
    final manager = $$TimelineEventsTableTableManager(
      $_db,
      $_db.timelineEvents,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_timelineEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoreEntitiesTable, List<LoreEntity>>
  _loreEntitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loreEntities,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.loreEntities.worldId),
  );

  $$LoreEntitiesTableProcessedTableManager get loreEntitiesRefs {
    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loreEntitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoreRelationsTable, List<LoreRelation>>
  _loreRelationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loreRelations,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.loreRelations.worldId),
  );

  $$LoreRelationsTableProcessedTableManager get loreRelationsRefs {
    final manager = $$LoreRelationsTableTableManager(
      $_db,
      $_db.loreRelations,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loreRelationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LoreEntityRelationsTable,
    List<LoreEntityRelation>
  >
  _loreEntityRelationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.loreEntityRelations,
        aliasName: $_aliasNameGenerator(
          db.worlds.id,
          db.loreEntityRelations.worldId,
        ),
      );

  $$LoreEntityRelationsTableProcessedTableManager get loreEntityRelationsRefs {
    final manager = $$LoreEntityRelationsTableTableManager(
      $_db,
      $_db.loreEntityRelations,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _loreEntityRelationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntityRevisionsTable, List<EntityRevision>>
  _entityRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entityRevisions,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.entityRevisions.worldId),
  );

  $$EntityRevisionsTableProcessedTableManager get entityRevisionsRefs {
    final manager = $$EntityRevisionsTableTableManager(
      $_db,
      $_db.entityRevisions,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _entityRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GraphCanvasesTable, List<GraphCanvas>>
  _graphCanvasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.graphCanvases,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.graphCanvases.worldId),
  );

  $$GraphCanvasesTableProcessedTableManager get graphCanvasesRefs {
    final manager = $$GraphCanvasesTableTableManager(
      $_db,
      $_db.graphCanvases,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_graphCanvasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoryWorksTable, List<StoryWork>>
  _storyWorksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyWorks,
    aliasName: $_aliasNameGenerator(db.worlds.id, db.storyWorks.worldId),
  );

  $$StoryWorksTableProcessedTableManager get storyWorksRefs {
    final manager = $$StoryWorksTableTableManager(
      $_db,
      $_db.storyWorks,
    ).filter((f) => f.worldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyWorksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorldsTableFilterComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> charactersRefs(
    Expression<bool> Function($$CharactersTableFilterComposer f) f,
  ) {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> templatesRefs(
    Expression<bool> Function($$TemplatesTableFilterComposer f) f,
  ) {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> groupsRefs(
    Expression<bool> Function($$GroupsTableFilterComposer f) f,
  ) {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timelineEventsRefs(
    Expression<bool> Function($$TimelineEventsTableFilterComposer f) f,
  ) {
    final $$TimelineEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableFilterComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loreEntitiesRefs(
    Expression<bool> Function($$LoreEntitiesTableFilterComposer f) f,
  ) {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loreRelationsRefs(
    Expression<bool> Function($$LoreRelationsTableFilterComposer f) f,
  ) {
    final $$LoreRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableFilterComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loreEntityRelationsRefs(
    Expression<bool> Function($$LoreEntityRelationsTableFilterComposer f) f,
  ) {
    final $$LoreEntityRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreEntityRelations,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntityRelationsTableFilterComposer(
            $db: $db,
            $table: $db.loreEntityRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entityRevisionsRefs(
    Expression<bool> Function($$EntityRevisionsTableFilterComposer f) f,
  ) {
    final $$EntityRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entityRevisions,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntityRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.entityRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> graphCanvasesRefs(
    Expression<bool> Function($$GraphCanvasesTableFilterComposer f) f,
  ) {
    final $$GraphCanvasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.graphCanvases,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GraphCanvasesTableFilterComposer(
            $db: $db,
            $table: $db.graphCanvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storyWorksRefs(
    Expression<bool> Function($$StoryWorksTableFilterComposer f) f,
  ) {
    final $$StoryWorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyWorks,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryWorksTableFilterComposer(
            $db: $db,
            $table: $db.storyWorks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorldsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorldsTable> {
  $$WorldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> charactersRefs<T extends Object>(
    Expression<T> Function($$CharactersTableAnnotationComposer a) f,
  ) {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> templatesRefs<T extends Object>(
    Expression<T> Function($$TemplatesTableAnnotationComposer a) f,
  ) {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> groupsRefs<T extends Object>(
    Expression<T> Function($$GroupsTableAnnotationComposer a) f,
  ) {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timelineEventsRefs<T extends Object>(
    Expression<T> Function($$TimelineEventsTableAnnotationComposer a) f,
  ) {
    final $$TimelineEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loreEntitiesRefs<T extends Object>(
    Expression<T> Function($$LoreEntitiesTableAnnotationComposer a) f,
  ) {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loreRelationsRefs<T extends Object>(
    Expression<T> Function($$LoreRelationsTableAnnotationComposer a) f,
  ) {
    final $$LoreRelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loreEntityRelationsRefs<T extends Object>(
    Expression<T> Function($$LoreEntityRelationsTableAnnotationComposer a) f,
  ) {
    final $$LoreEntityRelationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.loreEntityRelations,
          getReferencedColumn: (t) => t.worldId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LoreEntityRelationsTableAnnotationComposer(
                $db: $db,
                $table: $db.loreEntityRelations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> entityRevisionsRefs<T extends Object>(
    Expression<T> Function($$EntityRevisionsTableAnnotationComposer a) f,
  ) {
    final $$EntityRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entityRevisions,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntityRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.entityRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> graphCanvasesRefs<T extends Object>(
    Expression<T> Function($$GraphCanvasesTableAnnotationComposer a) f,
  ) {
    final $$GraphCanvasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.graphCanvases,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GraphCanvasesTableAnnotationComposer(
            $db: $db,
            $table: $db.graphCanvases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storyWorksRefs<T extends Object>(
    Expression<T> Function($$StoryWorksTableAnnotationComposer a) f,
  ) {
    final $$StoryWorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyWorks,
      getReferencedColumn: (t) => t.worldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryWorksTableAnnotationComposer(
            $db: $db,
            $table: $db.storyWorks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorldsTable,
          World,
          $$WorldsTableFilterComposer,
          $$WorldsTableOrderingComposer,
          $$WorldsTableAnnotationComposer,
          $$WorldsTableCreateCompanionBuilder,
          $$WorldsTableUpdateCompanionBuilder,
          (World, $$WorldsTableReferences),
          World,
          PrefetchHooks Function({
            bool charactersRefs,
            bool templatesRefs,
            bool groupsRefs,
            bool timelineEventsRefs,
            bool loreEntitiesRefs,
            bool loreRelationsRefs,
            bool loreEntityRelationsRefs,
            bool entityRevisionsRefs,
            bool graphCanvasesRefs,
            bool storyWorksRefs,
          })
        > {
  $$WorldsTableTableManager(_$AppDatabase db, $WorldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WorldsCompanion(
                id: id,
                name: name,
                description: description,
                isLocked: isLocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WorldsCompanion.insert(
                id: id,
                name: name,
                description: description,
                isLocked: isLocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WorldsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                charactersRefs = false,
                templatesRefs = false,
                groupsRefs = false,
                timelineEventsRefs = false,
                loreEntitiesRefs = false,
                loreRelationsRefs = false,
                loreEntityRelationsRefs = false,
                entityRevisionsRefs = false,
                graphCanvasesRefs = false,
                storyWorksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (charactersRefs) db.characters,
                    if (templatesRefs) db.templates,
                    if (groupsRefs) db.groups,
                    if (timelineEventsRefs) db.timelineEvents,
                    if (loreEntitiesRefs) db.loreEntities,
                    if (loreRelationsRefs) db.loreRelations,
                    if (loreEntityRelationsRefs) db.loreEntityRelations,
                    if (entityRevisionsRefs) db.entityRevisions,
                    if (graphCanvasesRefs) db.graphCanvases,
                    if (storyWorksRefs) db.storyWorks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (charactersRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          Character
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._charactersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).charactersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (templatesRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          Template
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._templatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).templatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (groupsRefs)
                        await $_getPrefetchedData<World, $WorldsTable, Group>(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._groupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(db, table, p0).groupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timelineEventsRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          TimelineEvent
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._timelineEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loreEntitiesRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          LoreEntity
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._loreEntitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).loreEntitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loreRelationsRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          LoreRelation
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._loreRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).loreRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loreEntityRelationsRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          LoreEntityRelation
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._loreEntityRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).loreEntityRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entityRevisionsRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          EntityRevision
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._entityRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).entityRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (graphCanvasesRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          GraphCanvas
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._graphCanvasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).graphCanvasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storyWorksRefs)
                        await $_getPrefetchedData<
                          World,
                          $WorldsTable,
                          StoryWork
                        >(
                          currentTable: table,
                          referencedTable: $$WorldsTableReferences
                              ._storyWorksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorldsTableReferences(
                                db,
                                table,
                                p0,
                              ).storyWorksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.worldId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorldsTable,
      World,
      $$WorldsTableFilterComposer,
      $$WorldsTableOrderingComposer,
      $$WorldsTableAnnotationComposer,
      $$WorldsTableCreateCompanionBuilder,
      $$WorldsTableUpdateCompanionBuilder,
      (World, $$WorldsTableReferences),
      World,
      PrefetchHooks Function({
        bool charactersRefs,
        bool templatesRefs,
        bool groupsRefs,
        bool timelineEventsRefs,
        bool loreEntitiesRefs,
        bool loreRelationsRefs,
        bool loreEntityRelationsRefs,
        bool entityRevisionsRefs,
        bool graphCanvasesRefs,
        bool storyWorksRefs,
      })
    >;
typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      required int worldId,
      required String name,
      Value<String?> avatarPath,
      Value<String> gender,
      Value<String> description,
      Value<int> status,
      Value<bool> isFavorite,
      Value<bool> isPinned,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<String> name,
      Value<String?> avatarPath,
      Value<String> gender,
      Value<String> description,
      Value<int> status,
      Value<bool> isFavorite,
      Value<bool> isPinned,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CharactersTableReferences
    extends BaseReferences<_$AppDatabase, $CharactersTable, Character> {
  $$CharactersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.characters.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CharacterFieldsTable, List<CharacterField>>
  _characterFieldsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterFields,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.characterFields.characterId,
    ),
  );

  $$CharacterFieldsTableProcessedTableManager get characterFieldsRefs {
    final manager = $$CharacterFieldsTableTableManager(
      $_db,
      $_db.characterFields,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterFieldsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CharacterStatsTable, List<CharacterStat>>
  _characterStatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterStats,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.characterStats.characterId,
    ),
  );

  $$CharacterStatsTableProcessedTableManager get characterStatsRefs {
    final manager = $$CharacterStatsTableTableManager(
      $_db,
      $_db.characterStats,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_characterStatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CharacterGalleriesTable, List<CharacterGallery>>
  _characterGalleriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.characterGalleries,
        aliasName: $_aliasNameGenerator(
          db.characters.id,
          db.characterGalleries.characterId,
        ),
      );

  $$CharacterGalleriesTableProcessedTableManager get characterGalleriesRefs {
    final manager = $$CharacterGalleriesTableTableManager(
      $_db,
      $_db.characterGalleries,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterGalleriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CharacterTagsTable, List<CharacterTag>>
  _characterTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterTags,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.characterTags.characterId,
    ),
  );

  $$CharacterTagsTableProcessedTableManager get characterTagsRefs {
    final manager = $$CharacterTagsTableTableManager(
      $_db,
      $_db.characterTags,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_characterTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CharacterGroupsTable, List<CharacterGroup>>
  _characterGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterGroups,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.characterGroups.characterId,
    ),
  );

  $$CharacterGroupsTableProcessedTableManager get characterGroupsRefs {
    final manager = $$CharacterGroupsTableTableManager(
      $_db,
      $_db.characterGroups,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimelineEventsTable, List<TimelineEvent>>
  _timelineEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timelineEvents,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.timelineEvents.characterId,
    ),
  );

  $$TimelineEventsTableProcessedTableManager get timelineEventsRefs {
    final manager = $$TimelineEventsTableTableManager(
      $_db,
      $_db.timelineEvents,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_timelineEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoreRelationsTable, List<LoreRelation>>
  _loreRelationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loreRelations,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.loreRelations.characterId,
    ),
  );

  $$LoreRelationsTableProcessedTableManager get loreRelationsRefs {
    final manager = $$LoreRelationsTableTableManager(
      $_db,
      $_db.loreRelations,
    ).filter((f) => f.characterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loreRelationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoryScenesTable, List<StoryScene>>
  _storyScenesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyScenes,
    aliasName: $_aliasNameGenerator(
      db.characters.id,
      db.storyScenes.povCharacterId,
    ),
  );

  $$StoryScenesTableProcessedTableManager get storyScenesRefs {
    final manager = $$StoryScenesTableTableManager(
      $_db,
      $_db.storyScenes,
    ).filter((f) => f.povCharacterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyScenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> characterFieldsRefs(
    Expression<bool> Function($$CharacterFieldsTableFilterComposer f) f,
  ) {
    final $$CharacterFieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterFields,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterFieldsTableFilterComposer(
            $db: $db,
            $table: $db.characterFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterStatsRefs(
    Expression<bool> Function($$CharacterStatsTableFilterComposer f) f,
  ) {
    final $$CharacterStatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterStats,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterStatsTableFilterComposer(
            $db: $db,
            $table: $db.characterStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterGalleriesRefs(
    Expression<bool> Function($$CharacterGalleriesTableFilterComposer f) f,
  ) {
    final $$CharacterGalleriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterGalleries,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterGalleriesTableFilterComposer(
            $db: $db,
            $table: $db.characterGalleries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterTagsRefs(
    Expression<bool> Function($$CharacterTagsTableFilterComposer f) f,
  ) {
    final $$CharacterTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterTags,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterTagsTableFilterComposer(
            $db: $db,
            $table: $db.characterTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> characterGroupsRefs(
    Expression<bool> Function($$CharacterGroupsTableFilterComposer f) f,
  ) {
    final $$CharacterGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterGroups,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterGroupsTableFilterComposer(
            $db: $db,
            $table: $db.characterGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timelineEventsRefs(
    Expression<bool> Function($$TimelineEventsTableFilterComposer f) f,
  ) {
    final $$TimelineEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableFilterComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loreRelationsRefs(
    Expression<bool> Function($$LoreRelationsTableFilterComposer f) f,
  ) {
    final $$LoreRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableFilterComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storyScenesRefs(
    Expression<bool> Function($$StoryScenesTableFilterComposer f) f,
  ) {
    final $$StoryScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.povCharacterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableFilterComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> characterFieldsRefs<T extends Object>(
    Expression<T> Function($$CharacterFieldsTableAnnotationComposer a) f,
  ) {
    final $$CharacterFieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterFields,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterFieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> characterStatsRefs<T extends Object>(
    Expression<T> Function($$CharacterStatsTableAnnotationComposer a) f,
  ) {
    final $$CharacterStatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterStats,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterStatsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> characterGalleriesRefs<T extends Object>(
    Expression<T> Function($$CharacterGalleriesTableAnnotationComposer a) f,
  ) {
    final $$CharacterGalleriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.characterGalleries,
          getReferencedColumn: (t) => t.characterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CharacterGalleriesTableAnnotationComposer(
                $db: $db,
                $table: $db.characterGalleries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> characterTagsRefs<T extends Object>(
    Expression<T> Function($$CharacterTagsTableAnnotationComposer a) f,
  ) {
    final $$CharacterTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterTags,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> characterGroupsRefs<T extends Object>(
    Expression<T> Function($$CharacterGroupsTableAnnotationComposer a) f,
  ) {
    final $$CharacterGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterGroups,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timelineEventsRefs<T extends Object>(
    Expression<T> Function($$TimelineEventsTableAnnotationComposer a) f,
  ) {
    final $$TimelineEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timelineEvents,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelineEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.timelineEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loreRelationsRefs<T extends Object>(
    Expression<T> Function($$LoreRelationsTableAnnotationComposer a) f,
  ) {
    final $$LoreRelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.characterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storyScenesRefs<T extends Object>(
    Expression<T> Function($$StoryScenesTableAnnotationComposer a) f,
  ) {
    final $$StoryScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.povCharacterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (Character, $$CharactersTableReferences),
          Character,
          PrefetchHooks Function({
            bool worldId,
            bool characterFieldsRefs,
            bool characterStatsRefs,
            bool characterGalleriesRefs,
            bool characterTagsRefs,
            bool characterGroupsRefs,
            bool timelineEventsRefs,
            bool loreRelationsRefs,
            bool storyScenesRefs,
          })
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                worldId: worldId,
                name: name,
                avatarPath: avatarPath,
                gender: gender,
                description: description,
                status: status,
                isFavorite: isFavorite,
                isPinned: isPinned,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required String name,
                Value<String?> avatarPath = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                worldId: worldId,
                name: name,
                avatarPath: avatarPath,
                gender: gender,
                description: description,
                status: status,
                isFavorite: isFavorite,
                isPinned: isPinned,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharactersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                worldId = false,
                characterFieldsRefs = false,
                characterStatsRefs = false,
                characterGalleriesRefs = false,
                characterTagsRefs = false,
                characterGroupsRefs = false,
                timelineEventsRefs = false,
                loreRelationsRefs = false,
                storyScenesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (characterFieldsRefs) db.characterFields,
                    if (characterStatsRefs) db.characterStats,
                    if (characterGalleriesRefs) db.characterGalleries,
                    if (characterTagsRefs) db.characterTags,
                    if (characterGroupsRefs) db.characterGroups,
                    if (timelineEventsRefs) db.timelineEvents,
                    if (loreRelationsRefs) db.loreRelations,
                    if (storyScenesRefs) db.storyScenes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable: $$CharactersTableReferences
                                        ._worldIdTable(db),
                                    referencedColumn:
                                        $$CharactersTableReferences
                                            ._worldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (characterFieldsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterField
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterStatsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterStat
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterStatsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterStatsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterGalleriesRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterGallery
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterGalleriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterGalleriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterTagsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterTag
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (characterGroupsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          CharacterGroup
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._characterGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).characterGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timelineEventsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          TimelineEvent
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._timelineEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loreRelationsRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          LoreRelation
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._loreRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).loreRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.characterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storyScenesRefs)
                        await $_getPrefetchedData<
                          Character,
                          $CharactersTable,
                          StoryScene
                        >(
                          currentTable: table,
                          referencedTable: $$CharactersTableReferences
                              ._storyScenesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CharactersTableReferences(
                                db,
                                table,
                                p0,
                              ).storyScenesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.povCharacterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, $$CharactersTableReferences),
      Character,
      PrefetchHooks Function({
        bool worldId,
        bool characterFieldsRefs,
        bool characterStatsRefs,
        bool characterGalleriesRefs,
        bool characterTagsRefs,
        bool characterGroupsRefs,
        bool timelineEventsRefs,
        bool loreRelationsRefs,
        bool storyScenesRefs,
      })
    >;
typedef $$CharacterFieldsTableCreateCompanionBuilder =
    CharacterFieldsCompanion Function({
      Value<int> id,
      required int characterId,
      required String fieldName,
      required String fieldType,
      Value<String?> value,
    });
typedef $$CharacterFieldsTableUpdateCompanionBuilder =
    CharacterFieldsCompanion Function({
      Value<int> id,
      Value<int> characterId,
      Value<String> fieldName,
      Value<String> fieldType,
      Value<String?> value,
    });

final class $$CharacterFieldsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CharacterFieldsTable, CharacterField> {
  $$CharacterFieldsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.characterFields.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterFieldsTable> {
  $$CharacterFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterFieldsTable> {
  $$CharacterFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterFieldsTable> {
  $$CharacterFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterFieldsTable,
          CharacterField,
          $$CharacterFieldsTableFilterComposer,
          $$CharacterFieldsTableOrderingComposer,
          $$CharacterFieldsTableAnnotationComposer,
          $$CharacterFieldsTableCreateCompanionBuilder,
          $$CharacterFieldsTableUpdateCompanionBuilder,
          (CharacterField, $$CharacterFieldsTableReferences),
          CharacterField,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharacterFieldsTableTableManager(
    _$AppDatabase db,
    $CharacterFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<String?> value = const Value.absent(),
              }) => CharacterFieldsCompanion(
                id: id,
                characterId: characterId,
                fieldName: fieldName,
                fieldType: fieldType,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int characterId,
                required String fieldName,
                required String fieldType,
                Value<String?> value = const Value.absent(),
              }) => CharacterFieldsCompanion.insert(
                id: id,
                characterId: characterId,
                fieldName: fieldName,
                fieldType: fieldType,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable:
                                    $$CharacterFieldsTableReferences
                                        ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterFieldsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterFieldsTable,
      CharacterField,
      $$CharacterFieldsTableFilterComposer,
      $$CharacterFieldsTableOrderingComposer,
      $$CharacterFieldsTableAnnotationComposer,
      $$CharacterFieldsTableCreateCompanionBuilder,
      $$CharacterFieldsTableUpdateCompanionBuilder,
      (CharacterField, $$CharacterFieldsTableReferences),
      CharacterField,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$CharacterStatsTableCreateCompanionBuilder =
    CharacterStatsCompanion Function({
      Value<int> id,
      required int characterId,
      required String label,
      Value<double> value,
      Value<double> maxValue,
      Value<int> sortOrder,
    });
typedef $$CharacterStatsTableUpdateCompanionBuilder =
    CharacterStatsCompanion Function({
      Value<int> id,
      Value<int> characterId,
      Value<String> label,
      Value<double> value,
      Value<double> maxValue,
      Value<int> sortOrder,
    });

final class $$CharacterStatsTableReferences
    extends BaseReferences<_$AppDatabase, $CharacterStatsTable, CharacterStat> {
  $$CharacterStatsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.characterStats.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterStatsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxValue => $composableBuilder(
    column: $table.maxValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxValue => $composableBuilder(
    column: $table.maxValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterStatsTable> {
  $$CharacterStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get maxValue =>
      $composableBuilder(column: $table.maxValue, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterStatsTable,
          CharacterStat,
          $$CharacterStatsTableFilterComposer,
          $$CharacterStatsTableOrderingComposer,
          $$CharacterStatsTableAnnotationComposer,
          $$CharacterStatsTableCreateCompanionBuilder,
          $$CharacterStatsTableUpdateCompanionBuilder,
          (CharacterStat, $$CharacterStatsTableReferences),
          CharacterStat,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharacterStatsTableTableManager(
    _$AppDatabase db,
    $CharacterStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<double> maxValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CharacterStatsCompanion(
                id: id,
                characterId: characterId,
                label: label,
                value: value,
                maxValue: maxValue,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int characterId,
                required String label,
                Value<double> value = const Value.absent(),
                Value<double> maxValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CharacterStatsCompanion.insert(
                id: id,
                characterId: characterId,
                label: label,
                value: value,
                maxValue: maxValue,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterStatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$CharacterStatsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterStatsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterStatsTable,
      CharacterStat,
      $$CharacterStatsTableFilterComposer,
      $$CharacterStatsTableOrderingComposer,
      $$CharacterStatsTableAnnotationComposer,
      $$CharacterStatsTableCreateCompanionBuilder,
      $$CharacterStatsTableUpdateCompanionBuilder,
      (CharacterStat, $$CharacterStatsTableReferences),
      CharacterStat,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$CharacterGalleriesTableCreateCompanionBuilder =
    CharacterGalleriesCompanion Function({
      Value<int> id,
      required int characterId,
      required String imagePath,
      Value<String> caption,
      Value<bool> isPrimary,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$CharacterGalleriesTableUpdateCompanionBuilder =
    CharacterGalleriesCompanion Function({
      Value<int> id,
      Value<int> characterId,
      Value<String> imagePath,
      Value<String> caption,
      Value<bool> isPrimary,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$CharacterGalleriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CharacterGalleriesTable,
          CharacterGallery
        > {
  $$CharacterGalleriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(
          db.characterGalleries.characterId,
          db.characters.id,
        ),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterGalleriesTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterGalleriesTable> {
  $$CharacterGalleriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGalleriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterGalleriesTable> {
  $$CharacterGalleriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGalleriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterGalleriesTable> {
  $$CharacterGalleriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGalleriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterGalleriesTable,
          CharacterGallery,
          $$CharacterGalleriesTableFilterComposer,
          $$CharacterGalleriesTableOrderingComposer,
          $$CharacterGalleriesTableAnnotationComposer,
          $$CharacterGalleriesTableCreateCompanionBuilder,
          $$CharacterGalleriesTableUpdateCompanionBuilder,
          (CharacterGallery, $$CharacterGalleriesTableReferences),
          CharacterGallery,
          PrefetchHooks Function({bool characterId})
        > {
  $$CharacterGalleriesTableTableManager(
    _$AppDatabase db,
    $CharacterGalleriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterGalleriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterGalleriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterGalleriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CharacterGalleriesCompanion(
                id: id,
                characterId: characterId,
                imagePath: imagePath,
                caption: caption,
                isPrimary: isPrimary,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int characterId,
                required String imagePath,
                Value<String> caption = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CharacterGalleriesCompanion.insert(
                id: id,
                characterId: characterId,
                imagePath: imagePath,
                caption: caption,
                isPrimary: isPrimary,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterGalleriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable:
                                    $$CharacterGalleriesTableReferences
                                        ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterGalleriesTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterGalleriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterGalleriesTable,
      CharacterGallery,
      $$CharacterGalleriesTableFilterComposer,
      $$CharacterGalleriesTableOrderingComposer,
      $$CharacterGalleriesTableAnnotationComposer,
      $$CharacterGalleriesTableCreateCompanionBuilder,
      $$CharacterGalleriesTableUpdateCompanionBuilder,
      (CharacterGallery, $$CharacterGalleriesTableReferences),
      CharacterGallery,
      PrefetchHooks Function({bool characterId})
    >;
typedef $$RelationsTableCreateCompanionBuilder =
    RelationsCompanion Function({
      Value<int> id,
      required int fromCharacterId,
      required int toCharacterId,
      required String relationType,
      Value<bool> isBidirectional,
      Value<String?> note,
      Value<String?> relationGroupId,
    });
typedef $$RelationsTableUpdateCompanionBuilder =
    RelationsCompanion Function({
      Value<int> id,
      Value<int> fromCharacterId,
      Value<int> toCharacterId,
      Value<String> relationType,
      Value<bool> isBidirectional,
      Value<String?> note,
      Value<String?> relationGroupId,
    });

final class $$RelationsTableReferences
    extends BaseReferences<_$AppDatabase, $RelationsTable, Relation> {
  $$RelationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CharactersTable _fromCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.relations.fromCharacterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get fromCharacterId {
    final $_column = $_itemColumn<int>('from_character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _toCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.relations.toCharacterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get toCharacterId {
    final $_column = $_itemColumn<int>('to_character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RelationsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationGroupId => $composableBuilder(
    column: $table.relationGroupId,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get fromCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get toCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationGroupId => $composableBuilder(
    column: $table.relationGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get fromCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get toCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationsTable> {
  $$RelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get relationGroupId => $composableBuilder(
    column: $table.relationGroupId,
    builder: (column) => column,
  );

  $$CharactersTableAnnotationComposer get fromCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get toCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelationsTable,
          Relation,
          $$RelationsTableFilterComposer,
          $$RelationsTableOrderingComposer,
          $$RelationsTableAnnotationComposer,
          $$RelationsTableCreateCompanionBuilder,
          $$RelationsTableUpdateCompanionBuilder,
          (Relation, $$RelationsTableReferences),
          Relation,
          PrefetchHooks Function({bool fromCharacterId, bool toCharacterId})
        > {
  $$RelationsTableTableManager(_$AppDatabase db, $RelationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fromCharacterId = const Value.absent(),
                Value<int> toCharacterId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<bool> isBidirectional = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> relationGroupId = const Value.absent(),
              }) => RelationsCompanion(
                id: id,
                fromCharacterId: fromCharacterId,
                toCharacterId: toCharacterId,
                relationType: relationType,
                isBidirectional: isBidirectional,
                note: note,
                relationGroupId: relationGroupId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fromCharacterId,
                required int toCharacterId,
                required String relationType,
                Value<bool> isBidirectional = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> relationGroupId = const Value.absent(),
              }) => RelationsCompanion.insert(
                id: id,
                fromCharacterId: fromCharacterId,
                toCharacterId: toCharacterId,
                relationType: relationType,
                isBidirectional: isBidirectional,
                note: note,
                relationGroupId: relationGroupId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({fromCharacterId = false, toCharacterId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fromCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromCharacterId,
                                    referencedTable: $$RelationsTableReferences
                                        ._fromCharacterIdTable(db),
                                    referencedColumn: $$RelationsTableReferences
                                        ._fromCharacterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (toCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toCharacterId,
                                    referencedTable: $$RelationsTableReferences
                                        ._toCharacterIdTable(db),
                                    referencedColumn: $$RelationsTableReferences
                                        ._toCharacterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelationsTable,
      Relation,
      $$RelationsTableFilterComposer,
      $$RelationsTableOrderingComposer,
      $$RelationsTableAnnotationComposer,
      $$RelationsTableCreateCompanionBuilder,
      $$RelationsTableUpdateCompanionBuilder,
      (Relation, $$RelationsTableReferences),
      Relation,
      PrefetchHooks Function({bool fromCharacterId, bool toCharacterId})
    >;
typedef $$TemplatesTableCreateCompanionBuilder =
    TemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> worldId,
    });
typedef $$TemplatesTableUpdateCompanionBuilder =
    TemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> worldId,
    });

final class $$TemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplatesTable, Template> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.templates.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager? get worldId {
    final $_column = $_itemColumn<int>('world_id');
    if ($_column == null) return null;
    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TemplateFieldsTable, List<TemplateField>>
  _templateFieldsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateFields,
    aliasName: $_aliasNameGenerator(
      db.templates.id,
      db.templateFields.templateId,
    ),
  );

  $$TemplateFieldsTableProcessedTableManager get templateFieldsRefs {
    final manager = $$TemplateFieldsTableTableManager(
      $_db,
      $_db.templateFields,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateFieldsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateFieldsRefs(
    Expression<bool> Function($$TemplateFieldsTableFilterComposer f) f,
  ) {
    final $$TemplateFieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateFields,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateFieldsTableFilterComposer(
            $db: $db,
            $table: $db.templateFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateFieldsRefs<T extends Object>(
    Expression<T> Function($$TemplateFieldsTableAnnotationComposer a) f,
  ) {
    final $$TemplateFieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateFields,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateFieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          Template,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (Template, $$TemplatesTableReferences),
          Template,
          PrefetchHooks Function({bool worldId, bool templateFieldsRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> worldId = const Value.absent(),
              }) => TemplatesCompanion(id: id, name: name, worldId: worldId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> worldId = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                name: name,
                worldId: worldId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({worldId = false, templateFieldsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateFieldsRefs) db.templateFields,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable: $$TemplatesTableReferences
                                        ._worldIdTable(db),
                                    referencedColumn: $$TemplatesTableReferences
                                        ._worldIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateFieldsRefs)
                        await $_getPrefetchedData<
                          Template,
                          $TemplatesTable,
                          TemplateField
                        >(
                          currentTable: table,
                          referencedTable: $$TemplatesTableReferences
                              ._templateFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      Template,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (Template, $$TemplatesTableReferences),
      Template,
      PrefetchHooks Function({bool worldId, bool templateFieldsRefs})
    >;
typedef $$TemplateFieldsTableCreateCompanionBuilder =
    TemplateFieldsCompanion Function({
      Value<int> id,
      required int templateId,
      required String fieldName,
      required String fieldType,
      Value<String?> defaultValue,
      Value<int> sortOrder,
    });
typedef $$TemplateFieldsTableUpdateCompanionBuilder =
    TemplateFieldsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<String> fieldName,
      Value<String> fieldType,
      Value<String?> defaultValue,
      Value<int> sortOrder,
    });

final class $$TemplateFieldsTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateFieldsTable, TemplateField> {
  $$TemplateFieldsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias(
        $_aliasNameGenerator(db.templateFields.templateId, db.templates.id),
      );

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateFieldsTable> {
  $$TemplateFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateFieldsTable> {
  $$TemplateFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateFieldsTable> {
  $$TemplateFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateFieldsTable,
          TemplateField,
          $$TemplateFieldsTableFilterComposer,
          $$TemplateFieldsTableOrderingComposer,
          $$TemplateFieldsTableAnnotationComposer,
          $$TemplateFieldsTableCreateCompanionBuilder,
          $$TemplateFieldsTableUpdateCompanionBuilder,
          (TemplateField, $$TemplateFieldsTableReferences),
          TemplateField,
          PrefetchHooks Function({bool templateId})
        > {
  $$TemplateFieldsTableTableManager(
    _$AppDatabase db,
    $TemplateFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<String?> defaultValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TemplateFieldsCompanion(
                id: id,
                templateId: templateId,
                fieldName: fieldName,
                fieldType: fieldType,
                defaultValue: defaultValue,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required String fieldName,
                required String fieldType,
                Value<String?> defaultValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TemplateFieldsCompanion.insert(
                id: id,
                templateId: templateId,
                fieldName: fieldName,
                fieldType: fieldType,
                defaultValue: defaultValue,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplateFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable: $$TemplateFieldsTableReferences
                                    ._templateIdTable(db),
                                referencedColumn:
                                    $$TemplateFieldsTableReferences
                                        ._templateIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TemplateFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateFieldsTable,
      TemplateField,
      $$TemplateFieldsTableFilterComposer,
      $$TemplateFieldsTableOrderingComposer,
      $$TemplateFieldsTableAnnotationComposer,
      $$TemplateFieldsTableCreateCompanionBuilder,
      $$TemplateFieldsTableUpdateCompanionBuilder,
      (TemplateField, $$TemplateFieldsTableReferences),
      TemplateField,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      required String name,
      required String color,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> color,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharacterTagsTable, List<CharacterTag>>
  _characterTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.characterTags.tagId),
  );

  $$CharacterTagsTableProcessedTableManager get characterTagsRefs {
    final manager = $$CharacterTagsTableTableManager(
      $_db,
      $_db.characterTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_characterTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> characterTagsRefs(
    Expression<bool> Function($$CharacterTagsTableFilterComposer f) f,
  ) {
    final $$CharacterTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterTagsTableFilterComposer(
            $db: $db,
            $table: $db.characterTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> characterTagsRefs<T extends Object>(
    Expression<T> Function($$CharacterTagsTableAnnotationComposer a) f,
  ) {
    final $$CharacterTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool characterTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
              }) => TagsCompanion(id: id, name: name, color: color),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String color,
              }) => TagsCompanion.insert(id: id, name: name, color: color),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({characterTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (characterTagsRefs) db.characterTags,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (characterTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, CharacterTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._characterTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TagsTableReferences(
                        db,
                        table,
                        p0,
                      ).characterTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool characterTagsRefs})
    >;
typedef $$CharacterTagsTableCreateCompanionBuilder =
    CharacterTagsCompanion Function({
      required int characterId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$CharacterTagsTableUpdateCompanionBuilder =
    CharacterTagsCompanion Function({
      Value<int> characterId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$CharacterTagsTableReferences
    extends BaseReferences<_$AppDatabase, $CharacterTagsTable, CharacterTag> {
  $$CharacterTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.characterTags.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias(
    $_aliasNameGenerator(db.characterTags.tagId, db.tags.id),
  );

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterTagsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterTagsTable> {
  $$CharacterTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterTagsTable> {
  $$CharacterTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterTagsTable> {
  $$CharacterTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterTagsTable,
          CharacterTag,
          $$CharacterTagsTableFilterComposer,
          $$CharacterTagsTableOrderingComposer,
          $$CharacterTagsTableAnnotationComposer,
          $$CharacterTagsTableCreateCompanionBuilder,
          $$CharacterTagsTableUpdateCompanionBuilder,
          (CharacterTag, $$CharacterTagsTableReferences),
          CharacterTag,
          PrefetchHooks Function({bool characterId, bool tagId})
        > {
  $$CharacterTagsTableTableManager(_$AppDatabase db, $CharacterTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> characterId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterTagsCompanion(
                characterId: characterId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int characterId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => CharacterTagsCompanion.insert(
                characterId: characterId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$CharacterTagsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn: $$CharacterTagsTableReferences
                                    ._characterIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$CharacterTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$CharacterTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterTagsTable,
      CharacterTag,
      $$CharacterTagsTableFilterComposer,
      $$CharacterTagsTableOrderingComposer,
      $$CharacterTagsTableAnnotationComposer,
      $$CharacterTagsTableCreateCompanionBuilder,
      $$CharacterTagsTableUpdateCompanionBuilder,
      (CharacterTag, $$CharacterTagsTableReferences),
      CharacterTag,
      PrefetchHooks Function({bool characterId, bool tagId})
    >;
typedef $$TrashTableCreateCompanionBuilder =
    TrashCompanion Function({
      Value<int> id,
      required String itemType,
      required int itemId,
      required String itemData,
      Value<DateTime> deletedAt,
    });
typedef $$TrashTableUpdateCompanionBuilder =
    TrashCompanion Function({
      Value<int> id,
      Value<String> itemType,
      Value<int> itemId,
      Value<String> itemData,
      Value<DateTime> deletedAt,
    });

class $$TrashTableFilterComposer extends Composer<_$AppDatabase, $TrashTable> {
  $$TrashTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemData => $composableBuilder(
    column: $table.itemData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrashTableOrderingComposer
    extends Composer<_$AppDatabase, $TrashTable> {
  $$TrashTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemData => $composableBuilder(
    column: $table.itemData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrashTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrashTable> {
  $$TrashTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemData =>
      $composableBuilder(column: $table.itemData, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TrashTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrashTable,
          TrashData,
          $$TrashTableFilterComposer,
          $$TrashTableOrderingComposer,
          $$TrashTableAnnotationComposer,
          $$TrashTableCreateCompanionBuilder,
          $$TrashTableUpdateCompanionBuilder,
          (TrashData, BaseReferences<_$AppDatabase, $TrashTable, TrashData>),
          TrashData,
          PrefetchHooks Function()
        > {
  $$TrashTableTableManager(_$AppDatabase db, $TrashTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrashTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrashTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrashTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> itemData = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
              }) => TrashCompanion(
                id: id,
                itemType: itemType,
                itemId: itemId,
                itemData: itemData,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemType,
                required int itemId,
                required String itemData,
                Value<DateTime> deletedAt = const Value.absent(),
              }) => TrashCompanion.insert(
                id: id,
                itemType: itemType,
                itemId: itemId,
                itemData: itemData,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrashTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrashTable,
      TrashData,
      $$TrashTableFilterComposer,
      $$TrashTableOrderingComposer,
      $$TrashTableAnnotationComposer,
      $$TrashTableCreateCompanionBuilder,
      $$TrashTableUpdateCompanionBuilder,
      (TrashData, BaseReferences<_$AppDatabase, $TrashTable, TrashData>),
      TrashData,
      PrefetchHooks Function()
    >;
typedef $$BackupsTableCreateCompanionBuilder =
    BackupsCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
      required String filePath,
    });
typedef $$BackupsTableUpdateCompanionBuilder =
    BackupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<String> filePath,
    });

class $$BackupsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BackupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupsTable> {
  $$BackupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);
}

class $$BackupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupsTable,
          Backup,
          $$BackupsTableFilterComposer,
          $$BackupsTableOrderingComposer,
          $$BackupsTableAnnotationComposer,
          $$BackupsTableCreateCompanionBuilder,
          $$BackupsTableUpdateCompanionBuilder,
          (Backup, BaseReferences<_$AppDatabase, $BackupsTable, Backup>),
          Backup,
          PrefetchHooks Function()
        > {
  $$BackupsTableTableManager(_$AppDatabase db, $BackupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> filePath = const Value.absent(),
              }) => BackupsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                filePath: filePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                required String filePath,
              }) => BackupsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                filePath: filePath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupsTable,
      Backup,
      $$BackupsTableFilterComposer,
      $$BackupsTableOrderingComposer,
      $$BackupsTableAnnotationComposer,
      $$BackupsTableCreateCompanionBuilder,
      $$BackupsTableUpdateCompanionBuilder,
      (Backup, BaseReferences<_$AppDatabase, $BackupsTable, Backup>),
      Backup,
      PrefetchHooks Function()
    >;
typedef $$GraphLayoutsTableCreateCompanionBuilder =
    GraphLayoutsCompanion Function({
      Value<int> id,
      required int worldId,
      required int characterId,
      Value<double> x,
      Value<double> y,
      Value<int?> canvasId,
    });
typedef $$GraphLayoutsTableUpdateCompanionBuilder =
    GraphLayoutsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<int> characterId,
      Value<double> x,
      Value<double> y,
      Value<int?> canvasId,
    });

class $$GraphLayoutsTableFilterComposer
    extends Composer<_$AppDatabase, $GraphLayoutsTable> {
  $$GraphLayoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get canvasId => $composableBuilder(
    column: $table.canvasId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraphLayoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $GraphLayoutsTable> {
  $$GraphLayoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get canvasId => $composableBuilder(
    column: $table.canvasId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraphLayoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GraphLayoutsTable> {
  $$GraphLayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<int> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<int> get canvasId =>
      $composableBuilder(column: $table.canvasId, builder: (column) => column);
}

class $$GraphLayoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GraphLayoutsTable,
          GraphLayout,
          $$GraphLayoutsTableFilterComposer,
          $$GraphLayoutsTableOrderingComposer,
          $$GraphLayoutsTableAnnotationComposer,
          $$GraphLayoutsTableCreateCompanionBuilder,
          $$GraphLayoutsTableUpdateCompanionBuilder,
          (
            GraphLayout,
            BaseReferences<_$AppDatabase, $GraphLayoutsTable, GraphLayout>,
          ),
          GraphLayout,
          PrefetchHooks Function()
        > {
  $$GraphLayoutsTableTableManager(_$AppDatabase db, $GraphLayoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphLayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphLayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphLayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<int?> canvasId = const Value.absent(),
              }) => GraphLayoutsCompanion(
                id: id,
                worldId: worldId,
                characterId: characterId,
                x: x,
                y: y,
                canvasId: canvasId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required int characterId,
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<int?> canvasId = const Value.absent(),
              }) => GraphLayoutsCompanion.insert(
                id: id,
                worldId: worldId,
                characterId: characterId,
                x: x,
                y: y,
                canvasId: canvasId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraphLayoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GraphLayoutsTable,
      GraphLayout,
      $$GraphLayoutsTableFilterComposer,
      $$GraphLayoutsTableOrderingComposer,
      $$GraphLayoutsTableAnnotationComposer,
      $$GraphLayoutsTableCreateCompanionBuilder,
      $$GraphLayoutsTableUpdateCompanionBuilder,
      (
        GraphLayout,
        BaseReferences<_$AppDatabase, $GraphLayoutsTable, GraphLayout>,
      ),
      GraphLayout,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$BasicInfoFieldsTableCreateCompanionBuilder =
    BasicInfoFieldsCompanion Function({
      Value<int> id,
      required String fieldName,
      Value<int> sortOrder,
      Value<bool> isVisible,
    });
typedef $$BasicInfoFieldsTableUpdateCompanionBuilder =
    BasicInfoFieldsCompanion Function({
      Value<int> id,
      Value<String> fieldName,
      Value<int> sortOrder,
      Value<bool> isVisible,
    });

class $$BasicInfoFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $BasicInfoFieldsTable> {
  $$BasicInfoFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BasicInfoFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $BasicInfoFieldsTable> {
  $$BasicInfoFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BasicInfoFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BasicInfoFieldsTable> {
  $$BasicInfoFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);
}

class $$BasicInfoFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BasicInfoFieldsTable,
          BasicInfoField,
          $$BasicInfoFieldsTableFilterComposer,
          $$BasicInfoFieldsTableOrderingComposer,
          $$BasicInfoFieldsTableAnnotationComposer,
          $$BasicInfoFieldsTableCreateCompanionBuilder,
          $$BasicInfoFieldsTableUpdateCompanionBuilder,
          (
            BasicInfoField,
            BaseReferences<
              _$AppDatabase,
              $BasicInfoFieldsTable,
              BasicInfoField
            >,
          ),
          BasicInfoField,
          PrefetchHooks Function()
        > {
  $$BasicInfoFieldsTableTableManager(
    _$AppDatabase db,
    $BasicInfoFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BasicInfoFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BasicInfoFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BasicInfoFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
              }) => BasicInfoFieldsCompanion(
                id: id,
                fieldName: fieldName,
                sortOrder: sortOrder,
                isVisible: isVisible,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fieldName,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
              }) => BasicInfoFieldsCompanion.insert(
                id: id,
                fieldName: fieldName,
                sortOrder: sortOrder,
                isVisible: isVisible,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BasicInfoFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BasicInfoFieldsTable,
      BasicInfoField,
      $$BasicInfoFieldsTableFilterComposer,
      $$BasicInfoFieldsTableOrderingComposer,
      $$BasicInfoFieldsTableAnnotationComposer,
      $$BasicInfoFieldsTableCreateCompanionBuilder,
      $$BasicInfoFieldsTableUpdateCompanionBuilder,
      (
        BasicInfoField,
        BaseReferences<_$AppDatabase, $BasicInfoFieldsTable, BasicInfoField>,
      ),
      BasicInfoField,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      required int worldId,
      required String name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.groups.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CharacterGroupsTable, List<CharacterGroup>>
  _characterGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.characterGroups,
    aliasName: $_aliasNameGenerator(db.groups.id, db.characterGroups.groupId),
  );

  $$CharacterGroupsTableProcessedTableManager get characterGroupsRefs {
    final manager = $$CharacterGroupsTableTableManager(
      $_db,
      $_db.characterGroups,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _characterGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> characterGroupsRefs(
    Expression<bool> Function($$CharacterGroupsTableFilterComposer f) f,
  ) {
    final $$CharacterGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterGroupsTableFilterComposer(
            $db: $db,
            $table: $db.characterGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> characterGroupsRefs<T extends Object>(
    Expression<T> Function($$CharacterGroupsTableAnnotationComposer a) f,
  ) {
    final $$CharacterGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharacterGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, $$GroupsTableReferences),
          Group,
          PrefetchHooks Function({bool worldId, bool characterGroupsRefs})
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                worldId: worldId,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                worldId: worldId,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GroupsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({worldId = false, characterGroupsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (characterGroupsRefs) db.characterGroups,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable: $$GroupsTableReferences
                                        ._worldIdTable(db),
                                    referencedColumn: $$GroupsTableReferences
                                        ._worldIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (characterGroupsRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          CharacterGroup
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._characterGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).characterGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, $$GroupsTableReferences),
      Group,
      PrefetchHooks Function({bool worldId, bool characterGroupsRefs})
    >;
typedef $$CharacterGroupsTableCreateCompanionBuilder =
    CharacterGroupsCompanion Function({
      Value<int> id,
      required int characterId,
      required int groupId,
    });
typedef $$CharacterGroupsTableUpdateCompanionBuilder =
    CharacterGroupsCompanion Function({
      Value<int> id,
      Value<int> characterId,
      Value<int> groupId,
    });

final class $$CharacterGroupsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CharacterGroupsTable, CharacterGroup> {
  $$CharacterGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.characterGroups.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GroupsTable _groupIdTable(_$AppDatabase db) => db.groups.createAlias(
    $_aliasNameGenerator(db.characterGroups.groupId, db.groups.id),
  );

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CharacterGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterGroupsTable> {
  $$CharacterGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterGroupsTable,
          CharacterGroup,
          $$CharacterGroupsTableFilterComposer,
          $$CharacterGroupsTableOrderingComposer,
          $$CharacterGroupsTableAnnotationComposer,
          $$CharacterGroupsTableCreateCompanionBuilder,
          $$CharacterGroupsTableUpdateCompanionBuilder,
          (CharacterGroup, $$CharacterGroupsTableReferences),
          CharacterGroup,
          PrefetchHooks Function({bool characterId, bool groupId})
        > {
  $$CharacterGroupsTableTableManager(
    _$AppDatabase db,
    $CharacterGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<int> groupId = const Value.absent(),
              }) => CharacterGroupsCompanion(
                id: id,
                characterId: characterId,
                groupId: groupId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int characterId,
                required int groupId,
              }) => CharacterGroupsCompanion.insert(
                id: id,
                characterId: characterId,
                groupId: groupId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CharacterGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterId = false, groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable:
                                    $$CharacterGroupsTableReferences
                                        ._characterIdTable(db),
                                referencedColumn:
                                    $$CharacterGroupsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$CharacterGroupsTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$CharacterGroupsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CharacterGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterGroupsTable,
      CharacterGroup,
      $$CharacterGroupsTableFilterComposer,
      $$CharacterGroupsTableOrderingComposer,
      $$CharacterGroupsTableAnnotationComposer,
      $$CharacterGroupsTableCreateCompanionBuilder,
      $$CharacterGroupsTableUpdateCompanionBuilder,
      (CharacterGroup, $$CharacterGroupsTableReferences),
      CharacterGroup,
      PrefetchHooks Function({bool characterId, bool groupId})
    >;
typedef $$TimelineEventsTableCreateCompanionBuilder =
    TimelineEventsCompanion Function({
      Value<int> id,
      required int worldId,
      Value<int?> characterId,
      required String year,
      Value<double> sortOrder,
      required String title,
      Value<String> description,
      Value<String> category,
      Value<int> importance,
      Value<DateTime> createdAt,
    });
typedef $$TimelineEventsTableUpdateCompanionBuilder =
    TimelineEventsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<int?> characterId,
      Value<String> year,
      Value<double> sortOrder,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<int> importance,
      Value<DateTime> createdAt,
    });

final class $$TimelineEventsTableReferences
    extends BaseReferences<_$AppDatabase, $TimelineEventsTable, TimelineEvent> {
  $$TimelineEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.timelineEvents.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.timelineEvents.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager? get characterId {
    final $_column = $_itemColumn<int>('character_id');
    if ($_column == null) return null;
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimelineEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineEventsTable,
          TimelineEvent,
          $$TimelineEventsTableFilterComposer,
          $$TimelineEventsTableOrderingComposer,
          $$TimelineEventsTableAnnotationComposer,
          $$TimelineEventsTableCreateCompanionBuilder,
          $$TimelineEventsTableUpdateCompanionBuilder,
          (TimelineEvent, $$TimelineEventsTableReferences),
          TimelineEvent,
          PrefetchHooks Function({bool worldId, bool characterId})
        > {
  $$TimelineEventsTableTableManager(
    _$AppDatabase db,
    $TimelineEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<int?> characterId = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<double> sortOrder = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> importance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TimelineEventsCompanion(
                id: id,
                worldId: worldId,
                characterId: characterId,
                year: year,
                sortOrder: sortOrder,
                title: title,
                description: description,
                category: category,
                importance: importance,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                Value<int?> characterId = const Value.absent(),
                required String year,
                Value<double> sortOrder = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> importance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TimelineEventsCompanion.insert(
                id: id,
                worldId: worldId,
                characterId: characterId,
                year: year,
                sortOrder: sortOrder,
                title: title,
                description: description,
                category: category,
                importance: importance,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelineEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({worldId = false, characterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (worldId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.worldId,
                                referencedTable: $$TimelineEventsTableReferences
                                    ._worldIdTable(db),
                                referencedColumn:
                                    $$TimelineEventsTableReferences
                                        ._worldIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (characterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.characterId,
                                referencedTable: $$TimelineEventsTableReferences
                                    ._characterIdTable(db),
                                referencedColumn:
                                    $$TimelineEventsTableReferences
                                        ._characterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimelineEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineEventsTable,
      TimelineEvent,
      $$TimelineEventsTableFilterComposer,
      $$TimelineEventsTableOrderingComposer,
      $$TimelineEventsTableAnnotationComposer,
      $$TimelineEventsTableCreateCompanionBuilder,
      $$TimelineEventsTableUpdateCompanionBuilder,
      (TimelineEvent, $$TimelineEventsTableReferences),
      TimelineEvent,
      PrefetchHooks Function({bool worldId, bool characterId})
    >;
typedef $$LoreEntitiesTableCreateCompanionBuilder =
    LoreEntitiesCompanion Function({
      Value<int> id,
      required int worldId,
      Value<int?> parentId,
      required String entityType,
      required String name,
      Value<String> summary,
      Value<String> content,
      Value<String?> coverImagePath,
      Value<String> tags,
      Value<String> customFields,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$LoreEntitiesTableUpdateCompanionBuilder =
    LoreEntitiesCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<int?> parentId,
      Value<String> entityType,
      Value<String> name,
      Value<String> summary,
      Value<String> content,
      Value<String?> coverImagePath,
      Value<String> tags,
      Value<String> customFields,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$LoreEntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $LoreEntitiesTable, LoreEntity> {
  $$LoreEntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.loreEntities.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LoreEntitiesTable _parentIdTable(_$AppDatabase db) =>
      db.loreEntities.createAlias(
        $_aliasNameGenerator(db.loreEntities.parentId, db.loreEntities.id),
      );

  $$LoreEntitiesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoreRelationsTable, List<LoreRelation>>
  _loreRelationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loreRelations,
    aliasName: $_aliasNameGenerator(
      db.loreEntities.id,
      db.loreRelations.loreId,
    ),
  );

  $$LoreRelationsTableProcessedTableManager get loreRelationsRefs {
    final manager = $$LoreRelationsTableTableManager(
      $_db,
      $_db.loreRelations,
    ).filter((f) => f.loreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loreRelationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoryScenesTable, List<StoryScene>>
  _storyScenesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyScenes,
    aliasName: $_aliasNameGenerator(
      db.loreEntities.id,
      db.storyScenes.locationId,
    ),
  );

  $$StoryScenesTableProcessedTableManager get storyScenesRefs {
    final manager = $$StoryScenesTableTableManager(
      $_db,
      $_db.storyScenes,
    ).filter((f) => f.locationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyScenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LoreEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $LoreEntitiesTable> {
  $$LoreEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableFilterComposer get parentId {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> loreRelationsRefs(
    Expression<bool> Function($$LoreRelationsTableFilterComposer f) f,
  ) {
    final $$LoreRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.loreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableFilterComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storyScenesRefs(
    Expression<bool> Function($$StoryScenesTableFilterComposer f) f,
  ) {
    final $$StoryScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableFilterComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoreEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $LoreEntitiesTable> {
  $$LoreEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableOrderingComposer get parentId {
    final $$LoreEntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoreEntitiesTable> {
  $$LoreEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableAnnotationComposer get parentId {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> loreRelationsRefs<T extends Object>(
    Expression<T> Function($$LoreRelationsTableAnnotationComposer a) f,
  ) {
    final $$LoreRelationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loreRelations,
      getReferencedColumn: (t) => t.loreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreRelationsTableAnnotationComposer(
            $db: $db,
            $table: $db.loreRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storyScenesRefs<T extends Object>(
    Expression<T> Function($$StoryScenesTableAnnotationComposer a) f,
  ) {
    final $$StoryScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoreEntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoreEntitiesTable,
          LoreEntity,
          $$LoreEntitiesTableFilterComposer,
          $$LoreEntitiesTableOrderingComposer,
          $$LoreEntitiesTableAnnotationComposer,
          $$LoreEntitiesTableCreateCompanionBuilder,
          $$LoreEntitiesTableUpdateCompanionBuilder,
          (LoreEntity, $$LoreEntitiesTableReferences),
          LoreEntity,
          PrefetchHooks Function({
            bool worldId,
            bool parentId,
            bool loreRelationsRefs,
            bool storyScenesRefs,
          })
        > {
  $$LoreEntitiesTableTableManager(_$AppDatabase db, $LoreEntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoreEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoreEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoreEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> customFields = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LoreEntitiesCompanion(
                id: id,
                worldId: worldId,
                parentId: parentId,
                entityType: entityType,
                name: name,
                summary: summary,
                content: content,
                coverImagePath: coverImagePath,
                tags: tags,
                customFields: customFields,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                Value<int?> parentId = const Value.absent(),
                required String entityType,
                required String name,
                Value<String> summary = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> customFields = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LoreEntitiesCompanion.insert(
                id: id,
                worldId: worldId,
                parentId: parentId,
                entityType: entityType,
                name: name,
                summary: summary,
                content: content,
                coverImagePath: coverImagePath,
                tags: tags,
                customFields: customFields,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoreEntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                worldId = false,
                parentId = false,
                loreRelationsRefs = false,
                storyScenesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loreRelationsRefs) db.loreRelations,
                    if (storyScenesRefs) db.storyScenes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable:
                                        $$LoreEntitiesTableReferences
                                            ._worldIdTable(db),
                                    referencedColumn:
                                        $$LoreEntitiesTableReferences
                                            ._worldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable:
                                        $$LoreEntitiesTableReferences
                                            ._parentIdTable(db),
                                    referencedColumn:
                                        $$LoreEntitiesTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loreRelationsRefs)
                        await $_getPrefetchedData<
                          LoreEntity,
                          $LoreEntitiesTable,
                          LoreRelation
                        >(
                          currentTable: table,
                          referencedTable: $$LoreEntitiesTableReferences
                              ._loreRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoreEntitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).loreRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.loreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storyScenesRefs)
                        await $_getPrefetchedData<
                          LoreEntity,
                          $LoreEntitiesTable,
                          StoryScene
                        >(
                          currentTable: table,
                          referencedTable: $$LoreEntitiesTableReferences
                              ._storyScenesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoreEntitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).storyScenesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.locationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LoreEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoreEntitiesTable,
      LoreEntity,
      $$LoreEntitiesTableFilterComposer,
      $$LoreEntitiesTableOrderingComposer,
      $$LoreEntitiesTableAnnotationComposer,
      $$LoreEntitiesTableCreateCompanionBuilder,
      $$LoreEntitiesTableUpdateCompanionBuilder,
      (LoreEntity, $$LoreEntitiesTableReferences),
      LoreEntity,
      PrefetchHooks Function({
        bool worldId,
        bool parentId,
        bool loreRelationsRefs,
        bool storyScenesRefs,
      })
    >;
typedef $$LoreRelationsTableCreateCompanionBuilder =
    LoreRelationsCompanion Function({
      Value<int> id,
      required int worldId,
      required int loreId,
      required int characterId,
      Value<String> role,
      Value<DateTime> createdAt,
    });
typedef $$LoreRelationsTableUpdateCompanionBuilder =
    LoreRelationsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<int> loreId,
      Value<int> characterId,
      Value<String> role,
      Value<DateTime> createdAt,
    });

final class $$LoreRelationsTableReferences
    extends BaseReferences<_$AppDatabase, $LoreRelationsTable, LoreRelation> {
  $$LoreRelationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.loreRelations.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LoreEntitiesTable _loreIdTable(_$AppDatabase db) =>
      db.loreEntities.createAlias(
        $_aliasNameGenerator(db.loreRelations.loreId, db.loreEntities.id),
      );

  $$LoreEntitiesTableProcessedTableManager get loreId {
    final $_column = $_itemColumn<int>('lore_id')!;

    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_loreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _characterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.loreRelations.characterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager get characterId {
    final $_column = $_itemColumn<int>('character_id')!;

    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_characterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoreRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $LoreRelationsTable> {
  $$LoreRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableFilterComposer get loreId {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get characterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoreRelationsTable> {
  $$LoreRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableOrderingComposer get loreId {
    final $$LoreEntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get characterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoreRelationsTable> {
  $$LoreRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableAnnotationComposer get loreId {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get characterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.characterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoreRelationsTable,
          LoreRelation,
          $$LoreRelationsTableFilterComposer,
          $$LoreRelationsTableOrderingComposer,
          $$LoreRelationsTableAnnotationComposer,
          $$LoreRelationsTableCreateCompanionBuilder,
          $$LoreRelationsTableUpdateCompanionBuilder,
          (LoreRelation, $$LoreRelationsTableReferences),
          LoreRelation,
          PrefetchHooks Function({bool worldId, bool loreId, bool characterId})
        > {
  $$LoreRelationsTableTableManager(_$AppDatabase db, $LoreRelationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoreRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoreRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoreRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<int> loreId = const Value.absent(),
                Value<int> characterId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoreRelationsCompanion(
                id: id,
                worldId: worldId,
                loreId: loreId,
                characterId: characterId,
                role: role,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required int loreId,
                required int characterId,
                Value<String> role = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoreRelationsCompanion.insert(
                id: id,
                worldId: worldId,
                loreId: loreId,
                characterId: characterId,
                role: role,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoreRelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({worldId = false, loreId = false, characterId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable:
                                        $$LoreRelationsTableReferences
                                            ._worldIdTable(db),
                                    referencedColumn:
                                        $$LoreRelationsTableReferences
                                            ._worldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (loreId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.loreId,
                                    referencedTable:
                                        $$LoreRelationsTableReferences
                                            ._loreIdTable(db),
                                    referencedColumn:
                                        $$LoreRelationsTableReferences
                                            ._loreIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (characterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.characterId,
                                    referencedTable:
                                        $$LoreRelationsTableReferences
                                            ._characterIdTable(db),
                                    referencedColumn:
                                        $$LoreRelationsTableReferences
                                            ._characterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LoreRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoreRelationsTable,
      LoreRelation,
      $$LoreRelationsTableFilterComposer,
      $$LoreRelationsTableOrderingComposer,
      $$LoreRelationsTableAnnotationComposer,
      $$LoreRelationsTableCreateCompanionBuilder,
      $$LoreRelationsTableUpdateCompanionBuilder,
      (LoreRelation, $$LoreRelationsTableReferences),
      LoreRelation,
      PrefetchHooks Function({bool worldId, bool loreId, bool characterId})
    >;
typedef $$LoreEntityRelationsTableCreateCompanionBuilder =
    LoreEntityRelationsCompanion Function({
      Value<int> id,
      required int worldId,
      required int fromLoreId,
      required int toLoreId,
      Value<String> relationType,
      Value<bool> isBidirectional,
      Value<String> note,
      Value<DateTime> createdAt,
    });
typedef $$LoreEntityRelationsTableUpdateCompanionBuilder =
    LoreEntityRelationsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<int> fromLoreId,
      Value<int> toLoreId,
      Value<String> relationType,
      Value<bool> isBidirectional,
      Value<String> note,
      Value<DateTime> createdAt,
    });

final class $$LoreEntityRelationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LoreEntityRelationsTable,
          LoreEntityRelation
        > {
  $$LoreEntityRelationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.loreEntityRelations.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LoreEntitiesTable _fromLoreIdTable(_$AppDatabase db) =>
      db.loreEntities.createAlias(
        $_aliasNameGenerator(
          db.loreEntityRelations.fromLoreId,
          db.loreEntities.id,
        ),
      );

  $$LoreEntitiesTableProcessedTableManager get fromLoreId {
    final $_column = $_itemColumn<int>('from_lore_id')!;

    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromLoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LoreEntitiesTable _toLoreIdTable(_$AppDatabase db) =>
      db.loreEntities.createAlias(
        $_aliasNameGenerator(
          db.loreEntityRelations.toLoreId,
          db.loreEntities.id,
        ),
      );

  $$LoreEntitiesTableProcessedTableManager get toLoreId {
    final $_column = $_itemColumn<int>('to_lore_id')!;

    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toLoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoreEntityRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $LoreEntityRelationsTable> {
  $$LoreEntityRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableFilterComposer get fromLoreId {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableFilterComposer get toLoreId {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntityRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoreEntityRelationsTable> {
  $$LoreEntityRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableOrderingComposer get fromLoreId {
    final $$LoreEntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableOrderingComposer get toLoreId {
    final $$LoreEntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntityRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoreEntityRelationsTable> {
  $$LoreEntityRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBidirectional => $composableBuilder(
    column: $table.isBidirectional,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableAnnotationComposer get fromLoreId {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableAnnotationComposer get toLoreId {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toLoreId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoreEntityRelationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoreEntityRelationsTable,
          LoreEntityRelation,
          $$LoreEntityRelationsTableFilterComposer,
          $$LoreEntityRelationsTableOrderingComposer,
          $$LoreEntityRelationsTableAnnotationComposer,
          $$LoreEntityRelationsTableCreateCompanionBuilder,
          $$LoreEntityRelationsTableUpdateCompanionBuilder,
          (LoreEntityRelation, $$LoreEntityRelationsTableReferences),
          LoreEntityRelation,
          PrefetchHooks Function({bool worldId, bool fromLoreId, bool toLoreId})
        > {
  $$LoreEntityRelationsTableTableManager(
    _$AppDatabase db,
    $LoreEntityRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoreEntityRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoreEntityRelationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LoreEntityRelationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<int> fromLoreId = const Value.absent(),
                Value<int> toLoreId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<bool> isBidirectional = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoreEntityRelationsCompanion(
                id: id,
                worldId: worldId,
                fromLoreId: fromLoreId,
                toLoreId: toLoreId,
                relationType: relationType,
                isBidirectional: isBidirectional,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required int fromLoreId,
                required int toLoreId,
                Value<String> relationType = const Value.absent(),
                Value<bool> isBidirectional = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LoreEntityRelationsCompanion.insert(
                id: id,
                worldId: worldId,
                fromLoreId: fromLoreId,
                toLoreId: toLoreId,
                relationType: relationType,
                isBidirectional: isBidirectional,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoreEntityRelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({worldId = false, fromLoreId = false, toLoreId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable:
                                        $$LoreEntityRelationsTableReferences
                                            ._worldIdTable(db),
                                    referencedColumn:
                                        $$LoreEntityRelationsTableReferences
                                            ._worldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (fromLoreId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromLoreId,
                                    referencedTable:
                                        $$LoreEntityRelationsTableReferences
                                            ._fromLoreIdTable(db),
                                    referencedColumn:
                                        $$LoreEntityRelationsTableReferences
                                            ._fromLoreIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (toLoreId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toLoreId,
                                    referencedTable:
                                        $$LoreEntityRelationsTableReferences
                                            ._toLoreIdTable(db),
                                    referencedColumn:
                                        $$LoreEntityRelationsTableReferences
                                            ._toLoreIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LoreEntityRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoreEntityRelationsTable,
      LoreEntityRelation,
      $$LoreEntityRelationsTableFilterComposer,
      $$LoreEntityRelationsTableOrderingComposer,
      $$LoreEntityRelationsTableAnnotationComposer,
      $$LoreEntityRelationsTableCreateCompanionBuilder,
      $$LoreEntityRelationsTableUpdateCompanionBuilder,
      (LoreEntityRelation, $$LoreEntityRelationsTableReferences),
      LoreEntityRelation,
      PrefetchHooks Function({bool worldId, bool fromLoreId, bool toLoreId})
    >;
typedef $$EntityRevisionsTableCreateCompanionBuilder =
    EntityRevisionsCompanion Function({
      Value<int> id,
      required int worldId,
      required String entityType,
      required int entityId,
      Value<String> title,
      required String content,
      Value<int> charCount,
      Value<DateTime> createdAt,
    });
typedef $$EntityRevisionsTableUpdateCompanionBuilder =
    EntityRevisionsCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<String> entityType,
      Value<int> entityId,
      Value<String> title,
      Value<String> content,
      Value<int> charCount,
      Value<DateTime> createdAt,
    });

final class $$EntityRevisionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $EntityRevisionsTable, EntityRevision> {
  $$EntityRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.entityRevisions.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntityRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $EntityRevisionsTable> {
  $$EntityRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntityRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntityRevisionsTable> {
  $$EntityRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntityRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntityRevisionsTable> {
  $$EntityRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get charCount =>
      $composableBuilder(column: $table.charCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntityRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntityRevisionsTable,
          EntityRevision,
          $$EntityRevisionsTableFilterComposer,
          $$EntityRevisionsTableOrderingComposer,
          $$EntityRevisionsTableAnnotationComposer,
          $$EntityRevisionsTableCreateCompanionBuilder,
          $$EntityRevisionsTableUpdateCompanionBuilder,
          (EntityRevision, $$EntityRevisionsTableReferences),
          EntityRevision,
          PrefetchHooks Function({bool worldId})
        > {
  $$EntityRevisionsTableTableManager(
    _$AppDatabase db,
    $EntityRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntityRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntityRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntityRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> charCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntityRevisionsCompanion(
                id: id,
                worldId: worldId,
                entityType: entityType,
                entityId: entityId,
                title: title,
                content: content,
                charCount: charCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required String entityType,
                required int entityId,
                Value<String> title = const Value.absent(),
                required String content,
                Value<int> charCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntityRevisionsCompanion.insert(
                id: id,
                worldId: worldId,
                entityType: entityType,
                entityId: entityId,
                title: title,
                content: content,
                charCount: charCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntityRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({worldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (worldId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.worldId,
                                referencedTable:
                                    $$EntityRevisionsTableReferences
                                        ._worldIdTable(db),
                                referencedColumn:
                                    $$EntityRevisionsTableReferences
                                        ._worldIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntityRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntityRevisionsTable,
      EntityRevision,
      $$EntityRevisionsTableFilterComposer,
      $$EntityRevisionsTableOrderingComposer,
      $$EntityRevisionsTableAnnotationComposer,
      $$EntityRevisionsTableCreateCompanionBuilder,
      $$EntityRevisionsTableUpdateCompanionBuilder,
      (EntityRevision, $$EntityRevisionsTableReferences),
      EntityRevision,
      PrefetchHooks Function({bool worldId})
    >;
typedef $$GraphCanvasesTableCreateCompanionBuilder =
    GraphCanvasesCompanion Function({
      Value<int> id,
      required int worldId,
      required String name,
      Value<String?> description,
      Value<bool> isDefault,
      Value<double> viewportX,
      Value<double> viewportY,
      Value<double> zoomScale,
      Value<String?> filterConfig,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GraphCanvasesTableUpdateCompanionBuilder =
    GraphCanvasesCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<String> name,
      Value<String?> description,
      Value<bool> isDefault,
      Value<double> viewportX,
      Value<double> viewportY,
      Value<double> zoomScale,
      Value<String?> filterConfig,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GraphCanvasesTableReferences
    extends BaseReferences<_$AppDatabase, $GraphCanvasesTable, GraphCanvas> {
  $$GraphCanvasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.graphCanvases.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GraphCanvasesTableFilterComposer
    extends Composer<_$AppDatabase, $GraphCanvasesTable> {
  $$GraphCanvasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get viewportX => $composableBuilder(
    column: $table.viewportX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get viewportY => $composableBuilder(
    column: $table.viewportY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zoomScale => $composableBuilder(
    column: $table.zoomScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterConfig => $composableBuilder(
    column: $table.filterConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GraphCanvasesTableOrderingComposer
    extends Composer<_$AppDatabase, $GraphCanvasesTable> {
  $$GraphCanvasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get viewportX => $composableBuilder(
    column: $table.viewportX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get viewportY => $composableBuilder(
    column: $table.viewportY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zoomScale => $composableBuilder(
    column: $table.zoomScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterConfig => $composableBuilder(
    column: $table.filterConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GraphCanvasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GraphCanvasesTable> {
  $$GraphCanvasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<double> get viewportX =>
      $composableBuilder(column: $table.viewportX, builder: (column) => column);

  GeneratedColumn<double> get viewportY =>
      $composableBuilder(column: $table.viewportY, builder: (column) => column);

  GeneratedColumn<double> get zoomScale =>
      $composableBuilder(column: $table.zoomScale, builder: (column) => column);

  GeneratedColumn<String> get filterConfig => $composableBuilder(
    column: $table.filterConfig,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GraphCanvasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GraphCanvasesTable,
          GraphCanvas,
          $$GraphCanvasesTableFilterComposer,
          $$GraphCanvasesTableOrderingComposer,
          $$GraphCanvasesTableAnnotationComposer,
          $$GraphCanvasesTableCreateCompanionBuilder,
          $$GraphCanvasesTableUpdateCompanionBuilder,
          (GraphCanvas, $$GraphCanvasesTableReferences),
          GraphCanvas,
          PrefetchHooks Function({bool worldId})
        > {
  $$GraphCanvasesTableTableManager(_$AppDatabase db, $GraphCanvasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraphCanvasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraphCanvasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraphCanvasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<double> viewportX = const Value.absent(),
                Value<double> viewportY = const Value.absent(),
                Value<double> zoomScale = const Value.absent(),
                Value<String?> filterConfig = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GraphCanvasesCompanion(
                id: id,
                worldId: worldId,
                name: name,
                description: description,
                isDefault: isDefault,
                viewportX: viewportX,
                viewportY: viewportY,
                zoomScale: zoomScale,
                filterConfig: filterConfig,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<double> viewportX = const Value.absent(),
                Value<double> viewportY = const Value.absent(),
                Value<double> zoomScale = const Value.absent(),
                Value<String?> filterConfig = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GraphCanvasesCompanion.insert(
                id: id,
                worldId: worldId,
                name: name,
                description: description,
                isDefault: isDefault,
                viewportX: viewportX,
                viewportY: viewportY,
                zoomScale: zoomScale,
                filterConfig: filterConfig,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GraphCanvasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({worldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (worldId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.worldId,
                                referencedTable: $$GraphCanvasesTableReferences
                                    ._worldIdTable(db),
                                referencedColumn: $$GraphCanvasesTableReferences
                                    ._worldIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GraphCanvasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GraphCanvasesTable,
      GraphCanvas,
      $$GraphCanvasesTableFilterComposer,
      $$GraphCanvasesTableOrderingComposer,
      $$GraphCanvasesTableAnnotationComposer,
      $$GraphCanvasesTableCreateCompanionBuilder,
      $$GraphCanvasesTableUpdateCompanionBuilder,
      (GraphCanvas, $$GraphCanvasesTableReferences),
      GraphCanvas,
      PrefetchHooks Function({bool worldId})
    >;
typedef $$StoryWorksTableCreateCompanionBuilder =
    StoryWorksCompanion Function({
      Value<int> id,
      required int worldId,
      required String title,
      Value<String> type,
      Value<String> summary,
      Value<String> status,
      Value<String?> coverImagePath,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StoryWorksTableUpdateCompanionBuilder =
    StoryWorksCompanion Function({
      Value<int> id,
      Value<int> worldId,
      Value<String> title,
      Value<String> type,
      Value<String> summary,
      Value<String> status,
      Value<String?> coverImagePath,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StoryWorksTableReferences
    extends BaseReferences<_$AppDatabase, $StoryWorksTable, StoryWork> {
  $$StoryWorksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorldsTable _worldIdTable(_$AppDatabase db) => db.worlds.createAlias(
    $_aliasNameGenerator(db.storyWorks.worldId, db.worlds.id),
  );

  $$WorldsTableProcessedTableManager get worldId {
    final $_column = $_itemColumn<int>('world_id')!;

    final manager = $$WorldsTableTableManager(
      $_db,
      $_db.worlds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_worldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StoryChaptersTable, List<StoryChapter>>
  _storyChaptersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyChapters,
    aliasName: $_aliasNameGenerator(db.storyWorks.id, db.storyChapters.workId),
  );

  $$StoryChaptersTableProcessedTableManager get storyChaptersRefs {
    final manager = $$StoryChaptersTableTableManager(
      $_db,
      $_db.storyChapters,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyChaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoryWorksTableFilterComposer
    extends Composer<_$AppDatabase, $StoryWorksTable> {
  $$StoryWorksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorldsTableFilterComposer get worldId {
    final $$WorldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableFilterComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storyChaptersRefs(
    Expression<bool> Function($$StoryChaptersTableFilterComposer f) f,
  ) {
    final $$StoryChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyChapters,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryChaptersTableFilterComposer(
            $db: $db,
            $table: $db.storyChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoryWorksTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryWorksTable> {
  $$StoryWorksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorldsTableOrderingComposer get worldId {
    final $$WorldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableOrderingComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryWorksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryWorksTable> {
  $$StoryWorksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorldsTableAnnotationComposer get worldId {
    final $$WorldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.worldId,
      referencedTable: $db.worlds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorldsTableAnnotationComposer(
            $db: $db,
            $table: $db.worlds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storyChaptersRefs<T extends Object>(
    Expression<T> Function($$StoryChaptersTableAnnotationComposer a) f,
  ) {
    final $$StoryChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyChapters,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.storyChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoryWorksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryWorksTable,
          StoryWork,
          $$StoryWorksTableFilterComposer,
          $$StoryWorksTableOrderingComposer,
          $$StoryWorksTableAnnotationComposer,
          $$StoryWorksTableCreateCompanionBuilder,
          $$StoryWorksTableUpdateCompanionBuilder,
          (StoryWork, $$StoryWorksTableReferences),
          StoryWork,
          PrefetchHooks Function({bool worldId, bool storyChaptersRefs})
        > {
  $$StoryWorksTableTableManager(_$AppDatabase db, $StoryWorksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryWorksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryWorksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryWorksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> worldId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryWorksCompanion(
                id: id,
                worldId: worldId,
                title: title,
                type: type,
                summary: summary,
                status: status,
                coverImagePath: coverImagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int worldId,
                required String title,
                Value<String> type = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryWorksCompanion.insert(
                id: id,
                worldId: worldId,
                title: title,
                type: type,
                summary: summary,
                status: status,
                coverImagePath: coverImagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoryWorksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({worldId = false, storyChaptersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storyChaptersRefs) db.storyChapters,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (worldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.worldId,
                                    referencedTable: $$StoryWorksTableReferences
                                        ._worldIdTable(db),
                                    referencedColumn:
                                        $$StoryWorksTableReferences
                                            ._worldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storyChaptersRefs)
                        await $_getPrefetchedData<
                          StoryWork,
                          $StoryWorksTable,
                          StoryChapter
                        >(
                          currentTable: table,
                          referencedTable: $$StoryWorksTableReferences
                              ._storyChaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoryWorksTableReferences(
                                db,
                                table,
                                p0,
                              ).storyChaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoryWorksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryWorksTable,
      StoryWork,
      $$StoryWorksTableFilterComposer,
      $$StoryWorksTableOrderingComposer,
      $$StoryWorksTableAnnotationComposer,
      $$StoryWorksTableCreateCompanionBuilder,
      $$StoryWorksTableUpdateCompanionBuilder,
      (StoryWork, $$StoryWorksTableReferences),
      StoryWork,
      PrefetchHooks Function({bool worldId, bool storyChaptersRefs})
    >;
typedef $$StoryChaptersTableCreateCompanionBuilder =
    StoryChaptersCompanion Function({
      Value<int> id,
      required int workId,
      Value<String> arcName,
      required String title,
      Value<String> summary,
      Value<String> status,
      Value<int> sortOrder,
      Value<int> wordCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StoryChaptersTableUpdateCompanionBuilder =
    StoryChaptersCompanion Function({
      Value<int> id,
      Value<int> workId,
      Value<String> arcName,
      Value<String> title,
      Value<String> summary,
      Value<String> status,
      Value<int> sortOrder,
      Value<int> wordCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StoryChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $StoryChaptersTable, StoryChapter> {
  $$StoryChaptersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoryWorksTable _workIdTable(_$AppDatabase db) =>
      db.storyWorks.createAlias(
        $_aliasNameGenerator(db.storyChapters.workId, db.storyWorks.id),
      );

  $$StoryWorksTableProcessedTableManager get workId {
    final $_column = $_itemColumn<int>('work_id')!;

    final manager = $$StoryWorksTableTableManager(
      $_db,
      $_db.storyWorks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StoryScenesTable, List<StoryScene>>
  _storyScenesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storyScenes,
    aliasName: $_aliasNameGenerator(
      db.storyChapters.id,
      db.storyScenes.chapterId,
    ),
  );

  $$StoryScenesTableProcessedTableManager get storyScenesRefs {
    final manager = $$StoryScenesTableTableManager(
      $_db,
      $_db.storyScenes,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyScenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoryChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $StoryChaptersTable> {
  $$StoryChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arcName => $composableBuilder(
    column: $table.arcName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoryWorksTableFilterComposer get workId {
    final $$StoryWorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.storyWorks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryWorksTableFilterComposer(
            $db: $db,
            $table: $db.storyWorks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storyScenesRefs(
    Expression<bool> Function($$StoryScenesTableFilterComposer f) f,
  ) {
    final $$StoryScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableFilterComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoryChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryChaptersTable> {
  $$StoryChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arcName => $composableBuilder(
    column: $table.arcName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoryWorksTableOrderingComposer get workId {
    final $$StoryWorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.storyWorks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryWorksTableOrderingComposer(
            $db: $db,
            $table: $db.storyWorks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryChaptersTable> {
  $$StoryChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get arcName =>
      $composableBuilder(column: $table.arcName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StoryWorksTableAnnotationComposer get workId {
    final $$StoryWorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.storyWorks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryWorksTableAnnotationComposer(
            $db: $db,
            $table: $db.storyWorks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storyScenesRefs<T extends Object>(
    Expression<T> Function($$StoryScenesTableAnnotationComposer a) f,
  ) {
    final $$StoryScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyScenes,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.storyScenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoryChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryChaptersTable,
          StoryChapter,
          $$StoryChaptersTableFilterComposer,
          $$StoryChaptersTableOrderingComposer,
          $$StoryChaptersTableAnnotationComposer,
          $$StoryChaptersTableCreateCompanionBuilder,
          $$StoryChaptersTableUpdateCompanionBuilder,
          (StoryChapter, $$StoryChaptersTableReferences),
          StoryChapter,
          PrefetchHooks Function({bool workId, bool storyScenesRefs})
        > {
  $$StoryChaptersTableTableManager(_$AppDatabase db, $StoryChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workId = const Value.absent(),
                Value<String> arcName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryChaptersCompanion(
                id: id,
                workId: workId,
                arcName: arcName,
                title: title,
                summary: summary,
                status: status,
                sortOrder: sortOrder,
                wordCount: wordCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workId,
                Value<String> arcName = const Value.absent(),
                required String title,
                Value<String> summary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryChaptersCompanion.insert(
                id: id,
                workId: workId,
                arcName: arcName,
                title: title,
                summary: summary,
                status: status,
                sortOrder: sortOrder,
                wordCount: wordCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoryChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workId = false, storyScenesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (storyScenesRefs) db.storyScenes],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workId,
                                referencedTable: $$StoryChaptersTableReferences
                                    ._workIdTable(db),
                                referencedColumn: $$StoryChaptersTableReferences
                                    ._workIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (storyScenesRefs)
                    await $_getPrefetchedData<
                      StoryChapter,
                      $StoryChaptersTable,
                      StoryScene
                    >(
                      currentTable: table,
                      referencedTable: $$StoryChaptersTableReferences
                          ._storyScenesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StoryChaptersTableReferences(
                            db,
                            table,
                            p0,
                          ).storyScenesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.chapterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StoryChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryChaptersTable,
      StoryChapter,
      $$StoryChaptersTableFilterComposer,
      $$StoryChaptersTableOrderingComposer,
      $$StoryChaptersTableAnnotationComposer,
      $$StoryChaptersTableCreateCompanionBuilder,
      $$StoryChaptersTableUpdateCompanionBuilder,
      (StoryChapter, $$StoryChaptersTableReferences),
      StoryChapter,
      PrefetchHooks Function({bool workId, bool storyScenesRefs})
    >;
typedef $$StoryScenesTableCreateCompanionBuilder =
    StoryScenesCompanion Function({
      Value<int> id,
      required int chapterId,
      required String title,
      Value<String> summary,
      Value<String> content,
      Value<int?> povCharacterId,
      Value<int?> locationId,
      Value<String> locationName,
      Value<String> timelineTime,
      Value<String> mood,
      Value<String> characterIds,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StoryScenesTableUpdateCompanionBuilder =
    StoryScenesCompanion Function({
      Value<int> id,
      Value<int> chapterId,
      Value<String> title,
      Value<String> summary,
      Value<String> content,
      Value<int?> povCharacterId,
      Value<int?> locationId,
      Value<String> locationName,
      Value<String> timelineTime,
      Value<String> mood,
      Value<String> characterIds,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StoryScenesTableReferences
    extends BaseReferences<_$AppDatabase, $StoryScenesTable, StoryScene> {
  $$StoryScenesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoryChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.storyChapters.createAlias(
        $_aliasNameGenerator(db.storyScenes.chapterId, db.storyChapters.id),
      );

  $$StoryChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$StoryChaptersTableTableManager(
      $_db,
      $_db.storyChapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CharactersTable _povCharacterIdTable(_$AppDatabase db) =>
      db.characters.createAlias(
        $_aliasNameGenerator(db.storyScenes.povCharacterId, db.characters.id),
      );

  $$CharactersTableProcessedTableManager? get povCharacterId {
    final $_column = $_itemColumn<int>('pov_character_id');
    if ($_column == null) return null;
    final manager = $$CharactersTableTableManager(
      $_db,
      $_db.characters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_povCharacterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LoreEntitiesTable _locationIdTable(_$AppDatabase db) =>
      db.loreEntities.createAlias(
        $_aliasNameGenerator(db.storyScenes.locationId, db.loreEntities.id),
      );

  $$LoreEntitiesTableProcessedTableManager? get locationId {
    final $_column = $_itemColumn<int>('location_id');
    if ($_column == null) return null;
    final manager = $$LoreEntitiesTableTableManager(
      $_db,
      $_db.loreEntities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_locationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoryScenesTableFilterComposer
    extends Composer<_$AppDatabase, $StoryScenesTable> {
  $$StoryScenesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timelineTime => $composableBuilder(
    column: $table.timelineTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterIds => $composableBuilder(
    column: $table.characterIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoryChaptersTableFilterComposer get chapterId {
    final $$StoryChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.storyChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryChaptersTableFilterComposer(
            $db: $db,
            $table: $db.storyChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableFilterComposer get povCharacterId {
    final $$CharactersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableFilterComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableFilterComposer get locationId {
    final $$LoreEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryScenesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryScenesTable> {
  $$StoryScenesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timelineTime => $composableBuilder(
    column: $table.timelineTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterIds => $composableBuilder(
    column: $table.characterIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoryChaptersTableOrderingComposer get chapterId {
    final $$StoryChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.storyChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.storyChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableOrderingComposer get povCharacterId {
    final $$CharactersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableOrderingComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableOrderingComposer get locationId {
    final $$LoreEntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryScenesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryScenesTable> {
  $$StoryScenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timelineTime => $composableBuilder(
    column: $table.timelineTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get characterIds => $composableBuilder(
    column: $table.characterIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StoryChaptersTableAnnotationComposer get chapterId {
    final $$StoryChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.storyChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.storyChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CharactersTableAnnotationComposer get povCharacterId {
    final $$CharactersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.povCharacterId,
      referencedTable: $db.characters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CharactersTableAnnotationComposer(
            $db: $db,
            $table: $db.characters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LoreEntitiesTableAnnotationComposer get locationId {
    final $$LoreEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.loreEntities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoreEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.loreEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryScenesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryScenesTable,
          StoryScene,
          $$StoryScenesTableFilterComposer,
          $$StoryScenesTableOrderingComposer,
          $$StoryScenesTableAnnotationComposer,
          $$StoryScenesTableCreateCompanionBuilder,
          $$StoryScenesTableUpdateCompanionBuilder,
          (StoryScene, $$StoryScenesTableReferences),
          StoryScene,
          PrefetchHooks Function({
            bool chapterId,
            bool povCharacterId,
            bool locationId,
          })
        > {
  $$StoryScenesTableTableManager(_$AppDatabase db, $StoryScenesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryScenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryScenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryScenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> povCharacterId = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<String> timelineTime = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<String> characterIds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryScenesCompanion(
                id: id,
                chapterId: chapterId,
                title: title,
                summary: summary,
                content: content,
                povCharacterId: povCharacterId,
                locationId: locationId,
                locationName: locationName,
                timelineTime: timelineTime,
                mood: mood,
                characterIds: characterIds,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chapterId,
                required String title,
                Value<String> summary = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> povCharacterId = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<String> timelineTime = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<String> characterIds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryScenesCompanion.insert(
                id: id,
                chapterId: chapterId,
                title: title,
                summary: summary,
                content: content,
                povCharacterId: povCharacterId,
                locationId: locationId,
                locationName: locationName,
                timelineTime: timelineTime,
                mood: mood,
                characterIds: characterIds,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoryScenesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                chapterId = false,
                povCharacterId = false,
                locationId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (chapterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.chapterId,
                                    referencedTable:
                                        $$StoryScenesTableReferences
                                            ._chapterIdTable(db),
                                    referencedColumn:
                                        $$StoryScenesTableReferences
                                            ._chapterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (povCharacterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.povCharacterId,
                                    referencedTable:
                                        $$StoryScenesTableReferences
                                            ._povCharacterIdTable(db),
                                    referencedColumn:
                                        $$StoryScenesTableReferences
                                            ._povCharacterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (locationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.locationId,
                                    referencedTable:
                                        $$StoryScenesTableReferences
                                            ._locationIdTable(db),
                                    referencedColumn:
                                        $$StoryScenesTableReferences
                                            ._locationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$StoryScenesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryScenesTable,
      StoryScene,
      $$StoryScenesTableFilterComposer,
      $$StoryScenesTableOrderingComposer,
      $$StoryScenesTableAnnotationComposer,
      $$StoryScenesTableCreateCompanionBuilder,
      $$StoryScenesTableUpdateCompanionBuilder,
      (StoryScene, $$StoryScenesTableReferences),
      StoryScene,
      PrefetchHooks Function({
        bool chapterId,
        bool povCharacterId,
        bool locationId,
      })
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorldsTableTableManager get worlds =>
      $$WorldsTableTableManager(_db, _db.worlds);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$CharacterFieldsTableTableManager get characterFields =>
      $$CharacterFieldsTableTableManager(_db, _db.characterFields);
  $$CharacterStatsTableTableManager get characterStats =>
      $$CharacterStatsTableTableManager(_db, _db.characterStats);
  $$CharacterGalleriesTableTableManager get characterGalleries =>
      $$CharacterGalleriesTableTableManager(_db, _db.characterGalleries);
  $$RelationsTableTableManager get relations =>
      $$RelationsTableTableManager(_db, _db.relations);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$TemplateFieldsTableTableManager get templateFields =>
      $$TemplateFieldsTableTableManager(_db, _db.templateFields);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$CharacterTagsTableTableManager get characterTags =>
      $$CharacterTagsTableTableManager(_db, _db.characterTags);
  $$TrashTableTableManager get trash =>
      $$TrashTableTableManager(_db, _db.trash);
  $$BackupsTableTableManager get backups =>
      $$BackupsTableTableManager(_db, _db.backups);
  $$GraphLayoutsTableTableManager get graphLayouts =>
      $$GraphLayoutsTableTableManager(_db, _db.graphLayouts);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$BasicInfoFieldsTableTableManager get basicInfoFields =>
      $$BasicInfoFieldsTableTableManager(_db, _db.basicInfoFields);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$CharacterGroupsTableTableManager get characterGroups =>
      $$CharacterGroupsTableTableManager(_db, _db.characterGroups);
  $$TimelineEventsTableTableManager get timelineEvents =>
      $$TimelineEventsTableTableManager(_db, _db.timelineEvents);
  $$LoreEntitiesTableTableManager get loreEntities =>
      $$LoreEntitiesTableTableManager(_db, _db.loreEntities);
  $$LoreRelationsTableTableManager get loreRelations =>
      $$LoreRelationsTableTableManager(_db, _db.loreRelations);
  $$LoreEntityRelationsTableTableManager get loreEntityRelations =>
      $$LoreEntityRelationsTableTableManager(_db, _db.loreEntityRelations);
  $$EntityRevisionsTableTableManager get entityRevisions =>
      $$EntityRevisionsTableTableManager(_db, _db.entityRevisions);
  $$GraphCanvasesTableTableManager get graphCanvases =>
      $$GraphCanvasesTableTableManager(_db, _db.graphCanvases);
  $$StoryWorksTableTableManager get storyWorks =>
      $$StoryWorksTableTableManager(_db, _db.storyWorks);
  $$StoryChaptersTableTableManager get storyChapters =>
      $$StoryChaptersTableTableManager(_db, _db.storyChapters);
  $$StoryScenesTableTableManager get storyScenes =>
      $$StoryScenesTableTableManager(_db, _db.storyScenes);
}
