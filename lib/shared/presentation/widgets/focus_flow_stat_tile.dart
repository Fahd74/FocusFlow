import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowStatTile extends StatelessWidget {
  const FocusFlowStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = FocusFlowColors.brand,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FocusFlowSpacing.md),
      decoration: BoxDecoration(
        color: FocusFlowColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        border: Border.all(color: FocusFlowColors.border),
        boxShadow: FocusFlowShadows.card,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
              ),
              child: Icon(icon, color: color, size: FocusFlowIconSize.md),
            ),
            const SizedBox(width: FocusFlowSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
