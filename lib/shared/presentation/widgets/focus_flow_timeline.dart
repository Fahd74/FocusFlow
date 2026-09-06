import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowTimelineItem extends StatelessWidget {
  const FocusFlowTimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.active = false,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: CircleAvatar(
            radius: 5,
            backgroundColor: active
                ? FocusFlowColors.brand
                : FocusFlowColors.border,
          ),
        ),
        const SizedBox(width: FocusFlowSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FocusFlowColors.surfaceNeutral,
              borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
            ),
            child: Text(trailing!, style: const TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}
