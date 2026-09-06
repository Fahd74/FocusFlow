import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'focus_flow_database.g.dart';

class GoalRows extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get typeId => text().references(GoalTypeRows, #id)();
  TextColumn get status => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GoalTypeRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  TextColumn get iconCode => text()();
  BoolColumn get isDefault => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskRows extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(GoalRows, #id)();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get status => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get reminderIntervalMinutes => integer()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get lastReminderAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserProfileRows extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get email => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get avatarType => text().nullable()();
  TextColumn get avatarAsset => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncMetadataRows extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text()();
  TextColumn get rowId => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [GoalRows, TaskRows, GoalTypeRows, SyncMetadataRows, UserProfileRows])
class FocusFlowDatabase extends _$FocusFlowDatabase {
  FocusFlowDatabase() : super(_openConnection());

  FocusFlowDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await customStatement('''
          INSERT OR IGNORE INTO goal_type_rows (id, name, color_hex, icon_code, is_default, created_at, updated_at) VALUES 
          ('personal', 'Personal', '#16A34A', 'person_outline_rounded', 1, $now, $now),
          ('work', 'Work', '#5048E5', 'business_center_outlined', 1, $now, $now),
          ('study', 'Study', '#F59E0B', 'school_outlined', 1, $now, $now),
          ('fitness', 'Fitness', '#EC4899', 'fitness_center_rounded', 1, $now, $now),
          ('other', 'Other', '#8B95A7', 'category_outlined', 1, $now, $now)
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          final goalCols = await _getTableColumnNames('goal_rows');
          if (!goalCols.contains('user_id')) {
            await customStatement('ALTER TABLE goal_rows ADD COLUMN user_id TEXT');
          }
          final taskCols = await _getTableColumnNames('task_rows');
          if (!taskCols.contains('user_id')) {
            await customStatement('ALTER TABLE task_rows ADD COLUMN user_id TEXT');
          }
          if (!taskCols.contains('last_reminder_at')) {
            await customStatement('ALTER TABLE task_rows ADD COLUMN last_reminder_at INTEGER');
          }
          if (!await _hasTable('sync_metadata_rows')) {
            await m.createTable(syncMetadataRows);
          }
        }
        if (from < 3) {
          if (!await _hasTable('goal_type_rows')) {
            await m.createTable(goalTypeRows);
          }

          // Seed defaults
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await customStatement('''
            INSERT OR IGNORE INTO goal_type_rows (id, name, color_hex, icon_code, is_default, created_at, updated_at) VALUES 
            ('personal', 'Personal', '#16A34A', 'person_outline_rounded', 1, $now, $now),
            ('work', 'Work', '#5048E5', 'business_center_outlined', 1, $now, $now),
            ('study', 'Study', '#F59E0B', 'school_outlined', 1, $now, $now),
            ('fitness', 'Fitness', '#EC4899', 'fitness_center_rounded', 1, $now, $now),
            ('other', 'Other', '#8B95A7', 'category_outlined', 1, $now, $now)
          ''');

          final goalCols = await _getTableColumnNames('goal_rows');
          if (goalCols.contains('type') && !goalCols.contains('type_id')) {
            await m.alterTable(
              TableMigration(
                goalRows,
                columnTransformer: {
                  goalRows.typeId: const CustomExpression('type'),
                },
              ),
            );
          }
        }
        if (from < 4) {
          if (!await _hasTable('user_profile_rows')) {
            await m.createTable(userProfileRows);
          }
        }
        if (from < 5) {
          final profileCols = await _getTableColumnNames('user_profile_rows');
          if (!profileCols.contains('first_name')) {
            await m.addColumn(userProfileRows, userProfileRows.firstName);
          }
          if (!profileCols.contains('last_name')) {
            await m.addColumn(userProfileRows, userProfileRows.lastName);
          }
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<Set<String>> _getTableColumnNames(String tableName) async {
    try {
      final rows = await customSelect("PRAGMA table_info('$tableName')").get();
      return rows.map((row) => row.read<String>('name')).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> _hasTable(String tableName) async {
    try {
      final rows = await customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
      ).get();
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDocuments = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDocuments.path, 'focus_flow.sqlite'));
    return NativeDatabase.createInBackground(dbFile);
  });
}
