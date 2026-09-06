import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';

class FocusFlowFilterChip extends StatelessWidget {
  const FocusFlowFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? FocusFlowColors.brand : FocusFlowColors.muted,
            ),
      label: Text(label),
    );
  }
}
