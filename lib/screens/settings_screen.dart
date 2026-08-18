import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers.dart';
import '../services/auth_service.dart';
import '../services/secure_credentials.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_tilt_card.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _toggleFingerprint(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    var ok = true;
    if (value) {
      final auth = LocalAuthentication();
      try {
        final available = await auth.getAvailableBiometrics();
        if (available.isNotEmpty) {
          ok = await auth.authenticate(
            localizedReason: 'Confirm to activate fingerprint login',
            options: const AuthenticationOptions(biometricOnly: true),
          );
        } else {
          ok = false;
        }
      } catch (_) {
        ok = false;
      }
    }
    if (!mounted) return;
    if (ok) {
      await ref.read(profileRepositoryProvider).setFingerprint(value);
      if (!value) {
        await ref.read(profileRepositoryProvider).setLastEmail('');
        await SecureCredentials.clear();
      }
      setState(() {
        _busy = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Fingerprint login on — login page par fingerprint button aa jayega'
                : 'Fingerprint login off',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00A86B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Fingerprint not verified',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetDemo() async {
    // Security: poora DB wipe kaam hai — sirf superAdmin (CEO) kar sakta hai.
    final me = ref.read(currentUserProvider);
    if (me == null || !me.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset sirf CEO (Super Admin) kar sakta hai'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo data reset?'),
        content: const Text(
            'All requests, chat, team, ratings and settings will be deleted and a fresh demo will start. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(profileRepositoryProvider).clear();
    // Also clear other repositories
    await ref.read(requestRepositoryProvider).clear();
    await ref.read(teamRepositoryProvider).clear();
    await ref.read(chatRepositoryProvider).clear();
    await ref.read(notificationRepositoryProvider).clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo data reset — please login again',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Crashlytics verify karne ke liye jaani-bujh kar crash. Release build
  // mein ye report Firebase Console > Crashlytics mein 1-2 min mein aati hai.
  Future<void> _testCrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test crash?'),
        content: const Text(
          'App abhi deliberately crash karega. Ye Crashlytics console mein '
          'report verify karne ke liye hai. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Crash'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Deliberate crash — release build mein Crashlytics isay pakar leta hai.
    FirebaseCrashlytics.instance.crash();
  }

  // Play Store requirement: har user apna account delete kar sakta hai.
  // AuthService.deleteAccount() sab data (requests, chats, profile, team
  // memberships) + Firebase Auth account delete karta hai.
  Future<void> _deleteAccount() async {
    final me = ref.read(currentUserProvider);
    final isCeo = me?.isSuperAdmin == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete my account?'),
        content: Text(
          isCeo
              ? 'Your account and all your data (requests, chats, profile, team) will be permanently deleted. '
                  '⚠️ You are the admin (CEO) — agar koi doosra admin na ho to app unmanageable ho sakti hai. '
                  'This cannot be undone. Are you sure?'
              : 'Your account and all your data (requests, chats, profile) will be permanently deleted. '
                  'This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final error = await AuthService.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(currentUserProvider.notifier).state = null;
    if (!mounted) return;
    unawaited(Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deleted', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fingerprintEnabled = ref.watch(fingerprintEnabledProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final darkMode = ref.watch(themeControllerProvider);
    // Reset Demo Data sirf superAdmin (CEO) ko dikhana hai.
    final isSuperAdmin = ref.read(currentUserProvider)?.isSuperAdmin ?? false;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppPalette.textPrimary, size: 20),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    GlassTiltCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeThumbColor: Color(0xFF00A86B),
                            title: Text(
                              'Dark Theme',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Aankhon ko aaram — dark mode on/off',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 12),
                            ),
                            secondary: Icon(
                              darkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: Color(0xFF00A86B),
                            ),
                            value: darkMode,
                            onChanged: (v) => ref.read(themeControllerProvider.notifier).setDark(v),
                          ),
                          Divider(
                              height: 1, color: AppPalette.track),
                          SwitchListTile(
                            activeThumbColor: Color(0xFF00A86B),
                            title: Text(
                              'Notifications',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Naye requests, assignments, status changes ki alerts',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 12),
                            ),
                            value: notificationsEnabled,
                            onChanged: _busy
                                ? null
                                : (v) async {
                                    await ref.read(profileRepositoryProvider).setNotificationsEnabled(v);
                                  },
                          ),
                          Divider(
                              height: 1, color: AppPalette.track),
                          SwitchListTile(
                            activeThumbColor: Color(0xFF00A86B),
                            title: Text(
                              'Fingerprint Login',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Show fingerprint button on login screen',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 12),
                            ),
                            value: fingerprintEnabled,
                            onChanged: _busy ? null : _toggleFingerprint,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    GlassTiltCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.info_outline_rounded,
                                color: Color(0xFF00A86B)),
                            title: Text(
                              'Solar Company',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Version $_version\nYour data is synced with Firebase cloud',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 12),
                            ),
                          ),
                          Divider(
                              height: 1, color: AppPalette.track),
                          if (isSuperAdmin)
                            ListTile(
                              onTap: _resetDemo,
                              leading: const Icon(Icons.delete_forever_rounded,
                                  color: Color(0xFFE53935)),
                              title: Text(
                                'Reset Demo Data',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Reset everything',
                                style: TextStyle(
                                    color: AppPalette.textMuted, fontSize: 12),
                              ),
                            ),
                          Divider(height: 1, color: AppPalette.track),
                          if (isSuperAdmin)
                            ListTile(
                              onTap: _testCrash,
                              leading: const Icon(Icons.bug_report_rounded,
                                  color: Color(0xFFFB8C00)),
                              title: Text(
                                'Test Crash (Crashlytics)',
                                style: TextStyle(
                                  color: Color(0xFFFB8C00),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Release build mein jaani-bujh kar crash — Crashlytics console verify karne ke liye',
                                style: TextStyle(
                                    color: AppPalette.textMuted, fontSize: 12),
                              ),
                            ),
                          Divider(height: 1, color: AppPalette.track),
                          ListTile(
                            onTap: _busy ? null : _deleteAccount,
                            leading: const Icon(Icons.person_remove_rounded,
                                color: Color(0xFFE53935)),
                            title: Text(
                              'Delete My Account',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Delete my account and all my data',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Demo logins: admin@company.com (CEO) · sub@company.com (Sub Admin) · koi bhi email (User)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppPalette.textFaint, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}