/// Firestore collection names — single source of truth
class Collections {
  const Collections._();

  static const String requests = 'requests';
  static const String messages = 'messages';
  static const String users = 'users';
  static const String team = 'team';
  static const String subTeams = 'sub_teams';
  static const String profiles = 'profiles';
  static const String notifications = 'notifications';
  static const String config = 'config';
}

/// SharedPreferences keys
class PrefsKeys {
  const PrefsKeys._();

  static const String requests = 'requests';
  static const String teamMembers = 'team_members';
  static const String messages = 'messages';
  static const String profiles = 'profiles';
  static const String subTeams = 'sub_teams';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
}