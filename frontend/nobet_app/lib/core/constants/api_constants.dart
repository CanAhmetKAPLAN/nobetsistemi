class ApiConstants {
  static const String baseUrl = 'https://api.nobetsistemi.online/api';

  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  static const String users = '$baseUrl/users';
  static const String usersMe = '$baseUrl/users/me';

  static const String groups = '$baseUrl/groups';
  static const String groupsMine = '$baseUrl/groups/mine';
  static const String groupsJoin = '$baseUrl/groups/join';

  static const String duties = '$baseUrl/duties';
  static const String dutiesAutoAssign = '$baseUrl/duties/auto-assign';
  static const String dutiesManual = '$baseUrl/duties/manual';
  static const String dutiesByMonth = '$baseUrl/duties/by-month';
  static const String dutiesMonthlyScores = '$baseUrl/duties/monthly-scores';
  static const String dutiesAutoFillMonth = '$baseUrl/duties/auto-fill-month';

  static const String leaves = '$baseUrl/leaves';
  static const String leavesMy = '$baseUrl/leaves/my';
  static const String leavesPending = '$baseUrl/leaves/pending';

  static const String swaps = '$baseUrl/swaps';
  static const String swapsMy = '$baseUrl/swaps/my';
  static const String swapsPending = '$baseUrl/swaps/pending';

  static const String notifications = '$baseUrl/notifications';
  static const String notificationsUnreadCount = '$baseUrl/notifications/unread-count';
  static const String notificationsReadAll = '$baseUrl/notifications/read-all';
}
