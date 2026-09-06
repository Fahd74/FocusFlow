import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/focus_flow_repository.dart';
import '../../../../core/domain/focus_flow_models.dart';

class GoalsState extends Equatable {
  const GoalsState({
    required this.goals,
    required this.goalProgress,
    required this.goalTypes,
    this.selectedType,
    this.isLoading = false,
  });

  final List<Goal> goals;
  final List<GoalProgress> goalProgress;
  final List<CustomGoalType> goalTypes;
  final String? selectedType;
  final bool isLoading;

  List<GoalProgress> get visibleGoals {
    if (selectedType == null) {
      return goalProgress;
    }
    return goalProgress
        .where((item) => item.goal.typeId == selectedType)
        .toList();
  }

  GoalsState copyWith({
    List<Goal>? goals,
    List<GoalProgress>? goalProgress,
    List<CustomGoalType>? goalTypes,
    String? selectedType,
    bool clearSelectedType = false,
    bool? isLoading,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      goalProgress: goalProgress ?? this.goalProgress,
      goalTypes: goalTypes ?? this.goalTypes,
      selectedType: clearSelectedType
          ? null
          : selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [goals, goalProgress, goalTypes, selectedType, isLoading];
}

class GoalsCubit extends Cubit<GoalsState> {
  GoalsCubit(this._repository)
    : super(
        GoalsState(
          goals: _repository.snapshot.goals,
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

  void selectType(String? typeId) {
    emit(
      state.copyWith(selectedType: typeId, clearSelectedType: typeId == null),
    );
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _repository.addGoal(
      title: title,
      description: description,
      typeId: typeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String description,
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _repository.updateGoal(
      id: id,
      title: title,
      description: description,
      typeId: typeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> deleteGoal(String goalId) => _repository.deleteGoal(goalId);

  Future<void> addGoalType({
    required String name,
    required String colorHex,
    required String iconCode,
  }) {
    return _repository.addGoalType(
      name: name,
      colorHex: colorHex,
      iconCode: iconCode,
    );
  }

  Future<void> updateGoalType({
    required String id,
    required String name,
    required String colorHex,
    required String iconCode,
  }) {
    return _repository.updateGoalType(
      id: id,
      name: name,
      colorHex: colorHex,
      iconCode: iconCode,
    );
  }

  Future<void> deleteGoalType(String id) => _repository.deleteGoalType(id);

  void _onSnapshot(FocusFlowSnapshot snapshot) {
    emit(
      state.copyWith(
        goals: snapshot.goals,
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
