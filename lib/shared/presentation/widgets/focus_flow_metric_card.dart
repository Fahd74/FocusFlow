import 'package:flutter/material.dart';

import '../../../app/theme/focus_flow_colors.dart';
import '../../../app/theme/focus_flow_tokens.dart';
import 'focus_flow_card.dart';
import 'focus_flow_progress_bar.dart';

class FocusFlowMetricItem {
  const FocusFlowMetricItem({
    required this.value,
    required this.label,
    this.tone = FocusFlowColors.brand,
  });

  final String value;
  final String label;
  final Color tone;
}

class FocusFlowMetricCard extends StatelessWidget {
  const FocusFlowMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.label,
    this.icon,
    this.items = const [],
    this.progress,
  });

  final String title;
  final String value;
  final String label;
  final IconData? icon;
  final List<FocusFlowMetricItem> items;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FocusFlowColors.brandSoft,
                    borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: FocusFlowColors.brand,
                    size: 22,
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: FocusFlowColors.ink,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: FocusFlowSpacing.md),
          if (items.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final item in items)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          item.value,
                          style: TextStyle(
                            color: item.tone,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FocusFlowColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                      ),
                ),
                const SizedBox(width: FocusFlowSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    color: FocusFlowColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (progress != null) ...[
            const SizedBox(height: FocusFlowSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Completion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FocusFlowColors.quiet,
                  ),
                ),
                Text(
                  '${(progress!.clamp(0.0, 1.0) * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FocusFlowColors.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: FocusFlowColors.surfaceHigh,
                color: FocusFlowColors.brand,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FocusFlowCompletionCard extends StatelessWidget {
  const FocusFlowCompletionCard({
    super.key,
    required this.title,
    required this.percentLabel,
    required this.progress,
    required this.caption,
    this.deltaLabel,
  });

  final String title;
  final String percentLabel;
  final double progress;
  final String caption;
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FocusFlowColors.brandSoft,
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: FocusFlowColors.brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: FocusFlowSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: FocusFlowColors.ink,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: FocusFlowSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentLabel,
                style: const TextStyle(
                  color: FocusFlowColors.brand,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (deltaLabel != null)
                Text(
                  deltaLabel!,
                  style: const TextStyle(
                    color: FocusFlowColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: FocusFlowSpacing.xs),
          FocusFlowProgressBar(value: progress, height: 6),
        ],
      ),
    );
  }
}
