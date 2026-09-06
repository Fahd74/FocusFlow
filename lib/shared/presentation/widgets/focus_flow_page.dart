import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';

class FocusFlowPage extends StatelessWidget {
  const FocusFlowPage({
    super.key,
    this.title = '',
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.onRefresh,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600
            ? FocusFlowSpacing.md
            : constraints.maxWidth < 900
            ? FocusFlowSpacing.lg
            : FocusFlowSpacing.xxl;

        final hasHeader = title.isNotEmpty ||
            leading != null ||
            subtitle != null ||
            actions.isNotEmpty;

        final body = ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            constraints.maxWidth < 600
                ? FocusFlowSpacing.lg
                : FocusFlowSpacing.xl,
            horizontalPadding,
            FocusFlowSpacing.xxl,
          ),
          children: [
            if (hasHeader) ...[
              Wrap(
                spacing: FocusFlowSpacing.md,
                runSpacing: FocusFlowSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(height: FocusFlowSpacing.md),
                        ],
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: FocusFlowSpacing.xs),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: FocusFlowSpacing.sm, children: actions),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.xl),
            ],
            ...children,
          ],
        );

        if (onRefresh != null) {
          return RefreshIndicator(
            onRefresh: onRefresh!,
            color: FocusFlowColors.brand,
            child: body,
          );
        }

        return body;
      },
    );
  }
}

class FocusFlowSectionHeader extends StatelessWidget {
  const FocusFlowSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
