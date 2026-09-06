import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

enum FocusFlowBadgeTone { neutral, brand, success, warning, danger }

class FocusFlowBadge extends StatelessWidget {
  const FocusFlowBadge({
    super.key,
    required this.label,
    this.tone = FocusFlowBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final FocusFlowBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      FocusFlowBadgeTone.brand => (
        FocusFlowColors.brandSoft,
        FocusFlowColors.brand,
      ),
      FocusFlowBadgeTone.success => (
        FocusFlowColors.successSoft,
        FocusFlowColors.success,
      ),
      FocusFlowBadgeTone.warning => (
        FocusFlowColors.warningSoft,
        FocusFlowColors.warning,
      ),
      FocusFlowBadgeTone.danger => (
        FocusFlowColors.dangerSoft,
        FocusFlowColors.danger,
      ),
      FocusFlowBadgeTone.neutral => (
        FocusFlowColors.surfaceNeutral,
        FocusFlowColors.muted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: FocusFlowIconSize.sm, color: colors.$2),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
