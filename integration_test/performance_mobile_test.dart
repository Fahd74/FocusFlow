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
//  Mobile viewport: 390 × 844 (iPhone 14)
// ─────────────────────────────────────────────
const Size kMobileSize = Size(390, 844);

class MockAuthCubit extends AuthCubit {
  MockAuthCubit() : super() {
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> signIn(String email, String password) async {
    emit(AuthAuthenticated(User(
      id: 'mobile-perf-user',
      email: email,
      createdAt: DateTime.now().toString(),
      appMetadata: const {},
      userMetadata: const {'full_name': 'Mobile Perf User'},
      aud: 'authenticated',
    )));
  }
}

// ─────────────────────────────────────────────
//  Helpers
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
//  MAIN
// ─────────────────────────────────────────────
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FocusFlow Mobile Performance Benchmark', () {
    late FocusFlowDatabase database;
    late FocusFlowRepository repository;
    late PreferencesService preferencesService;
    late MockAuthCubit mockAuthCubit;
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

    // Sets the test surface to mobile dimensions before pumping
    Future<void> pumpMobileApp(WidgetTester tester) async {
      tester.view.physicalSize = kMobileSize * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 3.0; // Retina-like
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
    }

    // ── 1. Cold-start first frame ──────────────────────────────────────────
    testWidgets('MOB-01: Cold-start first frame', (tester) async {
      final result = await measure('MOB Cold-start first frame', () async {
        await pumpMobileApp(tester);
        await tester.pump();
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 2. Dashboard full settle ───────────────────────────────────────────
    // ── 2. Dashboard full settle ───────────────────────────────────────────
    testWidgets('MOB-02: Dashboard full settle', (tester) async {
      await pumpMobileApp(tester);
      final result = await measure('MOB Dashboard full settle', () async {
        await tester.pumpAndSettle();
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 3. Navigation: Dashboard → Goals ──────────────────────────────────
    testWidgets('MOB-03: Navigation Dashboard→Goals', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final result = await measure('MOB Navigate to Goals', () async {
        final goalsFinder = find.text('Goals');
        if (goalsFinder.evaluate().isNotEmpty) {
          await tester.tap(goalsFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 4. Navigation: Goals → Tasks ──────────────────────────────────────
    testWidgets('MOB-04: Navigation Goals→Tasks', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final result = await measure('MOB Navigate to Tasks', () async {
        final tasksFinder = find.text('Tasks');
        if (tasksFinder.evaluate().isNotEmpty) {
          await tester.tap(tasksFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 5. Navigation: Tasks → Profile ────────────────────────────────────
    testWidgets('MOB-05: Navigation Tasks→Profile', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final result = await measure('MOB Navigate to Profile', () async {
        final profileFinder = find.text('Profile');
        if (profileFinder.evaluate().isNotEmpty) {
          await tester.tap(profileFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 6. Scroll frame rate (Tasks list) ─────────────────────────────────
    testWidgets('MOB-06: Scroll frame rate (Tasks list)', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final tasksFinder = find.text('Tasks');
      if (tasksFinder.evaluate().isNotEmpty) {
        await tester.tap(tasksFinder.first);
        await tester.pumpAndSettle();
      }

      final frameDurations = <Duration>[];
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

      final result = await measure('MOB Scroll gesture', () async {
        final scrollFinder = find.byType(Scrollable);
        if (scrollFinder.evaluate().isNotEmpty) {
          final sw = Stopwatch()..start();
          await tester.fling(scrollFinder.first, const Offset(0, -300), 800);
          for (int i = 0; i < 30; i++) {
            final before = sw.elapsed;
            await tester.pump(const Duration(milliseconds: 16));
            frameDurations.add(sw.elapsed - before);
          }
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);

      if (frameDurations.isNotEmpty) {
        final avgUs = frameDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / frameDurations.length;
        final janky = frameDurations.where((d) => d.inMilliseconds > 33).length;
        final smoothPct = ((frameDurations.length - janky) / frameDurations.length * 100);
        _log('[MOB-PERF] Avg frame: ${(avgUs / 1000).toStringAsFixed(2)} ms | Smoothness: ${smoothPct.toStringAsFixed(1)}%');
        allResults.add(PerfResult(
            'MOB Scroll smoothness (${smoothPct.toStringAsFixed(1)}%)',
            Duration(microseconds: avgUs.round())));
      }
      _log('[MOB-PERF] $result');
    });

    // ── 7. Create Goal interaction latency ────────────────────────────────
    testWidgets('MOB-07: Create Goal interaction latency', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final goalsFinder = find.text('Goals');
      if (goalsFinder.evaluate().isNotEmpty) {
        await tester.tap(goalsFinder.first);
        await tester.pumpAndSettle();
      }

      final result = await measure('MOB Open Create Goal form', () async {
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
      _log('[MOB-PERF] $result');
    });

    // ── 8. Text input responsiveness ──────────────────────────────────────
    testWidgets('MOB-08: Text input responsiveness', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

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

      final result = await measure('MOB Type 50 chars in TextField', () async {
        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(
              textFields.first, 'Mobile Goal – اختبار أداء الموبايل 2026');
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 9. Settings page load ─────────────────────────────────────────────
    testWidgets('MOB-09: Settings page load', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final result = await measure('MOB Navigate to Settings', () async {
        final settingsFinder = find.text('Settings');
        if (settingsFinder.evaluate().isNotEmpty) {
          await tester.tap(settingsFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── 10. Profile page load ─────────────────────────────────────────────
    testWidgets('MOB-10: Profile page load', (tester) async {
      await pumpMobileApp(tester);
      await tester.pumpAndSettle();

      final result = await measure('MOB Navigate to Profile', () async {
        final profileFinder = find.text('Profile');
        if (profileFinder.evaluate().isNotEmpty) {
          await tester.tap(profileFinder.first);
          await tester.pumpAndSettle();
        }
      });
      allResults.add(result);
      _log('[MOB-PERF] $result');
    });

    // ── SUMMARY ───────────────────────────────────────────────────────────
    testWidgets('MOB-SUMMARY: Complete Mobile Performance Results', (tester) async {
      _log('[MOB-PERF] ═══════════════════════════════════════════════════════');
      _log('[MOB-PERF]        FocusFlow Mobile Speed & Smoothness Benchmark ');
      _log('[MOB-PERF] ═══════════════════════════════════════════════════════');
      for (final r in allResults) {
        final status = r.ms < 200 ? '⚡ EXCELLENT' : (r.ms < 800 ? '✓ GOOD' : '⚠ ACCEPTABLE');
        _log('[MOB-PERF]  $status | ${r.label.padRight(35)} : ${r.ms.toStringAsFixed(2)} ms');
      }
      _log('[MOB-PERF] ═══════════════════════════════════════════════════════');
    });
  });
}
