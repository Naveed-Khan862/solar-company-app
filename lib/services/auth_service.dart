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
  // SEC-06: source mein koi hardcoded CEO email nahi — list hamesha Firestore
  // se aati hai (config/ceoEmails doc, SEC-04 signed-in-only read; legacy
  // fallback config/settings). ⚠️ Firestore mein config/ceoEmails doc bana
  // kar usme ceoEmails: [aapki-email] list rakho — warna app CEO ko superAdmin
  // nahi manegi. Console se email add/remove karo, code change ki zaroorat nahi.
  static List<String> _ceoEmails = [];

  static List<String> get ceoEmails => _ceoEmails;

  static Future<void> loadCeoEmails() async {
    // SEC-04: CEO email list ab config/ceoEmails doc mein (signed-in-only
    // read) — public config/settings se hata di gayi hai. Pehle naya doc,
    // phir legacy config/settings fallback (migration ke dauraan compatibility).
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
        // permission/network — agla source try karo, warna fallback list
      }
    }
  }

  static bool _configured = false;

  static bool get isConfigured => _configured;

  static void markConfigured() => _configured = true;

  static Future<UserModel> _resolveUser(User u) async {
    final email = (u.email ?? '').toLowerCase();
    // SEC-04: login ke baad (signed-in) config/ceoEmails dobara load karo —
    // pre-auth wala load (main.dart) sirf public settings hi padh sakta tha,
    // isliye ab yahan asli list refresh hoti hai.
    try {
      await loadCeoEmails();
    } catch (_) {}
    // Crashlytics — crash report ke saath user email bhi jaye taake pata
    // chale kis user ko masla aya (sirf internal, privacy-safe: email
    // hashed nahi, lekin sirf developer ko Crashlytics console mein dikhta).
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(email);
    } catch (_) {}
    try {
      // Doc ka ID = email (uniqueness). Purane uid-keyed docs migrante
      // hain aur delete ho jate hain taake koi duplicate na bachy.
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(email);
      final doc = await ref.get();
      Map<String, dynamic> data = {};
      if (doc.exists) {
        data = doc.data() ?? {};
      }
      final isCeo = ceoEmails.contains(email);
      if (data.isEmpty) {
        final legacy = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(20)
            .get();
        for (final d in legacy.docs) {
          if (d.id == email) continue;
          final ldata = d.data();
          if (ldata['role'] == 'superAdmin' || data.isEmpty) {
            data = ldata;
          }
          await d.reference.delete();
        }
      }
      final name = (data['name'] ?? u.displayName ?? email.split('@').first)
          .toString();
      final phone = (data['phone'] ?? '').toString();
      await ref.set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': isCeo ? 'superAdmin' : data['role'] ?? 'user',
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        // Registered flag — sirf login/signup yahan set karta hai. Team
        // add ke waqt ye check hota hai k email ka account bana hai ya nahi.
        'signedUp': true,
      });
      return UserModel(
        name: name,
        email: email,
        phone: phone,
        role: isCeo ? UserRole.superAdmin : _roleFromString(data['role']),
      );
    } catch (_) {
      if (ceoEmails.contains(email)) {
        return UserModel(
          name: u.displayName ?? email.split('@').first,
          email: email,
          phone: '',
          role: UserRole.superAdmin,
        );
      }
      return UserModel(
        name: u.displayName ?? email.split('@').first,
        email: email,
        phone: '',
        role: UserRole.user,
      );
    }
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
      // Fix #10: enumetration roknay ke liye messages generic — koi bhi
      // attacker ye na jaan sake ke email registered hai ya nahi.
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
      return AuthResult(await _resolveUser(u), null);
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
      // Fix #13: unverified email → dobara verification email bhejo (rules
      // request creation block karte hain jab tak verify nahi hota).
      String? notice;
      if (!u.emailVerified) {
        await u.sendEmailVerification();
        notice =
            'Verify your email — link bheja gaya hai. Request banana tab tak limited hai.';
      }
      return AuthResult(await _resolveUser(u), null, notice: notice);
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
      // Auth account pehle ban chuka hai — neeche koi bhi step fail ho to
      // signup ko fail mat karo, warna account orphan reh jata (auth mein
      // dikhe, users collection mein na ho). _resolveUser users doc dobara
      // banata hai, aur har login par bhi self-heal ho jata hai.
      try {
        await cred.user?.updateDisplayName(name);
      } catch (_) {
        // display name optional — fail ho to proceed (name email se aayega)
      }
      // Fix #13: signup par turant verification email — request creation
      // rules email_verified maangte hain.
      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {
        // verification email fail ho to signup proceed (rules tab bhi block karengi)
      }
      final lower = email.toLowerCase();
      // FIX: CEO ne pehle se subadmin/team-member bana rakha ho (users doc
      // maujood, role subAdmin) to signup par usay 'user' par downgrade mat
      // karo — existing role preserve karo. Naye user ke liye 'user'.
      // (Rules: self-update sirf apna current role likh sakta hai, isliye
      // existing role hi likhna allow hai.)
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
        // read fail ho (network) to default 'user' — _resolveUser baad mein
        // existing doc se sahi role parh leta hai.
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
        // users doc write fail ho (network/rules) to bhi signup proceed —
        // _resolveUser neeche dobara try karta hai, aur agli baar login par
        // bhi doc ban jata hai. Sirf CEO bina config/ceoEmails ke rules se
        // block ho sakta hai (role superAdmin) — wo config set karke login
        // karne par ban jata hai.
      }
      return AuthResult(await _resolveUser(cred.user!), null);
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

  /// Play Store requirement (account deletion): user ka poora data delete
  /// + Firebase Auth account delete. Sirf APNA data — requests (userEmail),
  /// messages (senderEmail), notifications (forEmail), profile/users/team
  /// doc, apni sub_team (agar subAdmin ho), aur doosri teams ki memberships.
  /// Assigned requests delete nahi hoti — unassign ho jati hain (client ki
  /// request rehti hai, sirf assignment hat'ti hai). Rules sab self-delete
  /// allow karte hain (firestore.rules — account deletion block).
  ///
  /// Returns null on success, otherwise error message.
  static Future<String?> deleteAccount() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final email = user?.email?.toLowerCase();
    if (user == null || email == null) return 'Not signed in';

    final db = FirebaseFirestore.instance;
    try {
      // 1. Assigned requests unassign — subAdmin ka account delete ho to
      //    clients ki requests orphan na rahen.
      await RequestRepository.instance.unassignAll(email);

      // 2. Apni cheezein delete (sirf apna data — rules allow karte hain).
      await _deleteWhere(
          db.collection(Collections.requests), 'userEmail', email);
      await _deleteWhere(
          db.collection(Collections.messages), 'senderEmail', email);
      await _deleteWhere(
          db.collection(Collections.notifications), 'forEmail', email);

      // 3. Docs — koi doc exist na ho to delete no-op hai (safe). Ek fail
      //    ho to baqi kaam rukna nahi chahiye.
      await _tryDelete(db.collection(Collections.profiles).doc(email));
      await _tryDelete(db.collection(Collections.users).doc(email));
      await _tryDelete(db.collection(Collections.team).doc(email));

      // 4. Apni sub_team + members (agar subAdmin ho).
      final myTeamRef = db.collection(Collections.subTeams).doc(email);
      final myMembers = await myTeamRef.collection('members').get();
      if (myMembers.docs.isNotEmpty) {
        final b = db.batch();
        for (final d in myMembers.docs) b.delete(d.reference);
        await b.commit();
      }
      await _tryDelete(myTeamRef);

      // 5. Doosri sub_teams ki memberships (jahan user member ho).
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

      // 7. Firebase Auth account — delete ke liye recent login chahiye.
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          await auth.signOut();
          return 'Data delete ho gaya. Login phir se karke "Delete Account" dobara dabao — login account bhi remove ho jayega.';
        }
        rethrow;
      }
      return null;
    } on FirebaseException catch (e) {
      return 'Delete fail hua: ${e.message}';
    } catch (_) {
      return 'Network issue — please try again';
    }
  }

  static Future<void> _deleteWhere(
    CollectionReference<Map<String, dynamic>> collection,
    String field,
    String value,
  ) async {
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
      // permission/network — aage badho, baqi cleanup important hai
    }
  }
}
