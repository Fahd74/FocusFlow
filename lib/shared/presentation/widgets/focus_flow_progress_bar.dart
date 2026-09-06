import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowProgressBar extends StatelessWidget {
  const FocusFlowProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = FocusFlowColors.brand,
    this.backgroundColor = FocusFlowColors.progressTrack,
  });

  final double value;
  final double height;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class FocusFlowProgressRow extends StatelessWidget {
  const FocusFlowProgressRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.color = FocusFlowColors.brand,
  });

  final String title;
  final String subtitle;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
              ),
              child: Icon(icon, color: color, size: FocusFlowIconSize.md),
            ),
            const SizedBox(width: FocusFlowSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: FocusFlowSpacing.sm),
        FocusFlowProgressBar(value: value, color: color),
      ],
    );
  }
}
