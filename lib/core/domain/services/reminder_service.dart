import '../focus_flow_models.dart';
import 'preferences_service.dart';

class ReminderService {
  ReminderService(this._preferencesService);

  final PreferencesService _preferencesService;

  bool isEligibleForReminder(FocusTask task) {
    // Remind ONLY for tasks that are not yet started
    if (task.status != ItemStatus.notYet) return false;

    final now = DateTime.now();
    if (now.isBefore(task.startDate)) return false;

    // Check DND enabled toggle before checking hours
    if (_preferencesService.dndEnabled) {
      final dndStartHour = _preferencesService.dndStartHour;
      final dndStartMinute = _preferencesService.dndStartMinute;
      final dndEndHour = _preferencesService.dndEndHour;
      final dndEndMinute = _preferencesService.dndEndMinute;

      final currentTotalMinutes = now.hour * 60 + now.minute;
      final dndStartTotal = dndStartHour * 60 + dndStartMinute;
      final dndEndTotal = dndEndHour * 60 + dndEndMinute;

      // Handle overnight DND (e.g. 22:00 to 08:00)
      if (dndStartTotal > dndEndTotal) {
        if (currentTotalMinutes >= dndStartTotal ||
            currentTotalMinutes < dndEndTotal) {
          return false;
        }
      } else if (dndStartTotal < dndEndTotal) {
        // Daytime DND (e.g. 09:00 to 17:00)
        if (currentTotalMinutes >= dndStartTotal &&
            currentTotalMinutes < dndEndTotal) {
          return false;
        }
      }
    }

    final secondsElapsed = task.lastReminderAt == null
        ? now.difference(task.startDate).inSeconds
        : now.difference(task.lastReminderAt!).inSeconds;

    // Use a small 5-second tolerance to account for minor timer drift/early ticks
    return secondsElapsed >= (task.reminderIntervalMinutes * 60 - 5);
  }
}
