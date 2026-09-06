import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;
  String? userId;

  PreferencesService(this._prefs);

  static const _keyDndStartHour = 'dnd_start_hour';
  static const _keyDndEndHour = 'dnd_end_hour';
  static const _keyDndStartMinute = 'dnd_start_minute';
  static const _keyDndEndMinute = 'dnd_end_minute';
  static const _keyNotificationSound = 'notification_sound';
  static const _keyTaskDeadlines = 'task_deadlines_enabled';
  static const _keyStreakAlerts = 'streak_alerts_enabled';
  static const _keyMobileNotifications = 'mobile_notifications_enabled';
  static const _keyEmailDigests = 'email_digests_enabled';
  static const _keyDesktopNotifications = 'desktop_notifications_enabled';
  static const _keyDndEnabled = 'dnd_enabled';
  static const _keyDesktopNotificationSound = 'desktop_notification_sound';
  static const _keyGuestName = 'guest_name';
  static const _keyGuestFirstName = 'guest_first_name';
  static const _keyGuestLastName = 'guest_last_name';
  static const _keyGuestEmail = 'guest_email';
  static const _keyCustomNotificationSoundPath = 'custom_notification_sound_path';
  static const _keyCustomDesktopNotificationSoundPath = 'custom_desktop_notification_sound_path';
  static const _keyAvatarType = 'avatar_type';
  static const _keyAvatarValue = 'avatar_value';
  static const _keyWindowsAutoStart = 'windows_auto_start_enabled';
  static const _keyPendingCompletedTaskIds = 'pending_completed_task_ids';

  String _getIsolatedKey(String baseKey) {
    if (userId == null) {
      return '${baseKey}_guest';
    }
    return '${baseKey}_$userId';
  }

  int get dndStartHour => _prefs.getInt(_getIsolatedKey(_keyDndStartHour)) ?? 22;
  int get dndStartMinute => _prefs.getInt(_getIsolatedKey(_keyDndStartMinute)) ?? 0;
  int get dndEndHour => _prefs.getInt(_getIsolatedKey(_keyDndEndHour)) ?? 8;
  int get dndEndMinute => _prefs.getInt(_getIsolatedKey(_keyDndEndMinute)) ?? 0;
  String get notificationSound =>
      _prefs.getString(_getIsolatedKey(_keyNotificationSound)) ?? 'chime';
  bool get taskDeadlines => _prefs.getBool(_getIsolatedKey(_keyTaskDeadlines)) ?? true;
  bool get streakAlerts => _prefs.getBool(_getIsolatedKey(_keyStreakAlerts)) ?? true;
  bool get mobileNotifications => _prefs.getBool(_getIsolatedKey(_keyMobileNotifications)) ?? true;
  bool get emailDigests => _prefs.getBool(_getIsolatedKey(_keyEmailDigests)) ?? false;
  bool get desktopNotifications => _prefs.getBool(_getIsolatedKey(_keyDesktopNotifications)) ?? true;
  bool get dndEnabled => _prefs.getBool(_getIsolatedKey(_keyDndEnabled)) ?? true;
  String get desktopNotificationSound => _prefs.getString(_getIsolatedKey(_keyDesktopNotificationSound)) ?? 'chime';
  bool get windowsAutoStart => _prefs.getBool(_keyWindowsAutoStart) ?? false;
  List<String> get pendingCompletedTaskIds => _prefs.getStringList(_keyPendingCompletedTaskIds) ?? [];
  String get guestName => _prefs.getString(_keyGuestName) ?? 'Guest User';
  String get guestFirstName => _prefs.getString(_keyGuestFirstName) ?? 'Guest';
  String get guestLastName => _prefs.getString(_keyGuestLastName) ?? 'User';
  String get guestEmail => _prefs.getString(_keyGuestEmail) ?? 'guest@focusflow.ai';
  String? get customNotificationSoundPath => _prefs.getString(_getIsolatedKey(_keyCustomNotificationSoundPath));
  String? get customDesktopNotificationSoundPath => _prefs.getString(_getIsolatedKey(_keyCustomDesktopNotificationSoundPath));
  String? get avatarType => _prefs.getString(_getIsolatedKey(_keyAvatarType));
  String? get avatarValue => _prefs.getString(_getIsolatedKey(_keyAvatarValue));

  DateTime? lastLocalUpdate;

  void _markLocalUpdate() {
    lastLocalUpdate = DateTime.now().toUtc();
  }

  Future<void> setDndStart(int hour, int minute) async {
    _markLocalUpdate();
    await _prefs.setInt(_getIsolatedKey(_keyDndStartHour), hour);
    await _prefs.setInt(_getIsolatedKey(_keyDndStartMinute), minute);
  }

  Future<void> setDndEnd(int hour, int minute) async {
    _markLocalUpdate();
    await _prefs.setInt(_getIsolatedKey(_keyDndEndHour), hour);
    await _prefs.setInt(_getIsolatedKey(_keyDndEndMinute), minute);
  }

  Future<void> setDndStartHour(int hour) async {
    _markLocalUpdate();
    await _prefs.setInt(_getIsolatedKey(_keyDndStartHour), hour);
  }

  Future<void> setDndEndHour(int hour) async {
    _markLocalUpdate();
    await _prefs.setInt(_getIsolatedKey(_keyDndEndHour), hour);
  }

  Future<void> setNotificationSound(String sound) async {
    _markLocalUpdate();
    await _prefs.setString(_getIsolatedKey(_keyNotificationSound), sound);
  }

  Future<void> setTaskDeadlines(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyTaskDeadlines), enabled);
  }

  Future<void> setStreakAlerts(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyStreakAlerts), enabled);
  }

  Future<void> setMobileNotifications(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyMobileNotifications), enabled);
  }

  Future<void> setEmailDigests(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyEmailDigests), enabled);
  }

  Future<void> setDesktopNotifications(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyDesktopNotifications), enabled);
  }

  Future<void> setDndEnabled(bool enabled) async {
    _markLocalUpdate();
    await _prefs.setBool(_getIsolatedKey(_keyDndEnabled), enabled);
  }

  Future<void> setDesktopNotificationSound(String sound) async {
    _markLocalUpdate();
    await _prefs.setString(_getIsolatedKey(_keyDesktopNotificationSound), sound);
  }

  Future<void> setGuestName(String name) async {
    await _prefs.setString(_keyGuestName, name);
  }

  Future<void> setGuestFirstName(String firstName) async {
    await _prefs.setString(_keyGuestFirstName, firstName);
  }

  Future<void> setGuestLastName(String lastName) async {
    await _prefs.setString(_keyGuestLastName, lastName);
  }

  Future<void> setGuestEmail(String email) async {
    await _prefs.setString(_keyGuestEmail, email);
  }

  Future<void> setCustomNotificationSoundPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_getIsolatedKey(_keyCustomNotificationSoundPath));
    } else {
      await _prefs.setString(_getIsolatedKey(_keyCustomNotificationSoundPath), path);
    }
  }

  Future<void> setCustomDesktopNotificationSoundPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_getIsolatedKey(_keyCustomDesktopNotificationSoundPath));
    } else {
      await _prefs.setString(_getIsolatedKey(_keyCustomDesktopNotificationSoundPath), path);
    }
  }

  Future<void> setAvatarType(String? type) async {
    if (type == null) {
      await _prefs.remove(_getIsolatedKey(_keyAvatarType));
    } else {
      await _prefs.setString(_getIsolatedKey(_keyAvatarType), type);
    }
  }

  Future<void> setAvatarValue(String? value) async {
    if (value == null) {
      await _prefs.remove(_getIsolatedKey(_keyAvatarValue));
    } else {
      await _prefs.setString(_getIsolatedKey(_keyAvatarValue), value);
    }
  }

  Future<void> setWindowsAutoStart(bool enabled) async {
    await _prefs.setBool(_keyWindowsAutoStart, enabled);
  }

  Future<void> clearPendingCompletedTaskIds() async {
    await _prefs.remove(_keyPendingCompletedTaskIds);
  }

  Map<String, dynamic> toMap() {
    return {
      'dnd_start_hour': dndStartHour,
      'dnd_start_minute': dndStartMinute,
      'dnd_end_hour': dndEndHour,
      'dnd_end_minute': dndEndMinute,
      'notification_sound': notificationSound,
      'task_deadlines_enabled': taskDeadlines,
      'streak_alerts_enabled': streakAlerts,
      'mobile_notifications_enabled': mobileNotifications,
      'email_digests_enabled': emailDigests,
      'desktop_notifications_enabled': desktopNotifications,
      'dnd_enabled': dndEnabled,
      'desktop_notification_sound': desktopNotificationSound,
    };
  }

  Future<void> fromMap(Map<String, dynamic> map) async {
    if (map['dnd_start_hour'] != null) await _prefs.setInt(_getIsolatedKey(_keyDndStartHour), map['dnd_start_hour'] as int);
    if (map['dnd_start_minute'] != null) await _prefs.setInt(_getIsolatedKey(_keyDndStartMinute), map['dnd_start_minute'] as int);
    if (map['dnd_end_hour'] != null) await _prefs.setInt(_getIsolatedKey(_keyDndEndHour), map['dnd_end_hour'] as int);
    if (map['dnd_end_minute'] != null) await _prefs.setInt(_getIsolatedKey(_keyDndEndMinute), map['dnd_end_minute'] as int);
    if (map['notification_sound'] != null) await _prefs.setString(_getIsolatedKey(_keyNotificationSound), map['notification_sound'] as String);
    if (map['task_deadlines_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyTaskDeadlines), map['task_deadlines_enabled'] as bool);
    if (map['streak_alerts_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyStreakAlerts), map['streak_alerts_enabled'] as bool);
    if (map['mobile_notifications_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyMobileNotifications), map['mobile_notifications_enabled'] as bool);
    if (map['email_digests_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyEmailDigests), map['email_digests_enabled'] as bool);
    if (map['desktop_notifications_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyDesktopNotifications), map['desktop_notifications_enabled'] as bool);
    if (map['dnd_enabled'] != null) await _prefs.setBool(_getIsolatedKey(_keyDndEnabled), map['dnd_enabled'] as bool);
    if (map['desktop_notification_sound'] != null) await _prefs.setString(_getIsolatedKey(_keyDesktopNotificationSound), map['desktop_notification_sound'] as String);
  }
}
