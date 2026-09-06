import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/auth_screens.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/goals/presentation/screens/goal_screens.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/task_screens.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../shared/presentation/focus_flow_shell.dart';
import '../../shared/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



bool _isSupabaseInitialized() {
  try {
    Supabase.instance;
    return true;
  } catch (_) {
    return false;
  }
}

GoRouter createAppRouter(
  AuthCubit authCubit, {
  String initialLocation = AppRoutes.dashboard,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final location = state.uri.path;
    if (location == AppRoutes.splash) return AppRoutes.dashboard;

    if (!_isSupabaseInitialized()) return null;
    final authState = authCubit.state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isGuest = authState is AuthGuest;

    final authPaths = [
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.forgotPassword,
      AppRoutes.checkEmail,
    ];

    final isAuthPath = authPaths.contains(location);

    final protectedPaths = [
      AppRoutes.dashboard,
      AppRoutes.goals,
      AppRoutes.tasks,
      AppRoutes.profile,
      AppRoutes.settings,
    ];

    final isProtected = protectedPaths.any((p) => location.startsWith(p));

    if (isLoggedIn || isGuest) {
      if (isAuthPath) {
        return AppRoutes.dashboard;
      }
    } else {
      if (isProtected) {
        return AppRoutes.login;
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => FocusFlowShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.goals,
          builder: (context, state) => const GoalsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AddGoalScreen(),
            ),
            GoRoute(
              path: ':goalId',
              builder: (context, state) =>
                  GoalDetailsScreen(goalId: state.pathParameters['goalId']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) =>
                      EditGoalScreen(goalId: state.pathParameters['goalId']!),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.tasks,
          builder: (context, state) => const TasksScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => AddTaskScreen(
                initialGoalId: state.uri.queryParameters['goalId'],
              ),
            ),
            GoRoute(
              path: ':taskId',
              builder: (context, state) =>
                  TaskDetailsScreen(taskId: state.pathParameters['taskId']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) =>
                      EditTaskScreen(taskId: state.pathParameters['taskId']!),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkEmail,
      builder: (context, state) => CheckEmailScreen(
        message: state.extra as String?,
      ),
    ),
  ],
);
