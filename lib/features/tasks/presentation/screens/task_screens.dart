import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../core/domain/focus_flow_models.dart';
import '../../../../shared/presentation/utils/date_picker_utils.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../../shared/presentation/widgets/focus_flow_card.dart';

import '../../../../core/data/remote/supabase_sync_engine.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';

import '../../../goals/presentation/cubit/goals_cubit.dart';
import '../cubit/tasks_cubit.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final goalTypes = context.watch<GoalsCubit>().state.goalTypes;
        final totalTasksCount = state.visibleTasks.length;

        final isDesktop = MediaQuery.sizeOf(context).width >= 1050;
        final isMobile = MediaQuery.sizeOf(context).width < 600;

        // Statistics computation for Sidebar/Focus Stats scoped to active Goal / Goal Type filters
        final statsTasks = state.tasks.where((task) {
          final matchesGoal = state.goalId == null || task.goalId == state.goalId;

          final taskGoal = state.goals.firstWhere(
            (g) => g.id == task.goalId,
            orElse: () => Goal(
              id: '',
              title: '',
              description: '',
              typeId: '',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final matchesGoalType = state.goalTypeId == null || taskGoal.typeId == state.goalTypeId;

          return matchesGoal && matchesGoalType;
        }).toList();

        final totalTasks = statsTasks.length;
        final completedTasks = statsTasks.where((t) => t.status == ItemStatus.done).length;

        final completedToday = statsTasks
            .where(
              (t) =>
                  t.status == ItemStatus.done &&
                  t.completedAt != null &&
                  DateUtils.isSameDay(t.completedAt, DateTime.now()),
            )
            .length;

        final totalToday = statsTasks
            .where(
              (t) =>
                  DateUtils.isSameDay(t.endDate, DateTime.now()) ||
                  (t.completedAt != null &&
                      DateUtils.isSameDay(t.completedAt, DateTime.now())),
            )
            .length;

        final todayProgress = totalToday > 0
            ? completedToday / totalToday
            : (totalTasks > 0 ? completedTasks / totalTasks : 0.0);



        // 7-day trend chart computation
        final last7Days = List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final count = state.tasks
              .where(
                (t) =>
                    t.status == ItemStatus.done &&
                    t.completedAt != null &&
                    DateUtils.isSameDay(t.completedAt, date),
              )
              .length;
          final dayName = DateFormat('E').format(date);
          return (dayName, count, DateUtils.isSameDay(date, DateTime.now()));
        });

        final maxCompletedVal = last7Days
            .map((e) => e.$2)
            .reduce((value, element) => value > element ? value : element);
        final maxCompleted = maxCompletedVal > 0 ? maxCompletedVal : 1;

        final mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Heading and Add Button
            if (!isMobile) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FocusFlowPrimaryButton(
                  label: 'Add Task',
                  icon: Icons.add_rounded,
                  onPressed: () => context.go(AppRoutes.addTask),
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.md),
            ],
            if (isMobile) ...[
              const SizedBox(height: FocusFlowSpacing.md),
              _buildFocusStatsCard(
                context: context,
                todayProgress: todayProgress,
                totalTasks: totalTasks,
                completedTasks: completedTasks,
                notYetTasks: statsTasks.where((t) => t.status == ItemStatus.notYet).length,
                overdueTasks: statsTasks.where((t) => t.isOverdue).length,
                last7Days: last7Days,
                maxCompleted: maxCompleted,
                showCharts: false,
              ),
              const SizedBox(height: FocusFlowSpacing.md),
            ],
            _MonthCalendar(
              selectedDate: state.selectedDate,
              showAllDates: state.showAllDates,
              tasks: state.tasks,
              selectedMonth: state.selectedMonth,
              selectedYear: state.selectedYear,
            ),
            const SizedBox(height: FocusFlowSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks ($totalTasksCount)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FocusFlowColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded, color: FocusFlowColors.brand),
                  tooltip: 'Filter & Sort',
                  onPressed: () => _showFilterSortPopup(context, state),
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.md),
            // Tasks Card Wrapper
            if (totalTasksCount == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.checklist_rounded,
                        size: 64,
                        color: FocusFlowColors.quiet,
                      ),
                      const SizedBox(height: FocusFlowSpacing.md),
                      Text('No tasks found.', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: FocusFlowSpacing.sm),
                      const Text('Try changing your filters or add a new task.'),
                    ],
                  ),
                ),
              )
            else ...[
              Column(
                children: [
                  for (final task in state.visibleTasks) ...[
                    () {
                      final taskGoal = state.goals.firstWhere(
                        (g) => g.id == task.goalId,
                        orElse: () => Goal(
                          id: task.goalId,
                          title: 'Unknown',
                          description: '',
                          typeId: 'other',
                          startDate: DateTime.now(),
                          endDate: DateTime.now(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      final type = goalTypes.firstWhere(
                        (t) => t.id == taskGoal.typeId,
                        orElse: () => CustomGoalType.fallback,
                      );
                      return _TaskRow(
                        task: task,
                        goal: taskGoal.title,
                        color: _parseColor(type.colorHex),
                        typeName: type.name,
                      );
                    }(),
                    const SizedBox(height: FocusFlowSpacing.md),
                  ],
                ],
              ),
            ],
          ],
        );

        final sidebarContent = Column(
          children: [
            // Focus Stats Card
            if (!isMobile) ...[
              _buildFocusStatsCard(
                context: context,
                todayProgress: todayProgress,
                totalTasks: totalTasks,
                completedTasks: completedTasks,
                notYetTasks: statsTasks.where((t) => t.status == ItemStatus.notYet).length,
                overdueTasks: statsTasks.where((t) => t.isOverdue).length,
                last7Days: last7Days,
                maxCompleted: maxCompleted,
                showCharts: true,
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
            ],

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
            title: '', // Custom title inside mainContent
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

        // Mobile
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: FocusFlowPage(
            title: '', // Custom title inside mainContent
            onRefresh: handleRefresh,
            children: [
              mainContent,
              const SizedBox(height: FocusFlowSpacing.xl),
              sidebarContent,
            ],
          ),
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: FocusFlowColors.brand,
                  onPressed: () => context.go(AppRoutes.addTask),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFocusStatsCard({
    required BuildContext context,
    required double todayProgress,
    required int totalTasks,
    required int completedTasks,
    required int notYetTasks,
    required int overdueTasks,
    required List<(String, int, bool)> last7Days,
    required int maxCompleted,
    required bool showCharts,
  }) {
    return FocusFlowCard(
      padding: showCharts ? const EdgeInsets.all(16) : const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCharts) const SizedBox(height: FocusFlowSpacing.xs),
          // Today's Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "TODAY'S PROGRESS",
                      style: TextStyle(
                        fontSize: showCharts ? 11 : 10,
                        fontWeight: FontWeight.bold,
                        color: FocusFlowColors.quiet,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(todayProgress * 100).round()}%',
                    style: TextStyle(
                      fontSize: showCharts ? 12 : 11,
                      fontWeight: FontWeight.bold,
                      color: FocusFlowColors.ink,
                    ),
                  ),
                ],
              ),
              SizedBox(height: showCharts ? 6 : 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                child: LinearProgressIndicator(
                  value: todayProgress,
                  minHeight: showCharts ? 6 : 4,
                  backgroundColor: FocusFlowColors.surfaceHigh,
                  color: FocusFlowColors.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: showCharts ? FocusFlowSpacing.lg : 8),
          if (!showCharts) ...[
            // Compact 1-row stat layout for Mobile
            Row(
              children: [
                _buildCompactStatBox(label: 'TOTAL', value: totalTasks, color: FocusFlowColors.brand),
                const SizedBox(width: 6),
                _buildCompactStatBox(label: 'DONE', value: completedTasks, color: FocusFlowColors.success),
                const SizedBox(width: 6),
                _buildCompactStatBox(label: 'NOT YET', value: notYetTasks, color: FocusFlowColors.brand),
                const SizedBox(width: 6),
                _buildCompactStatBox(
                  label: 'OVERDUE',
                  value: overdueTasks,
                  color: overdueTasks > 0 ? FocusFlowColors.danger : FocusFlowColors.quiet,
                ),
              ],
            ),
          ] else ...[
            // Metrics block layout: 2x2 grid for Desktop
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FocusFlowColors.surfaceLow,
                          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.quiet,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalTasks',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: FocusFlowSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FocusFlowColors.surfaceLow,
                          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.quiet,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedTasks',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FocusFlowSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FocusFlowColors.surfaceLow,
                          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NOT YET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.quiet,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$notYetTasks',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: FocusFlowSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FocusFlowColors.surfaceLow,
                          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.quiet,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$overdueTasks',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.lg),
            // Mini Trend Chart completed last 7 days
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in last7Days)
                    _TrendBar(
                      dayName: day.$1,
                      count: day.$2,
                      heightFactor: day.$2 / maxCompleted,
                      isToday: day.$3,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStatBox({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: FocusFlowColors.surfaceLow,
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: FocusFlowColors.quiet,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSortPopup(BuildContext context, TasksState state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<TasksCubit, TasksState>(
          builder: (context, state) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: FocusFlowColors.surface,
                  borderRadius: BorderRadius.circular(FocusFlowRadius.lg),
                  border: Border.all(color: FocusFlowColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Styled Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter & Sort',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: FocusFlowColors.ink,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: FocusFlowColors.muted),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: FocusFlowColors.border),
                    
                    // Dialog Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FILTER SECTION HEADER
                            Row(
                              children: [
                                const Icon(Icons.filter_alt_outlined, size: 16, color: FocusFlowColors.brand),
                                const SizedBox(width: 8),
                                Text(
                                  'FILTER BY',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.brand,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),
                            
                             // Status Dropdown
                            _buildPopupDropdown<TaskStatusFilter>(
                              label: 'Status',
                              key: ValueKey('status_${state.statusFilter.name}'),
                              value: state.statusFilter,
                              items: const [
                                DropdownMenuItem(value: TaskStatusFilter.all, child: Text('All Statuses')),
                                DropdownMenuItem(value: TaskStatusFilter.inProgress, child: Text('In Progress')),
                                DropdownMenuItem(value: TaskStatusFilter.notYet, child: Text('Not Yet')),
                                DropdownMenuItem(value: TaskStatusFilter.done, child: Text('Done')),
                                DropdownMenuItem(value: TaskStatusFilter.overdue, child: Text('Overdue')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  context.read<TasksCubit>().setStatusFilter(val);
                                }
                              },
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),

                            // Tasks View Dropdown
                            _buildPopupDropdown<bool>(
                              label: 'Tasks Filter',
                              key: ValueKey('tasks_filter_${state.showAllDates}'),
                              value: state.showAllDates,
                              items: const [
                                DropdownMenuItem(value: true, child: Text('All Tasks')),
                                DropdownMenuItem(value: false, child: Text('Day Tasks')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  if (val) {
                                    context.read<TasksCubit>().showAllDates();
                                  } else {
                                    final now = DateTime.now();
                                    DateTime targetDate;
                                    if (state.selectedMonth == now.month && state.selectedYear == now.year) {
                                      targetDate = DateTime(now.year, now.month, now.day);
                                    } else {
                                      targetDate = DateTime(state.selectedYear, state.selectedMonth, 1);
                                    }
                                    context.read<TasksCubit>().selectDate(targetDate);
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),

                            // Goal Type Dropdown
                            _buildPopupDropdown<String?>(
                              label: 'Goal Type',
                              key: ValueKey('goalType_${state.goalTypeId}'),
                              value: state.goalTypeId,
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('All Goal Types')),
                                for (final type in state.goalTypes)
                                  DropdownMenuItem<String?>(value: type.id, child: Text(type.name)),
                              ],
                              onChanged: (val) {
                                context.read<TasksCubit>().setGoalTypeFilter(val);
                              },
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),

                            // Goal Dropdown
                            _buildPopupDropdown<String?>(
                              label: 'Goal',
                              key: ValueKey('goal_${state.goalId}'),
                              value: state.goalId,
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('All Goals')),
                                for (final goal in state.goals)
                                  DropdownMenuItem<String?>(
                                    value: goal.id,
                                    child: Text(
                                      goal.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) {
                                context.read<TasksCubit>().setGoalFilter(val);
                              },
                            ),
                            const SizedBox(height: FocusFlowSpacing.lg),

                            // SORT SECTION HEADER
                            Row(
                              children: [
                                const Icon(Icons.sort_rounded, size: 16, color: FocusFlowColors.brand),
                                const SizedBox(width: 8),
                                Text(
                                  'SORT BY',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.brand,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),

                            // Sort field dropdown
                            _buildPopupDropdown<TaskSort>(
                              label: 'Sort Field',
                              key: ValueKey('sort_${state.sort.name}'),
                              value: state.sort,
                              items: const [
                                DropdownMenuItem(value: TaskSort.alphabet, child: Text('Alphabet (Title)')),
                                DropdownMenuItem(value: TaskSort.status, child: Text('Status')),
                                DropdownMenuItem(value: TaskSort.startDate, child: Text('Start Date')),
                                DropdownMenuItem(value: TaskSort.dueDate, child: Text('Due Date')),
                                DropdownMenuItem(value: TaskSort.goal, child: Text('Goal')),
                                DropdownMenuItem(value: TaskSort.goalType, child: Text('Goal Type')),
                                DropdownMenuItem(value: TaskSort.lastAdded, child: Text('Last Added')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  context.read<TasksCubit>().setSort(val);
                                }
                              },
                            ),
                            const SizedBox(height: FocusFlowSpacing.md),

                            // Direction Segmented Control
                            const Text(
                              'SORT DIRECTION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: FocusFlowSpacing.xs),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDirectionChip(
                                    label: 'Ascending',
                                    selected: state.sortAscending,
                                    onTap: () {
                                      context.read<TasksCubit>().setSortAscending(true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: FocusFlowSpacing.md),
                                Expanded(
                                  child: _buildDirectionChip(
                                    label: 'Descending',
                                    selected: !state.sortAscending,
                                    onTap: () {
                                      context.read<TasksCubit>().setSortAscending(false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: FocusFlowColors.border),
                    
                    // Action Buttons Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.read<TasksCubit>().setStatusFilter(TaskStatusFilter.all);
                              context.read<TasksCubit>().setGoalFilter(null);
                              context.read<TasksCubit>().setGoalTypeFilter(null);
                              context.read<TasksCubit>().setSort(TaskSort.dueDate);
                              context.read<TasksCubit>().setSortAscending(true);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: FocusFlowColors.danger,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: FocusFlowSpacing.md),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FocusFlowColors.brand,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopupDropdown<T>({
    required String label,
    required Key key,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: FocusFlowColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: FocusFlowColors.surfaceLow,
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
            border: Border.all(color: FocusFlowColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              key: key,
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: FocusFlowColors.brand,
                size: 20,
              ),
              dropdownColor: FocusFlowColors.surface,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FocusFlowColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? FocusFlowColors.brand.withValues(alpha: 0.1) : FocusFlowColors.surfaceLow,
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          border: Border.all(
            color: selected ? FocusFlowColors.brand : FocusFlowColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? FocusFlowColors.brand : FocusFlowColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.dayName,
    required this.count,
    required this.heightFactor,
    required this.isToday,
  });

  final String dayName;
  final int count;
  final double heightFactor;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: '$dayName: $count completed',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: heightFactor.clamp(0.08, 1.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isToday ? FocusFlowColors.brand : FocusFlowColors.brandSoft,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayName.substring(0, 1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? FocusFlowColors.brand : FocusFlowColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final tasksState = context.watch<TasksCubit>().state;
    final goalsState = context.watch<GoalsCubit>().state;

    if (tasksState.tasks.isEmpty) {
      return FocusFlowPage(
        title: '',
        children: [
          FocusFlowCard(
            child: Column(
              children: [
                const Text('No tasks available yet.'),
                const SizedBox(height: 12),
                FocusFlowPrimaryButton(
                  label: 'Back to Tasks',
                  onPressed: () => context.go(AppRoutes.tasks),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final task = tasksState.tasks.where((entry) => entry.id == taskId).firstOrNull;

    if (task == null) {
      return FocusFlowPage(
        title: '',
        children: [
          FocusFlowCard(
            child: Column(
              children: [
                const Text('Task not found. It may have been deleted.'),
                const SizedBox(height: 12),
                FocusFlowPrimaryButton(
                  label: 'Back to Tasks',
                  onPressed: () => context.go(AppRoutes.tasks),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final goal = goalsState.goals.firstWhere(
      (g) => g.id == task.goalId,
      orElse: () => Goal(
        id: '',
        typeId: '',
        title: 'Unknown Goal',
        description: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        status: ItemStatus.notYet,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final goalType = goalsState.goalTypes.firstWhere(
      (t) => t.id == goal.typeId,
      orElse: () => CustomGoalType.fallback,
    );

    final typeColor = _parseColor(goalType.colorHex);
    final statusLabel = task.isOverdue ? 'Overdue' : task.status.label;

    final statusColor = task.status == ItemStatus.done
        ? FocusFlowColors.success
        : (task.isOverdue
              ? FocusFlowColors.danger
              : (task.status == ItemStatus.inProgress
                    ? FocusFlowColors.warning
                    : FocusFlowColors.border));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;

        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.tasks),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Tasks',
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
                  'Task Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: FocusFlowColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.md),

            // Task Title
            Text(
              task.title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontFamily: 'SpaceGrotesk',
                fontSize: isDesktop ? 36 : 28,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            // Metadata row
            Row(
              children: [
                // Goal tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: typeColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 12, color: FocusFlowColors.border),
                const SizedBox(width: 10),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FocusFlowSpacing.lg),

            // Description (plain, no card)
            Padding(
              padding: const EdgeInsets.only(bottom: FocusFlowSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description.isNotEmpty
                        ? task.description
                        : 'No description provided.',
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: FocusFlowColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocusFlowSpacing.md),

            // Schedule & Reminder Grid
            LayoutBuilder(
              builder: (context, gridConstraints) {
                final wideGrid = gridConstraints.maxWidth >= 600;

                final scheduleCard = FocusFlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: FocusFlowColors.brand,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Schedule',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: FocusFlowColors.brand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'START DATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: FocusFlowColors.quiet,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().format(task.startDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: FocusFlowColors.ink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'DUE DATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: FocusFlowColors.quiet,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().format(task.endDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: task.isOverdue
                                  ? FocusFlowColors.danger
                                  : FocusFlowColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final reminderCard = Container(
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.08),
                    border: Border.all(color: typeColor.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Bell Graphic
                      Positioned(
                        right: -15,
                        top: -15,
                        child: Opacity(
                          opacity: 0.12,
                          child: Icon(
                            Icons.notifications_rounded,
                            size: 110,
                            color: typeColor,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.alarm_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Reminder',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CYCLE DURATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.quiet,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.history_rounded, color: typeColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      task.reminderIntervalMinutes > 0
                                          ? '${task.reminderIntervalMinutes}m'
                                          : 'Disabled',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: FocusFlowColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.quiet,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: typeColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      task.status == ItemStatus.done
                                          ? 'Inactive (Done)'
                                          : (task.reminderIntervalMinutes > 0
                                                ? 'Active'
                                                : 'Inactive'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: FocusFlowColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (wideGrid) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: scheduleCard),
                        const SizedBox(width: FocusFlowSpacing.md),
                        Expanded(child: reminderCard),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    scheduleCard,
                    const SizedBox(height: FocusFlowSpacing.md),
                    reminderCard,
                  ],
                );
              },
            ),
          ],
        );

        final actionsPanel = FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: FocusFlowColors.brand,
                ),
              ),
              const SizedBox(height: 16),
              // Mark Done / Mark Active Button
              if (task.status == ItemStatus.done)
                FocusFlowSecondaryButton(
                  label: 'Mark Active',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.read<TasksCubit>().pauseTask(task.id),
                  expanded: true,
                )
              else
                FocusFlowPrimaryButton(
                  label: 'Mark Done',
                  icon: Icons.done_all_rounded,
                  onPressed: () => context.read<TasksCubit>().completeTask(task.id),
                  expanded: true,
                ),
              const SizedBox(height: FocusFlowSpacing.sm),
              // Pause / Start Button
              if (task.status != ItemStatus.done) ...[
                if (task.status == ItemStatus.inProgress)
                  FocusFlowSecondaryButton(
                    label: 'Pause Task',
                    icon: Icons.pause_circle_outline_rounded,
                    onPressed: () => context.read<TasksCubit>().pauseTask(task.id),
                    expanded: true,
                  )
                else
                  FocusFlowSecondaryButton(
                    label: 'Start Task',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.read<TasksCubit>().startTask(task.id),
                    expanded: true,
                  ),
                const SizedBox(height: FocusFlowSpacing.sm),
              ],
              const Divider(height: 20),
              // Edit Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FocusFlowColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                  ),
                ),
                onPressed: () => context.go(AppRoutes.editTask(task.id)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.sm),
              // Delete Button
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FocusFlowColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text(
                        'Are you sure you want to delete this task? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: FocusFlowColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<TasksCubit>().deleteTask(task.id);
                    if (context.mounted) {
                      context.go(AppRoutes.tasks);
                    }
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );

        return FocusFlowPage(
          title: '', // Custom header with breadcrumbs built in
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: leftColumn),
                  const SizedBox(width: FocusFlowSpacing.lg),
                  SizedBox(width: 300, child: actionsPanel),
                ],
              )
            else
              Column(
                children: [
                  leftColumn,
                  const SizedBox(height: FocusFlowSpacing.lg),
                  actionsPanel,
                ],
              ),
          ],
        );
      },
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key, this.initialGoalId});

  final String? initialGoalId;

  @override
  Widget build(BuildContext context) {
    return FocusFlowPage(
      title: '',
      children: [_TaskFormContent(initialGoalId: initialGoalId)],
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksCubit>().state.tasks;
    final task = tasks.cast<FocusTask?>().firstWhere(
      (entry) => entry?.id == taskId,
      orElse: () => null,
    );

    return FocusFlowPage(
      title: '',
      children: [_TaskFormContent(isEdit: true, initialTask: task)],
    );
  }
}

class _TaskFormContent extends StatefulWidget {
  const _TaskFormContent({this.isEdit = false, this.initialTask, this.initialGoalId});

  final bool isEdit;
  final FocusTask? initialTask;
  final String? initialGoalId;

  @override
  State<_TaskFormContent> createState() => _TaskFormContentState();
}

class _TaskFormContentState extends State<_TaskFormContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customReminderController;
  String? _goalId;
  bool _reminderEnabled = true;
  int _reminderIntervalMinutes = 15;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialTask?.description ?? '',
    );

    final initialMinutes = widget.initialTask?.reminderIntervalMinutes ?? 15;
    _reminderEnabled = initialMinutes > 0;
    _reminderIntervalMinutes = _reminderEnabled ? initialMinutes : 15;

    _customReminderController = TextEditingController(
      text: _reminderIntervalMinutes.toString(),
    );

    _goalId = widget.initialTask?.goalId ?? widget.initialGoalId;
    _startDate = widget.initialTask?.startDate ?? DateTime.now();
    _endDate = widget.initialTask?.endDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customReminderController.dispose();
    super.dispose();
  }

  void _selectInterval(int minutes) {
    setState(() {
      _reminderIntervalMinutes = minutes;
      _customReminderController.text = minutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final currentGoalId =
            _goalId ?? (state.goals.isNotEmpty ? state.goals.first.id : null);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Breadcrumbs Navigation
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.tasks),
                      child: const Text(
                        'Tasks',
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
                      widget.isEdit ? 'Edit Task' : 'Add New',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FocusFlowColors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FocusFlowSpacing.md),

                // 3. Card 1: Task Definition & Scheduling
                FocusFlowCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Link to Goal
                      const Text(
                        'LINK TO GOAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(currentGoalId),
                        initialValue: currentGoalId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select a goal...',
                          hintStyle: const TextStyle(color: FocusFlowColors.quiet),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                          for (final goal in state.goals)
                            Text(
                              goal.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.brand,
                              ),
                            ),
                        ],
                        items: [
                          for (final goal in state.goals)
                            DropdownMenuItem(
                              value: goal.id,
                              child: Text(goal.title, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) => setState(() => _goalId = value),
                      ),
                      const SizedBox(height: 24),

                      // Task Title
                      const Text(
                        'TASK TITLE',
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
                          hintText: 'Add a title for your task...',
                          hintStyle: TextStyle(
                            color: FocusFlowColors.quiet.withValues(alpha: 0.7),
                            fontWeight: FontWeight.normal,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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
                            borderSide: const BorderSide(
                              color: FocusFlowColors.brand,
                              width: 1.5,
                            ),
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
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, color: FocusFlowColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Add context, links, or specific steps...',
                          hintStyle: const TextStyle(color: FocusFlowColors.quiet),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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

                      // Scheduling Section
                      const Text(
                        'SCHEDULING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FocusFlowColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: FocusFlowColors.quiet,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final today = DateTime(now.year, now.month, now.day);
                                    final selected = await selectFocusFlowDate(
                                      context,
                                      initialDate: _startDate,
                                      firstDate: widget.isEdit ? null : today,
                                    );
                                    if (selected != null) {
                                      setState(() {
                                        _startDate = selected;
                                        if (_endDate.isBefore(_startDate)) {
                                          _endDate = _startDate;
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FocusFlowColors.surfaceLow,
                                      border: Border.all(color: FocusFlowColors.border),
                                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          color: FocusFlowColors.quiet,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            DateFormat.yMMMd().format(_startDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: FocusFlowColors.brand,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: FocusFlowSpacing.md),

                          // Due Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: FocusFlowColors.quiet,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FocusFlowColors.surfaceLow,
                                      border: Border.all(color: FocusFlowColors.border),
                                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.event_note_rounded,
                                          color: FocusFlowColors.quiet,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            DateFormat.yMMMd().format(_endDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: FocusFlowColors.brand,
                                            ),
                                          ),
                                        ),
                                      ],
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
                const SizedBox(height: FocusFlowSpacing.lg),

                // 4. Card 2: Smart Reminders
                FocusFlowCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Reminders',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: FocusFlowColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Get notified at the right moment',
                                  style: TextStyle(fontSize: 12, color: FocusFlowColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _reminderEnabled,
                            activeTrackColor: FocusFlowColors.brand,
                            onChanged: (value) => setState(() => _reminderEnabled = value),
                          ),
                        ],
                      ),

                      if (_reminderEnabled) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 20),

                        const Text(
                          'QUICK INTERVALS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: FocusFlowColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, intervalsConstraints) {
                            final intervals = [15, 30, 60, 120, 240, 720];
                            final itemsPerRow = intervalsConstraints.maxWidth >= 500 ? 6 : 3;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: itemsPerRow,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.2,
                              ),
                              itemCount: intervals.length,
                              itemBuilder: (context, i) {
                                final minutes = intervals[i];
                                final isSelected = _reminderIntervalMinutes == minutes;
                                final label = minutes < 60
                                    ? '${minutes}m'
                                    : '${minutes ~/ 60}h';

                                return InkWell(
                                  onTap: () => _selectInterval(minutes),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? FocusFlowColors.brand.withValues(alpha: 0.08)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? FocusFlowColors.brand
                                            : FocusFlowColors.border,
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? FocusFlowColors.brand
                                            : FocusFlowColors.quiet,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 20),

                        // Custom alert setting
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Text(
                              'Or set custom:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: FocusFlowColors.ink,
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 40,
                              decoration: BoxDecoration(
                                color: FocusFlowColors.surfaceLow,
                                border: Border.all(color: FocusFlowColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _customReminderController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: FocusFlowColors.brand,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed >= 1) {
                                    setState(() => _reminderIntervalMinutes = parsed);
                                  }
                                },
                              ),
                            ),
                            const Text(
                              'minutes',
                              style: TextStyle(fontSize: 13, color: FocusFlowColors.muted),
                            ),
                            const Text(
                              'before due',
                              style: TextStyle(
                                fontSize: 12,
                                color: FocusFlowColors.quiet,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: FocusFlowSpacing.xl),

                // 5. Actions: Save & Cancel
                Column(
                  children: [
                    FocusFlowPrimaryButton(
                      label: _isLoading
                          ? (widget.isEdit ? 'Updating...' : 'Saving...')
                          : (widget.isEdit ? 'Update Task' : 'Save Task'),
                      icon: _isLoading ? null : Icons.save_outlined,
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final title = _titleController.text.trim();
                              final goalId =
                                  _goalId ??
                                  (state.goals.isNotEmpty ? state.goals.first.id : null);
                              if (title.isEmpty || goalId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task title and parent goal are required.'),
                                  ),
                                );
                                return;
                              }
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              if (!widget.isEdit && _startDate.isBefore(today)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Start Date cannot be in the past.'),
                                  ),
                                );
                                return;
                              }
                              if (_endDate.isBefore(_startDate)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Due Date must be after or equal to Start Date.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final actualReminderMinutes = _reminderEnabled
                                  ? _reminderIntervalMinutes
                                  : 0;

                              if (_reminderEnabled && actualReminderMinutes < 1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reminder interval must be at least 1 minute.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);
                              try {
                                final cubit = context.read<TasksCubit>();
                                if (widget.isEdit && widget.initialTask != null) {
                                  await cubit.updateTask(
                                    id: widget.initialTask!.id,
                                    goalId: goalId,
                                    title: title,
                                    description: _descriptionController.text.trim(),
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    reminderIntervalMinutes: actualReminderMinutes,
                                  );
                                } else {
                                  await cubit.addTask(
                                    goalId: goalId,
                                    title: title,
                                    description: _descriptionController.text.trim(),
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    reminderIntervalMinutes: actualReminderMinutes,
                                  );
                                }
                                if (context.mounted) {
                                  context.go(AppRoutes.tasks);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                      onTap: () => context.go(AppRoutes.tasks),
                      child: const Text(
                        'Cancel and return to tasks',
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.goal,
    required this.color,
    required this.typeName,
  });

  final FocusTask task;
  final String goal;
  final Color color;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    // Determine task color strip
    final stripColor = task.status == ItemStatus.done
        ? FocusFlowColors.success
        : (task.isOverdue
              ? FocusFlowColors.danger
              : (task.status == ItemStatus.inProgress
                    ? FocusFlowColors.warning
                    : FocusFlowColors.border));

    final isCompleted = task.status == ItemStatus.done;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final card = FocusFlowCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        child: InkWell(
          onTap: () => context.go(AppRoutes.taskDetails(task.id)),
          child: Stack(
            children: [
              // Left side indicator color strip (width: 4)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: stripColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const SizedBox(width: 4), // offset for color strip
                    // Checkbox button
                    IconButton(
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isCompleted ? FocusFlowColors.success : FocusFlowColors.quiet,
                        size: 24,
                      ),
                      onPressed: () {
                        if (isCompleted) {
                          context.read<TasksCubit>().pauseTask(task.id);
                        } else {
                          context.read<TasksCubit>().completeTask(task.id);
                        }
                      },
                      tooltip: isCompleted ? 'Mark Incomplete' : 'Mark Done',
                    ),
                    const SizedBox(width: 8),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? FocusFlowColors.muted
                                  : FocusFlowColors.ink,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Goal tag
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
                                  ),
                                  child: Text(
                                    typeName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Date text with arrow icon
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: DateFormat('d/M/yy').format(task.startDate),
                                      ),
                                      const WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 3),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 11,
                                            color: FocusFlowColors.brand,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: DateFormat('d/M/yy').format(task.endDate),
                                      ),
                                    ],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: task.isOverdue
                                          ? FocusFlowColors.danger
                                          : FocusFlowColors.quiet,
                                      fontWeight: task.isOverdue
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCompleted)
                          IconButton(
                            icon: Icon(
                              task.status == ItemStatus.inProgress
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: FocusFlowColors.brand,
                            ),
                            onPressed: () {
                              if (task.status == ItemStatus.inProgress) {
                                context.read<TasksCubit>().pauseTask(task.id);
                              } else {
                                context.read<TasksCubit>().startTask(task.id);
                              }
                            },
                            tooltip: task.status == ItemStatus.inProgress
                                ? 'Pause Task'
                                : 'Start Task',
                          ),
                        if (!isMobile)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: FocusFlowColors.danger,
                              size: 20,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: const Text(
                                    'Are you sure you want to delete this task? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: FocusFlowColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                context.read<TasksCubit>().deleteTask(task.id);
                              }
                            },
                            tooltip: 'Delete Task',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isMobile) {
      return Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: FocusFlowColors.danger,
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: const Text(
                'Are you sure you want to delete this task? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: FocusFlowColors.danger)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          context.read<TasksCubit>().deleteTask(task.id);
        },
        child: card,
      );
    }

    return card;
  }
}

Color _parseColor(String hex) {
  var hexColor = hex.replaceAll('#', '');
  if (hexColor.length == 6) {
hexColor = 'FF$hexColor';
  }
  return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF8B95A7);
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.selectedDate,
    required this.showAllDates,
    required this.tasks,
    required this.selectedMonth,
    required this.selectedYear,
  });

  final DateTime? selectedDate;
  final bool showAllDates;
  final List<FocusTask> tasks;
  final int selectedMonth;
  final int selectedYear;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  final ScrollController _scrollController = ScrollController();
  bool _isLeftHovered = false;
  bool _isRightHovered = false;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    final newOffset = (_scrollController.offset - 150).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final newOffset = (_scrollController.offset + 150).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasksCubit>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateUtils.getDaysInMonth(widget.selectedYear, widget.selectedMonth);

    final isMobile = MediaQuery.of(context).size.width < 768;

    // Dropdown Month Selector Container - Transparent, brand color, dense spacing
    final monthDropdown = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: widget.selectedMonth,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FocusFlowColors.brand, size: 20),
            dropdownColor: FocusFlowColors.surfaceHigh,
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
            isDense: true,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: FocusFlowColors.brand,
            ),
            onChanged: (newMonth) {
              if (newMonth != null) {
                cubit.selectMonth(newMonth, widget.selectedYear);
              }
            },
            items: [
              for (int m = 1; m <= 12; m++)
                DropdownMenuItem<int>(
                  value: m,
                  child: Text(_months[m - 1]),
                ),
            ],
          ),
        ),
      ],
    ),
    );

    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(fit: FlexFit.loose, child: monthDropdown),
        TextButton(
          onPressed: () {
            final todayDate = DateTime(now.year, now.month, now.day);
            cubit.selectDate(todayDate);

            // Programmatically scroll to today's card if the controller is attached
            if (_scrollController.hasClients) {
              final targetOffset = ((now.day - 1) * (52 + 8)).toDouble();
              final maxScroll = _scrollController.position.maxScrollExtent;
              _scrollController.animateTo(
                targetOffset.clamp(0.0, maxScroll),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: FocusFlowColors.brand,
            textStyle: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(isMobile ? 'Today' : 'Today Tasks'),
        ),
      ],
    );

    // Day scroll row widget (without All chip, padding at both ends)
    final dayListWidget = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 16),
          for (int day = 1; day <= daysInMonth; day++) ...[
            _buildDayCard(context, day, cubit, today),
            const SizedBox(width: FocusFlowSpacing.xs),
          ],
          const SizedBox(width: 16),
        ],
      ),
    );

    Widget daysRow;
    if (isMobile) {
      daysRow = SizedBox(
        height: 68,
        width: double.infinity,
        child: dayListWidget,
      );
    } else {
      daysRow = SizedBox(
        height: 68,
        child: Stack(
          children: [
            Positioned.fill(child: dayListWidget),
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildHoverScrollButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: _scrollLeft,
                  isHovered: _isLeftHovered,
                  onHoverChanged: (hovered) {
                    setState(() {
                      _isLeftHovered = hovered;
                    });
                  },
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildHoverScrollButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: _scrollRight,
                  isHovered: _isRightHovered,
                  onHoverChanged: (hovered) {
                    setState(() {
                      _isRightHovered = hovered;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const SizedBox(height: FocusFlowSpacing.md),
          daysRow,
        ],
      ),
    );
  }

  Widget _buildHoverScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isHovered,
    required ValueChanged<bool> onHoverChanged,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isHovered ? 0.95 : 0.25,
        child: Container(
          decoration: BoxDecoration(
            color: FocusFlowColors.surfaceHigh.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: FocusFlowColors.border, width: 1.5),
          ),
          child: IconButton(
            icon: Icon(icon, size: 20, color: FocusFlowColors.brand),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int day, TasksCubit cubit, DateTime today) {
    final date = DateTime(widget.selectedYear, widget.selectedMonth, day);
    final isSelected = !widget.showAllDates && widget.selectedDate != null && DateUtils.isSameDay(widget.selectedDate, date);
    final isToday = DateUtils.isSameDay(today, date);

    final dayStart = DateTime(date.year, date.month, date.day);
    final hasTasks = widget.tasks.any((task) {
      final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
      final end = DateTime(task.endDate.year, task.endDate.month, task.endDate.day);
      return !start.isAfter(dayStart) && !end.isBefore(dayStart);
    });

    final dayName = DateFormat('E').format(date).substring(0, 3).toUpperCase();

    return GestureDetector(
      onTap: () => cubit.selectDate(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? FocusFlowColors.brand
              : isToday
                  ? FocusFlowColors.brand.withValues(alpha: 0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          border: Border.all(
            color: isSelected
                ? FocusFlowColors.brand
                : isToday
                    ? FocusFlowColors.brand
                    : FocusFlowColors.border,
            width: isSelected || isToday ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FocusFlowColors.brand.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : FocusFlowColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : FocusFlowColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !hasTasks
                    ? Colors.transparent
                    : isSelected
                        ? Colors.white
                        : FocusFlowColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
