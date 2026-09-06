import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/focus_flow_repository.dart';
import '../../../../core/domain/focus_flow_models.dart';

enum TaskStatusFilter { all, notYet, inProgress, done, overdue }

enum TaskSort { alphabet, status, startDate, dueDate, goal, goalType, lastAdded }

class TasksState extends Equatable {
  const TasksState({
    required this.goals,
    required this.tasks,
    this.goalTypes = const [],
    this.statusFilter = TaskStatusFilter.all,
    this.goalId,
    this.goalTypeId,
    this.sort = TaskSort.dueDate,
    this.sortAscending = true,
    this.selectedDate,
    this.showAllDates = false,
    this.isLoading = false,
    required this.selectedMonth,
    required this.selectedYear,
  });

  final List<Goal> goals;
  final List<FocusTask> tasks;
  final List<CustomGoalType> goalTypes;
  final TaskStatusFilter statusFilter;
  final String? goalId;
  final String? goalTypeId;
  final TaskSort sort;
  final bool sortAscending;
  final DateTime? selectedDate;
  final bool showAllDates;
  final bool isLoading;
  final int selectedMonth;
  final int selectedYear;

  List<FocusTask> get visibleTasks {
    final filtered = tasks.where((task) {
      final matchesGoal = goalId == null || task.goalId == goalId;
      final matchesStatus = switch (statusFilter) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.notYet => task.status == ItemStatus.notYet,
        TaskStatusFilter.inProgress => task.status == ItemStatus.inProgress,
        TaskStatusFilter.done => task.status == ItemStatus.done,
        TaskStatusFilter.overdue => task.isOverdue,
      };

      final taskGoal = goals.firstWhere(
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
      final matchesGoalType = goalTypeId == null || taskGoal.typeId == goalTypeId;

      if (!matchesGoal || !matchesStatus || !matchesGoalType) return false;

      if (!showAllDates && selectedDate != null) {
        final d = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
        final end = DateTime(task.endDate.year, task.endDate.month, task.endDate.day);
        return !start.isAfter(d) && !end.isBefore(d);
      }

      return true;
    }).toList();

    int compareGoalTypes(FocusTask a, FocusTask b) {
      final aGoal = goals.firstWhere(
        (g) => g.id == a.goalId,
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
      final bGoal = goals.firstWhere(
        (g) => g.id == b.goalId,
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
      final aGoalTypeName = goalTypes
          .firstWhere(
            (t) => t.id == aGoal.typeId,
            orElse: () => CustomGoalType(
              id: '',
              name: 'Other',
              colorHex: '',
              iconCode: '',
              isDefault: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .name;
      final bGoalTypeName = goalTypes
          .firstWhere(
            (t) => t.id == bGoal.typeId,
            orElse: () => CustomGoalType(
              id: '',
              name: 'Other',
              colorHex: '',
              iconCode: '',
              isDefault: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .name;
      return aGoalTypeName.toLowerCase().compareTo(bGoalTypeName.toLowerCase());
    }

    filtered.sort((a, b) {
      final int result = switch (sort) {
        TaskSort.alphabet => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        TaskSort.status => a.status.index.compareTo(b.status.index),
        TaskSort.startDate => a.startDate.compareTo(b.startDate),
        TaskSort.dueDate => a.endDate.compareTo(b.endDate),
        TaskSort.goal => goalTitle(
          a.goalId,
        ).toLowerCase().compareTo(goalTitle(b.goalId).toLowerCase()),
        TaskSort.goalType => compareGoalTypes(a, b),
        TaskSort.lastAdded => a.createdAt.compareTo(b.createdAt),
      };
      return sortAscending ? result : -result;
    });
    return filtered;
  }

  String goalTitle(String id) {
    return goals
        .firstWhere(
          (goal) => goal.id == id,
          orElse: () => Goal(
            id: id,
            title: 'Unknown Goal',
            description: '',
            typeId: 'other',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .title;
  }

  TasksState copyWith({
    List<Goal>? goals,
    List<FocusTask>? tasks,
    List<CustomGoalType>? goalTypes,
    TaskStatusFilter? statusFilter,
    String? goalId,
    bool clearGoalId = false,
    String? goalTypeId,
    bool clearGoalTypeId = false,
    TaskSort? sort,
    bool? sortAscending,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    bool? showAllDates,
    bool? isLoading,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return TasksState(
      goals: goals ?? this.goals,
      tasks: tasks ?? this.tasks,
      goalTypes: goalTypes ?? this.goalTypes,
      statusFilter: statusFilter ?? this.statusFilter,
      goalId: clearGoalId ? null : goalId ?? this.goalId,
      goalTypeId: clearGoalTypeId ? null : goalTypeId ?? this.goalTypeId,
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedDate: clearSelectedDate ? null : selectedDate ?? this.selectedDate,
      showAllDates: showAllDates ?? this.showAllDates,
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }

  @override
  List<Object?> get props => [
    goals,
    tasks,
    goalTypes,
    statusFilter,
    goalId,
    goalTypeId,
    sort,
    sortAscending,
    selectedDate,
    showAllDates,
    isLoading,
    selectedMonth,
    selectedYear,
  ];
}

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(this._repository)
    : super(
        TasksState(
          goals: _repository.snapshot.goals,
          tasks: _repository.snapshot.tasks,
          goalTypes: _repository.snapshot.goalTypes,
          selectedDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          showAllDates: false,
          isLoading: true,
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
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

  void setStatusFilter(TaskStatusFilter filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void setGoalFilter(String? goalId) {
    emit(state.copyWith(goalId: goalId, clearGoalId: goalId == null));
  }

  void setGoalTypeFilter(String? goalTypeId) {
    emit(state.copyWith(goalTypeId: goalTypeId, clearGoalTypeId: goalTypeId == null));
  }

  void setSort(TaskSort sort) {
    emit(state.copyWith(sort: sort));
  }

  void setSortAscending(bool ascending) {
    emit(state.copyWith(sortAscending: ascending));
  }

  void selectMonth(int month, int year) {
    final now = DateTime.now();
    DateTime targetDate;
    if (month == now.month && year == now.year) {
      targetDate = DateTime(now.year, now.month, now.day);
    } else {
      targetDate = DateTime(year, month, 1);
    }
    emit(state.copyWith(
      selectedMonth: month,
      selectedYear: year,
      selectedDate: targetDate,
      showAllDates: false,
    ));
  }

  void selectDate(DateTime date) {
    emit(state.copyWith(
      selectedMonth: date.month,
      selectedYear: date.year,
      selectedDate: DateTime(date.year, date.month, date.day),
      showAllDates: false,
    ));
  }

  void showAllDates() {
    emit(state.copyWith(showAllDates: true, clearSelectedDate: true));
  }

  Future<void> addTask({
    required String goalId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int reminderIntervalMinutes,
  }) {
    return _repository.addTask(
      goalId: goalId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      reminderIntervalMinutes: reminderIntervalMinutes,
    );
  }

  Future<void> updateTask({
    required String id,
    required String goalId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required int reminderIntervalMinutes,
  }) {
    return _repository.updateTask(
      id: id,
      goalId: goalId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      reminderIntervalMinutes: reminderIntervalMinutes,
    );
  }

  Future<void> updateTaskReminder(String taskId) => _repository.updateTaskReminder(taskId);

  Future<void> startTask(String taskId) => _repository.startTask(taskId);

  Future<void> pauseTask(String taskId) => _repository.pauseTask(taskId);

  Future<void> completeTask(String taskId) => _repository.completeTask(taskId);

  Future<void> deleteTask(String taskId) => _repository.deleteTask(taskId);

  void _onSnapshot(FocusFlowSnapshot snapshot) {
    emit(
      state.copyWith(
        goals: snapshot.goals,
        tasks: snapshot.tasks,
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
