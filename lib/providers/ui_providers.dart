import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final requestCategoryFilterProvider = StateProvider<RequestCategory?>((ref) => null);

final requestStatusFilterProvider = StateProvider<RequestStatus?>((ref) => null);

final adminStatusFilterProvider = StateProvider<RequestStatus?>((ref) => null);

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

final chatSearchQueryProvider = StateProvider<String>((ref) => '');

final loadingStateProvider = StateProvider<bool>((ref) => true);

// ─────────────────────────────────────────────────────────────────────
// Auth — two providers, zero breakage:
//
// 1) authUserProvider  — reactive StreamProvider, listens to
//    FirebaseAuth.authStateChanges(). Resolves UserModel from Firestore.
//    NEW code should use this.
//
// 2) currentUserProvider — legacy StateProvider, kept for backward
//    compatibility. home_screen sets it on login, clears on logout.
//    Existing screens that call ref.read(currentUserProvider) keep
//    working.
//
// Eventually all screens migrate to (1) and (2) is deleted.
// ─────────────────────────────────────────────────────────────────────
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Reactive auth state from Firebase Auth.
/// Resolves UserModel on login, emits null on logout.
final authUserProvider = StreamProvider<UserModel?>((ref) async* {
  await for (final fbUser in fb.FirebaseAuth.instance.authStateChanges()) {
    if (fbUser == null) {
      yield null;
    } else {
      // Resolve user role/name from Firestore via existing AuthService.
      try {
        final user = await AuthService.resolveFirebaseUser(fbUser);
        yield user;
      } catch (_) {
        // Fallback: basic user with default role if Firestore resolve fails.
        yield UserModel(
          name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
          email: fbUser.email ?? '',
          phone: '',
          role: AuthService.ceoEmails.contains(fbUser.email?.toLowerCase())
              ? UserRole.superAdmin
              : UserRole.user,
        );
      }
    }
  }
});

/// Convenience: current user from the reactive auth stream.
/// Returns null when not logged in or still loading.
final currentUser = Provider<UserModel?>((ref) {
  return ref.watch(authUserProvider).valueOrNull;
});