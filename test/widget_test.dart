import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/app/focus_flow_app.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/services/preferences_service.dart';
import 'package:focus_flow/features/auth/presentation/cubit/auth_cubit.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
    final repository = FocusFlowRepository(database: database);
    addTearDown(repository.dispose);
    await repository.ready;
    return repository;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpMobileApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(FocusFlowApp(
      repository: await createRepository(),
      preferencesService: PreferencesService(await SharedPreferences.getInstance()),
      authCubit: AuthCubit()..continueAsGuest(),
      disablePolling: true,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('FocusFlow app starts on the dashboard shell', (tester) async {
    await pumpMobileApp(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Goal Summary'), findsOneWidget);
  });

  testWidgets('primary shell navigation reaches static phase 3 screens', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Goals').first);
    await tester.pumpAndSettle();
    expect(find.text('All Goals'), findsOneWidget);

    final fabGoal = find.byType(FloatingActionButton);
    expect(fabGoal, findsOneWidget);
    await tester.tap(fabGoal);
    await tester.pumpAndSettle();
    expect(find.text('Create New Goal'), findsOneWidget);

    await tester.tap(find.text('Goals').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_list_rounded), findsWidgets);

    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Guest User'), findsWidgets);
  });

  testWidgets('mobile shell keeps primary screens responsive', (tester) async {
    await pumpMobileApp(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Goals'), findsWidgets);

    await tester.tap(find.text('Goals').first);
    await tester.pumpAndSettle();
    expect(find.text('All Goals'), findsOneWidget);

    final fabGoal = find.byType(FloatingActionButton);
    expect(fabGoal, findsOneWidget);
    await tester.tap(fabGoal);
    await tester.pumpAndSettle();
    expect(find.text('Create New Goal'), findsOneWidget);

    await tester.tap(find.text('Goals').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_list_rounded), findsWidgets);

    final fabTask = find.byType(FloatingActionButton);
    expect(fabTask, findsOneWidget);
    await tester.tap(fabTask);
    await tester.pumpAndSettle();
    expect(find.text('LINK TO GOAL'), findsOneWidget);
  });
}
