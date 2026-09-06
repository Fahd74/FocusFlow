// ignore_for_file: avoid_print
import 'dart:developer' as dev;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';

void _log(String msg) {
  print(msg);
  dev.log(msg);
}

// ─────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────
class DbPerfResult {
  final String label;
  final Duration duration;
  final int count;

  const DbPerfResult(this.label, this.duration, {this.count = 1});

  double get ms => duration.inMicroseconds / 1000.0;
  double get perItemMs => count > 0 ? ms / count : ms;

  @override
  String toString() =>
      '$label: ${ms.toStringAsFixed(2)} ms'
      '${count > 1 ? ' (${perItemMs.toStringAsFixed(3)} ms/item × $count)' : ''}';
}

Future<DbPerfResult> measureDb(
  String label,
  Future<void> Function() fn, {
  int count = 1,
}) async {
  final sw = Stopwatch()..start();
  await fn();
  sw.stop();
  return DbPerfResult(label, sw.elapsed, count: count);
}

// ─────────────────────────────────────────────────────────────────
//  Shared goal ID for tasks
// ─────────────────────────────────────────────────────────────────
const _testGoalTitle = 'DB Perf Test Goal';
const _testUserId    = 'db-perf-user-001';

// ─────────────────────────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────────────────────────
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FocusFlow DB Performance Benchmark', () {
    late FocusFlowDatabase database;
    late FocusFlowRepository repository;

    final List<DbPerfResult> allResults = [];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
      repository = FocusFlowRepository(database: database, userId: _testUserId);
      await repository.ready;
    });

    tearDown(() async {
      repository.dispose();
      await database.close();
    });

    // ── DB-01: Insert 1 Goal ──────────────────────────────────────
    testWidgets('DB-01: Insert single Goal', (tester) async {
      final now = DateTime.now();
      final result = await measureDb('Insert 1 goal', () async {
        await repository.addGoal(
          title: _testGoalTitle,
          description: 'Goal for DB performance testing',
          typeId: 'personal',
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
        );
      });
      allResults.add(result);
      _log('[DB-PERF] $result');

      // Verify it was actually inserted
      final goals = repository.snapshot.goals;
      expect(goals.any((g) => g.title == _testGoalTitle), isTrue);
      expect(result.ms, lessThan(500),
          reason: 'Single goal insert should be < 500 ms');
    });

    // ── DB-02: Insert 10 Tasks (sequential) ──────────────────────
    testWidgets('DB-02: Insert 10 Tasks (sequential)', (tester) async {
      final now = DateTime.now();
      // Add a goal first
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal for tasks',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      const n = 10;
      final result = await measureDb(
        'Insert $n tasks (sequential)',
        () async {
          for (int i = 0; i < n; i++) {
            await repository.addTask(
              goalId: goalId,
              title: 'Perf Task #$i – اختبار قاعدة البيانات',
              description: 'Task $i for DB performance benchmark',
              startDate: now,
              endDate: now.add(Duration(hours: i + 1)),
              reminderIntervalMinutes: 30,
            );
          }
        },
        count: n,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(5000),
          reason: '10 sequential inserts should be < 5 s');
    });

    // ── DB-03: Insert 50 Tasks (sequential) ──────────────────────
    testWidgets('DB-03: Insert 50 Tasks (sequential)', (tester) async {
      final now = DateTime.now();
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal for 50 tasks',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 60)),
      );
      final goalId = repository.snapshot.goals.first.id;

      const n = 50;
      final result = await measureDb(
        'Insert $n tasks (sequential)',
        () async {
          for (int i = 0; i < n; i++) {
            await repository.addTask(
              goalId: goalId,
              title: 'Bulk Task #$i',
              description: 'Bulk task $i for DB perf',
              startDate: now,
              endDate: now.add(Duration(hours: i + 1)),
              reminderIntervalMinutes: 15,
            );
          }
        },
        count: n,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');

      // Verify count
      final tasks = repository.snapshot.tasks;
      expect(tasks.length, equals(n));
      expect(result.ms, lessThan(20000),
          reason: '50 sequential inserts should be < 20 s');
    });

    // ── DB-04: Snapshot query (tasks in memory) ───────────────────
    testWidgets('DB-04: Snapshot read – 50 tasks', (tester) async {
      final now = DateTime.now();
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal for snapshot test',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      // Seed 50 tasks
      for (int i = 0; i < 50; i++) {
        await repository.addTask(
          goalId: goalId,
          title: 'Snapshot Task #$i',
          description: 'Task $i',
          startDate: now,
          endDate: now.add(Duration(hours: i + 1)),
          reminderIntervalMinutes: 30,
        );
      }

      const iterations = 100;
      final result = await measureDb(
        'Snapshot read ×$iterations (filter tasks by goalId)',
        () async {
          for (int i = 0; i < iterations; i++) {
            final _ = repository.snapshot.tasks
                .where((t) => t.goalId == goalId)
                .toList();
          }
        },
        count: iterations,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(500),
          reason: '100 in-memory snapshot reads should be < 500 ms');
    });

    // ── DB-05: watchSnapshot emission after write ─────────────────
    testWidgets('DB-05: Stream watchSnapshot emission after write', (tester) async {
      final now = DateTime.now();

      // Listen for next snapshot emission triggered by addGoal
      final result = await measureDb('Stream emission after addGoal (watchSnapshot)', () async {
        final future = repository.watchSnapshot().first;
        await repository.addGoal(
          title: 'Stream Test Goal',
          description: 'Trigger a stream emission',
          typeId: 'personal',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
        );
        await future.timeout(
          const Duration(seconds: 5),
          onTimeout: () => repository.snapshot,
        );
      });

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(2000),
          reason: 'Stream emission after write should be < 2 s');
    });

    // ── DB-06: Update 10 tasks (deleteTask + re-add) ──────────────
    testWidgets('DB-06: Delete 10 tasks', (tester) async {
      final now = DateTime.now();
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal for delete test',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      for (int i = 0; i < 10; i++) {
        await repository.addTask(
          goalId: goalId,
          title: 'Delete Task #$i',
          description: 'Will be deleted',
          startDate: now,
          endDate: now.add(Duration(hours: i + 1)),
          reminderIntervalMinutes: 30,
        );
      }

      final taskIds = repository.snapshot.tasks.map((t) => t.id).toList();
      const n = 10;

      final result = await measureDb(
        'Delete $n tasks (soft-delete)',
        () async {
          for (final id in taskIds) {
            await repository.deleteTask(id);
          }
        },
        count: n,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(5000),
          reason: 'Deleting 10 tasks should be < 5 s');
    });

    // ── DB-07: completeTask latency ───────────────────────────────
    testWidgets('DB-07: Complete 10 tasks', (tester) async {
      final now = DateTime.now();
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal for complete test',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      for (int i = 0; i < 10; i++) {
        await repository.addTask(
          goalId: goalId,
          title: 'Complete Task #$i',
          description: 'Will be completed',
          startDate: now,
          endDate: now.add(Duration(hours: i + 1)),
          reminderIntervalMinutes: 30,
        );
      }

      final taskIds = repository.snapshot.tasks.map((t) => t.id).toList();
      const n = 10;

      final result = await measureDb(
        'Complete $n tasks',
        () async {
          for (final id in taskIds) {
            await repository.completeTask(id);
          }
        },
        count: n,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(5000),
          reason: 'Completing 10 tasks should be < 5 s');
    });

    // ── DB-08: deleteGoal cascade ─────────────────────────────────
    testWidgets('DB-08: Delete Goal (soft-delete + cascade)', (tester) async {
      final now = DateTime.now();
      await repository.addGoal(
        title: _testGoalTitle,
        description: 'Goal to cascade-delete',
        typeId: 'personal',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
      );
      final goalId = repository.snapshot.goals.first.id;

      // Add 20 child tasks
      for (int i = 0; i < 20; i++) {
        await repository.addTask(
          goalId: goalId,
          title: 'Cascade Task #$i',
          description: 'Child of goal to be deleted',
          startDate: now,
          endDate: now.add(Duration(hours: i + 1)),
          reminderIntervalMinutes: 30,
        );
      }

      final result = await measureDb(
        'Delete Goal + 20 tasks (cascade)',
        () async {
          await repository.deleteGoal(goalId);
        },
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(1000),
          reason: 'Goal cascade delete should be < 1 s');
    });

    // ── DB-09: goalProgress computation ──────────────────────────
    testWidgets('DB-09: goalProgress computation (10 goals × 10 tasks)', (tester) async {
      final now = DateTime.now();

      // Seed 10 goals with 10 tasks each
      for (int g = 0; g < 10; g++) {
        await repository.addGoal(
          title: 'Goal $g',
          description: 'Goal $g for progress test',
          typeId: 'personal',
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
        );
      }

      final goalIds = repository.snapshot.goals.map((g) => g.id).toList();
      for (final gid in goalIds) {
        for (int t = 0; t < 10; t++) {
          await repository.addTask(
            goalId: gid,
            title: 'Task $t for goal $gid',
            description: '',
            startDate: now,
            endDate: now.add(Duration(hours: t + 1)),
            reminderIntervalMinutes: 30,
          );
        }
      }

      const iterations = 50;
      final result = await measureDb(
        'goalProgress computation ×$iterations (10 goals × 10 tasks)',
        () async {
          for (int i = 0; i < iterations; i++) {
            final _ = repository.goalProgress;
          }
        },
        count: iterations,
      );

      allResults.add(result);
      _log('[DB-PERF] $result');
      expect(result.ms, lessThan(1000),
          reason: 'goalProgress 50× should be < 1 s');
    });

    // ── SUMMARY ───────────────────────────────────────────────────
    testWidgets('DB-SUMMARY: All DB performance results', (tester) async {
      _log('[DB-PERF] ══════════════════════════════════════════');
      _log('[DB-PERF]  FocusFlow DB Performance Summary');
      _log('[DB-PERF] ══════════════════════════════════════════');
      for (final r in allResults) {
        final status = r.ms < 1000 ? '✓' : (r.ms < 5000 ? '⚠' : '✗');
        _log('[DB-PERF]  $status $r');
      }
      _log('[DB-PERF] ══════════════════════════════════════════');
    });
  });
}
