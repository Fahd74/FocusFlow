import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/focus_flow_repository.dart';
import '../../../../core/domain/focus_flow_models.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.goals,
    required this.tasks,
    required this.goalProgress,
    required this.goalTypes,
    this.isLoading = false,
  });

  final List<Goal> goals;
  final List<FocusTask> tasks;
  final List<GoalProgress> goalProgress;
  final List<CustomGoalType> goalTypes;
  final bool isLoading;

  DashboardState copyWith({
    List<Goal>? goals,
    List<FocusTask>? tasks,
    List<GoalProgress>? goalProgress,
    List<CustomGoalType>? goalTypes,
    bool? isLoading,
  }) {
    return DashboardState(
      goals: goals ?? this.goals,
      tasks: tasks ?? this.tasks,
      goalProgress: goalProgress ?? this.goalProgress,
      goalTypes: goalTypes ?? this.goalTypes,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalGoals => goals.length;
  int get goalsDone =>
      goals.where((goal) => goal.status == ItemStatus.done).length;
  int get goalsInProgress =>
      goals.where((goal) => goal.status == ItemStatus.inProgress).length;
  int get totalTasks => tasks.length;
  int get tasksNotYet =>
      tasks.where((task) => task.status == ItemStatus.notYet).length;
  int get tasksInProgress =>
      tasks.where((task) => task.status == ItemStatus.inProgress).length;
  int get tasksDone =>
      tasks.where((task) => task.status == ItemStatus.done).length;
  int get overdueTasks => tasks.where((task) => task.isOverdue).length;

  int get currentStreak {
    final completedDates = tasks
        .where((task) => task.completedAt != null)
        .map((task) => DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completedDates.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final latestCompletion = completedDates.first;
    if (latestCompletion != today && latestCompletion != yesterday) {
      return 0;
    }

    int streak = 1;
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
    return streak;
  }

  List<FocusTask> get lastInProgressTasks {
    final inProgress =
        tasks.where((task) => task.status == ItemStatus.inProgress).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return inProgress.take(3).toList();
  }

  double get completionRate {
    if (tasks.isEmpty) {
      return 0;
    }
    return tasksDone / tasks.length;
  }

  @override
  List<Object?> get props => [goals, tasks, goalProgress, goalTypes, isLoading];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository)
    : super(
        DashboardState(
          goals: _repository.snapshot.goals,
          tasks: _repository.snapshot.tasks,
          goalProgress: _repository.goalProgress,
          goalTypes: _repository.snapshot.goalTypes,
          isLoading: true,
        ),
      ) {
    _subscription = _repository.watchSnapshot().listen(_onSnapshot);
    _init();
  }

  final FocusFlowRepository _repository;
  late final StreamSubscription<FocusFlowSnapshot> _subscription;

  Future<void> _init() async {
    await _repository.ready;
    emit(state.copyWith(isLoading: false));
  }

  void _onSnapshot(FocusFlowSnapshot snapshot) {
    emit(
      state.copyWith(
        goals: snapshot.goals,
        tasks: snapshot.tasks,
        goalProgress: _repository.goalProgress,
        goalTypes: snapshot.goalTypes,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
