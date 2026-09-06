import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';

/// FocusFlow Logo – Connectivity Blue theme (DESIGN.md)
/// Uses a network-node inspired mark: outer ring + center connector dot
class FocusFlowLogo extends StatelessWidget {
  const FocusFlowLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 32.0 : 38.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        Image.asset(
          'assets/images/logo.png',
          width: markSize,
          height: markSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FocusFlow',
              style: TextStyle(
                fontFamily: 'OpenSans',
                color: FocusFlowColors.brand, // primary brand color per DESIGN.md
                fontWeight: FontWeight.w700,
                fontSize: compact ? 17 : 16,
                height: 1,
                letterSpacing: -0.2,
              ),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Productivity Suite',
                  style: TextStyle(
                    color: FocusFlowColors.muted,
                    fontSize: 11,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
    );
  }
}
