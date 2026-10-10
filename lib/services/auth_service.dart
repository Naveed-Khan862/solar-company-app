import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/collections.dart';
import '../models/user.dart';
import '../repositories/local_storage.dart';
import '../repositories/request_repository.dart';
import 'secure_credentials.dart';

class AuthResult {
  final UserModel? user;
  final String? error;
  final String? notice;
  final bool cancelled;

  const AuthResult(this.user, this.error,
      {this.cancelled = false, this.notice});
}

class AuthService {
  // SEC-06: no hardcoded CEO email in source — the list always comes from the
  // Firestore config/ceoEmails doc (SEC-04 signed-in-only read; legacy
  // fallback config/settings). ⚠️ Create the config/ceoEmails doc in Firestore
  // with a ceoEmails: [your-email] list — otherwise the app will not treat the
  // CEO as superAdmin. Add/remove emails from the Console, no code change needed.
  static List<String> _ceoEmails = [];

  static List<String> get ceoEmails => _ceoEmails;

  static Future<void> loadCeoEmails() async {
    // SEC-04: the CEO email list now lives in the config/ceoEmails doc
    // (signed-in-only read) — it was removed from public config/settings. Try the
    // new doc first, then the legacy config/settings fallback (migration support).
    for (final docId in ['ceoEmails', 'settings']) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('config')
            .doc(docId)
            .get();
        final data = doc.data();
        if (data != null && data['ceoEmails'] is List) {
          _ceoEmails = (data['ceoEmails'] as List)
              .map((e) => e.toString().toLowerCase())
              .toList();
          return;
        }
      } catch (_) {
        // permission/network — try the next source, otherwise the fallback list
      }
    }
  }

  static bool _configured = false;

  static bool get isConfigured => _configured;

  static void markConfigured() => _configured = true;

  /// Resolve Firebase [User] to [UserModel] — reads/creates Firestore user
  /// doc, checks CEO list, sets Crashlytics identifier.
  /// Called on every login/signup and by the auth stream provider.
  static Future<UserModel> resolveFirebaseUser(User u) async {
    final email = (u.email ?? '').toLowerCase();
    await loadCeoEmails();
    await FirebaseCrashlytics.instance.setUserIdentifier(email);

    final ref = FirebaseFirestore.instance.collection('users').doc(email);
    final doc = await ref.get();
    final data = doc.exists ? doc.data()! : {};

    // Merge: keep existing role if present, otherwise CEO status decides
    final isCeo = ceoEmails.contains(email);
    final role = isCeo
        ? UserRole.superAdmin
        : (_roleFromString(data['role'] ?? 'user'));

    final name = (data['name'] ?? u.displayName ?? email.split('@').first)
        .toString();
    final phone = data['phone'] ?? '';

    // Write/update user doc with consistent data
    await ref.set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      'signedUp': true,
    }, SetOptions(merge: true));

    return UserModel(
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
  }

  static UserRole _roleFromString(String? role) {
    switch (role) {
      case 'superAdmin':
        return UserRole.superAdmin;
      case 'subAdmin':
        return UserRole.subAdmin;
      default:
        return UserRole.user;
    }
  }

  static String _errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Sign-up failed — try another email or login';
      case 'invalid-email':
        return 'Enter a valid email';
      case 'weak-password':
        return 'Password must be at least 8 characters';
      case 'wrong-password':
      case 'user-not-found':
        return 'Login failed — check your email and password';
      case 'too-many-requests':
        return 'Too many attempts — please wait a while';
      case 'network-request-failed':
        return 'Please check your internet connection';
      default:
        return e.message ?? 'Something went wrong — please try again';
    }
  }

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return const AuthResult(null, null, cancelled: true);
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final u = userCred.user;
      if (u == null) return const AuthResult(null, 'Sign-in failed');
      return AuthResult(await resolveFirebaseUser(u), null);
    } on FirebaseAuthException catch (e) {
      return AuthResult(null, _errorText(e));
    } catch (_) {
      return const AuthResult(
          null, 'Google sign-in failed — check Google Play Services');
    }
  }

  static Future<AuthResult> signInWithEmail(
      String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final u = cred.user;
      if (u == null) return const AuthResult(null, 'Login failed');
      // Fix #13: unverified email → send the verification email again (the rules
      // block request creation until the email is verified).
      String? notice;
      if (!u.emailVerified) {
        await u.sendEmailVerification();
        notice =
            'Verify your email — a verification link has been sent. Request creation is limited until you verify.';
      }
      return AuthResult(await resolveFirebaseUser(u), null, notice: notice);
    } on FirebaseAuthException catch (e) {
      return AuthResult(null, _errorText(e));
    } catch (_) {
      return const AuthResult(null, 'Network issue — please try again');
    }
  }

  static Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // The auth account is already created — if any step below fails,
      // do not fail the signup, otherwise the account stays orphaned (it exists
      // in auth but not in the users collection). _resolveUser recreates the
      // users doc, and it self-heals on every login too.
      try {
        await cred.user?.updateDisplayName(name);
      } catch (_) {
        // display name optional — proceed if it fails (the name comes from the email)
      }
      // Fix #13: verification email right at signup — the request creation
      // rules require email_verified.
      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {
        // if the verification email fails continue signup (the rules block anyway)
      }
      final lower = email.toLowerCase();
      // FIX: if the CEO already made this person a subadmin/team-member (the
      // users doc exists with role subAdmin), do not downgrade them to 'user'
      // on signup — keep the existing role. A new user gets 'user'.
      // (Rules: a self-update may only write its current role, so writing the
      // existing role is the only thing allowed.)
      String role;
      try {
        final existing = await FirebaseFirestore.instance
            .collection('users')
            .doc(lower)
            .get();
        role = ceoEmails.contains(lower)
            ? 'superAdmin'
            : (existing.exists
                ? (existing.data()?['role'] as String? ?? 'user')
                : 'user');
      } catch (_) {
        // if the read fails (network) default to 'user' — _resolveUser later
        // reads the correct role from the existing doc.
        role = ceoEmails.contains(lower) ? 'superAdmin' : 'user';
      }
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(lower)
            .set({
          'name': name,
          'email': lower,
          'phone': phone,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'signedUp': true,
        });
      } catch (_) {
        // even if the users doc write fails (network/rules) continue signup —
        // _resolveUser tries again below, and normally on the next login
        // the doc is created too. Only a CEO without config/ceoEmails can be
        // blocked by the rules (role superAdmin) — that one is created once the
        // config is set and they log in.
      }
      return AuthResult(await resolveFirebaseUser(cred.user!), null);
    } on FirebaseAuthException catch (e) {
      return AuthResult(null, _errorText(e));
    } catch (_) {
      return const AuthResult(null, 'Network issue — please try again');
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorText(e);
    } catch (_) {
      return 'Network issue — please try again';
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// Play Store requirement (account deletion): delete all of the user's data
  /// + delete the Firebase Auth account. OWN data only — requests (userEmail),
  /// messages (senderEmail), notifications (forEmail), profile/users/team
  /// doc, their own sub_team (if subAdmin), and memberships in other teams.
  /// Assigned requests are not deleted — they are unassigned (the client's
  /// request stays, only the assignment goes away). The rules allow every
  /// self-delete (firestore.rules — account deletion block).
  ///
  /// Returns null on success, otherwise error message.
  static Future<String?> deleteAccount() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final email = user?.email?.toLowerCase();
    if (user == null || email == null) return 'Not signed in';

    final db = FirebaseFirestore.instance;
    try {
      // 1. Unassign assigned requests — when a subAdmin account is deleted,
      //    client requests must not be left orphaned.
      await RequestRepository.instance.unassignAll(email);

      // 2. Delete own items (own data only — the rules allow it).
      await _deleteWhere(
          db.collection(Collections.requests), 'userEmail', email);
      await _deleteWhere(
          db.collection(Collections.messages), 'senderEmail', email);
      await _deleteWhere(
          db.collection(Collections.notifications), 'forEmail', email);

      // 3. Docs — deleting a non-existent doc is a no-op (safe). One failure
      //    must not stop the rest of the work.
      await _tryDelete(db.collection(Collections.profiles).doc(email));
      await _tryDelete(db.collection(Collections.users).doc(email));
      await _tryDelete(db.collection(Collections.team).doc(email));

      // 4. Apni sub_team + members (agar subAdmin ho).
      final myTeamRef = db.collection(Collections.team).doc(email);
      final myMembers = await myTeamRef.collection('members').get();
      if (myMembers.docs.isNotEmpty) {
        final b = db.batch();
        for (final d in myMembers.docs) b.delete(d.reference);
        await b.commit();
      }
      await _tryDelete(myTeamRef);

      // 5. Memberships in other sub_teams (where the user is a member).
      final memberships = await db
          .collectionGroup('members')
          .where('email', isEqualTo: email)
          .get();
      if (memberships.docs.isNotEmpty) {
        final b = db.batch();
        for (final d in memberships.docs) b.delete(d.reference);
        await b.commit();
      }

      // 6. Local data + fingerprint credentials clear.
      await LocalStorage.instance.saveSettings(SettingsData());
      await SecureCredentials.clear();

      // 7. Firebase Auth account — deletion requires a recent login.
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          await auth.signOut();
          return 'Your data has been deleted. Log in again and tap "Delete Account" once more — the login account will also be removed.';
        }
        rethrow;
      }
      return null;
    } on FirebaseException catch (e) {
      return 'Delete failed: ${e.message}';
    } catch (_) {
      return 'Network issue — please try again';
    }
  }

  static Future<void> _deleteWhere(
      CollectionReference<Map<String, dynamic>> collection,
      String field,
      String value,) async {
    final snap = await collection.where(field, isEqualTo: value).get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
  }

  static Future<void> _tryDelete(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.delete();
    } catch (_) {
      // permission/network — carry on, the rest of the cleanup matters
    }
  }
}