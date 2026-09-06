import 'package:equatable/equatable.dart';

enum ItemStatus { notYet, inProgress, done }

class CustomGoalType extends Equatable {
  const CustomGoalType({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconCode,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.userId,
  });

  final String id;
  final String name;
  final String colorHex;
  final String iconCode;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;

  CustomGoalType copyWith({
    String? name,
    String? colorHex,
    String? iconCode,
    bool? isDefault,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    bool clearDeletedAt = false,
    bool clearUserId = false,
  }) {
    return CustomGoalType(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    colorHex,
    iconCode,
    isDefault,
    createdAt,
    updatedAt,
    deletedAt,
    userId,
  ];

  /// A safe fallback used when goalTypes is empty to prevent `.first` crashes.
  static final fallback = CustomGoalType(
    id: 'other',
    name: 'Other',
    colorHex: '#8B95A7',
    iconCode: 'category_outlined',
    isDefault: true,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

extension ItemStatusLabel on ItemStatus {
  String get label {
    return switch (this) {
      ItemStatus.notYet => 'Not Yet',
      ItemStatus.inProgress => 'In Progress',
      ItemStatus.done => 'Done',
    };
  }
}

class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.typeId,
    this.status = ItemStatus.notYet,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.userId,
  });

  final String id;
  final String title;
  final String description;
  final String typeId;
  final ItemStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;

  Goal copyWith({
    String? title,
    String? description,
    String? typeId,
    ItemStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    bool clearDeletedAt = false,
    bool clearUserId = false,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      typeId: typeId ?? this.typeId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    typeId,
    status,
    startDate,
    endDate,
    createdAt,
    updatedAt,
    deletedAt,
    userId,
  ];
}

class FocusTask extends Equatable {
  const FocusTask({
    required this.id,
    required this.goalId,
    required this.title,
    required this.description,
    this.status = ItemStatus.notYet,
    required this.startDate,
    required this.endDate,
    required this.reminderIntervalMinutes,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.userId,
    this.lastReminderAt,
  });

  final String id;
  final String goalId;
  final String title;
  final String description;
  final ItemStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int reminderIntervalMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final DateTime? lastReminderAt;

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    return status != ItemStatus.done && taskEndDate.isBefore(today);
  }

  FocusTask copyWith({
    String? goalId,
    String? title,
    String? description,
    ItemStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? reminderIntervalMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    DateTime? lastReminderAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
    bool clearDeletedAt = false,
    bool clearUserId = false,
    bool clearLastReminderAt = false,
  }) {
    return FocusTask(
      id: id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      userId: clearUserId ? null : (userId ?? this.userId),
      lastReminderAt: clearLastReminderAt ? null : (lastReminderAt ?? this.lastReminderAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    goalId,
    title,
    description,
    status,
    startDate,
    endDate,
    reminderIntervalMinutes,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
    userId,
    lastReminderAt,
  ];
}

class GoalProgress extends Equatable {
  const GoalProgress({required this.goal, required this.progress});

  final Goal goal;
  final double progress;

  @override
  List<Object?> get props => [goal, progress];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.avatarType,
    this.avatarAsset,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String? avatarType; // 'upload' | 'asset'
  final String? avatarAsset;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    String? avatarType,
    String? avatarAsset,
    DateTime? updatedAt,
    bool clearAvatarUrl = false,
    bool clearAvatarType = false,
    bool clearAvatarAsset = false,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      avatarType: clearAvatarType ? null : (avatarType ?? this.avatarType),
      avatarAsset: clearAvatarAsset ? null : (avatarAsset ?? this.avatarAsset),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        firstName,
        lastName,
        email,
        avatarUrl,
        avatarType,
        avatarAsset,
        createdAt,
        updatedAt,
      ];
}

class FocusFlowSnapshot extends Equatable {
  const FocusFlowSnapshot({
    required this.goals,
    required this.tasks,
    required this.goalTypes,
    this.userProfile,
  });

  final List<Goal> goals;
  final List<FocusTask> tasks;
  final List<CustomGoalType> goalTypes;
  final UserProfile? userProfile;

  @override
  List<Object?> get props => [goals, tasks, goalTypes, userProfile];
}
