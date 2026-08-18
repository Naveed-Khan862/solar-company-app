import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user.dart';
import '../providers.dart';
import '../services/auth_service.dart';
import '../services/secure_credentials.dart';
import '../widgets/glass_tilt_card.dart';
import '../widgets/solar_house_scene.dart';
import '../widgets/solar_loader.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Repositories are loaded via initializeRepositoriesProvider in main.dart
    ref.read(initializeRepositoriesProvider.future).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!email.contains('@')) {
      setState(() {
        _loading = false;
        _error = 'Enter a valid email (e.g. user@company.com)';
      });
      return;
    }

    UserModel? user;
    String? error;

    final res = await AuthService.signInWithEmail(email, password);
    user = res.user;
    error = res.error;

    if (!mounted) return;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    await ref.read(profileRepositoryProvider).setLastEmail(email);
    // Fingerprint login ke liye password encrypted store mein save karo
    // (har email login par refresh hota hai). Login kabhi fail na ho isliye
    // try/catch — storage error aaye to login phir bhi proceed.
    if (password.isNotEmpty) {
      try {
        await SecureCredentials.save(email, password);
      } catch (_) {
        // secure storage fail ho to fingerprint agle email login par retry karega.
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);

    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(user: user!, notice: res.notice),
      ),
    ));
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AuthService.signInWithGoogle();
    if (!mounted) return;
    if (res.user != null) {
      await ref.read(profileRepositoryProvider).setLastEmail(res.user!.email);
      if (!mounted) return;
      setState(() => _loading = false);
      unawaited(Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: res.user!)),
      ));
    } else if (res.error != null) {
      setState(() {
        _loading = false;
        _error = res.error;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fingerprintLogin() async {
    final auth = LocalAuthentication();
    try {
      final available = await auth.getAvailableBiometrics();
      if (available.isEmpty) {
        setState(
          () => _error = 'Fingerprint not enrolled — set it up in Settings',
        );
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Solar Company login fingerprint',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!ok || !mounted) return;
      final cred = await SecureCredentials.read();
      if (cred == null) {
        setState(
          () => _error =
              'Fingerprint login need a password — login with email first',
        );
        return;
      }
      final res = await AuthService.signInWithEmail(cred.email, cred.password);
      if (!mounted) return;
      if (res.user != null) {
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(user: res.user!, notice: res.notice),
          ),
        ));
      } else {
        setState(() => _error = res.error ?? 'Login failed — login with email');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Fingerprint is not available on this device');
    }
  }

  bool get _fingerprintHero =>
      ref.read(fingerprintEnabledProvider) &&
      ref.read(profileRepositoryProvider).settings.lastEmail.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final lastEmail = ref.watch(
      profileRepositoryProvider.select((p) => p.settings.lastEmail),
    );
    return Scaffold(
      body: Stack(
        children: [
          SolarHouseScene(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF007A4D), Color(0xFF00B26B)],
                      ).createShader(bounds),
                      child: const Text(
                        'Solar Company',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      'Complaint Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassTiltCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_fingerprintHero) ...[
                            Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xFF00A86B),
                              size: 64,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Welcome back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              lastEmail,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppPalette.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: _fingerprintLogin,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00C97D),
                                      Color(0xFF00A86B),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00A86B,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Login with Fingerprint',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppPalette.border),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: AppPalette.textFaint,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: AppPalette.border),
                                ),
                              ],
                            ),
                          ],
                          Text(
                              'Welcome back',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Login to your account',
                              style: TextStyle(
                                color: AppPalette.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Field(
                              controller: _emailController,
                              hint: 'Email',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 14),
                            _Field(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppPalette.textMuted,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF00A86B),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _GradientButton(
                              loading: _loading,
                              label: _loading ? 'Logging in...' : 'Login',
                              icon: _loading
                                  ? null
                                  : Icons.arrow_forward_rounded,
                              onPressed: _loading ? null : _login,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppPalette.border),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: AppPalette.textFaint,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: AppPalette.border),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _loading ? null : _googleLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: AppPalette.surface,
                                    border: Border.all(
                                      color: AppPalette.border,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppPalette.shadow.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFF4285F4),
                                                Color(0xFFEA4335),
                                                Color(0xFFFBBC05),
                                                Color(0xFF34A853),
                                              ],
                                            ).createShader(bounds),
                                        child: const Text(
                                          'G',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: AppPalette.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New account? ',
                                  style: TextStyle(
                                    color: AppPalette.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Color(0xFF00A86B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          if (_loading) SolarLoader(overlay: true, message: 'Logging in...'),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: AppPalette.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppPalette.textFaint),
        prefixIcon: Icon(icon, color: Color(0xFF00A86B), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppPalette.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.4),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.loading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C97D), Color(0xFF00A86B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                if (loading) const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
