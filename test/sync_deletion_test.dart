import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/focus_flow_models.dart';

void main() {
  late FocusFlowDatabase db;
  late FocusFlowRepository repository;
  const testUserId = 'test-user-123';

  setUp(() async {
    db = FocusFlowDatabase.forTesting(NativeDatabase.memory());
    repository = FocusFlowRepository(database: db);
    await repository.ready;
    await repository.reloadForUser(testUserId);
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  test('deleting a task includes it in getAllTasksForSync with deletedAt', () async {
    // 1. Add goal and task
    await repository.addGoal(
      title: 'Sync Goal',
      description: 'Goal to test sync deletion',
      typeId: 'work',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
    );
    final goalId = repository.snapshot.goals.first.id;

    await repository.addTask(
      goalId: goalId,
      title: 'Sync Task',
      description: 'Task to delete',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
      reminderIntervalMinutes: 15,
    );
    final taskId = repository.snapshot.tasks.first.id;

    expect(repository.snapshot.tasks.length, 1);

    // 2. Delete task
    await repository.deleteTask(taskId);
    expect(repository.snapshot.tasks.length, 0);

    // 3. Verify sync query returns the soft-deleted task for Supabase push
    final syncTasks = await repository.getAllTasksForSync(userId: testUserId);
    expect(syncTasks.length, 1);
    expect(syncTasks.first.id, taskId);
    expect(syncTasks.first.deletedAt, isNotNull);
  });

  test('deleting a goal includes it and its tasks in sync queries with deletedAt', () async {
    // 1. Add goal and task
    await repository.addGoal(
      title: 'Goal to delete',
      description: 'Test',
      typeId: 'fitness',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
    );
    final goalId = repository.snapshot.goals.first.id;

    await repository.addTask(
      goalId: goalId,
      title: 'Child Task',
      description: 'Test',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
      reminderIntervalMinutes: 15,
    );

    // 2. Delete goal
    await repository.deleteGoal(goalId);
    expect(repository.snapshot.goals.length, 0);
    expect(repository.snapshot.tasks.length, 0);

    // 3. Verify sync queries return both soft-deleted records
    final syncGoals = await repository.getAllGoalsForSync(userId: testUserId);
    expect(syncGoals.length, 1);
    expect(syncGoals.first.id, goalId);
    expect(syncGoals.first.deletedAt, isNotNull);

    final syncTasks = await repository.getAllTasksForSync(userId: testUserId);
    expect(syncTasks.length, 1);
    expect(syncTasks.first.deletedAt, isNotNull);
  });

  test('pulling a deleted item from remote removes it from local snapshot', () async {
    // 1. Add local goal and task
    final now = DateTime.now();
    await repository.addGoal(
      title: 'Remote Parent Goal',
      description: 'Desc',
      typeId: 'work',
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
    );
    final goalId = repository.snapshot.goals.first.id;

    final task = FocusTask(
      id: 'remote-task-1',
      goalId: goalId,
      title: 'Remote Task',
      description: 'Desc',
      startDate: now,
      endDate: now.add(const Duration(days: 1)),
      reminderIntervalMinutes: 15,
      createdAt: now,
      updatedAt: now,
      userId: testUserId,
    );
    await repository.upsertTask(task);
    expect(repository.snapshot.tasks.any((t) => t.id == 'remote-task-1'), isTrue);

    // 2. Remote sends deleted update (deletedAt set)
    final deletedRemoteTask = task.copyWith(
      deletedAt: now.add(const Duration(seconds: 10)),
      updatedAt: now.add(const Duration(seconds: 10)),
    );
    await repository.upsertTask(deletedRemoteTask);

    // 3. Verify removed from memory snapshot and marked deleted in DB
    expect(repository.snapshot.tasks.any((t) => t.id == 'remote-task-1'), isFalse);
    final dbRows = await db.select(db.taskRows).get();
    final row = dbRows.firstWhere((r) => r.id == 'remote-task-1');
    expect(row.deletedAt, isNotNull);
  });
}
