import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/presentation/utils/icon_mapper.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../core/data/remote/supabase_sync_engine.dart';
import '../../../../core/domain/focus_flow_models.dart';
import '../../../../shared/presentation/widgets/focus_flow_card.dart';
import '../../../../shared/presentation/widgets/focus_flow_metric_card.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';
import '../../../../shared/presentation/widgets/focus_flow_progress_bar.dart';
import '../../../../shared/presentation/widgets/focus_flow_badge.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleRefresh(BuildContext context) async {
    try {
      final syncEngine = context.read<SupabaseSyncEngine?>();
      if (syncEngine != null) {
        await syncEngine.forceSync();
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, current) =>
          prev.runtimeType != current.runtimeType ||
          (prev is AuthAuthenticated &&
              current is AuthAuthenticated &&
              prev.user.id != current.user.id),
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final isGuest = user == null;

        return BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state.totalGoals == 0 && state.totalTasks == 0) {
              return FocusFlowPage(
                onRefresh: () => _handleRefresh(context),
                actions: [
                  if (!isGuest)
                    const FocusFlowBadge(
                      label: 'Cloud Sync Active',
                      tone: FocusFlowBadgeTone.success,
                      icon: Icons.cloud_done_rounded,
                    ),
                ],
                children: [
                  const SizedBox(height: FocusFlowSpacing.xl),
                  Center(
                    child: FocusFlowCard(
                      padding: const EdgeInsets.all(FocusFlowSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            size: FocusFlowIconSize.xl,
                            color: FocusFlowColors.brand,
                          ),
                          const SizedBox(height: FocusFlowSpacing.lg),
                          Text(
                            'Let\'s set your first goal!',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: FocusFlowSpacing.md),
                          const Text(
                            'FocusFlow helps you organize your projects into goals\nand track your tasks efficiently.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: FocusFlowSpacing.xl),
                          FocusFlowPrimaryButton(
                            label: 'Create Your First Goal',
                            icon: Icons.add_rounded,
                            onPressed: () => context.go(AppRoutes.addGoal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return FocusFlowPage(
              onRefresh: () => _handleRefresh(context),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final goalSummaryCard = SizedBox(
                      height: 195,
                      child: FocusFlowMetricCard(
                        title: 'Goal Summary',
                        value: '${state.totalGoals}',
                        label: 'Total Goals',
                        icon: Icons.track_changes_rounded,
                        items: [
                          FocusFlowMetricItem(
                            value: '${state.totalGoals}',
                            label: 'Total',
                            tone: FocusFlowColors.ink,
                          ),
                          FocusFlowMetricItem(
                            value: '${state.goalsInProgress}',
                            label: 'Active',
                            tone: FocusFlowColors.brand,
                          ),
                          FocusFlowMetricItem(
                            value: '${state.goalsDone}',
                            label: 'Done',
                            tone: FocusFlowColors.success,
                          ),
                        ],
                        progress: state.totalGoals > 0 ? state.goalsDone / state.totalGoals : 0.0,
                      ),
                    );

                    final taskSummaryCard = SizedBox(
                      height: 195,
                      child: FocusFlowMetricCard(
                        title: 'Task Summary',
                        value: '${state.totalTasks}',
                        label: 'Total Tasks',
                        icon: Icons.checklist_rounded,
                        items: [
                          FocusFlowMetricItem(
                            value: '${state.totalTasks}',
                            label: 'Total',
                            tone: FocusFlowColors.ink,
                          ),
                          FocusFlowMetricItem(
                            value: '${state.tasksNotYet}',
                            label: 'To Do',
                            tone: FocusFlowColors.quiet,
                          ),
                          FocusFlowMetricItem(
                            value: '${state.tasksInProgress}',
                            label: 'Active',
                            tone: FocusFlowColors.brand,
                          ),
                          FocusFlowMetricItem(
                            value: '${state.tasksDone}',
                            label: 'Done',
                            tone: FocusFlowColors.success,
                          ),
                        ],
                        progress: state.completionRate,
                      ),
                    );

                    if (constraints.maxWidth >= 600) {
                      return Row(
                        children: [
                          Expanded(child: goalSummaryCard),
                          const SizedBox(width: FocusFlowSpacing.lg),
                          Expanded(child: taskSummaryCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        goalSummaryCard,
                        const SizedBox(height: FocusFlowSpacing.md),
                        taskSummaryCard,
                      ],
                    );
                  },
                ),
                if (state.lastInProgressTasks.isNotEmpty) ...[
                  const SizedBox(height: FocusFlowSpacing.xl),
                  _LastTasksInProgressSection(tasks: state.lastInProgressTasks),
                ],
                const SizedBox(height: FocusFlowSpacing.xl),
                _ActiveGoalProgressCard(goals: state.goalProgress),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActiveGoalProgressCard extends StatelessWidget {
  const _ActiveGoalProgressCard({required this.goals});

  final List<GoalProgress> goals;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusFlowSectionHeader(
            title: 'Active Goal Progress',
            actionLabel: 'View All Goals',
            onAction: () => context.go(AppRoutes.goals),
          ),
          const SizedBox(height: FocusFlowSpacing.lg),
          for (final item in goals) ...[
            () {
              final type = context
                  .read<DashboardCubit>()
                  .state
                  .goalTypes
                  .firstWhere(
                    (t) => t.id == item.goal.typeId,
                    orElse: () => CustomGoalType.fallback,
                  );
              return FocusFlowProgressRow(
                title: item.goal.title,
                subtitle:
                    '${type.name} - Deadline: ${DateFormat.MMMd().format(item.goal.endDate)}',
                value: item.progress,
                icon: FocusFlowIconMapper.parseIcon(type.iconCode),
              );
            }(),
            if (item != goals.last) const SizedBox(height: FocusFlowSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _LastTasksInProgressSection extends StatelessWidget {
  const _LastTasksInProgressSection({required this.tasks});

  final List<FocusTask> tasks;

  @override
  Widget build(BuildContext context) {
    return FocusFlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusFlowSectionHeader(
            title: 'Last Tasks In Progress',
            actionLabel: 'View All Tasks',
            onAction: () => context.go(AppRoutes.tasks),
          ),
          const SizedBox(height: FocusFlowSpacing.lg),
          for (final task in tasks) ...[
            RepaintBoundary(
              child: InkWell(
                onTap: () => context.go(AppRoutes.tasks),
                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: FocusFlowSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const FocusFlowBadge(
                                  label: 'In Progress',
                                  tone: FocusFlowBadgeTone.brand,
                                ),
                                const SizedBox(width: FocusFlowSpacing.sm),
                                Text(
                                  DateFormat.MMMd().format(task.endDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled_rounded,
                          color: FocusFlowColors.brand,
                          size: FocusFlowIconSize.lg,
                        ),
                        onPressed: () => context.go(AppRoutes.tasks),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (task != tasks.last) const Divider(height: FocusFlowSpacing.lg),
          ],
        ],
      ),
    );
  }
}


