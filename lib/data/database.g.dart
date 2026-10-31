// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ChecklistListsTable extends ChecklistLists
    with TableInfo<$ChecklistListsTable, ChecklistList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 12),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPresetMeta = const VerificationMeta(
    'isPreset',
  );
  @override
  late final GeneratedColumn<bool> isPreset = GeneratedColumn<bool>(
    'is_preset',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_preset" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mnemonicMeta = const VerificationMeta(
    'mnemonic',
  );
  @override
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
    'mnemonic',
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
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderWeekdaysMeta = const VerificationMeta(
    'reminderWeekdays',
  );
  @override
  late final GeneratedColumn<String> reminderWeekdays = GeneratedColumn<String>(
    'reminder_weekdays',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    emoji,
    isPreset,
    mnemonic,
    sortOrder,
    reminderEnabled,
    reminderTime,
    reminderWeekdays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('is_preset')) {
      context.handle(
        _isPresetMeta,
        isPreset.isAcceptableOrUnknown(data['is_preset']!, _isPresetMeta),
      );
    }
    if (data.containsKey('mnemonic')) {
      context.handle(
        _mnemonicMeta,
        mnemonic.isAcceptableOrUnknown(data['mnemonic']!, _mnemonicMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('reminder_weekdays')) {
      context.handle(
        _reminderWeekdaysMeta,
        reminderWeekdays.isAcceptableOrUnknown(
          data['reminder_weekdays']!,
          _reminderWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      isPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_preset'],
      )!,
      mnemonic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mnemonic'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      reminderWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_weekdays'],
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
  $ChecklistListsTable createAlias(String alias) {
    return $ChecklistListsTable(attachedDatabase, alias);
  }
}

class ChecklistList extends DataClass implements Insertable<ChecklistList> {
  final String id;
  final String name;
  final String emoji;
  final bool isPreset;
  final String? mnemonic;
  final int sortOrder;
  final bool reminderEnabled;
  final String? reminderTime;
  final String? reminderWeekdays;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChecklistList({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isPreset,
    this.mnemonic,
    required this.sortOrder,
    required this.reminderEnabled,
    this.reminderTime,
    this.reminderWeekdays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['is_preset'] = Variable<bool>(isPreset);
    if (!nullToAbsent || mnemonic != null) {
      map['mnemonic'] = Variable<String>(mnemonic);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || reminderWeekdays != null) {
      map['reminder_weekdays'] = Variable<String>(reminderWeekdays);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChecklistListsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistListsCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      isPreset: Value(isPreset),
      mnemonic: mnemonic == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonic),
      sortOrder: Value(sortOrder),
      reminderEnabled: Value(reminderEnabled),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      reminderWeekdays: reminderWeekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderWeekdays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChecklistList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      isPreset: serializer.fromJson<bool>(json['isPreset']),
      mnemonic: serializer.fromJson<String?>(json['mnemonic']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      reminderWeekdays: serializer.fromJson<String?>(json['reminderWeekdays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'isPreset': serializer.toJson<bool>(isPreset),
      'mnemonic': serializer.toJson<String?>(mnemonic),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'reminderWeekdays': serializer.toJson<String?>(reminderWeekdays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChecklistList copyWith({
    String? id,
    String? name,
    String? emoji,
    bool? isPreset,
    Value<String?> mnemonic = const Value.absent(),
    int? sortOrder,
    bool? reminderEnabled,
    Value<String?> reminderTime = const Value.absent(),
    Value<String?> reminderWeekdays = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChecklistList(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    isPreset: isPreset ?? this.isPreset,
    mnemonic: mnemonic.present ? mnemonic.value : this.mnemonic,
    sortOrder: sortOrder ?? this.sortOrder,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    reminderWeekdays: reminderWeekdays.present
        ? reminderWeekdays.value
        : this.reminderWeekdays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChecklistList copyWithCompanion(ChecklistListsCompanion data) {
    return ChecklistList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      isPreset: data.isPreset.present ? data.isPreset.value : this.isPreset,
      mnemonic: data.mnemonic.present ? data.mnemonic.value : this.mnemonic,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      reminderWeekdays: data.reminderWeekdays.present
          ? data.reminderWeekdays.value
          : this.reminderWeekdays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('isPreset: $isPreset, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('reminderWeekdays: $reminderWeekdays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    emoji,
    isPreset,
    mnemonic,
    sortOrder,
    reminderEnabled,
    reminderTime,
    reminderWeekdays,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistList &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.isPreset == this.isPreset &&
          other.mnemonic == this.mnemonic &&
          other.sortOrder == this.sortOrder &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderTime == this.reminderTime &&
          other.reminderWeekdays == this.reminderWeekdays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistListsCompanion extends UpdateCompanion<ChecklistList> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<bool> isPreset;
  final Value<String?> mnemonic;
  final Value<int> sortOrder;
  final Value<bool> reminderEnabled;
  final Value<String?> reminderTime;
  final Value<String?> reminderWeekdays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChecklistListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.isPreset = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.reminderWeekdays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistListsCompanion.insert({
    required String id,
    required String name,
    required String emoji,
    this.isPreset = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.reminderWeekdays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       emoji = Value(emoji),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChecklistList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<bool>? isPreset,
    Expression<String>? mnemonic,
    Expression<int>? sortOrder,
    Expression<bool>? reminderEnabled,
    Expression<String>? reminderTime,
    Expression<String>? reminderWeekdays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (isPreset != null) 'is_preset': isPreset,
      if (mnemonic != null) 'mnemonic': mnemonic,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (reminderWeekdays != null) 'reminder_weekdays': reminderWeekdays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<bool>? isPreset,
    Value<String?>? mnemonic,
    Value<int>? sortOrder,
    Value<bool>? reminderEnabled,
    Value<String?>? reminderTime,
    Value<String?>? reminderWeekdays,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChecklistListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isPreset: isPreset ?? this.isPreset,
      mnemonic: mnemonic ?? this.mnemonic,
      sortOrder: sortOrder ?? this.sortOrder,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderWeekdays: reminderWeekdays ?? this.reminderWeekdays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (isPreset.present) {
      map['is_preset'] = Variable<bool>(isPreset.value);
    }
    if (mnemonic.present) {
      map['mnemonic'] = Variable<String>(mnemonic.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (reminderWeekdays.present) {
      map['reminder_weekdays'] = Variable<String>(reminderWeekdays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('isPreset: $isPreset, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('reminderWeekdays: $reminderWeekdays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GlobalItemsTable extends GlobalItems
    with TableInfo<$GlobalItemsTable, GlobalItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlobalItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forgotCountMeta = const VerificationMeta(
    'forgotCount',
  );
  @override
  late final GeneratedColumn<int> forgotCount = GeneratedColumn<int>(
    'forgot_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastForgotAtMeta = const VerificationMeta(
    'lastForgotAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastForgotAt = GeneratedColumn<DateTime>(
    'last_forgot_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    normalizedName,
    displayName,
    emoji,
    forgotCount,
    lastForgotAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'global_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<GlobalItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('forgot_count')) {
      context.handle(
        _forgotCountMeta,
        forgotCount.isAcceptableOrUnknown(
          data['forgot_count']!,
          _forgotCountMeta,
        ),
      );
    }
    if (data.containsKey('last_forgot_at')) {
      context.handle(
        _lastForgotAtMeta,
        lastForgotAt.isAcceptableOrUnknown(
          data['last_forgot_at']!,
          _lastForgotAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GlobalItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlobalItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      forgotCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}forgot_count'],
      )!,
      lastForgotAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_forgot_at'],
      ),
    );
  }

  @override
  $GlobalItemsTable createAlias(String alias) {
    return $GlobalItemsTable(attachedDatabase, alias);
  }
}

class GlobalItem extends DataClass implements Insertable<GlobalItem> {
  final String id;
  final String normalizedName;
  final String displayName;
  final String emoji;
  final int forgotCount;
  final DateTime? lastForgotAt;
  const GlobalItem({
    required this.id,
    required this.normalizedName,
    required this.displayName,
    required this.emoji,
    required this.forgotCount,
    this.lastForgotAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['display_name'] = Variable<String>(displayName);
    map['emoji'] = Variable<String>(emoji);
    map['forgot_count'] = Variable<int>(forgotCount);
    if (!nullToAbsent || lastForgotAt != null) {
      map['last_forgot_at'] = Variable<DateTime>(lastForgotAt);
    }
    return map;
  }

  GlobalItemsCompanion toCompanion(bool nullToAbsent) {
    return GlobalItemsCompanion(
      id: Value(id),
      normalizedName: Value(normalizedName),
      displayName: Value(displayName),
      emoji: Value(emoji),
      forgotCount: Value(forgotCount),
      lastForgotAt: lastForgotAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastForgotAt),
    );
  }

  factory GlobalItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlobalItem(
      id: serializer.fromJson<String>(json['id']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      emoji: serializer.fromJson<String>(json['emoji']),
      forgotCount: serializer.fromJson<int>(json['forgotCount']),
      lastForgotAt: serializer.fromJson<DateTime?>(json['lastForgotAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'displayName': serializer.toJson<String>(displayName),
      'emoji': serializer.toJson<String>(emoji),
      'forgotCount': serializer.toJson<int>(forgotCount),
      'lastForgotAt': serializer.toJson<DateTime?>(lastForgotAt),
    };
  }

  GlobalItem copyWith({
    String? id,
    String? normalizedName,
    String? displayName,
    String? emoji,
    int? forgotCount,
    Value<DateTime?> lastForgotAt = const Value.absent(),
  }) => GlobalItem(
    id: id ?? this.id,
    normalizedName: normalizedName ?? this.normalizedName,
    displayName: displayName ?? this.displayName,
    emoji: emoji ?? this.emoji,
    forgotCount: forgotCount ?? this.forgotCount,
    lastForgotAt: lastForgotAt.present ? lastForgotAt.value : this.lastForgotAt,
  );
  GlobalItem copyWithCompanion(GlobalItemsCompanion data) {
    return GlobalItem(
      id: data.id.present ? data.id.value : this.id,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      forgotCount: data.forgotCount.present
          ? data.forgotCount.value
          : this.forgotCount,
      lastForgotAt: data.lastForgotAt.present
          ? data.lastForgotAt.value
          : this.lastForgotAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlobalItem(')
          ..write('id: $id, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('displayName: $displayName, ')
          ..write('emoji: $emoji, ')
          ..write('forgotCount: $forgotCount, ')
          ..write('lastForgotAt: $lastForgotAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    normalizedName,
    displayName,
    emoji,
    forgotCount,
    lastForgotAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlobalItem &&
          other.id == this.id &&
          other.normalizedName == this.normalizedName &&
          other.displayName == this.displayName &&
          other.emoji == this.emoji &&
          other.forgotCount == this.forgotCount &&
          other.lastForgotAt == this.lastForgotAt);
}

class GlobalItemsCompanion extends UpdateCompanion<GlobalItem> {
  final Value<String> id;
  final Value<String> normalizedName;
  final Value<String> displayName;
  final Value<String> emoji;
  final Value<int> forgotCount;
  final Value<DateTime?> lastForgotAt;
  final Value<int> rowid;
  const GlobalItemsCompanion({
    this.id = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.emoji = const Value.absent(),
    this.forgotCount = const Value.absent(),
    this.lastForgotAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlobalItemsCompanion.insert({
    required String id,
    required String normalizedName,
    required String displayName,
    required String emoji,
    this.forgotCount = const Value.absent(),
    this.lastForgotAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       normalizedName = Value(normalizedName),
       displayName = Value(displayName),
       emoji = Value(emoji);
  static Insertable<GlobalItem> custom({
    Expression<String>? id,
    Expression<String>? normalizedName,
    Expression<String>? displayName,
    Expression<String>? emoji,
    Expression<int>? forgotCount,
    Expression<DateTime>? lastForgotAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (displayName != null) 'display_name': displayName,
      if (emoji != null) 'emoji': emoji,
      if (forgotCount != null) 'forgot_count': forgotCount,
      if (lastForgotAt != null) 'last_forgot_at': lastForgotAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlobalItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? normalizedName,
    Value<String>? displayName,
    Value<String>? emoji,
    Value<int>? forgotCount,
    Value<DateTime?>? lastForgotAt,
    Value<int>? rowid,
  }) {
    return GlobalItemsCompanion(
      id: id ?? this.id,
      normalizedName: normalizedName ?? this.normalizedName,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      forgotCount: forgotCount ?? this.forgotCount,
      lastForgotAt: lastForgotAt ?? this.lastForgotAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (forgotCount.present) {
      map['forgot_count'] = Variable<int>(forgotCount.value);
    }
    if (lastForgotAt.present) {
      map['last_forgot_at'] = Variable<DateTime>(lastForgotAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlobalItemsCompanion(')
          ..write('id: $id, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('displayName: $displayName, ')
          ..write('emoji: $emoji, ')
          ..write('forgotCount: $forgotCount, ')
          ..write('lastForgotAt: $lastForgotAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListItemsTable extends ListItems
    with TableInfo<$ListItemsTable, ListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalItemIdMeta = const VerificationMeta(
    'globalItemId',
  );
  @override
  late final GeneratedColumn<String> globalItemId = GeneratedColumn<String>(
    'global_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    globalItemId,
    name,
    emoji,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('global_item_id')) {
      context.handle(
        _globalItemIdMeta,
        globalItemId.isAcceptableOrUnknown(
          data['global_item_id']!,
          _globalItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_globalItemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
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
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      globalItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
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
  $ListItemsTable createAlias(String alias) {
    return $ListItemsTable(attachedDatabase, alias);
  }
}

class ListItem extends DataClass implements Insertable<ListItem> {
  final String id;
  final String listId;
  final String globalItemId;
  final String name;
  final String emoji;
  final int sortOrder;
  final DateTime createdAt;
  const ListItem({
    required this.id,
    required this.listId,
    required this.globalItemId,
    required this.name,
    required this.emoji,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['global_item_id'] = Variable<String>(globalItemId);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ListItemsCompanion toCompanion(bool nullToAbsent) {
    return ListItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      globalItemId: Value(globalItemId),
      name: Value(name),
      emoji: Value(emoji),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory ListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      globalItemId: serializer.fromJson<String>(json['globalItemId']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'globalItemId': serializer.toJson<String>(globalItemId),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ListItem copyWith({
    String? id,
    String? listId,
    String? globalItemId,
    String? name,
    String? emoji,
    int? sortOrder,
    DateTime? createdAt,
  }) => ListItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    globalItemId: globalItemId ?? this.globalItemId,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  ListItem copyWithCompanion(ListItemsCompanion data) {
    return ListItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      globalItemId: data.globalItemId.present
          ? data.globalItemId.value
          : this.globalItemId,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('globalItemId: $globalItemId, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listId, globalItemId, name, emoji, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.globalItemId == this.globalItemId &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class ListItemsCompanion extends UpdateCompanion<ListItem> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> globalItemId;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ListItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.globalItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListItemsCompanion.insert({
    required String id,
    required String listId,
    required String globalItemId,
    required String name,
    required String emoji,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       globalItemId = Value(globalItemId),
       name = Value(name),
       emoji = Value(emoji),
       createdAt = Value(createdAt);
  static Insertable<ListItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? globalItemId,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (globalItemId != null) 'global_item_id': globalItemId,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? globalItemId,
    Value<String>? name,
    Value<String>? emoji,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ListItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      globalItemId: globalItemId ?? this.globalItemId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (globalItemId.present) {
      map['global_item_id'] = Variable<String>(globalItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('globalItemId: $globalItemId, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackSessionsTable extends PackSessions
    with TableInfo<$PackSessionsTable, PackSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departedAtMeta = const VerificationMeta(
    'departedAt',
  );
  @override
  late final GeneratedColumn<DateTime> departedAt = GeneratedColumn<DateTime>(
    'departed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    status,
    startedAt,
    completedAt,
    departedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('departed_at')) {
      context.handle(
        _departedAtMeta,
        departedAt.isAcceptableOrUnknown(data['departed_at']!, _departedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      departedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}departed_at'],
      ),
    );
  }

  @override
  $PackSessionsTable createAlias(String alias) {
    return $PackSessionsTable(attachedDatabase, alias);
  }
}

class PackSession extends DataClass implements Insertable<PackSession> {
  final String id;
  final String listId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? departedAt;
  const PackSession({
    required this.id,
    required this.listId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.departedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || departedAt != null) {
      map['departed_at'] = Variable<DateTime>(departedAt);
    }
    return map;
  }

  PackSessionsCompanion toCompanion(bool nullToAbsent) {
    return PackSessionsCompanion(
      id: Value(id),
      listId: Value(listId),
      status: Value(status),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      departedAt: departedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(departedAt),
    );
  }

  factory PackSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackSession(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      departedAt: serializer.fromJson<DateTime?>(json['departedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'departedAt': serializer.toJson<DateTime?>(departedAt),
    };
  }

  PackSession copyWith({
    String? id,
    String? listId,
    String? status,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> departedAt = const Value.absent(),
  }) => PackSession(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    departedAt: departedAt.present ? departedAt.value : this.departedAt,
  );
  PackSession copyWithCompanion(PackSessionsCompanion data) {
    return PackSession(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      departedAt: data.departedAt.present
          ? data.departedAt.value
          : this.departedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackSession(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('departedAt: $departedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listId, status, startedAt, completedAt, departedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackSession &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.departedAt == this.departedAt);
}

class PackSessionsCompanion extends UpdateCompanion<PackSession> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> departedAt;
  final Value<int> rowid;
  const PackSessionsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.departedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackSessionsCompanion.insert({
    required String id,
    required String listId,
    required String status,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.departedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<PackSession> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? departedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (departedAt != null) 'departed_at': departedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? departedAt,
    Value<int>? rowid,
  }) {
    return PackSessionsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      departedAt: departedAt ?? this.departedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (departedAt.present) {
      map['departed_at'] = Variable<DateTime>(departedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackSessionsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('departedAt: $departedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackSessionItemsTable extends PackSessionItems
    with TableInfo<$PackSessionItemsTable, PackSessionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackSessionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listItemIdMeta = const VerificationMeta(
    'listItemId',
  );
  @override
  late final GeneratedColumn<String> listItemId = GeneratedColumn<String>(
    'list_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packedAtMeta = const VerificationMeta(
    'packedAt',
  );
  @override
  late final GeneratedColumn<DateTime> packedAt = GeneratedColumn<DateTime>(
    'packed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    listItemId,
    packedAt,
    skipped,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_session_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackSessionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('list_item_id')) {
      context.handle(
        _listItemIdMeta,
        listItemId.isAcceptableOrUnknown(
          data['list_item_id']!,
          _listItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_listItemIdMeta);
    }
    if (data.containsKey('packed_at')) {
      context.handle(
        _packedAtMeta,
        packedAt.isAcceptableOrUnknown(data['packed_at']!, _packedAtMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, listItemId};
  @override
  PackSessionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackSessionItem(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      listItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_item_id'],
      )!,
      packedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}packed_at'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
    );
  }

  @override
  $PackSessionItemsTable createAlias(String alias) {
    return $PackSessionItemsTable(attachedDatabase, alias);
  }
}

class PackSessionItem extends DataClass implements Insertable<PackSessionItem> {
  final String sessionId;
  final String listItemId;
  final DateTime? packedAt;
  final bool skipped;
  const PackSessionItem({
    required this.sessionId,
    required this.listItemId,
    this.packedAt,
    required this.skipped,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['list_item_id'] = Variable<String>(listItemId);
    if (!nullToAbsent || packedAt != null) {
      map['packed_at'] = Variable<DateTime>(packedAt);
    }
    map['skipped'] = Variable<bool>(skipped);
    return map;
  }

  PackSessionItemsCompanion toCompanion(bool nullToAbsent) {
    return PackSessionItemsCompanion(
      sessionId: Value(sessionId),
      listItemId: Value(listItemId),
      packedAt: packedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(packedAt),
      skipped: Value(skipped),
    );
  }

  factory PackSessionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackSessionItem(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      listItemId: serializer.fromJson<String>(json['listItemId']),
      packedAt: serializer.fromJson<DateTime?>(json['packedAt']),
      skipped: serializer.fromJson<bool>(json['skipped']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'listItemId': serializer.toJson<String>(listItemId),
      'packedAt': serializer.toJson<DateTime?>(packedAt),
      'skipped': serializer.toJson<bool>(skipped),
    };
  }

  PackSessionItem copyWith({
    String? sessionId,
    String? listItemId,
    Value<DateTime?> packedAt = const Value.absent(),
    bool? skipped,
  }) => PackSessionItem(
    sessionId: sessionId ?? this.sessionId,
    listItemId: listItemId ?? this.listItemId,
    packedAt: packedAt.present ? packedAt.value : this.packedAt,
    skipped: skipped ?? this.skipped,
  );
  PackSessionItem copyWithCompanion(PackSessionItemsCompanion data) {
    return PackSessionItem(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      listItemId: data.listItemId.present
          ? data.listItemId.value
          : this.listItemId,
      packedAt: data.packedAt.present ? data.packedAt.value : this.packedAt,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackSessionItem(')
          ..write('sessionId: $sessionId, ')
          ..write('listItemId: $listItemId, ')
          ..write('packedAt: $packedAt, ')
          ..write('skipped: $skipped')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, listItemId, packedAt, skipped);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackSessionItem &&
          other.sessionId == this.sessionId &&
          other.listItemId == this.listItemId &&
          other.packedAt == this.packedAt &&
          other.skipped == this.skipped);
}

class PackSessionItemsCompanion extends UpdateCompanion<PackSessionItem> {
  final Value<String> sessionId;
  final Value<String> listItemId;
  final Value<DateTime?> packedAt;
  final Value<bool> skipped;
  final Value<int> rowid;
  const PackSessionItemsCompanion({
    this.sessionId = const Value.absent(),
    this.listItemId = const Value.absent(),
    this.packedAt = const Value.absent(),
    this.skipped = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackSessionItemsCompanion.insert({
    required String sessionId,
    required String listItemId,
    this.packedAt = const Value.absent(),
    this.skipped = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       listItemId = Value(listItemId);
  static Insertable<PackSessionItem> custom({
    Expression<String>? sessionId,
    Expression<String>? listItemId,
    Expression<DateTime>? packedAt,
    Expression<bool>? skipped,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (listItemId != null) 'list_item_id': listItemId,
      if (packedAt != null) 'packed_at': packedAt,
      if (skipped != null) 'skipped': skipped,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackSessionItemsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? listItemId,
    Value<DateTime?>? packedAt,
    Value<bool>? skipped,
    Value<int>? rowid,
  }) {
    return PackSessionItemsCompanion(
      sessionId: sessionId ?? this.sessionId,
      listItemId: listItemId ?? this.listItemId,
      packedAt: packedAt ?? this.packedAt,
      skipped: skipped ?? this.skipped,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (listItemId.present) {
      map['list_item_id'] = Variable<String>(listItemId.value);
    }
    if (packedAt.present) {
      map['packed_at'] = Variable<DateTime>(packedAt.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackSessionItemsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('listItemId: $listItemId, ')
          ..write('packedAt: $packedAt, ')
          ..write('skipped: $skipped, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ForgotRecordsTable extends ForgotRecords
    with TableInfo<$ForgotRecordsTable, ForgotRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ForgotRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalItemIdMeta = const VerificationMeta(
    'globalItemId',
  );
  @override
  late final GeneratedColumn<String> globalItemId = GeneratedColumn<String>(
    'global_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    globalItemId,
    sessionId,
    listId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'forgot_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ForgotRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('global_item_id')) {
      context.handle(
        _globalItemIdMeta,
        globalItemId.isAcceptableOrUnknown(
          data['global_item_id']!,
          _globalItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_globalItemIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ForgotRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ForgotRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      globalItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_item_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ForgotRecordsTable createAlias(String alias) {
    return $ForgotRecordsTable(attachedDatabase, alias);
  }
}

class ForgotRecord extends DataClass implements Insertable<ForgotRecord> {
  final String id;
  final String globalItemId;
  final String? sessionId;
  final String? listId;
  final DateTime createdAt;
  const ForgotRecord({
    required this.id,
    required this.globalItemId,
    this.sessionId,
    this.listId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['global_item_id'] = Variable<String>(globalItemId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ForgotRecordsCompanion toCompanion(bool nullToAbsent) {
    return ForgotRecordsCompanion(
      id: Value(id),
      globalItemId: Value(globalItemId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      createdAt: Value(createdAt),
    );
  }

  factory ForgotRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ForgotRecord(
      id: serializer.fromJson<String>(json['id']),
      globalItemId: serializer.fromJson<String>(json['globalItemId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      listId: serializer.fromJson<String?>(json['listId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'globalItemId': serializer.toJson<String>(globalItemId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'listId': serializer.toJson<String?>(listId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ForgotRecord copyWith({
    String? id,
    String? globalItemId,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    DateTime? createdAt,
  }) => ForgotRecord(
    id: id ?? this.id,
    globalItemId: globalItemId ?? this.globalItemId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    listId: listId.present ? listId.value : this.listId,
    createdAt: createdAt ?? this.createdAt,
  );
  ForgotRecord copyWithCompanion(ForgotRecordsCompanion data) {
    return ForgotRecord(
      id: data.id.present ? data.id.value : this.id,
      globalItemId: data.globalItemId.present
          ? data.globalItemId.value
          : this.globalItemId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      listId: data.listId.present ? data.listId.value : this.listId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ForgotRecord(')
          ..write('id: $id, ')
          ..write('globalItemId: $globalItemId, ')
          ..write('sessionId: $sessionId, ')
          ..write('listId: $listId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, globalItemId, sessionId, listId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ForgotRecord &&
          other.id == this.id &&
          other.globalItemId == this.globalItemId &&
          other.sessionId == this.sessionId &&
          other.listId == this.listId &&
          other.createdAt == this.createdAt);
}

class ForgotRecordsCompanion extends UpdateCompanion<ForgotRecord> {
  final Value<String> id;
  final Value<String> globalItemId;
  final Value<String?> sessionId;
  final Value<String?> listId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ForgotRecordsCompanion({
    this.id = const Value.absent(),
    this.globalItemId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.listId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ForgotRecordsCompanion.insert({
    required String id,
    required String globalItemId,
    this.sessionId = const Value.absent(),
    this.listId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       globalItemId = Value(globalItemId),
       createdAt = Value(createdAt);
  static Insertable<ForgotRecord> custom({
    Expression<String>? id,
    Expression<String>? globalItemId,
    Expression<String>? sessionId,
    Expression<String>? listId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (globalItemId != null) 'global_item_id': globalItemId,
      if (sessionId != null) 'session_id': sessionId,
      if (listId != null) 'list_id': listId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ForgotRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? globalItemId,
    Value<String?>? sessionId,
    Value<String?>? listId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ForgotRecordsCompanion(
      id: id ?? this.id,
      globalItemId: globalItemId ?? this.globalItemId,
      sessionId: sessionId ?? this.sessionId,
      listId: listId ?? this.listId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (globalItemId.present) {
      map['global_item_id'] = Variable<String>(globalItemId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ForgotRecordsCompanion(')
          ..write('id: $id, ')
          ..write('globalItemId: $globalItemId, ')
          ..write('sessionId: $sessionId, ')
          ..write('listId: $listId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChecklistListsTable checklistLists = $ChecklistListsTable(this);
  late final $GlobalItemsTable globalItems = $GlobalItemsTable(this);
  late final $ListItemsTable listItems = $ListItemsTable(this);
  late final $PackSessionsTable packSessions = $PackSessionsTable(this);
  late final $PackSessionItemsTable packSessionItems = $PackSessionItemsTable(
    this,
  );
  late final $ForgotRecordsTable forgotRecords = $ForgotRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    checklistLists,
    globalItems,
    listItems,
    packSessions,
    packSessionItems,
    forgotRecords,
  ];
}

typedef $$ChecklistListsTableCreateCompanionBuilder =
    ChecklistListsCompanion Function({
      required String id,
      required String name,
      required String emoji,
      Value<bool> isPreset,
      Value<String?> mnemonic,
      Value<int> sortOrder,
      Value<bool> reminderEnabled,
      Value<String?> reminderTime,
      Value<String?> reminderWeekdays,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChecklistListsTableUpdateCompanionBuilder =
    ChecklistListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> emoji,
      Value<bool> isPreset,
      Value<String?> mnemonic,
      Value<int> sortOrder,
      Value<bool> reminderEnabled,
      Value<String?> reminderTime,
      Value<String?> reminderWeekdays,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ChecklistListsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistListsTable> {
  $$ChecklistListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPreset => $composableBuilder(
    column: $table.isPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderWeekdays => $composableBuilder(
    column: $table.reminderWeekdays,
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
}

class $$ChecklistListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistListsTable> {
  $$ChecklistListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPreset => $composableBuilder(
    column: $table.isPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderWeekdays => $composableBuilder(
    column: $table.reminderWeekdays,
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

class $$ChecklistListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistListsTable> {
  $$ChecklistListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<bool> get isPreset =>
      $composableBuilder(column: $table.isPreset, builder: (column) => column);

  GeneratedColumn<String> get mnemonic =>
      $composableBuilder(column: $table.mnemonic, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderWeekdays => $composableBuilder(
    column: $table.reminderWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistListsTable,
          ChecklistList,
          $$ChecklistListsTableFilterComposer,
          $$ChecklistListsTableOrderingComposer,
          $$ChecklistListsTableAnnotationComposer,
          $$ChecklistListsTableCreateCompanionBuilder,
          $$ChecklistListsTableUpdateCompanionBuilder,
          (
            ChecklistList,
            BaseReferences<_$AppDatabase, $ChecklistListsTable, ChecklistList>,
          ),
          ChecklistList,
          PrefetchHooks Function()
        > {
  $$ChecklistListsTableTableManager(
    _$AppDatabase db,
    $ChecklistListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<bool> isPreset = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> reminderWeekdays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistListsCompanion(
                id: id,
                name: name,
                emoji: emoji,
                isPreset: isPreset,
                mnemonic: mnemonic,
                sortOrder: sortOrder,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                reminderWeekdays: reminderWeekdays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String emoji,
                Value<bool> isPreset = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> reminderWeekdays = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChecklistListsCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                isPreset: isPreset,
                mnemonic: mnemonic,
                sortOrder: sortOrder,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                reminderWeekdays: reminderWeekdays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChecklistListsTable, ChecklistList>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChecklistListsTable,
                    ChecklistList
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistListsTable,
      ChecklistList,
      $$ChecklistListsTableFilterComposer,
      $$ChecklistListsTableOrderingComposer,
      $$ChecklistListsTableAnnotationComposer,
      $$ChecklistListsTableCreateCompanionBuilder,
      $$ChecklistListsTableUpdateCompanionBuilder,
      (
        ChecklistList,
        BaseReferences<_$AppDatabase, $ChecklistListsTable, ChecklistList>,
      ),
      ChecklistList,
      PrefetchHooks Function()
    >;
typedef $$GlobalItemsTableCreateCompanionBuilder =
    GlobalItemsCompanion Function({
      required String id,
      required String normalizedName,
      required String displayName,
      required String emoji,
      Value<int> forgotCount,
      Value<DateTime?> lastForgotAt,
      Value<int> rowid,
    });
typedef $$GlobalItemsTableUpdateCompanionBuilder =
    GlobalItemsCompanion Function({
      Value<String> id,
      Value<String> normalizedName,
      Value<String> displayName,
      Value<String> emoji,
      Value<int> forgotCount,
      Value<DateTime?> lastForgotAt,
      Value<int> rowid,
    });

class $$GlobalItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GlobalItemsTable> {
  $$GlobalItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get forgotCount => $composableBuilder(
    column: $table.forgotCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastForgotAt => $composableBuilder(
    column: $table.lastForgotAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GlobalItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GlobalItemsTable> {
  $$GlobalItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get forgotCount => $composableBuilder(
    column: $table.forgotCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastForgotAt => $composableBuilder(
    column: $table.lastForgotAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GlobalItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GlobalItemsTable> {
  $$GlobalItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get forgotCount => $composableBuilder(
    column: $table.forgotCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastForgotAt => $composableBuilder(
    column: $table.lastForgotAt,
    builder: (column) => column,
  );
}

class $$GlobalItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GlobalItemsTable,
          GlobalItem,
          $$GlobalItemsTableFilterComposer,
          $$GlobalItemsTableOrderingComposer,
          $$GlobalItemsTableAnnotationComposer,
          $$GlobalItemsTableCreateCompanionBuilder,
          $$GlobalItemsTableUpdateCompanionBuilder,
          (
            GlobalItem,
            BaseReferences<_$AppDatabase, $GlobalItemsTable, GlobalItem>,
          ),
          GlobalItem,
          PrefetchHooks Function()
        > {
  $$GlobalItemsTableTableManager(_$AppDatabase db, $GlobalItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GlobalItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlobalItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GlobalItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> forgotCount = const Value.absent(),
                Value<DateTime?> lastForgotAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalItemsCompanion(
                id: id,
                normalizedName: normalizedName,
                displayName: displayName,
                emoji: emoji,
                forgotCount: forgotCount,
                lastForgotAt: lastForgotAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String normalizedName,
                required String displayName,
                required String emoji,
                Value<int> forgotCount = const Value.absent(),
                Value<DateTime?> lastForgotAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalItemsCompanion.insert(
                id: id,
                normalizedName: normalizedName,
                displayName: displayName,
                emoji: emoji,
                forgotCount: forgotCount,
                lastForgotAt: lastForgotAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GlobalItemsTable, GlobalItem>(table),
                  BaseReferences<_$AppDatabase, $GlobalItemsTable, GlobalItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GlobalItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GlobalItemsTable,
      GlobalItem,
      $$GlobalItemsTableFilterComposer,
      $$GlobalItemsTableOrderingComposer,
      $$GlobalItemsTableAnnotationComposer,
      $$GlobalItemsTableCreateCompanionBuilder,
      $$GlobalItemsTableUpdateCompanionBuilder,
      (
        GlobalItem,
        BaseReferences<_$AppDatabase, $GlobalItemsTable, GlobalItem>,
      ),
      GlobalItem,
      PrefetchHooks Function()
    >;
typedef $$ListItemsTableCreateCompanionBuilder = ListItemsCompanion Function({
  required String id,
  required String listId,
  required String globalItemId,
  required String name,
  required String emoji,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ListItemsTableUpdateCompanionBuilder = ListItemsCompanion Function({
  Value<String> id,
  Value<String> listId,
  Value<String> globalItemId,
  Value<String> name,
  Value<String> emoji,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
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
}

class $$ListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
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
}

class $$ListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListItemsTable,
          ListItem,
          $$ListItemsTableFilterComposer,
          $$ListItemsTableOrderingComposer,
          $$ListItemsTableAnnotationComposer,
          $$ListItemsTableCreateCompanionBuilder,
          $$ListItemsTableUpdateCompanionBuilder,
          (ListItem, BaseReferences<_$AppDatabase, $ListItemsTable, ListItem>),
          ListItem,
          PrefetchHooks Function()
        > {
  $$ListItemsTableTableManager(_$AppDatabase db, $ListItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> globalItemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListItemsCompanion(
                id: id,
                listId: listId,
                globalItemId: globalItemId,
                name: name,
                emoji: emoji,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String globalItemId,
                required String name,
                required String emoji,
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ListItemsCompanion.insert(
                id: id,
                listId: listId,
                globalItemId: globalItemId,
                name: name,
                emoji: emoji,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListItemsTable, ListItem>(table),
                  BaseReferences<_$AppDatabase, $ListItemsTable, ListItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListItemsTable,
      ListItem,
      $$ListItemsTableFilterComposer,
      $$ListItemsTableOrderingComposer,
      $$ListItemsTableAnnotationComposer,
      $$ListItemsTableCreateCompanionBuilder,
      $$ListItemsTableUpdateCompanionBuilder,
      (ListItem, BaseReferences<_$AppDatabase, $ListItemsTable, ListItem>),
      ListItem,
      PrefetchHooks Function()
    >;
typedef $$PackSessionsTableCreateCompanionBuilder =
    PackSessionsCompanion Function({
      required String id,
      required String listId,
      required String status,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> departedAt,
      Value<int> rowid,
    });
typedef $$PackSessionsTableUpdateCompanionBuilder =
    PackSessionsCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> departedAt,
      Value<int> rowid,
    });

class $$PackSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PackSessionsTable> {
  $$PackSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PackSessionsTable> {
  $$PackSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackSessionsTable> {
  $$PackSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get departedAt => $composableBuilder(
    column: $table.departedAt,
    builder: (column) => column,
  );
}

class $$PackSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackSessionsTable,
          PackSession,
          $$PackSessionsTableFilterComposer,
          $$PackSessionsTableOrderingComposer,
          $$PackSessionsTableAnnotationComposer,
          $$PackSessionsTableCreateCompanionBuilder,
          $$PackSessionsTableUpdateCompanionBuilder,
          (
            PackSession,
            BaseReferences<_$AppDatabase, $PackSessionsTable, PackSession>,
          ),
          PackSession,
          PrefetchHooks Function()
        > {
  $$PackSessionsTableTableManager(_$AppDatabase db, $PackSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> departedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackSessionsCompanion(
                id: id,
                listId: listId,
                status: status,
                startedAt: startedAt,
                completedAt: completedAt,
                departedAt: departedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String status,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> departedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackSessionsCompanion.insert(
                id: id,
                listId: listId,
                status: status,
                startedAt: startedAt,
                completedAt: completedAt,
                departedAt: departedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackSessionsTable, PackSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PackSessionsTable,
                    PackSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackSessionsTable,
      PackSession,
      $$PackSessionsTableFilterComposer,
      $$PackSessionsTableOrderingComposer,
      $$PackSessionsTableAnnotationComposer,
      $$PackSessionsTableCreateCompanionBuilder,
      $$PackSessionsTableUpdateCompanionBuilder,
      (
        PackSession,
        BaseReferences<_$AppDatabase, $PackSessionsTable, PackSession>,
      ),
      PackSession,
      PrefetchHooks Function()
    >;
typedef $$PackSessionItemsTableCreateCompanionBuilder =
    PackSessionItemsCompanion Function({
      required String sessionId,
      required String listItemId,
      Value<DateTime?> packedAt,
      Value<bool> skipped,
      Value<int> rowid,
    });
typedef $$PackSessionItemsTableUpdateCompanionBuilder =
    PackSessionItemsCompanion Function({
      Value<String> sessionId,
      Value<String> listItemId,
      Value<DateTime?> packedAt,
      Value<bool> skipped,
      Value<int> rowid,
    });

class $$PackSessionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PackSessionItemsTable> {
  $$PackSessionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listItemId => $composableBuilder(
    column: $table.listItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get packedAt => $composableBuilder(
    column: $table.packedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackSessionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PackSessionItemsTable> {
  $$PackSessionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listItemId => $composableBuilder(
    column: $table.listItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get packedAt => $composableBuilder(
    column: $table.packedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackSessionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackSessionItemsTable> {
  $$PackSessionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get listItemId => $composableBuilder(
    column: $table.listItemId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get packedAt =>
      $composableBuilder(column: $table.packedAt, builder: (column) => column);

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);
}

class $$PackSessionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackSessionItemsTable,
          PackSessionItem,
          $$PackSessionItemsTableFilterComposer,
          $$PackSessionItemsTableOrderingComposer,
          $$PackSessionItemsTableAnnotationComposer,
          $$PackSessionItemsTableCreateCompanionBuilder,
          $$PackSessionItemsTableUpdateCompanionBuilder,
          (
            PackSessionItem,
            BaseReferences<
              _$AppDatabase,
              $PackSessionItemsTable,
              PackSessionItem
            >,
          ),
          PackSessionItem,
          PrefetchHooks Function()
        > {
  $$PackSessionItemsTableTableManager(
    _$AppDatabase db,
    $PackSessionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackSessionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackSessionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackSessionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> listItemId = const Value.absent(),
                Value<DateTime?> packedAt = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackSessionItemsCompanion(
                sessionId: sessionId,
                listItemId: listItemId,
                packedAt: packedAt,
                skipped: skipped,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String listItemId,
                Value<DateTime?> packedAt = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackSessionItemsCompanion.insert(
                sessionId: sessionId,
                listItemId: listItemId,
                packedAt: packedAt,
                skipped: skipped,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackSessionItemsTable, PackSessionItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PackSessionItemsTable,
                    PackSessionItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackSessionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackSessionItemsTable,
      PackSessionItem,
      $$PackSessionItemsTableFilterComposer,
      $$PackSessionItemsTableOrderingComposer,
      $$PackSessionItemsTableAnnotationComposer,
      $$PackSessionItemsTableCreateCompanionBuilder,
      $$PackSessionItemsTableUpdateCompanionBuilder,
      (
        PackSessionItem,
        BaseReferences<_$AppDatabase, $PackSessionItemsTable, PackSessionItem>,
      ),
      PackSessionItem,
      PrefetchHooks Function()
    >;
typedef $$ForgotRecordsTableCreateCompanionBuilder =
    ForgotRecordsCompanion Function({
      required String id,
      required String globalItemId,
      Value<String?> sessionId,
      Value<String?> listId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ForgotRecordsTableUpdateCompanionBuilder =
    ForgotRecordsCompanion Function({
      Value<String> id,
      Value<String> globalItemId,
      Value<String?> sessionId,
      Value<String?> listId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ForgotRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ForgotRecordsTable> {
  $$ForgotRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ForgotRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ForgotRecordsTable> {
  $$ForgotRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ForgotRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ForgotRecordsTable> {
  $$ForgotRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get globalItemId => $composableBuilder(
    column: $table.globalItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ForgotRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ForgotRecordsTable,
          ForgotRecord,
          $$ForgotRecordsTableFilterComposer,
          $$ForgotRecordsTableOrderingComposer,
          $$ForgotRecordsTableAnnotationComposer,
          $$ForgotRecordsTableCreateCompanionBuilder,
          $$ForgotRecordsTableUpdateCompanionBuilder,
          (
            ForgotRecord,
            BaseReferences<_$AppDatabase, $ForgotRecordsTable, ForgotRecord>,
          ),
          ForgotRecord,
          PrefetchHooks Function()
        > {
  $$ForgotRecordsTableTableManager(_$AppDatabase db, $ForgotRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ForgotRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ForgotRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ForgotRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> globalItemId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ForgotRecordsCompanion(
                id: id,
                globalItemId: globalItemId,
                sessionId: sessionId,
                listId: listId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String globalItemId,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ForgotRecordsCompanion.insert(
                id: id,
                globalItemId: globalItemId,
                sessionId: sessionId,
                listId: listId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ForgotRecordsTable, ForgotRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ForgotRecordsTable,
                    ForgotRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ForgotRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ForgotRecordsTable,
      ForgotRecord,
      $$ForgotRecordsTableFilterComposer,
      $$ForgotRecordsTableOrderingComposer,
      $$ForgotRecordsTableAnnotationComposer,
      $$ForgotRecordsTableCreateCompanionBuilder,
      $$ForgotRecordsTableUpdateCompanionBuilder,
      (
        ForgotRecord,
        BaseReferences<_$AppDatabase, $ForgotRecordsTable, ForgotRecord>,
      ),
      ForgotRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChecklistListsTableTableManager get checklistLists =>
      $$ChecklistListsTableTableManager(_db, _db.checklistLists);
  $$GlobalItemsTableTableManager get globalItems =>
      $$GlobalItemsTableTableManager(_db, _db.globalItems);
  $$ListItemsTableTableManager get listItems =>
      $$ListItemsTableTableManager(_db, _db.listItems);
  $$PackSessionsTableTableManager get packSessions =>
      $$PackSessionsTableTableManager(_db, _db.packSessions);
  $$PackSessionItemsTableTableManager get packSessionItems =>
      $$PackSessionItemsTableTableManager(_db, _db.packSessionItems);
  $$ForgotRecordsTableTableManager get forgotRecords =>
      $$ForgotRecordsTableTableManager(_db, _db.forgotRecords);
}
