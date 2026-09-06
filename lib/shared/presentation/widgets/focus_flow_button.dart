import 'package:flutter/material.dart';

class FocusFlowPrimaryButton extends StatelessWidget {
  const FocusFlowPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
        : FilledButton(
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class FocusFlowSecondaryButton extends StatelessWidget {
  const FocusFlowSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? OutlinedButton(
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
