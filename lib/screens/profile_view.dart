import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user.dart';
import '../providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_tilt_card.dart';
import '../widgets/stat_row.dart';
import 'settings_screen.dart';

class ProfileView extends ConsumerStatefulWidget {
  final UserModel user;

  const ProfileView({super.key, required this.user});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      String photoValue;
      // Fix #9: photo Firebase Storage mein upload hoti hai (best practice,
      // Blaze plan par). Spark (free) plan par Storage enable nahi hota —
      // us case mein base64 Firestore fallback (jo Spark par chalta hai).
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos/${widget.user.email}.jpg');
        // Purani photo (URL wali) delete karo taake storage na bhare.
        final old = ref.read(profileRepositoryProvider).photoFor(widget.user.email);
        if (old != null && old.startsWith('http')) {
          try {
            await FirebaseStorage.instance.refFromURL(old).delete();
          } catch (_) {
            // purani file delete na ho to ignore
          }
        }
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        photoValue = await storageRef.getDownloadURL();
      } catch (_) {
        // Storage unavailable (Spark plan) → legacy base64 fallback.
        photoValue = base64Encode(bytes);
      }
      await ref.read(profileRepositoryProvider).saveProfile(
        email: widget.user.email,
        photo: photoValue,
      );
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select photo')),
      );
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(
        text: ref.read(displayNameProvider(widget.user)));
    final phoneCtrl = TextEditingController(
        text: ref.read(displayPhoneProvider(widget.user)));
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: AppPalette.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppPalette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Naam',
                labelStyle: TextStyle(color: AppPalette.textMuted),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppPalette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: TextStyle(color: AppPalette.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final phone = phoneCtrl.text.trim();
    if (phone.isNotEmpty &&
        phone.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 11-digit phone number'),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await ref.read(profileRepositoryProvider).saveProfile(
      email: widget.user.email,
      name: nameCtrl.text.trim(),
      phone: phone,
    );
    if (mounted) setState(() {});
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final email = widget.user.email;
    final outcome = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        bool sendingReset = false;

        Future<String?> save() async {
          final repo = ref.read(profileRepositoryProvider);
          try {
            await repo.changePassword(
              oldPassword: oldCtrl.text,
              newPassword: newCtrl.text,
            );
            return null;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'wrong-password' ||
                e.code == 'invalid-credential') {
              return 'Old password is incorrect';
            }
            return e.message ?? 'Failed to change password';
          } catch (_) {
            return 'Network issue — please try again';
          }
        }

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Change Password',
              style: TextStyle(color: AppPalette.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppPalette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Old password',
                    labelStyle: TextStyle(color: AppPalette.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppPalette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'New password',
                    labelStyle: TextStyle(color: AppPalette.textMuted),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: sendingReset
                        ? null
                        : () async {
                            setDialogState(() => sendingReset = true);
                            await AuthService.sendPasswordReset(email);
                            if (ctx.mounted) Navigator.of(ctx).pop('sent');
                          },
                    child: Text(
                      sendingReset
                          ? 'Sending...'
                          : 'Forgot password? Send reset link',
                      style: const TextStyle(color: AppPalette.primary),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final err = await save();
                  if (!ctx.mounted) return;
                  if (err == null) {
                    Navigator.of(ctx).pop('changed');
                  } else {
                    setDialogState(() => error = err);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
        );
      },
    );
    if (!mounted || outcome == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome == 'changed'
            ? 'Password changed'
            : 'Reset link sent to your email'),
      ),
    );
  }

  Future<void> _toggleFingerprint(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      try {
        final available = await auth.getAvailableBiometrics();
        if (available.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Enroll a fingerprint first in Phone Settings → Security')),
          );
          setState(() {});
          return;
        }
      } catch (_) {}
      try {
        final ok = await auth.authenticate(
          localizedReason: 'Authenticate to enable fingerprint',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!ok) {
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fingerprint not verified — try again')),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint error')),
        );
        return;
      }
    }
    await ref.read(profileRepositoryProvider).setFingerprint(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final pending = ref.watch(pendingCountProvider(user));
    final inProgress = ref.watch(inProgressCountProvider(user));
    final resolved = ref.watch(resolvedCountProvider(user));
    final displayName = ref.watch(displayNameProvider(user));
    final displayPhone = ref.watch(displayPhoneProvider(user));
    final photo = ref.watch(photoProvider(user));
    final fingerEnabled = ref.watch(fingerprintEnabledProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        GlassTiltCard(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  photo != null
                      ? ClipOval(
                          child: photo.startsWith('http')
                              ? Image.network(
                                  photo,
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                )
                              : Image.memory(
                                  // Legacy base64 photos (migration se pehle)
                                  base64Decode(photo),
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Container(
                          width: 86,
                          height: 86,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00C97D),
                                  Color(0xFF00A86B)
                                ]),
                          ),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppPalette.cardBorder),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          color: Color(0xFF00A86B), size: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                displayName,
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                user.roleLabel,
                style: TextStyle(
                    color: Color(0xFF00A86B), fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                user.email,
                style: TextStyle(color: AppPalette.textMuted, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                displayPhone,
                style: TextStyle(color: AppPalette.textFaint, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _profileBtn(Icons.edit_rounded, 'Edit', _editProfile),
                  const SizedBox(width: 10),
                  _profileBtn(Icons.camera_alt_rounded, 'Photo', _pickPhoto),
                  const SizedBox(width: 10),
                  _profileBtn(Icons.lock_reset_rounded, 'Password',
                      _changePassword),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Text(
              user.isSuperAdmin
                  ? 'Requests (All)'
                  : user.isSubAdmin
                      ? 'Requests (My Assignments)'
                      : 'Requests (Meri)',
              style: TextStyle(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StatRow(
          stats: [
            StatData('Pending', '$pending', Icons.pending_actions_rounded,
                const Color(0xFFFFB300)),
            StatData('In Progress', '$inProgress',
                Icons.hourglass_top_rounded, const Color(0xFF2196F3)),
          ],
        ),
        const SizedBox(height: 14),
        StatRow(
          stats: [
            StatData('Resolved', '$resolved', Icons.check_circle_rounded,
                const Color(0xFF2E7D32)),
            StatData('Total', '${pending + inProgress + resolved}',
                Icons.assignment_rounded, const Color(0xFF00A86B)),
          ],
        ),
        const SizedBox(height: 16),
        GlassTiltCard(
          child: Row(
            children: [
              Icon(Icons.fingerprint_rounded,
                  color: Color(0xFF00A86B), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fingerprint Login',
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sign in with fingerprint on the login screen',
                      style: TextStyle(color: AppPalette.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: fingerEnabled,
                activeTrackColor: const Color(0xFF00A86B),
                onChanged: _toggleFingerprint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassTiltCard(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1976D2).withValues(alpha: 0.13),
                    ),
                    child: Icon(Icons.settings_rounded,
                        color: Color(0xFF1976D2), size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Notifications, app info, reset demo',
                          style:
                              TextStyle(color: AppPalette.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFB0BDB5), size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppPalette.surfaceSoft,
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF00A86B), size: 16),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
