import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../core/domain/focus_flow_models.dart';
import '../../../../shared/presentation/utils/date_picker_utils.dart';
import '../../../../shared/presentation/utils/icon_mapper.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../../shared/presentation/widgets/focus_flow_card.dart';

import '../../../../shared/presentation/widgets/focus_flow_filter_chip.dart';
import '../../../../core/data/remote/supabase_sync_engine.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';

import '../../../../shared/presentation/widgets/focus_flow_progress_bar.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../cubit/goals_cubit.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsState = context.watch<GoalsCubit>().state;
    final tasksState = context.watch<TasksCubit>().state;

    if (goalsState.isLoading || tasksState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate streak dynamically from tasksState
    final completedDates = tasksState.tasks
        .where((task) => task.completedAt != null)
        .map((task) => DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (completedDates.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final latestCompletion = completedDates.first;
      if (latestCompletion == today || latestCompletion == yesterday) {
        streak = 1;
        for (int i = 0; i < completedDates.length - 1; i++) {
          final current = completedDates[i];
          final next = completedDates[i + 1];
          final difference = current.difference(next).inDays;
          if (difference == 1) {
            streak++;
          } else if (difference > 1) {
            break;
          }
        }
      }
    }

    final activeGoalsCount = goalsState.goals
        .where((g) => g.status != ItemStatus.done)
        .length;
    final completedGoalsCount = goalsState.goals
        .where((g) => g.status == ItemStatus.done)
        .length;
    final totalGoalsCount = goalsState.goals.length;
    final goalCompletionRate = totalGoalsCount > 0 ? (completedGoalsCount / totalGoalsCount) : 0.0;

    final upcomingTasks = tasksState.tasks
        .where((t) => t.status != ItemStatus.done)
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
    final activeTasks = upcomingTasks.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;
        final isMobile = constraints.maxWidth < 600;

        final mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FocusFlowPrimaryButton(
                  label: 'Add Goal',
                  icon: Icons.add_rounded,
                  onPressed: () => context.go(AppRoutes.addGoal),
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.md),
            ],
            // Compact Goal Summary for Mobile (single compact card at top)
            if (isMobile) ...[
              FocusFlowCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: FocusFlowColors.surfaceLow,
                              borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$activeGoalsCount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.brand,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: FocusFlowColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: FocusFlowSpacing.xs),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: FocusFlowColors.surfaceLow,
                              borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$completedGoalsCount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.success,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: FocusFlowColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: FocusFlowSpacing.xs),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: FocusFlowColors.surfaceLow,
                              borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: FocusFlowColors.brand,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        '$streak',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: FocusFlowColors.brand,
                                          height: 1.1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Streak',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: FocusFlowColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FocusFlowSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Completion',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FocusFlowColors.quiet,
                          ),
                        ),
                        Text(
                          '${(goalCompletionRate * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: FocusFlowColors.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                      child: LinearProgressIndicator(
                        value: goalCompletionRate.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: FocusFlowColors.surfaceHigh,
                        color: FocusFlowColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.sm),
            ],
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FocusFlowFilterChip(
                    label: 'All Goals',
                    selected: goalsState.selectedType == null,
                    onSelected: (_) =>
                        context.read<GoalsCubit>().selectType(null),
                  ),
                  for (final type in goalsState.goalTypes) ...[
                    const SizedBox(width: FocusFlowSpacing.sm),
                    FocusFlowFilterChip(
                      label: type.name,
                      selected: goalsState.selectedType == type.id,
                      onSelected: (_) =>
                          context.read<GoalsCubit>().selectType(type.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: FocusFlowSpacing.lg),
            if (goalsState.visibleGoals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.track_changes_outlined,
                        size: 64,
                        color: FocusFlowColors.quiet,
                      ),
                      const SizedBox(height: FocusFlowSpacing.md),
                      Text(
                        goalsState.selectedType == null
                            ? 'You haven\'t set any goals yet.'
                            : 'No goals found for this category.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: FocusFlowSpacing.sm),
                      const Text(
                          'Create a goal to start tracking your progress.'),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goalsState.visibleGoals.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 2 : (constraints.maxWidth >= 640 ? 2 : 1),
                  crossAxisSpacing: FocusFlowSpacing.md,
                  mainAxisSpacing: FocusFlowSpacing.md,
                  mainAxisExtent: 190,
                ),
                itemBuilder: (context, index) {
                  final item = goalsState.visibleGoals[index];
                  final type = goalsState.goalTypes.firstWhere(
                    (t) => t.id == item.goal.typeId,
                    orElse: () => CustomGoalType.fallback,
                  );
                  return _GoalCard(item: item, type: type);
                },
              ),
          ],
        );

        final sidebarContent = Column(
          children: [
            // Goal Summary Panel
            FocusFlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: FocusFlowSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: FocusFlowColors.surfaceLow,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$activeGoalsCount',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: FocusFlowColors.brand,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Active Goals',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FocusFlowColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: FocusFlowSpacing.md),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: FocusFlowColors.surfaceLow,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$completedGoalsCount',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: FocusFlowColors.success,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FocusFlowColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FocusFlowSpacing.sm),
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
                        '${(goalCompletionRate * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 11,
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
                      value: goalCompletionRate.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: FocusFlowColors.surfaceHigh,
                      color: FocusFlowColors.brand,
                    ),
                  ),
                  const SizedBox(height: FocusFlowSpacing.md),
                  // Streak Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          FocusFlowColors.brandSoft,
                          Color(0xFFE8F0FE),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: FocusFlowColors.brand.withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Streak',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: FocusFlowColors.brandHover,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$streak Days',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: FocusFlowColors.brand),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: FocusFlowColors.brand,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocusFlowSpacing.lg),
            // Upcoming Milestones Timeline
            FocusFlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: FocusFlowColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Due Tasks',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FocusFlowSpacing.lg),
                  if (activeTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No upcoming tasks',
                          style: TextStyle(
                            fontSize: 13,
                            color: FocusFlowColors.quiet,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        final task = activeTasks[index];
                        final goalTitle = tasksState.goalTitle(task.goalId);
                        final dayLabel = _getTimelineDayLabel(task.endDate);

                        final circleColor = index == 0
                            ? FocusFlowColors.brand
                            : (index == 1
                                ? FocusFlowColors.secondary
                                : FocusFlowColors.borderStrong);

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline line and circle
                              SizedBox(
                                width: 24,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: FocusFlowColors.surface,
                                        border: Border.all(
                                          color: circleColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    if (index != activeTasks.length - 1)
                                      Expanded(
                                        child: Container(
                                          width: 1.5,
                                          color: FocusFlowColors.border,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: circleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: FocusFlowColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        goalTitle,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: FocusFlowColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: FocusFlowSpacing.xs),
                  IntrinsicWidth(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.tasks),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'View All Tasks',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        Future<void> handleRefresh() async {
          try {
            final syncEngine = context.read<SupabaseSyncEngine?>();
            if (syncEngine != null) {
              await syncEngine.forceSync();
            } else {
              await Future.delayed(const Duration(milliseconds: 600));
            }
          } catch (_) {}
        }

        if (isDesktop) {
          return FocusFlowPage(
            title: '', // Custom page header is inside the grid row
            onRefresh: handleRefresh,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mainContent),
                  const SizedBox(width: FocusFlowSpacing.xl),
                  SizedBox(width: 320, child: sidebarContent),
                ],
              ),
            ],
          );
        }

        // Mobile/Tablet
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: FocusFlowPage(
            title: '', // Custom header inside mainContent
            onRefresh: handleRefresh,
            children: [
              mainContent,
            ],
          ),
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: FocusFlowColors.brand,
                  onPressed: () => context.go(AppRoutes.addGoal),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  String _getTimelineDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.difference(today).inDays < 7 &&
        taskDate.isAfter(today)) {
      return DateFormat('EEEE').format(date); // e.g. "Friday"
    } else {
      return DateFormat('MMM d').format(date); // e.g. "Oct 12"
    }
  }
}

class GoalDetailsScreen extends StatelessWidget {
  const GoalDetailsScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    final goalsState = context.watch<GoalsCubit>().state;
    final tasksState = context.watch<TasksCubit>().state;

    if (goalsState.goalProgress.isEmpty) {
      return FocusFlowPage(
        title: '',
        children: [
          FocusFlowCard(
            child: Column(
              children: [
                const Text('No goals available yet.'),
                const SizedBox(height: 12),
                FocusFlowPrimaryButton(
                  label: 'Back to Goals',
                  onPressed: () => context.go(AppRoutes.goals),
                ),
              ],
            ),
          )
        ],
      );
    }

    final item = goalsState.goalProgress
        .where((entry) => entry.goal.id == goalId)
        .firstOrNull;

    if (item == null) {
      return FocusFlowPage(
        title: '',
        children: [
          FocusFlowCard(
            child: Column(
              children: [
                const Text('Goal not found. It may have been deleted.'),
                const SizedBox(height: 12),
                FocusFlowPrimaryButton(
                  label: 'Back to Goals',
                  onPressed: () => context.go(AppRoutes.goals),
                ),
              ],
            ),
          )
        ],
      );
    }

    final goal = item.goal;
    final type = goalsState.goalTypes.firstWhere(
      (t) => t.id == goal.typeId,
      orElse: () => CustomGoalType.fallback,
    );
    final typeColor = _parseColor(type.colorHex);
    final typeIcon = FocusFlowIconMapper.parseIcon(type.iconCode);

    final goalTasks = tasksState.tasks
        .where((task) => task.goalId == goal.id)
        .toList();

    final notYetCount = goalTasks
        .where((task) => task.status == ItemStatus.notYet)
        .length;
    final inProgressCount = goalTasks
        .where((task) => task.status == ItemStatus.inProgress)
        .length;
    final doneCount = goalTasks
        .where((task) => task.status == ItemStatus.done)
        .length;
    final overdueCount = goalTasks
        .where((task) => task.isOverdue)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;

        return FocusFlowPage(
          title: '', // Custom header with breadcrumbs is built inside
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.goals),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Goals',
                      style: TextStyle(
                        fontSize: 12,
                        color: FocusFlowColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: FocusFlowColors.quiet,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Goal Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: FocusFlowColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.md),

            // Page Header: Title + Status Badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: isDesktop ? 36 : 28,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: FocusFlowSpacing.sm,
                  runSpacing: FocusFlowSpacing.xs,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: FocusFlowColors.surfaceLow,
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.pill),
                        border: Border.all(color: FocusFlowColors.border),
                      ),
                      child: Text(
                        goal.status.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                        ),
                      ),
                    ),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: typeColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            type.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.lg),

            // Description (Above Timeline card, left-aligned)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: FocusFlowSpacing.md),
                child: Text(
                  goal.description.isNotEmpty
                      ? goal.description
                      : 'No description provided.',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 14,
                    color: FocusFlowColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // Timeline & Overall Progress Card (Full width on Desktop & Mobile)
            FocusFlowCard(
              child: Row(
                children: [
                  // Circular Progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: item.progress,
                          strokeWidth: 8,
                          backgroundColor: FocusFlowColors.surfaceLow,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        '${(item.progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Timeline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TIMELINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: FocusFlowColors.quiet,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: FocusFlowColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${DateFormat.yMMMd().format(goal.startDate)} — ${DateFormat.yMMMd().format(goal.endDate)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: FocusFlowColors.brandHover,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocusFlowSpacing.md),

            // Summary Stats Row (5 blocks side-by-side on mobile & desktop)
            Row(
              children: [
                Expanded(
                  child: _BentoStatCard(
                    label: 'Tasks',
                    value: '${goalTasks.length}'.padLeft(2, '0'),
                    color: FocusFlowColors.brand,
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.xs),
                Expanded(
                  child: _BentoStatCard(
                    label: 'Not Yet',
                    value: '$notYetCount'.padLeft(2, '0'),
                    color: FocusFlowColors.quiet,
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.xs),
                Expanded(
                  child: _BentoStatCard(
                    label: 'Active',
                    value: '$inProgressCount'.padLeft(2, '0'),
                    color: FocusFlowColors.warning,
                    bottomBorderColor: FocusFlowColors.warning,
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.xs),
                Expanded(
                  child: _BentoStatCard(
                    label: 'Done',
                    value: '$doneCount'.padLeft(2, '0'),
                    color: FocusFlowColors.success,
                    bottomBorderColor: FocusFlowColors.success,
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.xs),
                Expanded(
                  child: _BentoStatCard(
                    label: 'Overdue',
                    value: '$overdueCount'.padLeft(2, '0'),
                    color: FocusFlowColors.danger,
                    bottomBorderColor: FocusFlowColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.lg),

            // Tasks List
            FocusFlowCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tasks in this Goal',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go(
                              '${AppRoutes.addTask}?goalId=${goal.id}'),
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Add Task'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  if (goalTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No tasks in this goal yet. Click Add Task to start.',
                          style: TextStyle(
                            fontSize: 13,
                            color: FocusFlowColors.quiet,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final task in goalTasks)
                          _GoalDetailsTaskRow(
                            task: task,
                            typeColor: typeColor,
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: FocusFlowSpacing.lg),

            // Action Buttons side by side at the bottom of the page
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: FocusFlowColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.md),
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.editGoal(goal.id)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Edit Goal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: FocusFlowSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FocusFlowColors.danger,
                      side: const BorderSide(color: FocusFlowColors.danger),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.md),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Goal'),
                          content: const Text(
                              'Are you sure you want to delete this goal and all its tasks? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: FocusFlowColors.danger),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context.read<GoalsCubit>().deleteGoal(goal.id);
                        if (context.mounted) {
                          context.go(AppRoutes.goals);
                        }
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Delete Goal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  const _BentoStatCard({
    required this.label,
    required this.value,
    required this.color,
    this.bottomBorderColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color? bottomBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FocusFlowColors.surface,
        border: Border.all(color: FocusFlowColors.border),
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: FocusFlowColors.muted,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (bottomBorderColor != null)
            Container(
              height: 3,
              color: bottomBorderColor,
            ),
        ],
      ),
    );
  }
}


class _GoalDetailsTaskRow extends StatelessWidget {
  const _GoalDetailsTaskRow({
    required this.task,
    required this.typeColor,
  });

  final FocusTask task;
  final Color typeColor;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == ItemStatus.done;
    final statusLabel = task.isOverdue ? 'Overdue' : task.status.label;

    final statusColor = task.status == ItemStatus.done
        ? FocusFlowColors.success
        : (task.isOverdue
            ? FocusFlowColors.danger
            : (task.status == ItemStatus.inProgress
                ? FocusFlowColors.warning
                : FocusFlowColors.border));

    return InkWell(
      onTap: () => context.go(AppRoutes.taskDetails(task.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: FocusFlowColors.border),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            IconButton(
              icon: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? typeColor : FocusFlowColors.quiet,
                size: 24,
              ),
              onPressed: () {
                if (isCompleted) {
                  context.read<TasksCubit>().pauseTask(task.id);
                } else {
                  context.read<TasksCubit>().completeTask(task.id);
                }
              },
            ),
            const SizedBox(width: 8),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? FocusFlowColors.muted
                          : FocusFlowColors.ink,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('d/M/yy').format(task.startDate),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: FocusFlowColors.quiet,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: FocusFlowColors.brand,
                        ),
                      ),
                      Text(
                        DateFormat('d/M/yy').format(task.endDate),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: FocusFlowColors.quiet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AddGoalScreen extends StatelessWidget {
  const AddGoalScreen({super.key, this.initialTypeId});

  final String? initialTypeId;

  @override
  Widget build(BuildContext context) {
    return FocusFlowPage(
      title: '',
      children: [
        _GoalFormContent(
          initialTypeId: initialTypeId,
        ),
      ],
    );
  }
}

class EditGoalScreen extends StatelessWidget {
  const EditGoalScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsCubit>().state.goals;
    final goal = goals.cast<Goal?>().firstWhere(
      (entry) => entry?.id == goalId,
      orElse: () => null,
    );

    return FocusFlowPage(
      title: '',
      children: [_GoalFormContent(isEdit: true, initialGoal: goal)],
    );
  }
}

class _GoalFormContent extends StatefulWidget {
  const _GoalFormContent({this.isEdit = false, this.initialGoal, this.initialTypeId});

  final bool isEdit;
  final Goal? initialGoal;
  final String? initialTypeId;

  @override
  State<_GoalFormContent> createState() => _GoalFormContentState();
}

class _GoalFormContentState extends State<_GoalFormContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _typeId;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<GoalsCubit>().state;
    _titleController = TextEditingController(
      text: widget.initialGoal?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialGoal?.description ?? '',
    );
    _typeId = widget.initialTypeId ??
        widget.initialGoal?.typeId ??
        (state.goalTypes.isNotEmpty ? state.goalTypes.first.id : null);
    _startDate = widget.initialGoal?.startDate ?? DateTime.now();
    _endDate =
        widget.initialGoal?.endDate ??
        DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, state) {
        final currentTypeId = _typeId ?? (state.goalTypes.isNotEmpty ? state.goalTypes.first.id : null);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Breadcrumbs Navigation
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.goals),
                        child: const Text(
                          'Goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: FocusFlowColors.quiet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: FocusFlowColors.quiet,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isEdit ? 'Edit Goal' : 'Create New Goal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FocusFlowColors.brand,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FocusFlowSpacing.md),

                // 3. Card: Goal Details
                FocusFlowCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with edit_note icon
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            color: FocusFlowColors.brand,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Goal Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.brand,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 24),

                      // Goal Title
                      const Text(
                        'GOAL TITLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.brand,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g., Master React Native',
                          hintStyle: TextStyle(
                            color: FocusFlowColors.quiet.withValues(alpha: 0.7),
                            fontWeight: FontWeight.normal,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: FocusFlowColors.surfaceLow,
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: FocusFlowColors.border),
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: FocusFlowColors.border),
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: FocusFlowColors.brand, width: 1.5),
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 14, color: FocusFlowColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Describe the outcome and purpose of this goal...',
                          hintStyle: const TextStyle(color: FocusFlowColors.quiet),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: FocusFlowColors.surfaceLow,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Goal Type Dropdown
                      const Text(
                        'GOAL TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(currentTypeId),
                        initialValue: currentTypeId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select type (e.g., Career, Health, Personal)',
                          hintStyle: const TextStyle(color: FocusFlowColors.quiet),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: FocusFlowColors.surfaceLow,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                          ),
                        ),
                        selectedItemBuilder: (context) => [
                          for (final type in state.goalTypes)
                            Text(
                              type.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: FocusFlowColors.brand),
                            ),
                        ],
                        items: [
                          for (final type in state.goalTypes)
                            DropdownMenuItem(
                              value: type.id,
                              child: Text(type.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _typeId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Scheduling (Start & End Date Row)
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(fontSize: 11, color: FocusFlowColors.quiet, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final selected = await selectFocusFlowDate(
                                      context,
                                      initialDate: _startDate,
                                    );
                                    if (selected != null) {
                                      setState(() {
                                        _startDate = selected;
                                        if (_endDate.isBefore(_startDate)) {
                                          _endDate = _startDate.add(const Duration(days: 1));
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: FocusFlowColors.surfaceLow,
                                      border: Border.all(color: FocusFlowColors.border),
                                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            color: FocusFlowColors.quiet,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat.yMMMd().format(_startDate),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: FocusFlowColors.brand,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: FocusFlowSpacing.md),

                          // Target End Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target End Date',
                                  style: TextStyle(fontSize: 11, color: FocusFlowColors.quiet, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final selected = await selectFocusFlowDate(
                                      context,
                                      initialDate: _endDate,
                                      firstDate: _startDate,
                                    );
                                    if (selected != null) {
                                      setState(() => _endDate = selected);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: FocusFlowColors.surfaceLow,
                                      border: Border.all(color: FocusFlowColors.border),
                                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.event_note_rounded,
                                            color: FocusFlowColors.quiet,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat.yMMMd().format(_endDate),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: FocusFlowColors.brand,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FocusFlowSpacing.xl),

                // 4. Save and Cancel Buttons
                Column(
                  children: [
                    FocusFlowPrimaryButton(
                      label: _isLoading
                          ? (widget.isEdit ? 'Updating...' : 'Saving...')
                          : (widget.isEdit ? 'Update Goal' : 'Save Goal'),
                      icon: _isLoading ? null : Icons.save_outlined,
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final title = _titleController.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Goal title is required.')),
                                );
                                return;
                              }
                              if (_endDate.isBefore(_startDate)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Target End Date must be after Start Date.'),
                                  ),
                                );
                                return;
                              }
                              setState(() => _isLoading = true);
                              try {
                                final cubit = context.read<GoalsCubit>();
                                final actualTypeId = _typeId ?? (cubit.state.goalTypes.isNotEmpty ? cubit.state.goalTypes.first.id : null);
                                if (widget.isEdit && widget.initialGoal != null) {
                                  if (actualTypeId == null) return;
                                  await cubit.updateGoal(
                                    id: widget.initialGoal!.id,
                                    title: title,
                                    description: _descriptionController.text.trim(),
                                    typeId: actualTypeId,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                  );
                                } else {
                                  if (actualTypeId == null) return;
                                  await cubit.addGoal(
                                    title: title,
                                    description: _descriptionController.text.trim(),
                                    typeId: actualTypeId,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                  );
                                }
                                if (context.mounted) {
                                  context.go(AppRoutes.goals);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      expanded: true,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => context.go(AppRoutes.goals),
                      child: const Text(
                        'Cancel and return to goals',
                        style: TextStyle(
                          fontSize: 12,
                          color: FocusFlowColors.quiet,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.item, required this.type});

  final GoalProgress item;
  final CustomGoalType type;

  @override
  Widget build(BuildContext context) {
    final goal = item.goal;
    final color = _parseColor(type.colorHex);
    final icon = FocusFlowIconMapper.parseIcon(type.iconCode);

    return FocusFlowCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(AppRoutes.goalDetails(goal.id)),
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          type.name,
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FocusFlowColors.surfaceLow,
                      borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                    ),
                    child: Text(
                      goal.status.label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: FocusFlowColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.md),
              Text(
                goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: FocusFlowColors.ink,
                    ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  goal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FocusFlowColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: FocusFlowColors.quiet,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateRange(goal.startDate, goal.endDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: FocusFlowColors.quiet,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(item.progress * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.xs),
              FocusFlowProgressBar(
                value: item.progress,
                color: color,
                height: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startMonth = DateFormat.MMM().format(start);
    final endMonth = DateFormat.MMM().format(end);
    if (start.year == end.year) {
      return '$startMonth - $endMonth';
    } else {
      final startYearShort = start.year.toString().substring(2);
      final endYearShort = end.year.toString().substring(2);
      return "$startMonth '$startYearShort - $endMonth '$endYearShort";
    }
  }
}







Color _parseColor(String hex) {
  var hexColor = hex.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF8B95A7);
}
