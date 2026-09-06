import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/focus_flow_models.dart';
import 'local/focus_flow_database.dart';

class FocusFlowRepository {
  FocusFlowRepository({FocusFlowDatabase? database, String? userId})
    : _database = database ?? FocusFlowDatabase(),
      _ownsDatabase = database == null,
      _currentUserId = userId {
    _snapshot = _seedSnapshot();
    _controller.add(_snapshot);
    ready = _loadOrSeedDatabase();
    unawaited(ready);
  }

  final _uuid = const Uuid();
  final _controller = StreamController<FocusFlowSnapshot>.broadcast();
  final FocusFlowDatabase _database;
  final bool _ownsDatabase;
  String? _currentUserId;
  late Future<void> ready;
  late FocusFlowSnapshot _snapshot;

  Stream<FocusFlowSnapshot> watchSnapshot() => _controller.stream;

  FocusFlowSnapshot get snapshot => _snapshot;

  /// Call this when the authenticated user changes (login/logout/switch account).
  /// Clears the in-memory snapshot and reloads only data belonging to [userId].
  /// Pass `null` for guest mode.
  Future<void> reloadForUser(String? userId) async {
    _currentUserId = userId;
    _snapshot = _seedSnapshot();
    _controller.add(_snapshot);
    ready = _loadOrSeedDatabase();
    await ready;
  }

  List<GoalProgress> get goalProgress {
    return _snapshot.goals.map((goal) {
      final tasks = _snapshot.tasks.where((task) => task.goalId == goal.id);
      if (tasks.isEmpty) {
        return GoalProgress(goal: goal, progress: 0);
      }
      final done = tasks.where((task) => task.status == ItemStatus.done).length;
      return GoalProgress(goal: goal, progress: done / tasks.length);
    }).toList();
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final now = DateTime.now();
      final goal = Goal(
        id: _uuid.v4(),
        title: title,
        description: description,
        typeId: typeId,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      );
      await _database
          .into(_database.goalRows)
          .insertOnConflictUpdate(_goalToCompanion(goal));
      _emit(_snapshot.copyWith(goals: [..._snapshot.goals, goal]));
    } catch (e) {
      debugPrint('Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String description,
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final now = DateTime.now();
      final goals = _snapshot.goals.map((goal) {
        if (goal.id != id) {
          return goal;
        }
        return goal.copyWith(
          title: title,
          description: description,
          typeId: typeId,
          startDate: startDate,
          endDate: endDate,
          updatedAt: now,
        );
      }).toList();
      final updatedGoal = goals.where((goal) => goal.id == id).firstOrNull;
      if (updatedGoal == null) return; // ID not found — nothing to persist
      await _database
          .into(_database.goalRows)
          .insertOnConflictUpdate(_goalToCompanion(updatedGoal));
      _emit(_snapshot.copyWith(goals: goals));
    } catch (e) {
      debugPrint('Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final now = DateTime.now();
      await (_database.update(_database.goalRows)
            ..where((goal) => goal.id.equals(goalId)))
          .write(GoalRowsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (_database.update(_database.taskRows)
            ..where((task) => task.goalId.equals(goalId)))
          .write(TaskRowsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      _emit(
        _snapshot.copyWith(
          goals: _snapshot.goals.where((goal) => goal.id != goalId).toList(),
          tasks: _snapshot.tasks.where((task) => task.goalId != goalId).toList(),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  Future<void> addGoalType({
    required String name,
    required String colorHex,
    required String iconCode,
  }) async {
    try {
      final now = DateTime.now();
      final type = CustomGoalType(
        id: _uuid.v4(),
        name: name,
        colorHex: colorHex,
        iconCode: iconCode,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      );
      await _database
          .into(_database.goalTypeRows)
          .insertOnConflictUpdate(_goalTypeToCompanion(type));
      _emit(_snapshot.copyWith(goalTypes: [..._snapshot.goalTypes, type]));
    } catch (e) {
      debugPrint('Error adding goal type: $e');
      rethrow;
    }
  }

  Future<void> updateGoalType({
    required String id,
    required String name,
    required String colorHex,
    required String iconCode,
  }) async {
    try {
      final now = DateTime.now();
      final types = _snapshot.goalTypes.map((type) {
        if (type.id != id) return type;
        return type.copyWith(
          name: name,
          colorHex: colorHex,
          iconCode: iconCode,
          updatedAt: now,
        );
      }).toList();
      final updatedType = types.where((type) => type.id == id).firstOrNull;
      if (updatedType == null) return; // ID not found — nothing to persist
      await _database
          .into(_database.goalTypeRows)
          .insertOnConflictUpdate(_goalTypeToCompanion(updatedType));
      _emit(_snapshot.copyWith(goalTypes: types));
    } catch (e) {
      debugPrint('Error updating goal type: $e');
      rethrow;
    }
  }

  Future<void> deleteGoalType(String typeId) async {
    try {
      final now = DateTime.now();

      // Soft delete the goal type
      await (_database.update(
        _database.goalTypeRows,
      )..where((type) => type.id.equals(typeId))).write(
        GoalTypeRowsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      // Fallback reassignment for goals
      await (_database.update(
        _database.goalRows,
      )..where((goal) => goal.typeId.equals(typeId))).write(
        GoalRowsCompanion(typeId: const Value('other'), updatedAt: Value(now)),
      );

      final newGoals = _snapshot.goals.map((goal) {
        if (goal.typeId == typeId) {
          return goal.copyWith(typeId: 'other', updatedAt: now);
        }
        return goal;
      }).toList();

      _emit(
        _snapshot.copyWith(
          goalTypes: _snapshot.goalTypes
              .where((type) => type.id != typeId)
              .toList(),
          goals: newGoals,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting goal type: $e');
      rethrow;
    }
  }

  Future<void> addTask({
    required String goalId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int reminderIntervalMinutes,
  }) async {
    try {
      final now = DateTime.now();
      final task = FocusTask(
        id: _uuid.v4(),
        goalId: goalId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        reminderIntervalMinutes: reminderIntervalMinutes,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      );
      await _database
          .into(_database.taskRows)
          .insertOnConflictUpdate(_taskToCompanion(task));
      _emit(_snapshot.copyWith(tasks: [..._snapshot.tasks, task]));
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask({
    required String id,
    required String goalId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int reminderIntervalMinutes,
  }) async {
    try {
      final now = DateTime.now();
      await _updateTask(
        id,
        (task, _) => task.copyWith(
          goalId: goalId,
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          reminderIntervalMinutes: reminderIntervalMinutes,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskReminder(String taskId) async {
    try {
      await _updateTask(
        taskId,
        (task, now) => task.copyWith(
          lastReminderAt: now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error updating task reminder: $e');
      rethrow;
    }
  }

  Future<void> startTask(String taskId) async {
    try {
      await _updateTask(
        taskId,
        (task, now) => task.copyWith(
          status: ItemStatus.inProgress,
          startedAt: task.startedAt ?? now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error starting task: $e');
      rethrow;
    }
  }

  Future<void> pauseTask(String taskId) async {
    try {
      await _updateTask(
        taskId,
        (task, now) => task.copyWith(
          status: ItemStatus.notYet,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error pausing task: $e');
      rethrow;
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await _updateTask(
        taskId,
        (task, now) => task.copyWith(
          status: ItemStatus.done,
          completedAt: task.completedAt ?? now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Error completing task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final now = DateTime.now();
      await (_database.update(_database.taskRows)
            ..where((task) => task.id.equals(taskId)))
          .write(TaskRowsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      _emit(
        _snapshot.copyWith(
          tasks: _snapshot.tasks.where((task) => task.id != taskId).toList(),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  void dispose() {
    _controller.close();
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
  }

  Future<void> _updateTask(
    String taskId,
    FocusTask Function(FocusTask task, DateTime now) update,
  ) async {
    try {
      final now = DateTime.now();
      final tasks = _snapshot.tasks.map((task) {
        if (task.id != taskId) {
          return task;
        }
        return update(task, now);
      }).toList();
      final updatedTask = tasks.where((task) => task.id == taskId).firstOrNull;
      if (updatedTask == null) return; // ID not found — nothing to persist
      await _database
          .into(_database.taskRows)
          .insertOnConflictUpdate(_taskToCompanion(updatedTask));
      _emit(_snapshot.copyWith(tasks: tasks));
    } catch (e) {
      debugPrint('Error in _updateTask: $e');
      rethrow;
    }
  }

  void Function()? onDataChanged;

  void _emit(FocusFlowSnapshot snapshot) {
    _snapshot = _syncGoalStatuses(snapshot);
    _controller.add(_snapshot);
    onDataChanged?.call();
  }

  FocusFlowSnapshot _syncGoalStatuses(FocusFlowSnapshot snapshot) {
    final goals = snapshot.goals.map((goal) {
      final tasks = snapshot.tasks.where((task) => task.goalId == goal.id);
      final ItemStatus status;
      if (tasks.isEmpty) {
        status = ItemStatus.notYet;
      } else if (tasks.every((task) => task.status == ItemStatus.done)) {
        status = ItemStatus.done;
      } else if (tasks.every((task) => task.status == ItemStatus.notYet)) {
        status = ItemStatus.notYet;
      } else {
        status = ItemStatus.inProgress;
      }

      if (goal.status == status) {
        return goal;
      }

      final newGoal = goal.copyWith(status: status, updatedAt: DateTime.now());
      unawaited(_database.into(_database.goalRows).insertOnConflictUpdate(_goalToCompanion(newGoal)));
      return newGoal;
    }).toList();

    return FocusFlowSnapshot(
      goals: goals,
      tasks: snapshot.tasks,
      goalTypes: snapshot.goalTypes,
    );
  }

  FocusFlowSnapshot _seedSnapshot() {
    final now = DateTime.now();

    final goalTypes = [
      CustomGoalType(
        id: 'personal',
        name: 'Personal',
        colorHex: '#16A34A',
        iconCode: 'person_outline_rounded',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      CustomGoalType(
        id: 'work',
        name: 'Work',
        colorHex: '#5048E5',
        iconCode: 'business_center_outlined',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      CustomGoalType(
        id: 'study',
        name: 'Study',
        colorHex: '#F59E0B',
        iconCode: 'school_outlined',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      CustomGoalType(
        id: 'fitness',
        name: 'Fitness',
        colorHex: '#EC4899',
        iconCode: 'fitness_center_rounded',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      CustomGoalType(
        id: 'other',
        name: 'Other',
        colorHex: '#8B95A7',
        iconCode: 'category_outlined',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return FocusFlowSnapshot(
      goals: const [],
      tasks: const [],
      goalTypes: goalTypes,
    );
  }

  Future<void> _loadOrSeedDatabase() async {
    // Migrate old 'development' goal type to 'other' if present in DB
    await (_database.update(_database.goalRows)
          ..where((row) => row.typeId.equals('development')))
        .write(GoalRowsCompanion(typeId: const Value('other'), updatedAt: Value(DateTime.now())));

    await (_database.delete(_database.goalTypeRows)
          ..where((row) => row.id.equals('development')))
        .go();

    // Always seed/update default goal types
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.goalTypeRows,
        _snapshot.goalTypes.map(_goalTypeToCompanion).toList(),
      );
    });

    // Reload filtered data for the current user.
    // Guest (null) sees only rows with userId IS NULL.
    // Authenticated users see only rows with their userId.
    final goalRows = await (_database.select(_database.goalRows)
          ..where(
            (row) => _currentUserId == null
                ? row.userId.isNull()
                : row.userId.equals(_currentUserId!),
          ))
        .get();

    final taskRows = await (_database.select(_database.taskRows)
          ..where(
            (row) => _currentUserId == null
                ? row.userId.isNull()
                : row.userId.equals(_currentUserId!),
          ))
        .get();

    // Goal types are global (seeded defaults + user-created custom types)
    final typeRows = await (_database.select(_database.goalTypeRows)
          ..where(
            (row) => row.userId.isNull() |
                (_currentUserId != null
                    ? row.userId.equals(_currentUserId!)
                    : row.userId.isNull()),
          ))
        .get();

    UserProfile? userProfile;
    if (_currentUserId != null) {
      final profileRow = await (_database.select(_database.userProfileRows)
            ..where((row) => row.id.equals(_currentUserId!)))
          .getSingleOrNull();
      if (profileRow != null) {
        userProfile = _userProfileFromRow(profileRow);
      }
    }

    _emit(
      FocusFlowSnapshot(
        goalTypes: typeRows
            .where((row) => row.deletedAt == null)
            .map(_goalTypeFromRow)
            .toList(),
        goals: goalRows
            .where((row) => row.deletedAt == null)
            .map(_goalFromRow)
            .toList(),
        tasks: taskRows
            .where((row) => row.deletedAt == null)
            .map(_taskFromRow)
            .toList(),
        userProfile: userProfile,
      ),
    );
  }

  Future<void> upsertGoal(Goal goal) async {
    try {
      await _database.into(_database.goalRows).insertOnConflictUpdate(_goalToCompanion(goal));
      final List<Goal> updatedGoals;
      final isForCurrentUser = goal.userId == _currentUserId;
      if (!isForCurrentUser || goal.deletedAt != null) {
        updatedGoals = _snapshot.goals.where((g) => g.id != goal.id).toList();
      } else {
        final exists = _snapshot.goals.any((g) => g.id == goal.id);
        updatedGoals = exists
            ? [for (final g in _snapshot.goals) if (g.id == goal.id) goal else g]
            : [..._snapshot.goals, goal];
      }
      _emit(_snapshot.copyWith(goals: updatedGoals));
    } catch (e) {
      debugPrint('Error upserting goal: $e');
      rethrow;
    }
  }

  Future<void> upsertGoalType(CustomGoalType type) async {
    try {
      await _database.into(_database.goalTypeRows).insertOnConflictUpdate(_goalTypeToCompanion(type));
      final List<CustomGoalType> updatedTypes;
      final isForCurrentUser = type.userId == null || type.userId == _currentUserId;
      if (!isForCurrentUser || type.deletedAt != null) {
        updatedTypes = _snapshot.goalTypes.where((t) => t.id != type.id).toList();
      } else {
        final exists = _snapshot.goalTypes.any((t) => t.id == type.id);
        updatedTypes = exists
            ? [for (final t in _snapshot.goalTypes) if (t.id == type.id) type else t]
            : [..._snapshot.goalTypes, type];
      }
      _emit(_snapshot.copyWith(goalTypes: updatedTypes));
    } catch (e) {
      debugPrint('Error upserting goal type: $e');
      rethrow;
    }
  }

  Future<void> upsertTask(FocusTask task) async {
    try {
      await _database.into(_database.taskRows).insertOnConflictUpdate(_taskToCompanion(task));
      final List<FocusTask> updatedTasks;
      final isForCurrentUser = task.userId == _currentUserId;
      if (!isForCurrentUser || task.deletedAt != null) {
        updatedTasks = _snapshot.tasks.where((t) => t.id != task.id).toList();
      } else {
        final exists = _snapshot.tasks.any((t) => t.id == task.id);
        updatedTasks = exists
            ? [for (final t in _snapshot.tasks) if (t.id == task.id) task else t]
            : [..._snapshot.tasks, task];
      }
      _emit(_snapshot.copyWith(tasks: updatedTasks));
    } catch (e) {
      debugPrint('Error upserting task: $e');
      rethrow;
    }
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    try {
      await _database.into(_database.userProfileRows).insertOnConflictUpdate(_userProfileToCompanion(profile));
      _emit(_snapshot.copyWith(userProfile: profile));
    } catch (e) {
      debugPrint('Error upserting user profile: $e');
      rethrow;
    }
  }

  Future<List<Goal>> getAllGoalsForSync({DateTime? since, required String userId}) async {
    final query = _database.select(_database.goalRows)
      ..where((row) => row.userId.equals(userId) | row.userId.isNull());
    if (since != null) {
      query.where((row) => row.updatedAt.isBiggerOrEqualValue(since));
    }
    final rows = await query.get();
    return rows.map(_goalFromRow).toList();
  }

  Future<List<FocusTask>> getAllTasksForSync({DateTime? since, required String userId}) async {
    final query = _database.select(_database.taskRows)
      ..where((row) => row.userId.equals(userId) | row.userId.isNull());
    if (since != null) {
      query.where((row) => row.updatedAt.isBiggerOrEqualValue(since));
    }
    final rows = await query.get();
    return rows.map(_taskFromRow).toList();
  }

  Future<List<CustomGoalType>> getAllGoalTypesForSync({DateTime? since, required String userId}) async {
    final query = _database.select(_database.goalTypeRows)
      ..where((row) => row.userId.equals(userId) | (row.userId.isNull() & row.isDefault.equals(false)));
    if (since != null) {
      query.where((row) => row.updatedAt.isBiggerOrEqualValue(since));
    }
    final rows = await query.get();
    return rows.map(_goalTypeFromRow).toList();
  }
}

Goal _goalFromRow(GoalRow row) {
  return Goal(
    id: row.id,
    title: row.title,
    description: row.description,
    typeId: row.typeId,
    status: ItemStatus.values.firstWhere(
      (e) => e.name == row.status,
      orElse: () => ItemStatus.notYet,
    ),
    startDate: row.startDate,
    endDate: row.endDate,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    userId: row.userId,
  );
}

FocusTask _taskFromRow(TaskRow row) {
  return FocusTask(
    id: row.id,
    goalId: row.goalId,
    title: row.title,
    description: row.description,
    status: ItemStatus.values.firstWhere(
      (e) => e.name == row.status,
      orElse: () => ItemStatus.notYet,
    ),
    startDate: row.startDate,
    endDate: row.endDate,
    reminderIntervalMinutes: row.reminderIntervalMinutes,
    startedAt: row.startedAt,
    completedAt: row.completedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    userId: row.userId,
    lastReminderAt: row.lastReminderAt,
  );
}

GoalRowsCompanion _goalToCompanion(Goal goal) {
  return GoalRowsCompanion(
    id: Value(goal.id),
    title: Value(goal.title),
    description: Value(goal.description),
    typeId: Value(goal.typeId),
    status: Value(goal.status.name),
    startDate: Value(goal.startDate),
    endDate: Value(goal.endDate),
    createdAt: Value(goal.createdAt),
    updatedAt: Value(goal.updatedAt),
    deletedAt: Value(goal.deletedAt),
    userId: Value(goal.userId),
  );
}

TaskRowsCompanion _taskToCompanion(FocusTask task) {
  return TaskRowsCompanion(
    id: Value(task.id),
    goalId: Value(task.goalId),
    title: Value(task.title),
    description: Value(task.description),
    status: Value(task.status.name),
    startDate: Value(task.startDate),
    endDate: Value(task.endDate),
    reminderIntervalMinutes: Value(task.reminderIntervalMinutes),
    startedAt: Value(task.startedAt),
    completedAt: Value(task.completedAt),
    createdAt: Value(task.createdAt),
    updatedAt: Value(task.updatedAt),
    deletedAt: Value(task.deletedAt),
    userId: Value(task.userId),
    lastReminderAt: Value(task.lastReminderAt),
  );
}

CustomGoalType _goalTypeFromRow(GoalTypeRow row) {
  return CustomGoalType(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    iconCode: row.iconCode,
    isDefault: row.isDefault,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    userId: row.userId,
  );
}

GoalTypeRowsCompanion _goalTypeToCompanion(CustomGoalType type) {
  return GoalTypeRowsCompanion(
    id: Value(type.id),
    name: Value(type.name),
    colorHex: Value(type.colorHex),
    iconCode: Value(type.iconCode),
    isDefault: Value(type.isDefault),
    createdAt: Value(type.createdAt),
    updatedAt: Value(type.updatedAt),
    deletedAt: Value(type.deletedAt),
    userId: Value(type.userId),
  );
}

UserProfile _userProfileFromRow(UserProfileRow row) {
  return UserProfile(
    id: row.id,
    fullName: row.fullName,
    firstName: row.firstName,
    lastName: row.lastName,
    email: row.email,
    avatarUrl: row.avatarUrl,
    avatarType: row.avatarType,
    avatarAsset: row.avatarAsset,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

UserProfileRowsCompanion _userProfileToCompanion(UserProfile profile) {
  return UserProfileRowsCompanion(
    id: Value(profile.id),
    fullName: Value(profile.fullName),
    firstName: Value(profile.firstName),
    lastName: Value(profile.lastName),
    email: Value(profile.email),
    avatarUrl: Value(profile.avatarUrl),
    avatarType: Value(profile.avatarType),
    avatarAsset: Value(profile.avatarAsset),
    createdAt: Value(profile.createdAt),
    updatedAt: Value(profile.updatedAt),
  );
}

extension on FocusFlowSnapshot {
  FocusFlowSnapshot copyWith({
    List<Goal>? goals,
    List<FocusTask>? tasks,
    List<CustomGoalType>? goalTypes,
    UserProfile? userProfile,
    bool clearUserProfile = false,
  }) {
    return FocusFlowSnapshot(
      goals: goals ?? this.goals,
      tasks: tasks ?? this.tasks,
      goalTypes: goalTypes ?? this.goalTypes,
      userProfile: clearUserProfile ? null : (userProfile ?? this.userProfile),
    );
  }
}
