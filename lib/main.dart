import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'widgets/solar_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SolarCompanyApp()));
}

class SolarCompanyApp extends ConsumerStatefulWidget {
  const SolarCompanyApp({super.key});

  @override
  ConsumerState<SolarCompanyApp> createState() => _SolarCompanyAppState();
}

class _SolarCompanyAppState extends ConsumerState<SolarCompanyApp> {
  bool _firebaseReady = false;
  bool _firebaseFailed = false;
  String _firebaseError = '';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() {
      _firebaseReady = false;
      _firebaseFailed = false;
    });
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      AuthService.markConfigured();

      // App Check — bots/scripts ko Firestore se rokta hai. Debug builds
      // debug provider use karte hain (token logcat mein aata hai → console
      // mein "Manage debug tokens" se add karo); release Play Integrity.
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );

      // Crashlytics — production crashes report karta hai (free, Spark par
      // bhi chalta hai). Flutter (UI) + platform/Dart errors dono catch.
      final crashlytics = FirebaseCrashlytics.instance;
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      // No demo mode: without Firebase the app cannot be used.
      if (mounted) {
        setState(() {
          _firebaseFailed = true;
          _firebaseError = e.toString();
        });
      }
      return;
    }
    // CEO list needs only config (public read). Repositories load after
    // login (they need authentication).
    try {
      await AuthService.loadCeoEmails();
    } catch (_) {}
    if (mounted) setState(() => _firebaseReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Solar Company',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: _firebaseFailed
          ? _FirebaseErrorScreen(
              error: _firebaseError,
              onRetry: _initApp,
            )
          : _firebaseReady
              ? const LoginScreen()
              : const SolarLoader(message: 'Connecting to Firebase...'),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00A86B),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1B2A21) : Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            dark ? const Color(0xFF22332A) : const Color(0xFF1B2E24),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _FirebaseErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: Color(0xFF00A86B), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Could not connect to Firebase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app needs a working internet connection to use Firebase.\n'
                'Check your network and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
