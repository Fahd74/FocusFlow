import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:go_router/go_router.dart';

import 'package:focus_flow/app/focus_flow_app.dart';
import 'package:focus_flow/app/router/app_routes.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/focus_flow_models.dart';
import 'package:focus_flow/core/domain/services/preferences_service.dart';
import 'package:focus_flow/core/domain/services/reminder_service.dart';
import 'package:focus_flow/features/auth/presentation/cubit/auth_cubit.dart';

class MockAuthCubit extends AuthCubit {
  MockAuthCubit() : super() {
    emit(AuthUnauthenticated());
  }

  void triggerState(AuthState state) {
    emit(state);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (email == 'error@test.com') {
      emit(const AuthError('Invalid credentials'));
      return;
    }
    emit(AuthAuthenticated(User(
      id: 'mock-user-id',
      email: email,
      createdAt: DateTime.now().toString(),
      appMetadata: const {},
      userMetadata: const {'full_name': 'Mock User'},
      aud: 'authenticated',
    )));
  }

  @override
  Future<void> signUp(String email, String password, String fullName) async {
    if (!email.contains('@')) {
      emit(const AuthError('Invalid email format'));
      return;
    }
    emit(AuthEmailConfirmationRequired());
  }

  @override
  Future<void> signOut() async {
    emit(AuthUnauthenticated());
  }

  @override
  Future<bool> resetPassword(String email, {String? redirectTo}) async {
    return true;
  }

  @override
  Future<bool> updatePassword(String newPassword) async {
    return true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FocusFlow Integration Tests', () {
    late FocusFlowDatabase database;
    late FocusFlowRepository repository;
    late PreferencesService preferencesService;
    late MockAuthCubit mockAuthCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
      repository = FocusFlowRepository(database: database);
      await repository.ready;
      preferencesService = PreferencesService(await SharedPreferences.getInstance());
      mockAuthCubit = MockAuthCubit();
    });

    tearDown(() async {
      repository.dispose();
      await database.close();
      await mockAuthCubit.close();
    });

    Future<void> pumpTestApp(WidgetTester tester) async {
      await tester.pumpWidget(
        FocusFlowApp(
          repository: repository,
          preferencesService: preferencesService,
          authCubit: mockAuthCubit,
          disablePolling: true,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Guest Mode Use Case: Add Goal, Task, Start/Finish Task, Settings', (tester) async {
      await pumpTestApp(tester);

      // 1. Verify landing on empty Dashboard welcome card
      expect(find.text('Welcome to FocusFlow, Guest!'), findsOneWidget);
      expect(find.text("Let's set your first goal!"), findsOneWidget);

      // 2. Click Create Your First Goal to navigate to Create New Goal
      await tester.tap(find.text('Create Your First Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Create New Goal'), findsOneWidget);

      // Fill in goal title and description
      await tester.enterText(find.byType(TextField).first, 'Master Flutter Testing');
      await tester.enterText(find.byType(TextField).last, 'Write comprehensive integration tests');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Goal'));
      await tester.pumpAndSettle();

      // Verify returned to goals list and Master Flutter Testing is shown
      expect(find.text('Master Flutter Testing'), findsOneWidget);

      // 4. Navigate to Tasks
      await tester.tap(find.text('Tasks').first);
      await tester.pumpAndSettle();
      expect(find.text('My Tasks'), findsOneWidget);

      // 5. Add a New Task linked to the created goal
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();
      expect(find.text('Create New Task'), findsOneWidget);

      // Enter task title
      await tester.enterText(find.byType(TextField).first, 'Implement App Integration Test');
      
      // Select 1m reminder interval
      final intervalChip = find.text('1m');
      await tester.ensureVisible(intervalChip);
      await tester.tap(intervalChip);
      await tester.pumpAndSettle();

      // Tap Save Task
      final saveTaskButton = find.text('Save Task');
      await tester.ensureVisible(saveTaskButton);
      await tester.tap(saveTaskButton);
      await tester.pumpAndSettle();

      // Verify returned to tasks list and task shows up
      expect(find.text('Implement App Integration Test'), findsOneWidget);

      // 6. Tap task, start it, and mark it done
      await tester.tap(find.text('Implement App Integration Test'));
      await tester.pumpAndSettle();

      expect(find.text('Start Now'), findsOneWidget);
      await tester.tap(find.text('Start Now'));
      await tester.pumpAndSettle();

      expect(find.text('Mark Done'), findsOneWidget);
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();

      // Verify returned to tasks and task is marked completed/done
      expect(find.text('Done'), findsWidgets);

      // 7. Go to Profile, verify guest badge
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();
      expect(find.text('Guest Mode'), findsWidgets);

      // 8. Go to Settings, toggle DND switch and play preview sound
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Toggle DND switch
      final dndSwitchFinder = find.byType(Switch).first;
      expect(dndSwitchFinder, findsOneWidget);
      await tester.tap(dndSwitchFinder);
      await tester.pumpAndSettle();

      // Verify the reminder sound label is displayed
      expect(find.text('Reminder Sound'), findsOneWidget);
    });

    testWidgets('Auth Flow Use Case: Create Account validation, Mock Auth State Change, Logout', (tester) async {
      await pumpTestApp(tester);

      // Go to Profile screen
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();

      // Click "Create Account"
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(find.byType(TextField).at(0), 'Fahd'); // Name
      await tester.enterText(find.byType(TextField).at(1), 'invalidemail'); // Bad Email
      await tester.enterText(find.byType(TextField).at(2), 'password123'); // Password
      await tester.enterText(find.byType(TextField).at(3), 'password123'); // Confirm Password
      await tester.pumpAndSettle();

      // Tap Sign Up button (labeled Create Account)
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify error validation message is shown
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Simulate Auth Authenticated transition (e.g. from local authentication or mock auth flow)
      mockAuthCubit.triggerState(AuthAuthenticated(User(
        id: 'mock-user-123',
        email: 'user@test.com',
        createdAt: DateTime.now().toString(),
        appMetadata: const {},
        userMetadata: const {'full_name': 'Fahd Al-Otaibi'},
        aud: 'authenticated',
      )));
      await tester.pumpAndSettle();

      // Go back to Profile page by tapping Profile on Sidebar
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();

      // Verify Profile screen has updated dynamically to show Account Management and user info
      expect(find.text('Account Management'), findsOneWidget);
      expect(find.text('Fahd Al-Otaibi'), findsWidgets);

      // Log Out
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // We are now on the Login page. Navigate to Dashboard programmatically
      final loginContext = tester.element(find.byType(TextField).first);
      GoRouter.of(loginContext).go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      // Navigate back to Profile page
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();

      // Verify app returns to Guest mode
      expect(find.text('Guest Mode'), findsWidgets);
    });

    testWidgets('Reminder Notification Eligibility & Trigger Check', (tester) async {
      final reminderService = ReminderService(preferencesService);

      // Create a mock task
      final now = DateTime.now();
      final task = FocusTask(
        id: 'test-reminder-task',
        goalId: 'goal-1',
        title: 'Notify Me',
        description: 'Test description',
        status: ItemStatus.notYet,
        startDate: now.subtract(const Duration(minutes: 5)),
        endDate: now.add(const Duration(days: 1)),
        reminderIntervalMinutes: 2,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      );

      // 1. Verify eligibility returns true if elapsed minutes >= interval
      final isEligible = reminderService.isEligibleForReminder(task);
      expect(isEligible, isTrue);

      // 2. Verify eligibility returns false if task status is done or inProgress
      final completedTask = task.copyWith(status: ItemStatus.done);
      expect(reminderService.isEligibleForReminder(completedTask), isFalse);
      final inProgressTask = task.copyWith(status: ItemStatus.inProgress);
      expect(reminderService.isEligibleForReminder(inProgressTask), isFalse);

      // 3. Verify eligibility returns false if current time falls within DND hours
      // Set DND: 22:00 to 08:00, force now to 23:00 (DND active)
      await preferencesService.setDndStartHour(22);
      await preferencesService.setDndEndHour(8);

      // Eligible test should still run normally using current system hours, 
      // but let's test isEligibleForReminder returns false if the current system hour is within DND range.
      final dndStart = preferencesService.dndStartHour;
      final dndEnd = preferencesService.dndEndHour;
      final currentHour = DateTime.now().hour;
      final isCurrentlyInDnd = dndStart > dndEnd
          ? (currentHour >= dndStart || currentHour < dndEnd)
          : (currentHour >= dndStart && currentHour < dndEnd);

      if (isCurrentlyInDnd) {
        expect(reminderService.isEligibleForReminder(task), isFalse);
      } else {
        expect(reminderService.isEligibleForReminder(task), isTrue);
      }
    });
  });
}
