// ignore_for_file: avoid_print
import 'dart:developer' as dev;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:focus_flow/app/focus_flow_app.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/services/preferences_service.dart';
import 'package:focus_flow/features/auth/presentation/cubit/auth_cubit.dart';

void _log(String msg) {
  print(msg);
  dev.log(msg);
}

// ─────────────────────────────────────────────
//  Mock Auth (same as app_test.dart)
// ─────────────────────────────────────────────
class MockAuthCubit extends AuthCubit {
  MockAuthCubit() : super() {
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> signIn(String email, String password) async {
    emit(AuthAuthenticated(User(
      id: 'perf-user-id',
      email: email,
      createdAt: DateTime.now().toString(),
      appMetadata: const {},
      userMetadata: const {'full_name': 'Perf User'},
      aud: 'authenticated',
    )));
  }
}

// ─────────────────────────────────────────────
//  Stopwatch helpers
// ─────────────────────────────────────────────
class PerfResult {
  final String label;
  final Duration duration;
  const PerfResult(this.label, this.duration);

  double get ms => duration.inMicroseconds / 1000.0;

  @override
  String toString() => '$label: ${ms.toStringAsFixed(2)} ms';
}

Future<PerfResult> measure(String label, Future<void> Function() fn) async {
  final sw = Stopwatch()..start();
  await fn();
  sw.stop();
  return PerfResult(label, sw.elapsed);
}

// ─────────────────────────────────────────────
//  Frame timing helpers
// ─────────────────────────────────────────────
class FrameStats {
  final List<Duration> frameDurations;

  FrameStats(this.frameDurations);

  double get averageFps {
    if (frameDurations.isEmpty) return 0;
    final avgMicros =
        frameDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
            frameDurations.length;
    return avgMicros == 0 ? 0 : 1e6 / avgMicros;
  }

  double get avgFrameMs {
    if (frameDurations.isEmpty) return 0;
    return (frameDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
            frameDurations.length) /
        1000.0;
  }

  double get p99Ms {
    if (frameDurations.isEmpty) return 0;
    final sorted = [...frameDurations]..sort((a, b) => a.compareTo(b));
    return sorted[(sorted.length * 0.99).floor()].inMicroseconds / 1000.0;
  }

  double get jankyFramePct {
    if (frameDurations.isEmpty) return 0;
    const threshold = Duration(milliseconds: 33); // 30fps budget in debug runner
    final janky = frameDurations.where((d) => d > threshold).length;
    return (janky / frameDurations.length) * 100;
  }

  double get smoothnessPct => (100 - jankyFramePct).clamp(0, 100);
}


// ─────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FocusFlow Performance Benchmark', () {
    late FocusFlowDatabase database;
    late FocusFlowRepository repository;
    late PreferencesService preferencesService;
    late MockAuthCubit mockAuthCubit;

    // Collected results across all tests
    final List<PerfResult> allResults = [];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
      repository = FocusFlowRepository(database: database);
      await repository.ready;
      preferencesService =
          PreferencesService(await SharedPreferences.getInstance());
      mockAuthCubit = MockAuthCubit();
    });

    tearDown(() async {
      repository.dispose();
      await database.close();
      await mockAuthCubit.close();
    });

    // ── 1. App cold-start (first frame render) ──────────────────────────────
    testWidgets('PERF-01: Cold-start first frame', (tester) async {
      final result = await measure('Cold-start first frame', () async {
        await tester.pumpWidget(
          FocusFlowApp(
            repository: repository,
            preferencesService: preferencesService,
            authCubit: mockAuthCubit,
            disablePolling: true,
          ),
        );
        await tester.pump(); // single frame
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 2. Dashboard full settle ─────────────────────────────────────────────
    testWidgets('PERF-02: Dashboard full settle', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );

      final result = await measure('Dashboard full settle', () async {
        await tester.pumpAndSettle();
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 3. Navigation latency: Dashboard → Goals ──────────────────────────────
    testWidgets('PERF-03: Navigation Dashboard→Goals', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      final result = await measure('Navigate to Goals', () async {
        final goalsFinder = find.text('Goals');
        if (goalsFinder.evaluate().isNotEmpty) {
          await tester.tap(goalsFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 4. Navigation latency: Goals → Tasks ─────────────────────────────────
    testWidgets('PERF-04: Navigation Goals→Tasks', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      final result = await measure('Navigate to Tasks', () async {
        final tasksFinder = find.text('Tasks');
        if (tasksFinder.evaluate().isNotEmpty) {
          await tester.tap(tasksFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 5. Navigation: Tasks → Profile ───────────────────────────────────────
    testWidgets('PERF-05: Navigation Tasks→Profile', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      final result = await measure('Navigate to Profile', () async {
        final profileFinder = find.text('Profile');
        if (profileFinder.evaluate().isNotEmpty) {
          await tester.tap(profileFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 6. Frame rate while scrolling (if list exists) ───────────────────────
    testWidgets('PERF-06: Scroll frame rate (Tasks list)', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Tasks
      final tasksFinder = find.text('Tasks');
      if (tasksFinder.evaluate().isNotEmpty) {
        await tester.tap(tasksFinder.first);
        await tester.pumpAndSettle();
      }

      // Collect frame timings during scroll
      final frameDurations = <Duration>[];
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

      final scrollResult = await measure('Scroll gesture (Tasks list)', () async {
        final scrollFinder = find.byType(Scrollable);
        if (scrollFinder.evaluate().isNotEmpty) {
          final sw = Stopwatch()..start();
          await tester.fling(
            scrollFinder.first,
            const Offset(0, -300),
            1000,
          );
          // Collect ~30 frames
          for (int i = 0; i < 30; i++) {
            final before = sw.elapsed;
            await tester.pump(const Duration(milliseconds: 16));
            final after = sw.elapsed;
            frameDurations.add(after - before);
          }
          await tester.pumpAndSettle();
        }
      });
      allResults.add(scrollResult);

      if (frameDurations.isNotEmpty) {
        final stats = FrameStats(frameDurations);
        _log('[PERF] Avg Frame Render Time: ${stats.avgFrameMs.toStringAsFixed(2)} ms');
        _log('[PERF] Avg FPS during scroll: ${stats.averageFps.toStringAsFixed(1)} FPS');
        _log('[PERF] Smoothness: ${stats.smoothnessPct.toStringAsFixed(1)}%');
        allResults.add(PerfResult(
            'Scroll smoothness (${stats.smoothnessPct.toStringAsFixed(1)}%)',
            Duration(
                microseconds: (stats.avgFrameMs * 1000).round())));
      }
      _log('[PERF] $scrollResult');
    });

    // ── 7. Goal creation interaction latency ─────────────────────────────────
    testWidgets('PERF-07: Create Goal interaction latency', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Goals
      final goalsFinder = find.text('Goals');
      if (goalsFinder.evaluate().isNotEmpty) {
        await tester.tap(goalsFinder.first);
        await tester.pumpAndSettle();
      }

      final result = await measure('Open Create Goal form', () async {
        final createGoalBtn = find.text('Create Your First Goal');
        final addGoalBtn = find.text('Add Goal');
        final fabFinder = find.byType(FloatingActionButton);

        if (createGoalBtn.evaluate().isNotEmpty) {
          await tester.tap(createGoalBtn.first);
        } else if (addGoalBtn.evaluate().isNotEmpty) {
          await tester.tap(addGoalBtn.first);
        } else if (fabFinder.evaluate().isNotEmpty) {
          await tester.tap(fabFinder.first);
        }
        await tester.pumpAndSettle();
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 8. Text input responsiveness ─────────────────────────────────────────
    testWidgets('PERF-08: Text input responsiveness', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Goals and open create form
      final goalsFinder = find.text('Goals');
      if (goalsFinder.evaluate().isNotEmpty) {
        await tester.tap(goalsFinder.first);
        await tester.pumpAndSettle();
      }

      final createGoalBtn = find.text('Create Your First Goal');
      final addGoalBtn = find.text('Add Goal');
      final fabFinder = find.byType(FloatingActionButton);
      if (createGoalBtn.evaluate().isNotEmpty) {
        await tester.tap(createGoalBtn.first);
      } else if (addGoalBtn.evaluate().isNotEmpty) {
        await tester.tap(addGoalBtn.first);
      } else if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder.first);
      }
      await tester.pumpAndSettle();

      final result = await measure('Type 50 chars in TextField', () async {
        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(
              textFields.first, 'Performance Goal – تقييم أداء التطبيق 2026');
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 9. Settings page load ─────────────────────────────────────────────────
    testWidgets('PERF-09: Settings page load', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      final result = await measure('Navigate to Settings', () async {
        final settingsFinder = find.text('Settings');
        if (settingsFinder.evaluate().isNotEmpty) {
          await tester.tap(settingsFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── 10. Profile page load ─────────────────────────────────────────────────
    testWidgets('PERF-10: Profile page load', (tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();

      final result = await measure('Navigate to Profile', () async {
        final profileFinder = find.text('Profile');
        if (profileFinder.evaluate().isNotEmpty) {
          await tester.tap(profileFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[PERF] $result');
    });

    // ── SUMMARY ─────────────────────────────────────────────────────────────
    testWidgets('PERF-SUMMARY: Complete Performance & Smoothness Results', (tester) async {
      _log('[PERF] ═══════════════════════════════════════════════════════');
      _log('[PERF]        FocusFlow Speed & Smoothness Benchmark           ');
      _log('[PERF] ═══════════════════════════════════════════════════════');
      for (final r in allResults) {
        final status = r.ms < 200 ? '⚡ EXCELLENT' : (r.ms < 800 ? '✓ GOOD' : '⚠ ACCEPTABLE');
        _log('[PERF]  $status | ${r.label.padRight(35)} : ${r.ms.toStringAsFixed(2)} ms');
      }
      _log('[PERF] ═══════════════════════════════════════════════════════');
    });
  });
}
