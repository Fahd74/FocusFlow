import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime, local;


import 'app/focus_flow_app.dart';
import 'core/data/focus_flow_repository.dart';
import 'core/data/remote/supabase_sync_engine.dart';
import 'core/domain/focus_flow_models.dart';
import 'core/domain/services/fcm_service.dart';
import 'core/domain/services/preferences_service.dart';
import 'core/domain/services/reminder_service.dart';
import 'core/domain/services/windows_tray_service.dart';


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      tz.initializeTimeZones();
      final prefs = await SharedPreferences.getInstance();
      final preferencesService = PreferencesService(prefs);
      final repository = FocusFlowRepository();
      await repository.ready;
      final reminderService = ReminderService(preferencesService);

      final tasks = repository.snapshot.tasks;

      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await notificationsPlugin.initialize(
        settings: const InitializationSettings(android: initializationSettingsAndroid),
      );

      // Create notification channels if they don't exist yet
      final androidImpl =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'focusflow_reminders_default',
          'Task Reminders (Default Sound)',
          description: 'Notifications for FocusFlow task reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidImpl?.createNotificationChannel(
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
      await androidImpl?.createNotificationChannel(
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
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'focusflow_reminders_none',
          'Task Reminders (Silent)',
          description: 'Silent notifications for FocusFlow',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
        ),
      );

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

      final androidDetails = AndroidNotificationDetails(
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
      final platformDetails =
          NotificationDetails(android: androidDetails);

      for (final t in tasks) {
        // Re-schedule upcoming occurrences so the scheduling window is continuously renewed
        // even when the app is closed (guarantees notifications keep firing on time).
        if (t.status == ItemStatus.notYet && t.reminderIntervalMinutes > 0) {
          try {
            final baseId = (t.id.hashCode.abs()) % 10000;

            final now = DateTime.now();
            DateTime nextTime = t.lastReminderAt == null
                ? t.startDate
                : t.lastReminderAt!
                    .add(Duration(minutes: t.reminderIntervalMinutes));

            while (nextTime.isBefore(now)) {
              nextTime = nextTime.add(Duration(minutes: t.reminderIntervalMinutes));
            }

            // Cover at least 26 hours of notifications, capped at 200 per task.
            final neededFor26h = ((26 * 60) / t.reminderIntervalMinutes).ceil();
            final maxOccurrences = neededFor26h.clamp(50, 200);
            for (int i = 0; i < maxOccurrences; i++) {
              final occurrenceTime =
                  nextTime.add(Duration(minutes: i * t.reminderIntervalMinutes));
              if (occurrenceTime.isAfter(t.endDate)) break;

              await notificationsPlugin.zonedSchedule(
                id: baseId * 100 + i,
                title: 'FocusFlow',
                body: 'Time to start: ${t.title}',
                scheduledDate: TZDateTime.from(occurrenceTime, local),
                notificationDetails: platformDetails,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                payload: t.id,
              );
            }
          } catch (e) {
            debugPrint('Workmanager re-schedule error for task ${t.id}: $e');
          }
        }
      }

      // Self-renew: re-register the periodic task to ensure it keeps running
      // even if Android OS tries to throttle or stop it.
      try {
        await Workmanager().registerPeriodicTask(
          'focusflow_periodic_reminder_task',
          'focusflow_periodic_reminder_task',
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } catch (e) {
        debugPrint('Workmanager self-renewal error: $e');
      }
    } catch (e) {
      debugPrint('Background Workmanager error: $e');
    }
    return Future.value(true);
  });
}


void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine if launched silently (e.g. from Windows Startup registry key)
  final bool startSilent = args.contains('--silent') || args.contains('--minimized');

  // Initialize Firebase on Android for FCM
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  // Initialize background Workmanager on Android for periodic checks when closed
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'focusflow_periodic_reminder_task',
        'focusflow_periodic_reminder_task',
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('Workmanager init error: $e');
    }
  }

  // local_notifier is desktop-only (Windows/macOS/Linux).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await localNotifier.setup(appName: 'FocusFlow');
      if (Platform.isWindows) {
        // Pass startSilent so tray service hides the window on startup
        await WindowsTrayService.instance.init(startSilent: startSilent);
      }
    } catch (e) {
      debugPrint('LocalNotifier/Tray setup warning: $e');
    }
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv load warning: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialize error: $e');
    }
  }

  // Initialize FCM on Android (after Supabase so token can be stored)
  if (!kIsWeb && Platform.isAndroid) {
    await FcmService.instance.init();
  }

  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);
  final repository = FocusFlowRepository();

  final syncEngine = SupabaseSyncEngine(
    repository: repository,
    preferences: prefs,
    preferencesService: preferencesService,
  );

  // Debounce forceSync on rapid local data mutations (500ms debounce)
  Timer? syncDebounceTimer;
  repository.onDataChanged = () {
    syncDebounceTimer?.cancel();
    syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      syncEngine.forceSync();
    });
  };

  runApp(FocusFlowApp(
    repository: repository,
    preferencesService: preferencesService,
    syncEngine: syncEngine,
  ));
}


