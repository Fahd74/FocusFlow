import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/data/focus_flow_repository.dart';
import '../core/data/remote/supabase_sync_engine.dart';
import '../core/domain/services/preferences_service.dart';
import '../core/domain/services/reminder_service.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../features/goals/presentation/cubit/goals_cubit.dart';
import '../features/reminders/presentation/cubit/reminder_cubit.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/tasks/presentation/cubit/tasks_cubit.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/focus_flow_theme.dart';

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({
    super.key,
    this.repository,
    this.preferencesService,
    this.authCubit,
    this.syncEngine,
    this.disablePolling = false,
    this.initialLocation,
  });

  final FocusFlowRepository? repository;
  final PreferencesService? preferencesService;
  final AuthCubit? authCubit;
  final SupabaseSyncEngine? syncEngine;
  final bool disablePolling;
  final String? initialLocation;

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  late final GoRouter _router;
  late final FocusFlowRepository _repository;
  late final AuthCubit _authCubit;
  late final SettingsCubit _settingsCubit;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FocusFlowRepository();
    _authCubit = widget.authCubit ?? AuthCubit();
    _router = createAppRouter(
      _authCubit,
      initialLocation: widget.initialLocation ?? AppRoutes.dashboard,
    );
    _settingsCubit = SettingsCubit(widget.preferencesService!);
    _settingsCubit.onSettingsChanged = () {
      widget.syncEngine?.broadcastSettingsUpdated();
      widget.syncEngine?.forceSync();
    };
    widget.syncEngine?.onSettingsSynced = () {
      _settingsCubit.loadSettings();
    };
    // Listen to auth state changes to reload data for the correct user
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
    // Synchronize initial auth state
    _onAuthStateChanged(_authCubit.state);
  }

  void _onAuthStateChanged(AuthState authState) async {
    String? userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }
    // Set userId on preferencesService to isolate preferences
    widget.preferencesService?.userId = userId;
    // Reload settings state for the new user/guest
    _settingsCubit.loadSettings();
    // Reload repository data scoped to the new user (null = guest)
    await _repository.reloadForUser(userId);
    if (userId != null) {
      widget.syncEngine?.forceSync();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    // Only dispose if we created these ourselves (not injected)
    if (widget.repository == null) {
      _repository.dispose();
    }
    if (widget.authCubit == null) {
      _authCubit.close();
    }
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider(
          create: (context) => DashboardCubit(context.read<FocusFlowRepository>()),
        ),
        BlocProvider.value(value: _settingsCubit),
        BlocProvider(
          create: (context) => GoalsCubit(context.read<FocusFlowRepository>()),
        ),
        BlocProvider(
          create: (context) => TasksCubit(context.read<FocusFlowRepository>()),
        ),
        BlocProvider(
          lazy: false,
          create: (context) {
            final reminderCubit = ReminderCubit(
              authCubit: context.read<AuthCubit>(),
              tasksCubit: context.read<TasksCubit>(),
              preferencesService: widget.preferencesService!,
              reminderService: ReminderService(widget.preferencesService!),
              disablePolling: widget.disablePolling,
            );
            reminderCubit.onMarkDoneFromNotification = (taskId) async {
              await context.read<TasksCubit>().completeTask(taskId);
              await widget.syncEngine?.broadcastNotificationDismissed(taskId);
            };
            reminderCubit.onNotificationTapped = (taskId) {
              // Navigate to the Task Details screen using the router
              _router.go('/tasks/$taskId');
            };
            widget.syncEngine?.onRemoteNotificationDismissed = (taskId) {
              reminderCubit.dismissNotificationForTask(taskId);
            };
            // Defer processing pending completions until the widget tree is fully
            // built so that TasksCubit and its repository are ready.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              reminderCubit.processPendingCompletedTasks();
            });
            return reminderCubit;
          },
        ),

      ],
      child: MaterialApp.router(
        title: 'FocusFlow',
        debugShowCheckedModeBanner: false,
        theme: FocusFlowTheme.light(),
        routerConfig: _router,
      ),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _repository),
        RepositoryProvider.value(value: widget.preferencesService!),
        if (widget.syncEngine != null)
          RepositoryProvider.value(value: widget.syncEngine!),
      ],
      child: app,
    );
  }
}
