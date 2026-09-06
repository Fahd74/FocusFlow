import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/services/preferences_service.dart';
import '../../../../core/domain/services/windows_tray_service.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.dndStartHour,
    required this.dndStartMinute,
    required this.dndEndHour,
    required this.dndEndMinute,
    required this.notificationSound,
    required this.taskDeadlines,
    required this.streakAlerts,
    required this.mobileNotifications,
    required this.emailDigests,
    required this.desktopNotifications,
    required this.dndEnabled,
    required this.desktopNotificationSound,
    this.windowsAutoStart = false,
    this.customSoundPath,
    this.customDesktopSoundPath,
  });

  final int dndStartHour;
  final int dndStartMinute;
  final int dndEndHour;
  final int dndEndMinute;
  final String notificationSound;
  final bool taskDeadlines;
  final bool streakAlerts;
  final bool mobileNotifications;
  final bool emailDigests;
  final bool desktopNotifications;
  final bool dndEnabled;
  final String desktopNotificationSound;
  final bool windowsAutoStart;
  final String? customSoundPath;
  final String? customDesktopSoundPath;

  TimeOfDay get dndStart => TimeOfDay(hour: dndStartHour, minute: dndStartMinute);
  TimeOfDay get dndEnd => TimeOfDay(hour: dndEndHour, minute: dndEndMinute);

  SettingsState copyWith({
    int? dndStartHour,
    int? dndStartMinute,
    int? dndEndHour,
    int? dndEndMinute,
    String? notificationSound,
    bool? taskDeadlines,
    bool? streakAlerts,
    bool? mobileNotifications,
    bool? emailDigests,
    bool? desktopNotifications,
    bool? dndEnabled,
    String? desktopNotificationSound,
    bool? windowsAutoStart,
    String? customSoundPath,
    bool clearCustomSoundPath = false,
    String? customDesktopSoundPath,
    bool clearCustomDesktopSoundPath = false,
  }) {
    return SettingsState(
      dndStartHour: dndStartHour ?? this.dndStartHour,
      dndStartMinute: dndStartMinute ?? this.dndStartMinute,
      dndEndHour: dndEndHour ?? this.dndEndHour,
      dndEndMinute: dndEndMinute ?? this.dndEndMinute,
      notificationSound: notificationSound ?? this.notificationSound,
      taskDeadlines: taskDeadlines ?? this.taskDeadlines,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      mobileNotifications: mobileNotifications ?? this.mobileNotifications,
      emailDigests: emailDigests ?? this.emailDigests,
      desktopNotifications: desktopNotifications ?? this.desktopNotifications,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      desktopNotificationSound: desktopNotificationSound ?? this.desktopNotificationSound,
      windowsAutoStart: windowsAutoStart ?? this.windowsAutoStart,
      customSoundPath: clearCustomSoundPath ? null : (customSoundPath ?? this.customSoundPath),
      customDesktopSoundPath: clearCustomDesktopSoundPath ? null : (customDesktopSoundPath ?? this.customDesktopSoundPath),
    );
  }

  @override
  List<Object?> get props => [
        dndStartHour,
        dndStartMinute,
        dndEndHour,
        dndEndMinute,
        notificationSound,
        taskDeadlines,
        streakAlerts,
        mobileNotifications,
        emailDigests,
        desktopNotifications,
        dndEnabled,
        desktopNotificationSound,
        windowsAutoStart,
        customSoundPath,
        customDesktopSoundPath,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._preferencesService)
    : super(
        SettingsState(
          dndStartHour: _preferencesService.dndStartHour,
          dndStartMinute: _preferencesService.dndStartMinute,
          dndEndHour: _preferencesService.dndEndHour,
          dndEndMinute: _preferencesService.dndEndMinute,
          notificationSound: _preferencesService.notificationSound,
          taskDeadlines: _preferencesService.taskDeadlines,
          streakAlerts: _preferencesService.streakAlerts,
          mobileNotifications: _preferencesService.mobileNotifications,
          emailDigests: _preferencesService.emailDigests,
          desktopNotifications: _preferencesService.desktopNotifications,
          dndEnabled: _preferencesService.dndEnabled,
          desktopNotificationSound: _preferencesService.desktopNotificationSound,
          windowsAutoStart: _preferencesService.windowsAutoStart,
          customSoundPath: _preferencesService.customNotificationSoundPath,
          customDesktopSoundPath: _preferencesService.customDesktopNotificationSoundPath,
        ),
      );

  final PreferencesService _preferencesService;
  void Function()? onSettingsChanged;

  void _notify() {
    onSettingsChanged?.call();
  }

  void loadSettings() {
    emit(SettingsState(
      dndStartHour: _preferencesService.dndStartHour,
      dndStartMinute: _preferencesService.dndStartMinute,
      dndEndHour: _preferencesService.dndEndHour,
      dndEndMinute: _preferencesService.dndEndMinute,
      notificationSound: _preferencesService.notificationSound,
      taskDeadlines: _preferencesService.taskDeadlines,
      streakAlerts: _preferencesService.streakAlerts,
      mobileNotifications: _preferencesService.mobileNotifications,
      emailDigests: _preferencesService.emailDigests,
      desktopNotifications: _preferencesService.desktopNotifications,
      dndEnabled: _preferencesService.dndEnabled,
      desktopNotificationSound: _preferencesService.desktopNotificationSound,
      windowsAutoStart: _preferencesService.windowsAutoStart,
      customSoundPath: _preferencesService.customNotificationSoundPath,
      customDesktopSoundPath: _preferencesService.customDesktopNotificationSoundPath,
    ));
  }

  Future<void> updateDndStart(TimeOfDay time) async {
    await _preferencesService.setDndStart(time.hour, time.minute);
    emit(state.copyWith(dndStartHour: time.hour, dndStartMinute: time.minute));
    _notify();
  }

  Future<void> updateDndEnd(TimeOfDay time) async {
    await _preferencesService.setDndEnd(time.hour, time.minute);
    emit(state.copyWith(dndEndHour: time.hour, dndEndMinute: time.minute));
    _notify();
  }

  // Keep legacy single-hour setters for backward compat
  Future<void> updateDndStartHour(int hour) async {
    await _preferencesService.setDndStart(hour, 0);
    emit(state.copyWith(dndStartHour: hour, dndStartMinute: 0));
    _notify();
  }

  Future<void> updateDndEndHour(int hour) async {
    await _preferencesService.setDndEnd(hour, 0);
    emit(state.copyWith(dndEndHour: hour, dndEndMinute: 0));
    _notify();
  }

  Future<void> updateNotificationSound(String sound) async {
    await _preferencesService.setNotificationSound(sound);
    emit(state.copyWith(notificationSound: sound));
    _notify();
  }

  Future<void> updateTaskDeadlines(bool enabled) async {
    await _preferencesService.setTaskDeadlines(enabled);
    emit(state.copyWith(taskDeadlines: enabled));
    _notify();
  }

  Future<void> updateStreakAlerts(bool enabled) async {
    await _preferencesService.setStreakAlerts(enabled);
    emit(state.copyWith(streakAlerts: enabled));
    _notify();
  }

  Future<void> updateMobileNotifications(bool enabled) async {
    await _preferencesService.setMobileNotifications(enabled);
    emit(state.copyWith(mobileNotifications: enabled));
    _notify();
  }

  Future<void> updateEmailDigests(bool enabled) async {
    await _preferencesService.setEmailDigests(enabled);
    emit(state.copyWith(emailDigests: enabled));
    _notify();
  }

  Future<void> updateDesktopNotifications(bool enabled) async {
    await _preferencesService.setDesktopNotifications(enabled);
    emit(state.copyWith(desktopNotifications: enabled));
    _notify();
  }

  Future<void> updateDndEnabled(bool enabled) async {
    await _preferencesService.setDndEnabled(enabled);
    emit(state.copyWith(dndEnabled: enabled));
    _notify();
  }

  Future<void> updateDesktopNotificationSound(String sound) async {
    await _preferencesService.setDesktopNotificationSound(sound);
    emit(state.copyWith(desktopNotificationSound: sound));
    _notify();
  }

  Future<void> updateCustomNotificationSoundPath(String? path) async {
    await _preferencesService.setCustomNotificationSoundPath(path);
    if (path == null) {
      emit(state.copyWith(clearCustomSoundPath: true));
    } else {
      emit(state.copyWith(customSoundPath: path));
    }
    _notify();
  }

  Future<void> updateCustomDesktopNotificationSoundPath(String? path) async {
    await _preferencesService.setCustomDesktopNotificationSoundPath(path);
    if (path == null) {
      emit(state.copyWith(clearCustomDesktopSoundPath: true));
    } else {
      emit(state.copyWith(customDesktopSoundPath: path));
    }
    _notify();
  }

  Future<void> updateWindowsAutoStart(bool enabled) async {
    await _preferencesService.setWindowsAutoStart(enabled);
    await WindowsTrayService.setAutoStart(enabled);
    emit(state.copyWith(windowsAutoStart: enabled));
    _notify();
  }
}
