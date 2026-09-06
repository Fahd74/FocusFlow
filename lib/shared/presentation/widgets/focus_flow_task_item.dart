import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowTaskItem extends StatelessWidget {
  const FocusFlowTaskItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FocusFlowSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: active
                    ? FocusFlowColors.brandSoft
                    : Colors.transparent,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: active ? FocusFlowColors.brand : FocusFlowColors.quiet,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: FocusFlowColors.quiet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
