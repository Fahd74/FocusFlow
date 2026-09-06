import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';
import 'focus_flow_card.dart';

class FocusFlowEmptyState extends StatelessWidget {
  const FocusFlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: FocusFlowColors.brandSoft,
              borderRadius: BorderRadius.circular(FocusFlowRadius.md),
            ),
            child: Icon(icon, color: FocusFlowColors.brand),
          ),
          const SizedBox(height: FocusFlowSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FocusFlowSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: FocusFlowSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
