import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_tilt_card.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // FirebaseAuth khud user-not-found error deta hai — Firestore pre-auth
      // read nahi karte (rules allow nahi karti).
      final err = await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _loading = false;
          _error = err;
        });
        return;
      }

      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Network issue — please try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppPalette.textPrimary, size: 20),
                    ),
                    Text(
                      'Forgot Password',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassTiltCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              _sent ? Icons.mark_email_read_outlined : Icons.mail_outline_rounded,
                              size: 40,
                              color: Color(0xFF00A86B),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _sent ? 'Check your email' : 'Enter your email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 14),
                            if (!_sent) ...[
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: AppPalette.textPrimary),
                                decoration: _dec('Email'),
                              ),
                            ] else ...[
                              SizedBox(height: 6),
                              Text(
                                'Reset link sent to ${_emailController.text.trim()}.\n'
                                'Open the email on this phone, tap the link, '
                                'and set your new password there.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppPalette.textMuted, fontSize: 13),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F), fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: _loading
                                  ? null
                                  : _sent
                                      ? () => Navigator.of(context).pop()
                                      : _sendResetLink,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C97D),
                                        Color(0xFF00A86B)
                                      ]),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A86B)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _loading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _sent
                                            ? 'Done'
                                            : 'Send Reset Link',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppPalette.textFaint),
      filled: true,
      fillColor: AppPalette.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.4),
      ),
    );
  }
}