import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';
import '../utils/icon_mapper.dart';

class FocusFlowColorPalette extends StatelessWidget {
  const FocusFlowColorPalette({
    super.key,
    required this.selectedColor,
    required this.onSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Wrap(
      spacing: FocusFlowSpacing.sm,
      runSpacing: FocusFlowSpacing.sm,
      children: [
        for (final color in FocusFlowColors.goalTypeChoices)
          Tooltip(
            message:
                '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            child: InkWell(
              borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
              onTap: () => onSelected(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == color
                        ? scaffoldBg
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FocusFlowIconPalette extends StatelessWidget {
  const FocusFlowIconPalette({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  final IconData selectedIcon;
  final ValueChanged<IconData> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FocusFlowSpacing.sm,
      runSpacing: FocusFlowSpacing.sm,
      children: [
        for (final icon in FocusFlowIconMapper.choices)
          InkWell(
            onTap: () => onSelected(icon),
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedIcon == icon
                    ? FocusFlowColors.brand
                    : FocusFlowColors.surfaceLow,
                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                border: Border.all(
                  color: selectedIcon == icon
                      ? FocusFlowColors.brand
                      : FocusFlowColors.border,
                ),
              ),
              child: Icon(
                icon,
                color: selectedIcon == icon ? Colors.white : FocusFlowColors.quiet,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

