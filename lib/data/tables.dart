import 'package:drift/drift.dart';

class ChecklistLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(max: 12)();
  TextColumn get emoji => text()();
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  TextColumn get mnemonic => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get reminderTime => text().nullable()();
  TextColumn get reminderWeekdays => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class GlobalItems extends Table {
  TextColumn get id => text()();
  TextColumn get normalizedName => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get emoji => text()();
  IntColumn get forgotCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastForgotAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ListItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get globalItemId => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PackSessions extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get status => text()(); // in_progress, completed, departed, departed_incomplete, abandoned
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get departedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PackSessionItems extends Table {
  TextColumn get sessionId => text()();
  TextColumn get listItemId => text()();
  DateTimeColumn get packedAt => dateTime().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {sessionId, listItemId};
}

class ForgotRecords extends Table {
  TextColumn get id => text()();
  TextColumn get globalItemId => text()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get listId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
