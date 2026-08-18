import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/collections.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Device-level settings only (no user data).
  // Data (requests, team, chats, notifications, profiles) is 100% Firestore.
  Future<SettingsData> getSettings() async {
    final prefs = await _instance;
    final raw = prefs.getString(PrefsKeys.settings);
    if (raw == null) return SettingsData();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return SettingsData(
      fingerprint: map['fingerprint'] ?? false,
      lastEmail: map['lastEmail'] ?? '',
      notifications: map['notifications'] ?? true,
    );
  }

  Future<void> saveSettings(SettingsData data) async {
    final prefs = await _instance;
    await prefs.setString(
      PrefsKeys.settings,
      jsonEncode({
        'fingerprint': data.fingerprint,
        'lastEmail': data.lastEmail,
        'notifications': data.notifications,
      }),
    );
  }
}

class SettingsData {
  final bool fingerprint;
  final String lastEmail;
  final bool notifications;

  SettingsData({
    this.fingerprint = false,
    this.lastEmail = '',
    this.notifications = true,
  });

  SettingsData copyWith({
    bool? fingerprint,
    String? lastEmail,
    bool? notifications,
  }) => SettingsData(
    fingerprint: fingerprint ?? this.fingerprint,
    lastEmail: lastEmail ?? this.lastEmail,
    notifications: notifications ?? this.notifications,
  );
}
