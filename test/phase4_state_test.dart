import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/focus_flow_models.dart';
import 'package:focus_flow/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:focus_flow/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:focus_flow/features/tasks/presentation/cubit/tasks_cubit.dart';

void main() {
  Future<void> seedMockData(FocusFlowDatabase db) async {
    final now = DateTime.now();

    await db.into(db.goalRows).insert(
      GoalRowsCompanion.insert(
        id: 'goal-react-native',
        title: 'Master React Native',
        description: 'Complete the advanced course and build 3 apps.',
        typeId: 'work',
        status: 'inProgress',
        startDate: now.subtract(const Duration(days: 18)),
        endDate: now.add(const Duration(days: 42)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.goalRows).insert(
      GoalRowsCompanion.insert(
        id: 'goal-campaign',
        title: 'Launch Q4 Marketing Campaign',
        description: 'Finalize creatives and publish the campaign.',
        typeId: 'fitness',
        status: 'inProgress',
        startDate: now.subtract(const Duration(days: 8)),
        endDate: now.add(const Duration(days: 20)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.goalRows).insert(
      GoalRowsCompanion.insert(
        id: 'goal-reading',
        title: 'Read 12 Non-Fiction Books',
        description: 'Focus on management, productivity, and growth.',
        typeId: 'personal',
        status: 'inProgress',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 90)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.into(db.taskRows).insert(
      TaskRowsCompanion.insert(
        id: 'task-setup',
        goalId: 'goal-react-native',
        title: 'Setup project environment',
        description: 'Create the base app structure and install dependencies.',
        status: 'done',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 7)),
        reminderIntervalMinutes: 30,
        completedAt: Value(now.subtract(const Duration(days: 7))),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.taskRows).insert(
      TaskRowsCompanion.insert(
        id: 'task-auth',
        goalId: 'goal-react-native',
        title: 'Build authentication flow',
        description: 'Connect login, signup, and password reset screens.',
        status: 'inProgress',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 4)),
        reminderIntervalMinutes: 15,
        startedAt: Value(now.subtract(const Duration(days: 1))),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.taskRows).insert(
      TaskRowsCompanion.insert(
        id: 'task-mockups',
        goalId: 'goal-campaign',
        title: 'Design high-fidelity mockups',
        description: 'Prepare final UI screens for mobile and desktop.',
        status: 'notYet',
        startDate: now,
        endDate: now.add(const Duration(days: 6)),
        reminderIntervalMinutes: 60,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.taskRows).insert(
      TaskRowsCompanion.insert(
        id: 'task-budget',
        goalId: 'goal-campaign',
        title: 'Review Q3 budget draft',
        description: 'Check spend, blockers, and remaining approvals.',
        status: 'inProgress',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.subtract(const Duration(days: 1)),
        reminderIntervalMinutes: 30,
        startedAt: Value(now.subtract(const Duration(days: 2))),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.taskRows).insert(
      TaskRowsCompanion.insert(
        id: 'task-book',
        goalId: 'goal-reading',
        title: 'Finish Atomic Habits notes',
        description: 'Summarize the useful practices into personal rules.',
        status: 'done',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.subtract(const Duration(days: 1)),
        reminderIntervalMinutes: 120,
        completedAt: Value(now.subtract(const Duration(days: 1))),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<FocusFlowRepository> createRepository() async {
    final database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await seedMockData(database);
    final repo = FocusFlowRepository(database: database);
    addTearDown(repo.dispose);
    await repo.ready;
    return repo;
  }

  test('seeded goal progress is calculated from child tasks', () async {
    final repository = await createRepository();

    final progressById = {
      for (final item in repository.goalProgress) item.goal.id: item.progress,
    };

    expect(progressById['goal-react-native'], 0.5);
    expect(progressById['goal-campaign'], 0);
    expect(progressById['goal-reading'], 1);
  });

  test('new goals default to not yet', () async {
    final repository = await createRepository();
    final cubit = GoalsCubit(repository);
    addTearDown(cubit.close);

    await cubit.addGoal(
      title: 'Ship Phase 4',
      description: 'Connect presentation state to app data.',
      typeId: 'fitness',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
    );
    await Future<void>.delayed(Duration.zero);

    final created = cubit.state.goals.last;
    expect(created.title, 'Ship Phase 4');
    expect(created.status, ItemStatus.notYet);
  });

  test('BUG4 - goal status follows child tasks dynamically', () async {
    final repository = await createRepository();
    final goalsCubit = GoalsCubit(repository);
    final tasksCubit = TasksCubit(repository);
    addTearDown(goalsCubit.close);
    addTearDown(tasksCubit.close);

    // Create a new goal.
    await goalsCubit.addGoal(
      title: 'Bug4 Goal',
      description: 'Goal to test status transitions.',
      typeId: 'fitness',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
    );
    await Future<void>.delayed(Duration.zero);

    var goal = goalsCubit.state.goals.firstWhere((g) => g.title == 'Bug4 Goal');
    // Initially, it has no tasks, so it should be notYet.
    expect(goal.status, ItemStatus.notYet);

    // Add a task to this goal (default status notYet).
    await tasksCubit.addTask(
      goalId: goal.id,
      title: 'Task 1',
      description: 'First task',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 15),
      reminderIntervalMinutes: 60,
    );
    await Future<void>.delayed(Duration.zero);

    goal = goalsCubit.state.goals.firstWhere((g) => g.id == goal.id);
    // Since Task 1 is notYet, goal status should still be notYet.
    expect(goal.status, ItemStatus.notYet);

    // Add another task to this goal.
    await tasksCubit.addTask(
      goalId: goal.id,
      title: 'Task 2',
      description: 'Second task',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 15),
      reminderIntervalMinutes: 60,
    );
    await Future<void>.delayed(Duration.zero);

    var t1 = tasksCubit.state.tasks.firstWhere((t) => t.title == 'Task 1' && t.goalId == goal.id);
    var t2 = tasksCubit.state.tasks.firstWhere((t) => t.title == 'Task 2' && t.goalId == goal.id);

    // Start Task 1 -> goal should become inProgress.
    await tasksCubit.startTask(t1.id);
    await Future<void>.delayed(Duration.zero);

    goal = goalsCubit.state.goals.firstWhere((g) => g.id == goal.id);
    expect(goal.status, ItemStatus.inProgress);

    // Complete Task 1 (t2 is still notYet) -> goal status should still be inProgress.
    await tasksCubit.completeTask(t1.id);
    await Future<void>.delayed(Duration.zero);

    goal = goalsCubit.state.goals.firstWhere((g) => g.id == goal.id);
    expect(goal.status, ItemStatus.inProgress);

    // Complete Task 2 (now all tasks are done) -> goal status should become done.
    await tasksCubit.completeTask(t2.id);
    await Future<void>.delayed(Duration.zero);

    goal = goalsCubit.state.goals.firstWhere((g) => g.id == goal.id);
    expect(goal.status, ItemStatus.done);
  });

  test('task filters and status transitions update cubit state', () async {
    final repository = await createRepository();
    final cubit = TasksCubit(repository);
    addTearDown(cubit.close);

    cubit.setStatusFilter(TaskStatusFilter.notYet);
    expect(cubit.state.visibleTasks.map((task) => task.id), ['task-mockups']);

    await cubit.startTask('task-mockups');
    await Future<void>.delayed(Duration.zero);

    final started = cubit.state.tasks.firstWhere(
      (task) => task.id == 'task-mockups',
    );
    expect(started.status, ItemStatus.inProgress);
    expect(started.startedAt, isNotNull);
    expect(cubit.state.visibleTasks, isEmpty);
  });

  test('dashboard counts react to task completion', () async {
    final repository = await createRepository();
    final cubit = DashboardCubit(repository);
    addTearDown(cubit.close);

    expect(cubit.state.totalGoals, 3);
    expect(cubit.state.totalTasks, 5);
    expect(cubit.state.tasksDone, 2);
    expect(cubit.state.overdueTasks, 1);

    await repository.completeTask('task-budget');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tasksDone, 3);
    expect(cubit.state.overdueTasks, 0);
  });

  test('goal update and delete mutate shared state', () async {
    final repository = await createRepository();
    final cubit = GoalsCubit(repository);
    addTearDown(cubit.close);

    await cubit.updateGoal(
      id: 'goal-reading',
      title: 'Read 18 Non-Fiction Books',
      description: 'Updated reading target.',
      typeId: 'study',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      cubit.state.goals.firstWhere((goal) => goal.id == 'goal-reading').title,
      'Read 18 Non-Fiction Books',
    );

    await cubit.deleteGoal('goal-reading');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.goals.any((goal) => goal.id == 'goal-reading'), isFalse);
    expect(
      repository.snapshot.tasks.any((task) => task.goalId == 'goal-reading'),
      isFalse,
    );
  });

  test(
    'task update keeps existing status while changing editable fields',
    () async {
      final repository = await createRepository();
      final cubit = TasksCubit(repository);
      addTearDown(cubit.close);

      await cubit.updateTask(
        id: 'task-auth',
        goalId: 'goal-campaign',
        title: 'Reconnect auth flow',
        description: 'Move task under campaign goal for test.',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 10),
        reminderIntervalMinutes: 120,
      );
      await Future<void>.delayed(Duration.zero);

      final updated = cubit.state.tasks.firstWhere(
        (task) => task.id == 'task-auth',
      );
      expect(updated.goalId, 'goal-campaign');
      expect(updated.title, 'Reconnect auth flow');
      expect(updated.status, ItemStatus.inProgress);
      expect(updated.reminderIntervalMinutes, 120);
    },
  );

  test('repository reloads persisted rows from Drift database', () async {
    final database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final firstRepository = FocusFlowRepository(database: database);
    addTearDown(firstRepository.dispose);
    await firstRepository.ready;

    await firstRepository.addGoal(
      title: 'Persisted Goal',
      description: 'Stored in Drift.',
      typeId: 'work',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 31),
    );
    final persistedGoalId = firstRepository.snapshot.goals.last.id;
    await firstRepository.addTask(
      goalId: persistedGoalId,
      title: 'Persisted Task',
      description: 'Stored with parent goal.',
      startDate: DateTime(2026, 3, 2),
      endDate: DateTime(2026, 3, 3),
      reminderIntervalMinutes: 15,
    );

    final secondRepository = FocusFlowRepository(database: database);
    addTearDown(secondRepository.dispose);
    await secondRepository.ready;

    expect(
      secondRepository.snapshot.goals.any(
        (goal) => goal.title == 'Persisted Goal',
      ),
      isTrue,
    );
    expect(
      secondRepository.snapshot.tasks.any(
        (task) => task.title == 'Persisted Task',
      ),
      isTrue,
    );
  });

  test('deleting a goal type reassigns its goals to "other"', () async {
    final repository = await createRepository();
    final cubit = GoalsCubit(repository);
    addTearDown(cubit.close);

    await cubit.addGoalType(
      name: 'Custom',
      colorHex: '#000000',
      iconCode: 'star_border_rounded',
    );
    await Future<void>.delayed(Duration.zero);

    final typeId = cubit.state.goalTypes.last.id;

    await cubit.addGoal(
      title: 'Custom Goal',
      description: 'Using custom type',
      typeId: typeId,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.goals.last.typeId, typeId);

    await cubit.deleteGoalType(typeId);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.goalTypes.any((t) => t.id == typeId), isFalse);
    expect(cubit.state.goals.last.typeId, 'other');
  });
}
