// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<int> takenAt = GeneratedColumn<int>(
      'taken_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
      'is_demo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_demo" IN (0, 1))'));
  static const VerificationMeta _storyIdMeta =
      const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
      'story_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, data, takenAt, kind, isDemo, storyId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<ItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('is_demo')) {
      context.handle(_isDemoMeta,
          isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta));
    } else if (isInserting) {
      context.missing(_isDemoMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta,
          storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}taken_at'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      isDemo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_demo'])!,
      storyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}story_id']),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  /// The item id (`frame-042`, `mem-…`).
  final String id;

  /// The full memory-item JSON.
  final String data;

  /// Capture time, milliseconds since epoch.
  final int takenAt;

  /// Media kind name (`photo`, `video`, `voiceNote`, `note`).
  final String kind;

  /// True for seeded/demo content.
  final bool isDemo;

  /// Story id, when the item belongs to a story.
  final String? storyId;
  const ItemRow(
      {required this.id,
      required this.data,
      required this.takenAt,
      required this.kind,
      required this.isDemo,
      this.storyId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['taken_at'] = Variable<int>(takenAt);
    map['kind'] = Variable<String>(kind);
    map['is_demo'] = Variable<bool>(isDemo);
    if (!nullToAbsent || storyId != null) {
      map['story_id'] = Variable<String>(storyId);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      data: Value(data),
      takenAt: Value(takenAt),
      kind: Value(kind),
      isDemo: Value(isDemo),
      storyId: storyId == null && nullToAbsent
          ? const Value.absent()
          : Value(storyId),
    );
  }

  factory ItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      takenAt: serializer.fromJson<int>(json['takenAt']),
      kind: serializer.fromJson<String>(json['kind']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
      storyId: serializer.fromJson<String?>(json['storyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'takenAt': serializer.toJson<int>(takenAt),
      'kind': serializer.toJson<String>(kind),
      'isDemo': serializer.toJson<bool>(isDemo),
      'storyId': serializer.toJson<String?>(storyId),
    };
  }

  ItemRow copyWith(
          {String? id,
          String? data,
          int? takenAt,
          String? kind,
          bool? isDemo,
          Value<String?> storyId = const Value.absent()}) =>
      ItemRow(
        id: id ?? this.id,
        data: data ?? this.data,
        takenAt: takenAt ?? this.takenAt,
        kind: kind ?? this.kind,
        isDemo: isDemo ?? this.isDemo,
        storyId: storyId.present ? storyId.value : this.storyId,
      );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('takenAt: $takenAt, ')
          ..write('kind: $kind, ')
          ..write('isDemo: $isDemo, ')
          ..write('storyId: $storyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, takenAt, kind, isDemo, storyId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.takenAt == this.takenAt &&
          other.kind == this.kind &&
          other.isDemo == this.isDemo &&
          other.storyId == this.storyId);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> takenAt;
  final Value<String> kind;
  final Value<bool> isDemo;
  final Value<String?> storyId;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.storyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String data,
    required int takenAt,
    required String kind,
    required bool isDemo,
    this.storyId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data),
        takenAt = Value(takenAt),
        kind = Value(kind),
        isDemo = Value(isDemo);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? takenAt,
    Expression<String>? kind,
    Expression<bool>? isDemo,
    Expression<String>? storyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (takenAt != null) 'taken_at': takenAt,
      if (kind != null) 'kind': kind,
      if (isDemo != null) 'is_demo': isDemo,
      if (storyId != null) 'story_id': storyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? data,
      Value<int>? takenAt,
      Value<String>? kind,
      Value<bool>? isDemo,
      Value<String?>? storyId,
      Value<int>? rowid}) {
    return ItemsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      takenAt: takenAt ?? this.takenAt,
      kind: kind ?? this.kind,
      isDemo: isDemo ?? this.isDemo,
      storyId: storyId ?? this.storyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(takenAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('takenAt: $takenAt, ')
          ..write('kind: $kind, ')
          ..write('isDemo: $isDemo, ')
          ..write('storyId: $storyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, StoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
      'is_demo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_demo" IN (0, 1))'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data, isDemo, startedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(Insertable<StoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('is_demo')) {
      context.handle(_isDemoMeta,
          isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta));
    } else if (isInserting) {
      context.missing(_isDemoMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      isDemo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_demo'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class StoryRow extends DataClass implements Insertable<StoryRow> {
  /// The story id.
  final String id;

  /// The full story JSON, chapters included.
  final String data;

  /// True for seeded/demo content.
  final bool isDemo;

  /// Story start, milliseconds since epoch.
  final int startedAt;
  const StoryRow(
      {required this.id,
      required this.data,
      required this.isDemo,
      required this.startedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['is_demo'] = Variable<bool>(isDemo);
    map['started_at'] = Variable<int>(startedAt);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      data: Value(data),
      isDemo: Value(isDemo),
      startedAt: Value(startedAt),
    );
  }

  factory StoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'isDemo': serializer.toJson<bool>(isDemo),
      'startedAt': serializer.toJson<int>(startedAt),
    };
  }

  StoryRow copyWith({String? id, String? data, bool? isDemo, int? startedAt}) =>
      StoryRow(
        id: id ?? this.id,
        data: data ?? this.data,
        isDemo: isDemo ?? this.isDemo,
        startedAt: startedAt ?? this.startedAt,
      );
  StoryRow copyWithCompanion(StoriesCompanion data) {
    return StoryRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('isDemo: $isDemo, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, isDemo, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.isDemo == this.isDemo &&
          other.startedAt == this.startedAt);
}

class StoriesCompanion extends UpdateCompanion<StoryRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<bool> isDemo;
  final Value<int> startedAt;
  final Value<int> rowid;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoriesCompanion.insert({
    required String id,
    required String data,
    required bool isDemo,
    required int startedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data),
        isDemo = Value(isDemo),
        startedAt = Value(startedAt);
  static Insertable<StoryRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<bool>? isDemo,
    Expression<int>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (isDemo != null) 'is_demo': isDemo,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? data,
      Value<bool>? isDemo,
      Value<int>? startedAt,
      Value<int>? rowid}) {
    return StoriesCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      isDemo: isDemo ?? this.isDemo,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('isDemo: $isDemo, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LayersTable extends Layers with TableInfo<$LayersTable, LayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoryIdMeta =
      const VerificationMeta('memoryId');
  @override
  late final GeneratedColumn<String> memoryId = GeneratedColumn<String>(
      'memory_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data, memoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'layers';
  @override
  VerificationContext validateIntegrity(Insertable<LayerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('memory_id')) {
      context.handle(_memoryIdMeta,
          memoryId.isAcceptableOrUnknown(data['memory_id']!, _memoryIdMeta));
    } else if (isInserting) {
      context.missing(_memoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LayerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      memoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memory_id'])!,
    );
  }

  @override
  $LayersTable createAlias(String alias) {
    return $LayersTable(attachedDatabase, alias);
  }
}

class LayerRow extends DataClass implements Insertable<LayerRow> {
  /// The layer id.
  final String id;

  /// The full edit-layer JSON.
  final String data;

  /// The memory this layer edits.
  final String memoryId;
  const LayerRow(
      {required this.id, required this.data, required this.memoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['memory_id'] = Variable<String>(memoryId);
    return map;
  }

  LayersCompanion toCompanion(bool nullToAbsent) {
    return LayersCompanion(
      id: Value(id),
      data: Value(data),
      memoryId: Value(memoryId),
    );
  }

  factory LayerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LayerRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      memoryId: serializer.fromJson<String>(json['memoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'memoryId': serializer.toJson<String>(memoryId),
    };
  }

  LayerRow copyWith({String? id, String? data, String? memoryId}) => LayerRow(
        id: id ?? this.id,
        data: data ?? this.data,
        memoryId: memoryId ?? this.memoryId,
      );
  LayerRow copyWithCompanion(LayersCompanion data) {
    return LayerRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      memoryId: data.memoryId.present ? data.memoryId.value : this.memoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LayerRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('memoryId: $memoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, memoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayerRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.memoryId == this.memoryId);
}

class LayersCompanion extends UpdateCompanion<LayerRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<String> memoryId;
  final Value<int> rowid;
  const LayersCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.memoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LayersCompanion.insert({
    required String id,
    required String data,
    required String memoryId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data),
        memoryId = Value(memoryId);
  static Insertable<LayerRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<String>? memoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (memoryId != null) 'memory_id': memoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LayersCompanion copyWith(
      {Value<String>? id,
      Value<String>? data,
      Value<String>? memoryId,
      Value<int>? rowid}) {
    return LayersCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      memoryId: memoryId ?? this.memoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (memoryId.present) {
      map['memory_id'] = Variable<String>(memoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LayersCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('memoryId: $memoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, PersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(Insertable<PersonRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PersonRow extends DataClass implements Insertable<PersonRow> {
  /// The person id.
  final String id;

  /// The full person JSON.
  final String data;
  const PersonRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      data: Value(data),
    );
  }

  factory PersonRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  PersonRow copyWith({String? id, String? data}) => PersonRow(
        id: id ?? this.id,
        data: data ?? this.data,
      );
  PersonRow copyWithCompanion(PeopleCompanion data) {
    return PersonRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRow && other.id == this.id && other.data == this.data);
}

class PeopleCompanion extends UpdateCompanion<PersonRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data);
  static Insertable<PersonRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith(
      {Value<String>? id, Value<String>? data, Value<int>? rowid}) {
    return PeopleCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacesTable extends Places with TableInfo<$PlacesTable, PlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(Insertable<PlaceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class PlaceRow extends DataClass implements Insertable<PlaceRow> {
  /// The place id.
  final String id;

  /// The full place JSON.
  final String data;
  const PlaceRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      data: Value(data),
    );
  }

  factory PlaceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  PlaceRow copyWith({String? id, String? data}) => PlaceRow(
        id: id ?? this.id,
        data: data ?? this.data,
      );
  PlaceRow copyWithCompanion(PlacesCompanion data) {
    return PlaceRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceRow && other.id == this.id && other.data == this.data);
}

class PlacesCompanion extends UpdateCompanion<PlaceRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacesCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data);
  static Insertable<PlaceRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacesCompanion copyWith(
      {Value<String>? id, Value<String>? data, Value<int>? rowid}) {
    return PlacesCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceNotesTable extends VoiceNotes
    with TableInfo<$VoiceNotesTable, VoiceNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
      'is_demo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_demo" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [id, data, isDemo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_notes';
  @override
  VerificationContext validateIntegrity(Insertable<VoiceNoteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('is_demo')) {
      context.handle(_isDemoMeta,
          isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta));
    } else if (isInserting) {
      context.missing(_isDemoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceNoteRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      isDemo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_demo'])!,
    );
  }

  @override
  $VoiceNotesTable createAlias(String alias) {
    return $VoiceNotesTable(attachedDatabase, alias);
  }
}

class VoiceNoteRow extends DataClass implements Insertable<VoiceNoteRow> {
  /// The voice note id.
  final String id;

  /// The full voice-note JSON.
  final String data;

  /// True for seeded/demo content.
  final bool isDemo;
  const VoiceNoteRow(
      {required this.id, required this.data, required this.isDemo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    map['is_demo'] = Variable<bool>(isDemo);
    return map;
  }

  VoiceNotesCompanion toCompanion(bool nullToAbsent) {
    return VoiceNotesCompanion(
      id: Value(id),
      data: Value(data),
      isDemo: Value(isDemo),
    );
  }

  factory VoiceNoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceNoteRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
      'isDemo': serializer.toJson<bool>(isDemo),
    };
  }

  VoiceNoteRow copyWith({String? id, String? data, bool? isDemo}) =>
      VoiceNoteRow(
        id: id ?? this.id,
        data: data ?? this.data,
        isDemo: isDemo ?? this.isDemo,
      );
  VoiceNoteRow copyWithCompanion(VoiceNotesCompanion data) {
    return VoiceNoteRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceNoteRow(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('isDemo: $isDemo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, isDemo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceNoteRow &&
          other.id == this.id &&
          other.data == this.data &&
          other.isDemo == this.isDemo);
}

class VoiceNotesCompanion extends UpdateCompanion<VoiceNoteRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<bool> isDemo;
  final Value<int> rowid;
  const VoiceNotesCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceNotesCompanion.insert({
    required String id,
    required String data,
    required bool isDemo,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data),
        isDemo = Value(isDemo);
  static Insertable<VoiceNoteRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<bool>? isDemo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (isDemo != null) 'is_demo': isDemo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceNotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? data,
      Value<bool>? isDemo,
      Value<int>? rowid}) {
    return VoiceNotesCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      isDemo: isDemo ?? this.isDemo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceNotesCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('isDemo: $isDemo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShareLinksTable extends ShareLinks
    with TableInfo<$ShareLinksTable, ShareLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShareLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'share_links';
  @override
  VerificationContext validateIntegrity(Insertable<ShareLinkRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShareLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShareLinkRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $ShareLinksTable createAlias(String alias) {
    return $ShareLinksTable(attachedDatabase, alias);
  }
}

class ShareLinkRow extends DataClass implements Insertable<ShareLinkRow> {
  /// The share link id.
  final String id;

  /// The full share-link JSON.
  final String data;
  const ShareLinkRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  ShareLinksCompanion toCompanion(bool nullToAbsent) {
    return ShareLinksCompanion(
      id: Value(id),
      data: Value(data),
    );
  }

  factory ShareLinkRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShareLinkRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  ShareLinkRow copyWith({String? id, String? data}) => ShareLinkRow(
        id: id ?? this.id,
        data: data ?? this.data,
      );
  ShareLinkRow copyWithCompanion(ShareLinksCompanion data) {
    return ShareLinkRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShareLinkRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShareLinkRow && other.id == this.id && other.data == this.data);
}

class ShareLinksCompanion extends UpdateCompanion<ShareLinkRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const ShareLinksCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShareLinksCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data);
  static Insertable<ShareLinkRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShareLinksCompanion copyWith(
      {Value<String>? id, Value<String>? data, Value<int>? rowid}) {
    return ShareLinksCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShareLinksCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MomentsTable extends Moments with TableInfo<$MomentsTable, MomentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MomentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moments';
  @override
  VerificationContext validateIntegrity(Insertable<MomentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MomentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MomentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $MomentsTable createAlias(String alias) {
    return $MomentsTable(attachedDatabase, alias);
  }
}

class MomentRow extends DataClass implements Insertable<MomentRow> {
  /// The moment id.
  final String id;

  /// The full reconstructed-moment JSON.
  final String data;
  const MomentRow({required this.id, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data'] = Variable<String>(data);
    return map;
  }

  MomentsCompanion toCompanion(bool nullToAbsent) {
    return MomentsCompanion(
      id: Value(id),
      data: Value(data),
    );
  }

  factory MomentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MomentRow(
      id: serializer.fromJson<String>(json['id']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'data': serializer.toJson<String>(data),
    };
  }

  MomentRow copyWith({String? id, String? data}) => MomentRow(
        id: id ?? this.id,
        data: data ?? this.data,
      );
  MomentRow copyWithCompanion(MomentsCompanion data) {
    return MomentRow(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MomentRow(')
          ..write('id: $id, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MomentRow && other.id == this.id && other.data == this.data);
}

class MomentsCompanion extends UpdateCompanion<MomentRow> {
  final Value<String> id;
  final Value<String> data;
  final Value<int> rowid;
  const MomentsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MomentsCompanion.insert({
    required String id,
    required String data,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        data = Value(data);
  static Insertable<MomentRow> custom({
    Expression<String>? id,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MomentsCompanion copyWith(
      {Value<String>? id, Value<String>? data, Value<int>? rowid}) {
    return MomentsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MomentsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(Insertable<MetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  /// The meta key (`version`, `corrections`, `account`, `settings`,
  /// `importState`, `onboardingSeen`).
  final String key;

  /// The JSON value for the key.
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory MetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) => MetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $LayersTable layers = $LayersTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $PlacesTable places = $PlacesTable(this);
  late final $VoiceNotesTable voiceNotes = $VoiceNotesTable(this);
  late final $ShareLinksTable shareLinks = $ShareLinksTable(this);
  late final $MomentsTable moments = $MomentsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  late final Index itemsTakenAtIdx = Index('items_taken_at_idx',
      'CREATE INDEX items_taken_at_idx ON items (taken_at)');
  late final Index itemsKindIdx =
      Index('items_kind_idx', 'CREATE INDEX items_kind_idx ON items (kind)');
  late final Index itemsIsDemoIdx = Index(
      'items_is_demo_idx', 'CREATE INDEX items_is_demo_idx ON items (is_demo)');
  late final Index itemsStoryIdx = Index(
      'items_story_idx', 'CREATE INDEX items_story_idx ON items (story_id)');
  late final Index storiesIsDemoIdx = Index('stories_is_demo_idx',
      'CREATE INDEX stories_is_demo_idx ON stories (is_demo)');
  late final Index layersMemoryIdx = Index('layers_memory_idx',
      'CREATE INDEX layers_memory_idx ON layers (memory_id)');
  late final Index voiceNotesIsDemoIdx = Index('voice_notes_is_demo_idx',
      'CREATE INDEX voice_notes_is_demo_idx ON voice_notes (is_demo)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        items,
        stories,
        layers,
        people,
        places,
        voiceNotes,
        shareLinks,
        moments,
        meta,
        itemsTakenAtIdx,
        itemsKindIdx,
        itemsIsDemoIdx,
        itemsStoryIdx,
        storiesIsDemoIdx,
        layersMemoryIdx,
        voiceNotesIsDemoIdx
      ];
}

typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  required String data,
  required int takenAt,
  required String kind,
  required bool isDemo,
  Value<String?> storyId,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> takenAt,
  Value<String> kind,
  Value<bool> isDemo,
  Value<String?> storyId,
  Value<int> rowid,
});

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnFilters(column));
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storyId => $composableBuilder(
      column: $table.storyId, builder: (column) => ColumnOrderings(column));
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);

  GeneratedColumn<String> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);
}

class $$ItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsTable,
    ItemRow,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
    ItemRow,
    PrefetchHooks Function()> {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> takenAt = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<bool> isDemo = const Value.absent(),
            Value<String?> storyId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            data: data,
            takenAt: takenAt,
            kind: kind,
            isDemo: isDemo,
            storyId: storyId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            required int takenAt,
            required String kind,
            required bool isDemo,
            Value<String?> storyId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCompanion.insert(
            id: id,
            data: data,
            takenAt: takenAt,
            kind: kind,
            isDemo: isDemo,
            storyId: storyId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ItemsTable, ItemRow>(table),
                    BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsTable,
    ItemRow,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
    ItemRow,
    PrefetchHooks Function()>;
typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  required String id,
  required String data,
  required bool isDemo,
  required int startedAt,
  Value<int> rowid,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<bool> isDemo,
  Value<int> startedAt,
  Value<int> rowid,
});

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$StoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoriesTable,
    StoryRow,
    $$StoriesTableFilterComposer,
    $$StoriesTableOrderingComposer,
    $$StoriesTableAnnotationComposer,
    $$StoriesTableCreateCompanionBuilder,
    $$StoriesTableUpdateCompanionBuilder,
    (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
    StoryRow,
    PrefetchHooks Function()> {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<bool> isDemo = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoriesCompanion(
            id: id,
            data: data,
            isDemo: isDemo,
            startedAt: startedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            required bool isDemo,
            required int startedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoriesCompanion.insert(
            id: id,
            data: data,
            isDemo: isDemo,
            startedAt: startedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StoriesTable, StoryRow>(table),
                    BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StoriesTable,
    StoryRow,
    $$StoriesTableFilterComposer,
    $$StoriesTableOrderingComposer,
    $$StoriesTableAnnotationComposer,
    $$StoriesTableCreateCompanionBuilder,
    $$StoriesTableUpdateCompanionBuilder,
    (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
    StoryRow,
    PrefetchHooks Function()>;
typedef $$LayersTableCreateCompanionBuilder = LayersCompanion Function({
  required String id,
  required String data,
  required String memoryId,
  Value<int> rowid,
});
typedef $$LayersTableUpdateCompanionBuilder = LayersCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<String> memoryId,
  Value<int> rowid,
});

class $$LayersTableFilterComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoryId => $composableBuilder(
      column: $table.memoryId, builder: (column) => ColumnFilters(column));
}

class $$LayersTableOrderingComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryId => $composableBuilder(
      column: $table.memoryId, builder: (column) => ColumnOrderings(column));
}

class $$LayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LayersTable> {
  $$LayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get memoryId =>
      $composableBuilder(column: $table.memoryId, builder: (column) => column);
}

class $$LayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LayersTable,
    LayerRow,
    $$LayersTableFilterComposer,
    $$LayersTableOrderingComposer,
    $$LayersTableAnnotationComposer,
    $$LayersTableCreateCompanionBuilder,
    $$LayersTableUpdateCompanionBuilder,
    (LayerRow, BaseReferences<_$AppDatabase, $LayersTable, LayerRow>),
    LayerRow,
    PrefetchHooks Function()> {
  $$LayersTableTableManager(_$AppDatabase db, $LayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> memoryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LayersCompanion(
            id: id,
            data: data,
            memoryId: memoryId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            required String memoryId,
            Value<int> rowid = const Value.absent(),
          }) =>
              LayersCompanion.insert(
            id: id,
            data: data,
            memoryId: memoryId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LayersTable, LayerRow>(table),
                    BaseReferences<_$AppDatabase, $LayersTable, LayerRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LayersTable,
    LayerRow,
    $$LayersTableFilterComposer,
    $$LayersTableOrderingComposer,
    $$LayersTableAnnotationComposer,
    $$LayersTableCreateCompanionBuilder,
    $$LayersTableUpdateCompanionBuilder,
    (LayerRow, BaseReferences<_$AppDatabase, $LayersTable, LayerRow>),
    LayerRow,
    PrefetchHooks Function()>;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  required String id,
  required String data,
  Value<int> rowid,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> rowid,
});

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$PeopleTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeopleTable,
    PersonRow,
    $$PeopleTableFilterComposer,
    $$PeopleTableOrderingComposer,
    $$PeopleTableAnnotationComposer,
    $$PeopleTableCreateCompanionBuilder,
    $$PeopleTableUpdateCompanionBuilder,
    (PersonRow, BaseReferences<_$AppDatabase, $PeopleTable, PersonRow>),
    PersonRow,
    PrefetchHooks Function()> {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeopleCompanion(
            id: id,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) =>
              PeopleCompanion.insert(
            id: id,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PeopleTable, PersonRow>(table),
                    BaseReferences<_$AppDatabase, $PeopleTable, PersonRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PeopleTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeopleTable,
    PersonRow,
    $$PeopleTableFilterComposer,
    $$PeopleTableOrderingComposer,
    $$PeopleTableAnnotationComposer,
    $$PeopleTableCreateCompanionBuilder,
    $$PeopleTableUpdateCompanionBuilder,
    (PersonRow, BaseReferences<_$AppDatabase, $PeopleTable, PersonRow>),
    PersonRow,
    PrefetchHooks Function()>;
typedef $$PlacesTableCreateCompanionBuilder = PlacesCompanion Function({
  required String id,
  required String data,
  Value<int> rowid,
});
typedef $$PlacesTableUpdateCompanionBuilder = PlacesCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> rowid,
});

class $$PlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$PlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$PlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$PlacesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlacesTable,
    PlaceRow,
    $$PlacesTableFilterComposer,
    $$PlacesTableOrderingComposer,
    $$PlacesTableAnnotationComposer,
    $$PlacesTableCreateCompanionBuilder,
    $$PlacesTableUpdateCompanionBuilder,
    (PlaceRow, BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>),
    PlaceRow,
    PrefetchHooks Function()> {
  $$PlacesTableTableManager(_$AppDatabase db, $PlacesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlacesCompanion(
            id: id,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlacesCompanion.insert(
            id: id,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PlacesTable, PlaceRow>(table),
                    BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlacesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlacesTable,
    PlaceRow,
    $$PlacesTableFilterComposer,
    $$PlacesTableOrderingComposer,
    $$PlacesTableAnnotationComposer,
    $$PlacesTableCreateCompanionBuilder,
    $$PlacesTableUpdateCompanionBuilder,
    (PlaceRow, BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>),
    PlaceRow,
    PrefetchHooks Function()>;
typedef $$VoiceNotesTableCreateCompanionBuilder = VoiceNotesCompanion Function({
  required String id,
  required String data,
  required bool isDemo,
  Value<int> rowid,
});
typedef $$VoiceNotesTableUpdateCompanionBuilder = VoiceNotesCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<bool> isDemo,
  Value<int> rowid,
});

class $$VoiceNotesTableFilterComposer
    extends Composer<_$AppDatabase, $VoiceNotesTable> {
  $$VoiceNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnFilters(column));
}

class $$VoiceNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoiceNotesTable> {
  $$VoiceNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDemo => $composableBuilder(
      column: $table.isDemo, builder: (column) => ColumnOrderings(column));
}

class $$VoiceNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoiceNotesTable> {
  $$VoiceNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);
}

class $$VoiceNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VoiceNotesTable,
    VoiceNoteRow,
    $$VoiceNotesTableFilterComposer,
    $$VoiceNotesTableOrderingComposer,
    $$VoiceNotesTableAnnotationComposer,
    $$VoiceNotesTableCreateCompanionBuilder,
    $$VoiceNotesTableUpdateCompanionBuilder,
    (
      VoiceNoteRow,
      BaseReferences<_$AppDatabase, $VoiceNotesTable, VoiceNoteRow>
    ),
    VoiceNoteRow,
    PrefetchHooks Function()> {
  $$VoiceNotesTableTableManager(_$AppDatabase db, $VoiceNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<bool> isDemo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceNotesCompanion(
            id: id,
            data: data,
            isDemo: isDemo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            required bool isDemo,
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceNotesCompanion.insert(
            id: id,
            data: data,
            isDemo: isDemo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$VoiceNotesTable, VoiceNoteRow>(table),
                    BaseReferences<_$AppDatabase, $VoiceNotesTable,
                        VoiceNoteRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VoiceNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VoiceNotesTable,
    VoiceNoteRow,
    $$VoiceNotesTableFilterComposer,
    $$VoiceNotesTableOrderingComposer,
    $$VoiceNotesTableAnnotationComposer,
    $$VoiceNotesTableCreateCompanionBuilder,
    $$VoiceNotesTableUpdateCompanionBuilder,
    (
      VoiceNoteRow,
      BaseReferences<_$AppDatabase, $VoiceNotesTable, VoiceNoteRow>
    ),
    VoiceNoteRow,
    PrefetchHooks Function()>;
typedef $$ShareLinksTableCreateCompanionBuilder = ShareLinksCompanion Function({
  required String id,
  required String data,
  Value<int> rowid,
});
typedef $$ShareLinksTableUpdateCompanionBuilder = ShareLinksCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> rowid,
});

class $$ShareLinksTableFilterComposer
    extends Composer<_$AppDatabase, $ShareLinksTable> {
  $$ShareLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$ShareLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $ShareLinksTable> {
  $$ShareLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$ShareLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShareLinksTable> {
  $$ShareLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$ShareLinksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShareLinksTable,
    ShareLinkRow,
    $$ShareLinksTableFilterComposer,
    $$ShareLinksTableOrderingComposer,
    $$ShareLinksTableAnnotationComposer,
    $$ShareLinksTableCreateCompanionBuilder,
    $$ShareLinksTableUpdateCompanionBuilder,
    (
      ShareLinkRow,
      BaseReferences<_$AppDatabase, $ShareLinksTable, ShareLinkRow>
    ),
    ShareLinkRow,
    PrefetchHooks Function()> {
  $$ShareLinksTableTableManager(_$AppDatabase db, $ShareLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShareLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShareLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShareLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShareLinksCompanion(
            id: id,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShareLinksCompanion.insert(
            id: id,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShareLinksTable, ShareLinkRow>(table),
                    BaseReferences<_$AppDatabase, $ShareLinksTable,
                        ShareLinkRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShareLinksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShareLinksTable,
    ShareLinkRow,
    $$ShareLinksTableFilterComposer,
    $$ShareLinksTableOrderingComposer,
    $$ShareLinksTableAnnotationComposer,
    $$ShareLinksTableCreateCompanionBuilder,
    $$ShareLinksTableUpdateCompanionBuilder,
    (
      ShareLinkRow,
      BaseReferences<_$AppDatabase, $ShareLinksTable, ShareLinkRow>
    ),
    ShareLinkRow,
    PrefetchHooks Function()>;
typedef $$MomentsTableCreateCompanionBuilder = MomentsCompanion Function({
  required String id,
  required String data,
  Value<int> rowid,
});
typedef $$MomentsTableUpdateCompanionBuilder = MomentsCompanion Function({
  Value<String> id,
  Value<String> data,
  Value<int> rowid,
});

class $$MomentsTableFilterComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$MomentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$MomentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MomentsTable> {
  $$MomentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$MomentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MomentsTable,
    MomentRow,
    $$MomentsTableFilterComposer,
    $$MomentsTableOrderingComposer,
    $$MomentsTableAnnotationComposer,
    $$MomentsTableCreateCompanionBuilder,
    $$MomentsTableUpdateCompanionBuilder,
    (MomentRow, BaseReferences<_$AppDatabase, $MomentsTable, MomentRow>),
    MomentRow,
    PrefetchHooks Function()> {
  $$MomentsTableTableManager(_$AppDatabase db, $MomentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MomentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MomentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MomentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsCompanion(
            id: id,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) =>
              MomentsCompanion.insert(
            id: id,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MomentsTable, MomentRow>(table),
                    BaseReferences<_$AppDatabase, $MomentsTable, MomentRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MomentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MomentsTable,
    MomentRow,
    $$MomentsTableFilterComposer,
    $$MomentsTableOrderingComposer,
    $$MomentsTableAnnotationComposer,
    $$MomentsTableCreateCompanionBuilder,
    $$MomentsTableUpdateCompanionBuilder,
    (MomentRow, BaseReferences<_$AppDatabase, $MomentsTable, MomentRow>),
    MomentRow,
    PrefetchHooks Function()>;
typedef $$MetaTableCreateCompanionBuilder = MetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaTableUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MetaTable,
    MetaRow,
    $$MetaTableFilterComposer,
    $$MetaTableOrderingComposer,
    $$MetaTableAnnotationComposer,
    $$MetaTableCreateCompanionBuilder,
    $$MetaTableUpdateCompanionBuilder,
    (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
    MetaRow,
    PrefetchHooks Function()> {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              MetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MetaTable, MetaRow>(table),
                    BaseReferences<_$AppDatabase, $MetaTable, MetaRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MetaTable,
    MetaRow,
    $$MetaTableFilterComposer,
    $$MetaTableOrderingComposer,
    $$MetaTableAnnotationComposer,
    $$MetaTableCreateCompanionBuilder,
    $$MetaTableUpdateCompanionBuilder,
    (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
    MetaRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$LayersTableTableManager get layers =>
      $$LayersTableTableManager(_db, _db.layers);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$VoiceNotesTableTableManager get voiceNotes =>
      $$VoiceNotesTableTableManager(_db, _db.voiceNotes);
  $$ShareLinksTableTableManager get shareLinks =>
      $$ShareLinksTableTableManager(_db, _db.shareLinks);
  $$MomentsTableTableManager get moments =>
      $$MomentsTableTableManager(_db, _db.moments);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
