class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const dashboard = '/dashboard';
  static const goals = '/goals';
  static const addGoal = '/goals/new';
  static const goalDetailsPattern = '/goals/:goalId';
  static const tasks = '/tasks';
  static const addTask = '/tasks/new';
  static const taskDetailsPattern = '/tasks/:taskId';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const checkEmail = '/check-email';

  static String goalDetails(String goalId) => '/goals/$goalId';

  static String editGoal(String goalId) => '/goals/$goalId/edit';

  static String taskDetails(String taskId) => '/tasks/$taskId';

  static String editTask(String taskId) => '/tasks/$taskId/edit';
}
