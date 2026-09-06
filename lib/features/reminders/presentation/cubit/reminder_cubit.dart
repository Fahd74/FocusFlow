import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/domain/focus_flow_models.dart';
import '../../../../core/domain/services/preferences_service.dart';
import '../../../../core/domain/services/reminder_service.dart';
import '../../../../core/domain/services/windows_tray_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';

class ReminderState {}

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit({
    required this.authCubit,
    required this.tasksCubit,
    required this.reminderService,
    required this.preferencesService,
    this.disablePolling = false,
  }) : super(ReminderState()) {
    _initNotifications();
    _tasksSubscription = tasksCubit.stream.listen((tasksState) {
      _syncAllTaskSchedules(tasksState.tasks);
    });
    if (!disablePolling) {
      _startPolling();
    }
  }

  final AuthCubit authCubit;
  final TasksCubit tasksCubit;
  final ReminderService reminderService;
  final PreferencesService preferencesService;
  final bool disablePolling;

  /// Optional callback: called when user taps "Mark as Done" from notification.
  /// Set by the widget tree to handle task completion.
  void Function(String taskId)? onMarkDoneFromNotification;

  /// Optional callback: called when user taps a notification body (not an action button).
  /// Should navigate to the task details screen for the given taskId.
  void Function(String taskId)? onNotificationTapped;

  /// Optional callback: called when a remote dismissal broadcast arrives.
  void Function(String taskId)? onRemoteDismiss;

  /// Maximum number of scheduled alarm slots per task.
  /// Dynamically capped but never exceeds this value to respect Android alarm limits.
  static const int _kMaxAlarmSlotsPerTask = 200;

  /// Tracks task IDs that were scheduled in the previous sync cycle.
  /// Used to detect and cancel alarms for deleted/removed tasks.
  final Set<String> _previouslyScheduledTaskIds = {};

  StreamSubscription<TasksState>? _tasksSubscription;
  Timer? _timer;
  Timer? _soundTimer;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ──────────────────────────────────────────────
  // Init
  // ──────────────────────────────────────────────

  Future<void> _initNotifications() async {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        // Handle action button tap (Mark as Done) when app is in foreground/background
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      // Check if the app was launched by tapping a notification (cold start)
      final launchDetails =
          await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payload = launchDetails.notificationResponse!.payload!;
        final actionId = launchDetails.notificationResponse!.actionId;
        // Only navigate (not mark-done) for plain taps on the notification body
        if (actionId == null || actionId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNotificationTapped?.call(payload);
          });
        }
      }

      if (Platform.isAndroid) {
        final androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        try {
          await androidImplementation?.requestNotificationsPermission();
        } catch (_) {}

        // Clear any lingering group summary notification
        await _flutterLocalNotificationsPlugin.cancel(id: 999999);

        // 1. Default system sound channel
        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_reminders_default',
            'Task Reminders (Default Sound)',
            description: 'Notifications for FocusFlow task reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        // 2. Bell sound channel
        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_reminders_bell',
            'Task Reminders (Bell Sound)',
            description: 'Notifications for FocusFlow task reminders',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('bell'),
            enableVibration: true,
          ),
        );

        // 3. Chime sound channel
        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_reminders_chime',
            'Task Reminders (Chime Sound)',
            description: 'Notifications for FocusFlow task reminders',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('chime'),
            enableVibration: true,
          ),
        );

        // 4. Silent channel
        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_reminders_none',
            'Task Reminders (Silent)',
            description: 'Silent notifications for FocusFlow',
            importance: Importance.high,
            playSound: false,
            enableVibration: true,
          ),
        );
      } else if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    }

    // Immediately synchronize all active task schedules
    _syncAllTaskSchedules(tasksCubit.state.tasks);
  }

  // ──────────────────────────────────────────────
  // Battery UX dialog — shown once on first launch
  // ──────────────────────────────────────────────

  /// Show a transparent UX dialog explaining background permission, then request it.
  Future<void> requestBatteryOptimizationWithDialog(BuildContext context) async {
    if (!Platform.isAndroid) return;
    try {
      const channel = MethodChannel('com.focusflow.app/battery_optimization');
      final isIgnoring =
          await channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      if (isIgnoring == true) return; // already granted, skip dialog

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Keep Reminders Active'),
          content: const Text(
            'To make sure your task reminders arrive on time — even when '
            'FocusFlow is closed — please allow it to run in the background.\n\n'
            'This keeps the notification engine alive without draining your battery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await channel.invokeMethod('requestIgnoreBatteryOptimizations');
      }
    } catch (e) {
      debugPrint('Battery optimization dialog error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Notification action callbacks
  // ──────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;

    if (response.actionId == 'mark_done') {
      // User tapped the "Mark as Done" action button
      _handleMarkDone(response.payload!);
    } else if (response.actionId == null || response.actionId!.isEmpty) {
      // User tapped the notification body itself → navigate to Task Details
      _handleNotificationTap(response.payload!);
    }
  }

  /// Called when user taps "Mark as Done" while app is in background/terminated.
  void _handleMarkDone(String taskId) {
    try {
      onMarkDoneFromNotification?.call(taskId);
    } catch (e) {
      debugPrint('Mark done callback error: $e');
    }
  }

  /// Called when user taps the notification body → navigate to Task Details.
  void _handleNotificationTap(String taskId) {
    try {
      onNotificationTapped?.call(taskId);
    } catch (e) {
      debugPrint('Notification tap callback error: $e');
    }
  }

  /// Dismiss a local notification by task ID (called when remote dismissal arrives).
  Future<void> dismissNotificationForTask(String taskId) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final notifId = (taskId.hashCode.abs()) & 0x7FFFFFFF;
    await _flutterLocalNotificationsPlugin.cancel(id: notifId);
    // Also cancel all scheduled occurrences
    final baseId = (taskId.hashCode.abs()) % 10000;
    for (int i = 0; i < _kMaxAlarmSlotsPerTask; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: baseId * 100 + i);
    }
  }

  /// Process any task completions queued from background notification interactions while app was terminated
  Future<void> processPendingCompletedTasks() async {
    try {
      final pending = preferencesService.pendingCompletedTaskIds;
      if (pending.isNotEmpty) {
        debugPrint('Processing ${pending.length} pending completed tasks from background response');
        for (final taskId in pending) {
          _handleMarkDone(taskId);
        }
        await preferencesService.clearPendingCompletedTaskIds();
      }
    } catch (e) {
      debugPrint('Error processing pending completed tasks: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Schedule synchronization for all tasks
  // ──────────────────────────────────────────────

  Future<void> _syncAllTaskSchedules(List<FocusTask> tasks) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final authState = authCubit.state;
    if (authState is! AuthAuthenticated && authState is! AuthGuest) {
      return;
    }

    final currentTaskIds = tasks.map((t) => t.id).toSet();

    // Cancel alarms for tasks that were previously scheduled but are now
    // removed (deleted) from the list – fixes the "ghost notification" bug.
    final removedTaskIds = _previouslyScheduledTaskIds.difference(currentTaskIds);
    for (final removedId in removedTaskIds) {
      final baseId = (removedId.hashCode.abs()) % 10000;
      for (int i = 0; i < _kMaxAlarmSlotsPerTask; i++) {
        await _flutterLocalNotificationsPlugin.cancel(id: baseId * 100 + i);
      }
      debugPrint('Cancelled all alarms for removed task: $removedId');
    }

    for (final task in tasks) {
      await _scheduleTaskOSNotification(task);
    }

    _previouslyScheduledTaskIds
      ..clear()
      ..addAll(currentTaskIds);
  }

  // ──────────────────────────────────────────────
  // Polling (for Desktop & periodic refresh)
  // ──────────────────────────────────────────────

  void _startPolling() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkReminders();
    });
  }

  Future<void> _checkReminders() async {
    final authState = authCubit.state;
    if (authState is! AuthAuthenticated && authState is! AuthGuest) {
      return;
    }

    final tasks = tasksCubit.state.tasks;

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      for (final task in tasks) {
        if (reminderService.isEligibleForReminder(task)) {
          await _showNotification(task);
          await tasksCubit.updateTaskReminder(task.id);
        }
      }
    } else {
      // On mobile, keep OS exact alarm schedules synchronized
      _syncAllTaskSchedules(tasks);
    }
  }

  // ──────────────────────────────────────────────
  // Android Notification Details Helper
  // ──────────────────────────────────────────────

  AndroidNotificationDetails _getAndroidNotificationDetails() {
    final sound = preferencesService.notificationSound;
    final channelId = switch (sound) {
      'bell' => 'focusflow_reminders_bell',
      'chime' => 'focusflow_reminders_chime',
      'none' => 'focusflow_reminders_none',
      _ => 'focusflow_reminders_default',
    };
    final channelName = switch (sound) {
      'bell' => 'Task Reminders (Bell Sound)',
      'chime' => 'Task Reminders (Chime Sound)',
      'none' => 'Task Reminders (Silent)',
      _ => 'Task Reminders (Default Sound)',
    };
    final isSilent = sound == 'none';
    final rawSound = (sound == 'bell' || sound == 'chime')
        ? RawResourceAndroidNotificationSound(sound)
        : null;

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for FocusFlow task reminders',
      importance: isSilent ? Importance.high : Importance.max,
      priority: Priority.high,
      playSound: !isSilent,
      sound: rawSound,
      enableVibration: true,
      actions: const [
        AndroidNotificationAction(
          'mark_done',
          'Mark as Done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // AlarmManager exact scheduling (Android/iOS)
  // ──────────────────────────────────────────────

  Future<void> _scheduleTaskOSNotification(FocusTask task) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final baseId = (task.id.hashCode.abs()) % 10000;

    // If task is completed, in progress, or reminder disabled, cancel all alarms
    if (task.status != ItemStatus.notYet || task.reminderIntervalMinutes <= 0) {
      for (int i = 0; i < _kMaxAlarmSlotsPerTask; i++) {
        await _flutterLocalNotificationsPlugin.cancel(id: baseId * 100 + i);
      }
      return;
    }

    final now = DateTime.now();
    DateTime nextTime = task.lastReminderAt == null
        ? task.startDate
        : task.lastReminderAt!.add(Duration(minutes: task.reminderIntervalMinutes));

    while (nextTime.isBefore(now)) {
      nextTime = nextTime.add(Duration(minutes: task.reminderIntervalMinutes));
    }

    final androidDetails = _getAndroidNotificationDetails();
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    // Schedule enough occurrences to cover at least 26 hours, capped at
    // _kMaxAlarmSlotsPerTask to respect Android alarm limits.
    final neededFor26h = ((26 * 60) / task.reminderIntervalMinutes).ceil();
    final maxOccurrences = neededFor26h.clamp(50, _kMaxAlarmSlotsPerTask);
    for (int i = 0; i < maxOccurrences; i++) {
      final occurrenceTime =
          nextTime.add(Duration(minutes: i * task.reminderIntervalMinutes));
      if (occurrenceTime.isAfter(task.endDate)) break;

      final tzScheduledTime = tz.TZDateTime.from(occurrenceTime, tz.local);
      final notificationId = baseId * 100 + i;

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'FocusFlow',
          body: 'Time to start: ${task.title}',
          scheduledDate: tzScheduledTime,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id,
        );
      } catch (e) {
        debugPrint('Error scheduling notification occurrence $i: $e');
      }
    }
  }

  // ──────────────────────────────────────────────
  // Show notification (Desktop trigger)
  // ──────────────────────────────────────────────

  Future<void> _showNotification(FocusTask task) async {
    final isDesktopPlatform =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    if (isDesktopPlatform) {
      final customPath = preferencesService.customDesktopNotificationSoundPath;
      final sound = preferencesService.desktopNotificationSound;
      final isDefaultSound = customPath == null && sound == 'default';

      if (!isDefaultSound) {
        if (customPath != null && customPath.isNotEmpty) {
          try {
            await _audioPlayer.play(DeviceFileSource(customPath));
          } catch (e) {
            debugPrint('Error playing custom sound: $e');
          }
        } else if (sound != 'none') {
          try {
            await _audioPlayer.play(AssetSource('sounds/$sound.wav'));
          } catch (e) {
            debugPrint('Error playing preset sound ($sound): $e');
          }
        }

        _soundTimer?.cancel();
        _soundTimer = Timer(const Duration(seconds: 5), () async {
          try {
            await _audioPlayer.stop();
          } catch (_) {}
        });
      }

      final notification = LocalNotification(
        title: 'FocusFlow',
        body: 'Time to start: ${task.title}',
        silent: !isDefaultSound,
        actions: [
          LocalNotificationAction(text: 'Mark as Done'),
        ],
      );
      notification.onClick = () async {
        if (Platform.isWindows) {
          await WindowsTrayService.instance.showApp();
        }
        _handleNotificationTap(task.id);
      };
      notification.onClickAction = (actionIndex) async {
        if (actionIndex == 0) {
          _handleMarkDone(task.id);
        }
      };
      notification.show();
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _timer?.cancel();
    _soundTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}

// ──────────────────────────────────────────────
// Top-level handler for background notification actions (required by flutter_local_notifications)
// ──────────────────────────────────────────────
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) async {
  debugPrint('Background notification action: ${response.actionId} payload: ${response.payload}');
  if (response.actionId == 'mark_done' && response.payload != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'pending_completed_task_ids';
      final pending = prefs.getStringList(key) ?? [];
      if (!pending.contains(response.payload)) {
        pending.add(response.payload!);
        await prefs.setStringList(key, pending);
        debugPrint('Saved pending completed task in background: ${response.payload}');
      }
    } catch (e) {
      debugPrint('Error saving pending completed task in background: $e');
    }
  }
}
