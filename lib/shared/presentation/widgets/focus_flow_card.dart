import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowCard extends StatelessWidget {
  const FocusFlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FocusFlowSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FocusFlowColors.surface,
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        border: Border.all(color: FocusFlowColors.border),
        boxShadow: FocusFlowShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
