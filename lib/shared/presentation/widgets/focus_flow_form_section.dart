import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_tokens.dart';
import 'focus_flow_card.dart';

class FocusFlowFormSection extends StatelessWidget {
  const FocusFlowFormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: FocusFlowSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: FocusFlowSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
