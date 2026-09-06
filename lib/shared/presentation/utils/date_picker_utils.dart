import 'package:flutter/material.dart';
import '../../../../app/theme/focus_flow_colors.dart';

Future<DateTime?> selectFocusFlowDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final result = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FocusFlowColors.brand,
            onPrimary: FocusFlowColors.surface,
            onSurface: FocusFlowColors.ink,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: FocusFlowColors.brand),
          ),
        ),
        child: child!,
      );
    },
  );

  if (result != null) {
    // Keep existing time of day, but change the date
    return DateTime(
      result.year,
      result.month,
      result.day,
      initialDate.hour,
      initialDate.minute,
    );
  }
  return null;
}
