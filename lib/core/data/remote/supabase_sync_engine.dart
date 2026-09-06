import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/focus_flow_models.dart';
import '../../domain/services/preferences_service.dart';
import '../focus_flow_repository.dart';

class SupabaseSyncEngine {
  SupabaseSyncEngine({
    required this.repository,
    required this.preferences,
    this.preferencesService,
  }) {
    if (_supabase.auth.currentSession != null) {
      _startSyncTimer();
    }
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _startSyncTimer();
      } else {
        _stopSyncTimer();
      }
    });
  }

  final FocusFlowRepository repository;
  final SharedPreferences preferences;
  final PreferencesService? preferencesService;
  void Function()? onSettingsSynced;

  /// Called when a remote device sends a notification dismissal broadcast.
  /// Set this callback in ReminderCubit to cancel the local notification.
  void Function(String taskId)? onRemoteNotificationDismissed;

  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _syncTimer;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _broadcastChannel;
  bool _isSyncing = false;

  String _lastSyncKey(String userId) => 'last_supabase_sync_time_$userId';

  void _startSyncTimer() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _subscribeRealtime(userId);
      _subscribeBroadcast(userId);
    }
    _sync(); // Initial sync
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => _sync());
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _stopSyncTimer();
  }

  void _subscribeRealtime(String userId) {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = _supabase
          .channel('public:focus_flow_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            callback: (payload) {
              debugPrint('Supabase Realtime event received for table: ${payload.table}');
              if (payload.table == 'user_preferences') {
                _pullPreferencesOnly(userId);
              } else if (!_isSyncing) {
                _pullChanges(null, userId);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  /// Subscribe to the user-scoped broadcast channel for cross-device events (dismissals & settings).
  void _subscribeBroadcast(String userId) {
    try {
      _broadcastChannel?.unsubscribe();
      _broadcastChannel = _supabase
          .channel('focusflow_notifications_$userId')
          .onBroadcast(
            event: 'notification_dismissed',
            callback: (payload) {
              final taskId = payload['task_id'] as String?;
              if (taskId != null) {
                debugPrint('Remote notification dismissal for task: $taskId');
                onRemoteNotificationDismissed?.call(taskId);
              }
            },
          )
          .onBroadcast(
            event: 'settings_updated',
            callback: (payload) async {
              try {
                final settings = payload['settings'] as Map?;
                if (settings != null && preferencesService != null) {
                  debugPrint('Remote settings broadcast received: $settings');
                  final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(settings);
                  await preferencesService!.fromMap(settingsMap);
                  onSettingsSynced?.call();
                }
              } catch (e) {
                debugPrint('Error applying broadcast settings: $e');
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Broadcast subscription error: $e');
    }
  }

  /// Broadcast a notification dismissal event to all other devices of this user.
  Future<void> broadcastNotificationDismissed(String taskId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _broadcastChannel == null) return;
      await _broadcastChannel!.sendBroadcastMessage(
        event: 'notification_dismissed',
        payload: {'task_id': taskId},
      );
      debugPrint('Broadcast dismissal sent for task: $taskId');
    } catch (e) {
      debugPrint('Broadcast send error: $e');
    }
  }

  /// Broadcast instant settings update to all other devices of this user.
  Future<void> broadcastSettingsUpdated() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _broadcastChannel == null || preferencesService == null) return;
      await _broadcastChannel!.sendBroadcastMessage(
        event: 'settings_updated',
        payload: {'settings': preferencesService!.toMap()},
      );
      debugPrint('Broadcast settings updated sent');
    } catch (e) {
      debugPrint('Broadcast settings send error: $e');
    }
  }

  Future<void> forceSync() => _sync();

  Future<void> _sync() async {
    if (_isSyncing) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isSyncing = true;
    try {
      final key = _lastSyncKey(userId);
      final lastSyncIso = preferences.getString(key);
      DateTime? lastSync;
      if (lastSyncIso != null) {
        lastSync = DateTime.parse(lastSyncIso);
      }

      final now = DateTime.now().toUtc();

      // 1. Push local changes to Supabase FIRST
      await _pushChanges(lastSync, userId);

      // 2. Pull changes from Supabase
      await _pullChanges(lastSync, userId);

      // 3. Update user-scoped last sync time ONLY if both push and pull succeeded
      await preferences.setString(key, now.toIso8601String());
      debugPrint('Sync succeeded for user $userId at $now');
    } catch (e, stack) {
      debugPrint('Sync failed: $e\n$stack');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pullChanges(DateTime? lastSync, String userId) async {
    // Pull User Profile
    try {
      try {
        final authResponse = await _supabase.auth.getUser();
        final user = authResponse.user;
        if (user != null && user.userMetadata != null && user.userMetadata!.isNotEmpty) {
          final meta = user.userMetadata!;
          final profile = UserProfile(
            id: user.id,
            fullName: meta['full_name'] as String? ?? user.email ?? '',
            firstName: meta['first_name'] as String? ?? '',
            lastName: meta['last_name'] as String? ?? '',
            email: user.email ?? '',
            avatarUrl: meta['avatar_url'] as String?,
            avatarType: meta['avatar_type'] as String?,
            avatarAsset: meta['avatar_asset'] as String?,
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await repository.upsertUserProfile(profile);
        }
      } catch (_) {}

      final profileData = await _supabase.from('users').select().eq('id', userId);
      for (final row in profileData) {
        final profile = UserProfile(
          id: row['id'],
          fullName: row['full_name'],
          firstName: row['first_name'] ?? '',
          lastName: row['last_name'] ?? '',
          email: row['email'],
          avatarUrl: row['avatar_url'],
          avatarType: row['avatar_type'],
          avatarAsset: row['avatar_asset'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
        );
        await repository.upsertUserProfile(profile);
      }
    } catch (e) {
      debugPrint('Pull user profile failed: $e');
    }

    // Pull Goal Types
    try {
      var queryTypes = _supabase.from('goal_types').select().eq('user_id', userId);
      if (lastSync != null) {
        queryTypes = queryTypes.gte('updated_at', lastSync.toIso8601String());
      }
      final typesData = await queryTypes;
      for (final row in typesData) {
        final type = CustomGoalType(
          id: row['id'],
          name: row['name'],
          colorHex: row['color_hex'],
          iconCode: row['icon_code'],
          isDefault: row['is_default'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at']) : null,
          userId: row['user_id'],
        );
        await repository.upsertGoalType(type);
      }
    } catch (e) {
      debugPrint('Pull goal types failed: $e');
    }

    // Pull Goals
    try {
      var queryGoals = _supabase.from('goals').select().eq('user_id', userId);
      if (lastSync != null) {
        queryGoals = queryGoals.gte('updated_at', lastSync.toIso8601String());
      }
      final goalsData = await queryGoals;
      for (final row in goalsData) {
        final goal = Goal(
          id: row['id'],
          title: row['title'],
          description: row['description'],
          typeId: row['type_id'],
          status: row['status'] != null
              ? ItemStatus.values.firstWhere(
                  (e) => e.name == row['status'],
                  orElse: () => ItemStatus.inProgress,
                )
              : ItemStatus.inProgress,
          startDate: DateTime.parse(row['start_date']),
          endDate: DateTime.parse(row['end_date']),
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at']) : null,
          userId: row['user_id'],
        );
        await repository.upsertGoal(goal);
      }
    } catch (e) {
      debugPrint('Pull goals failed: $e');
    }

    // Pull Tasks
    try {
      var queryTasks = _supabase.from('tasks').select().eq('user_id', userId);
      if (lastSync != null) {
        queryTasks = queryTasks.gte('updated_at', lastSync.toIso8601String());
      }
      final tasksData = await queryTasks;
      for (final row in tasksData) {
        final task = FocusTask(
          id: row['id'],
          goalId: row['goal_id'],
          title: row['title'],
          description: row['description'],
          status: ItemStatus.values.firstWhere(
            (e) => e.name == row['status'],
            orElse: () => ItemStatus.notYet,
          ),
          startDate: DateTime.parse(row['start_date']),
          endDate: DateTime.parse(row['end_date']),
          reminderIntervalMinutes: row['reminder_interval_minutes'],
          startedAt: row['started_at'] != null ? DateTime.parse(row['started_at']) : null,
          completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at']) : null,
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
          deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at']) : null,
          userId: row['user_id'],
          lastReminderAt: row['last_reminder_at'] != null ? DateTime.parse(row['last_reminder_at']) : null,
        );
        await repository.upsertTask(task);
      }
    } catch (e) {
      debugPrint('Pull tasks failed: $e');
    }

    // Pull Preferences
    await _pullPreferencesOnly(userId);
  }

  Future<void> _pullPreferencesOnly(String userId) async {
    try {
      if (preferencesService != null) {
        final prefData = await _supabase.from('user_preferences').select().eq('user_id', userId).maybeSingle();
        if (prefData != null && prefData['settings'] != null) {
          final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(prefData['settings'] as Map);
          await preferencesService!.fromMap(settingsMap);
          onSettingsSynced?.call();
          debugPrint('User preferences pulled and applied successfully');
        }
      }
    } catch (e) {
      debugPrint('Pull user preferences failed: $e');
    }
  }

  Future<void> _pushChanges(DateTime? lastSync, String userId) async {
    final lastSyncUtc = lastSync?.toUtc();

    // Push Preferences
    try {
      if (preferencesService != null) {
        final payload = {
          'user_id': userId,
          'settings': preferencesService!.toMap(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        await _supabase.from('user_preferences').upsert(payload);
      }
    } catch (e) {
      debugPrint('Push user preferences failed: $e');
    }

    // Push Goal Types (including soft-deleted types)
    try {
      final typesToPush = await repository.getAllGoalTypesForSync(
        since: lastSyncUtc,
        userId: userId,
      );
      if (typesToPush.isNotEmpty) {
        final payload = typesToPush.map((t) => {
          'id': t.id,
          'name': t.name,
          'color_hex': t.colorHex,
          'icon_code': t.iconCode,
          'is_default': t.isDefault,
          'created_at': t.createdAt.toUtc().toIso8601String(),
          'updated_at': t.updatedAt.toUtc().toIso8601String(),
          'deleted_at': t.deletedAt?.toUtc().toIso8601String(),
          'user_id': userId,
        }).toList();
        await _supabase.from('goal_types').upsert(payload);
      }
    } catch (e) {
      debugPrint('Push goal types failed: $e');
    }

    // Push Goals (including soft-deleted goals)
    try {
      final goalsToPush = await repository.getAllGoalsForSync(
        since: lastSyncUtc,
        userId: userId,
      );
      if (goalsToPush.isNotEmpty) {
        final payload = goalsToPush.map((g) => {
          'id': g.id,
          'title': g.title,
          'description': g.description,
          'type_id': g.typeId,
          'status': g.status.name,
          'start_date': g.startDate.toUtc().toIso8601String(),
          'end_date': g.endDate.toUtc().toIso8601String(),
          'created_at': g.createdAt.toUtc().toIso8601String(),
          'updated_at': g.updatedAt.toUtc().toIso8601String(),
          'deleted_at': g.deletedAt?.toUtc().toIso8601String(),
          'user_id': userId,
        }).toList();
        await _supabase.from('goals').upsert(payload);
      }
    } catch (e) {
      debugPrint('Push goals failed: $e');
    }

    // Push Tasks (including soft-deleted tasks)
    try {
      final tasksToPush = await repository.getAllTasksForSync(
        since: lastSyncUtc,
        userId: userId,
      );
      if (tasksToPush.isNotEmpty) {
        final payload = tasksToPush.map((t) => {
          'id': t.id,
          'goal_id': t.goalId,
          'title': t.title,
          'description': t.description,
          'status': t.status.name,
          'start_date': t.startDate.toUtc().toIso8601String(),
          'end_date': t.endDate.toUtc().toIso8601String(),
          'reminder_interval_minutes': t.reminderIntervalMinutes,
          'started_at': t.startedAt?.toUtc().toIso8601String(),
          'completed_at': t.completedAt?.toUtc().toIso8601String(),
          'created_at': t.createdAt.toUtc().toIso8601String(),
          'updated_at': t.updatedAt.toUtc().toIso8601String(),
          'deleted_at': t.deletedAt?.toUtc().toIso8601String(),
          'user_id': userId,
          'last_reminder_at': t.lastReminderAt?.toUtc().toIso8601String(),
        }).toList();
        await _supabase.from('tasks').upsert(payload);
      }
    } catch (e) {
      debugPrint('Push tasks failed: $e');
    }
  }
}
