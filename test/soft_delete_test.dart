import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/features/dashboard/presentation/cubit/dashboard_cubit.dart';

void main() {
  FocusFlowDatabase createDatabase() {
    final database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    return database;
  }

  FocusFlowRepository createRepository({FocusFlowDatabase? database}) {
    final db = database ?? createDatabase();
    final repository = FocusFlowRepository(database: db);
    addTearDown(repository.dispose);
    return repository;
  }

  test(
    'soft-deleted goal is hidden from snapshot but remains in Drift',
    () async {
      final database = createDatabase();
      final repository = createRepository(database: database);
      await repository.ready;

      await repository.addGoal(
        title: 'Master React Native',
        description: 'Test goal',
        typeId: 'work',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      final goalId = repository.snapshot.goals
          .firstWhere((goal) => goal.title == 'Master React Native')
          .id;

      await repository.deleteGoal(goalId);
      await Future<void>.delayed(Duration.zero);

      // Goal is hidden from the snapshot.
      expect(
        repository.snapshot.goals.any((goal) => goal.id == goalId),
        isFalse,
      );

      // Tombstone row remains in the database.
      final rows = await database.select(database.goalRows).get();
      final tombstone = rows.where((row) => row.id == goalId);
      expect(tombstone, hasLength(1));
      expect(tombstone.first.deletedAt, isNotNull);
    },
  );

  test('soft-deleting a goal also soft-deletes its child tasks', () async {
    final database = createDatabase();
    final repository = createRepository(database: database);
    await repository.ready;

    await repository.addGoal(
      title: 'Master React Native',
      description: 'Test goal',
      typeId: 'work',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    final goalId = repository.snapshot.goals
        .firstWhere((goal) => goal.title == 'Master React Native')
        .id;

    await repository.addTask(
      goalId: goalId,
      title: 'Test Task',
      description: 'Test task description',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      reminderIntervalMinutes: 15,
    );

    final childTaskIds = repository.snapshot.tasks
        .where((task) => task.goalId == goalId)
        .map((task) => task.id)
        .toList();
    expect(childTaskIds, isNotEmpty);

    await repository.deleteGoal(goalId);
    await Future<void>.delayed(Duration.zero);

    // Child tasks are hidden from the snapshot.
    for (final taskId in childTaskIds) {
      expect(
        repository.snapshot.tasks.any((task) => task.id == taskId),
        isFalse,
      );
    }

    // Tombstone rows remain in the database.
    final taskRows = await database.select(database.taskRows).get();
    for (final taskId in childTaskIds) {
      final tombstone = taskRows.where((row) => row.id == taskId);
      expect(tombstone, hasLength(1));
      expect(tombstone.first.deletedAt, isNotNull);
    }
  });

  test(
    'soft-deleted task is hidden from snapshot but remains in Drift',
    () async {
      final database = createDatabase();
      final repository = createRepository(database: database);
      await repository.ready;

      await repository.addGoal(
        title: 'Master React Native',
        description: 'Test goal',
        typeId: 'work',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      await repository.addTask(
        goalId: goalId,
        title: 'Test Task',
        description: 'Test task description',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        reminderIntervalMinutes: 15,
      );
      final taskId = repository.snapshot.tasks.first.id;

      await repository.deleteTask(taskId);
      await Future<void>.delayed(Duration.zero);

      // Task is hidden from the snapshot.
      expect(
        repository.snapshot.tasks.any((task) => task.id == taskId),
        isFalse,
      );

      // Tombstone row remains in the database.
      final rows = await database.select(database.taskRows).get();
      final tombstone = rows.where((row) => row.id == taskId);
      expect(tombstone, hasLength(1));
      expect(tombstone.first.deletedAt, isNotNull);
    },
  );

  test('dashboard counts exclude soft-deleted records', () async {
    final repository = createRepository();
    await repository.ready;

    await repository.addGoal(
      title: 'Test Goal',
      description: 'Test goal description',
      typeId: 'work',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
    final goalId = repository.snapshot.goals.first.id;

    await repository.addTask(
      goalId: goalId,
      title: 'Test Task',
      description: 'Test task description',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      reminderIntervalMinutes: 15,
    );

    final cubit = DashboardCubit(repository);
    addTearDown(cubit.close);

    final initialGoals = cubit.state.totalGoals;
    final initialTasks = cubit.state.totalTasks;

    final childTaskCount = repository.snapshot.tasks
        .where((task) => task.goalId == goalId)
        .length;

    await repository.deleteGoal(goalId);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.totalGoals, initialGoals - 1);
    expect(cubit.state.totalTasks, initialTasks - childTaskCount);
  });

  test('second repository load filters out soft-deleted rows', () async {
    final database = createDatabase();
    final firstRepository = createRepository(database: database);
    await firstRepository.ready;

    await firstRepository.addGoal(
      title: 'Master React Native',
      description: 'Test goal',
      typeId: 'work',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    final goalId = firstRepository.snapshot.goals
        .firstWhere((goal) => goal.title == 'Master React Native')
        .id;

    await firstRepository.deleteGoal(goalId);
    await Future<void>.delayed(Duration.zero);

    // Second repository on the same database.
    final secondRepository = createRepository(database: database);
    await secondRepository.ready;

    // Deleted goal is not in the new snapshot.
    expect(
      secondRepository.snapshot.goals.any((goal) => goal.id == goalId),
      isFalse,
    );

    // But tombstone persists in the database.
    final rows = await database.select(database.goalRows).get();
    final tombstone = rows.where((row) => row.id == goalId);
    expect(tombstone, hasLength(1));
    expect(tombstone.first.deletedAt, isNotNull);
  });
}
