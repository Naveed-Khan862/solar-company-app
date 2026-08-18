import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/collections.dart';
import '../models/user.dart';
import 'request_repository.dart';

class TeamRepository {
  TeamRepository._();

  static final TeamRepository instance = TeamRepository._();

  final List<UserModel> _team = [];
  final Map<String, List<UserModel>> _subTeams = {};
  bool _loaded = false;
  final _revisionController = StreamController<int>.broadcast();

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  List<UserModel> get team => List.unmodifiable(_team);
  List<UserModel> subTeamOf(String email) => List.unmodifiable(_subTeams[email] ?? const []);
  Map<String, List<UserModel>> get subTeams => Map.unmodifiable(_subTeams);

  /// #13 (privacy): team lists sirf woh load hoti hain jo user access kar
  /// sakta hai — superAdmin → sab; subAdmin → apni team; member (normal
  /// user) → sirf woh sub_teams jahan wo member hai (collectionGroup).
  /// Rest of the app (chat channels, team_view) inhi scoped lists se chalta
  /// hai, isliye UI pe koi farq nahi aata.
  ///
  /// Har hissa ALAG try/catch mein hai: koi ek query fail ho (permission,
  /// malformed doc, network) to poori team load na ruke. Jab tak `_bump()`
  /// na ho, UI pehle wali (khali) list dikhati rehti hai — isliye finally
  /// mein hamesha bump karte hain taake jo bhi load hua wo dikhe.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    final db = FirebaseFirestore.instance;
    _team.clear();
    _subTeams.clear();

    try {
      if (user.isSuperAdmin) {
        // Sub Admins ki list — ye hi sab se zaroori hai. Fail ho to list
        // khali rehti hai (rules/permission), lekin aage ke steps chalein.
        final teamSnap = await db.collection(Collections.team).get();
        _team.addAll(teamSnap.docs.map((d) => _userFromJson(d.data())));

        final stSnap = await db.collection(Collections.subTeams).get();
        for (final doc in stSnap.docs) {
          try {
            final membersSnap = await db
                .collection(Collections.subTeams)
                .doc(doc.id)
                .collection('members')
                .get();
            _subTeams[doc.id] = membersSnap.docs
                .map((d) => _userFromJson(d.data()))
                .toList();
          } catch (_) {
            // ek sub-team ke members fail hon to baqi sab load ho jayein
          }
        }
      } else if (user.isSubAdmin) {
        final membersSnap = await db
            .collection(Collections.subTeams)
            .doc(user.email)
            .collection('members')
            .get();
        _subTeams[user.email] =
            membersSnap.docs.map((d) => _userFromJson(d.data())).toList();
      }
    } catch (_) {
      // team list hi fail ho to kuch load nahi hoga — neeche memberships
      // try hota hai, aur finally bump hamesha hota hai.
    }

    // Normal user / subAdmin kisi department ka member — apni memberships
    // collectionGroup se (rules: sirf apna member doc readable). Iska fail
    // hona team list ko kharab nahi karta — isliye alag try/catch.
    try {
      final myMemberships = await db
          .collectionGroup('members')
          .where('email', isEqualTo: user.email)
          .get();
      for (final d in myMemberships.docs) {
        final owner = d.reference.parent.parent!.id;
        final list = _subTeams[owner] ??= [];
        // dedupe: subAdmin apni hi team ka member ho to double na aaye
        if (list.every((m) => m.email != user.email)) {
          list.add(_userFromJson(d.data()));
        }
      }
    } catch (_) {
      // memberships n/a ya permission — team list pehle hi load ho chuki hai
    } finally {
      _loaded = true;
      _bump();
    }
  }

  // users doc guarantee — role yahan se rules ke getRole() ko milta hai.
  // Google login wale accounts ke liye bhi direct banta hai, "registered"
  // check ki zaroorat nahi (admin khud decide karta hai).
  Future<void> _ensureUserDoc(UserModel member, String role) async {
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(member.email.toLowerCase())
        .set({
      'name': member.name,
      'email': member.email.toLowerCase(),
      'phone': member.phone,
      'role': role,
    }, SetOptions(merge: true));
  }

  /// Email ka signup hua hai ya nahi — users doc par `signedUp: true` flag
  /// (jo sirf login/signup par `_resolveUser` lagata hai). Bina flag ke doc
  /// (provisioned/pending) ya missing doc = account nahi bana.
  Future<String?> _checkRegistered(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(email.toLowerCase())
          .get();
      if (!doc.exists || doc.data()?['signedUp'] != true) {
        return 'This email is not registered yet — ye email hamare data mein '
            'abhi nahi hai, iska account abhi nahi bana. Pehle is email se '
            'signup/login karein.';
      }
      return null;
    } catch (_) {
      return 'Network issue — signup check nahi ho saka. Please try again';
    }
  }

  Future<String?> addTeamMember(UserModel member) async {
    // Duplicate check: ek hi email dobaara subAdmin nahi ban sakta.
    if (_team.any((u) => u.email == member.email)) {
      return 'This email is already in the team';
    }
    // Sirf woh email add ho sakti hai jis ka account pehle se bana ho.
    final notRegistered = await _checkRegistered(member.email);
    if (notRegistered != null) return notRegistered;
    try {
      await _ensureUserDoc(member, 'subAdmin');
      await FirebaseFirestore.instance
          .collection(Collections.team)
          .doc(member.email)
          .set({
        ..._userToJson(member),
        'role': 'subAdmin',
      });
    } catch (_) {
      return 'Network issue — please try again';
    }
    _team.add(member);
    _bump();
    return null;
  }

  Future<void> removeTeamMember(String email) async {
    await FirebaseFirestore.instance
        .collection(Collections.team)
        .doc(email)
        .delete();
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(email.toLowerCase())
        .update({'role': 'user'});
    // Removed subAdmin ki saari assigned requests unassign karo — warna wo
    // requests uske naam par 'assigned' rehti hain aur removed user ko
    // dikhti hain.
    await RequestRepository.instance.unassignAll(email);
    _team.removeWhere((u) => u.email == email);
    _bump();
  }

  Future<String?> addSubTeamMember(String subAdminEmail, UserModel member) async {
    // Duplicate check: ek hi member dobaara team mein add nahi ho sakta.
    final existing = _subTeams[subAdminEmail] ?? const [];
    if (existing.any((u) => u.email == member.email)) {
      return 'This member is already in your team';
    }
    // Sirf woh email add ho sakti hai jis ka account pehle se bana ho.
    final notRegistered = await _checkRegistered(member.email);
    if (notRegistered != null) return notRegistered;
    try {
      await _ensureUserDoc(member, 'user');
      await FirebaseFirestore.instance
          .collection(Collections.subTeams)
          .doc(subAdminEmail)
          .collection('members')
          .doc(member.email)
          .set(_userToJson(member));
    } catch (_) {
      return 'Network issue — please try again';
    }
    (_subTeams[subAdminEmail] ??= []).add(member);
    _bump();
    return null;
  }

  Future<void> removeSubTeamMember(String subAdminEmail, String memberEmail) async {
    await FirebaseFirestore.instance
        .collection(Collections.subTeams)
        .doc(subAdminEmail)
        .collection('members')
        .doc(memberEmail)
        .delete();
    _subTeams[subAdminEmail]?.removeWhere((u) => u.email == memberEmail);
    _bump();
  }

  Future<void> clear() async {
    final db = FirebaseFirestore.instance;
    final teamSnap = await db.collection(Collections.team).get();
    final stSnap = await db.collection(Collections.subTeams).get();
    final batch = db.batch();
    for (final d in teamSnap.docs) batch.delete(d.reference);
    for (final d in stSnap.docs) {
      final members = await d.reference.collection('members').get();
      for (final m in members.docs) batch.delete(m.reference);
      batch.delete(d.reference);
    }
    await batch.commit();
    _team.clear();
    _subTeams.clear();
    _bump();
  }

  void resetLoaded() => _loaded = false;

  Map<String, dynamic> _userToJson(UserModel u) => {
    'name': u.name,
    'email': u.email,
    'phone': u.phone,
    'role': u.role.name,
  };

  /// Defensive parse: koi ek purana/malformed doc (missing name/email/phone)
  /// aaye to throw karne ki bajaye default values — warna ek bad doc poori
  /// team list ko gira deta tha (addAll ke andar exception).
  UserModel _userFromJson(Map<String, dynamic> json) => UserModel(
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role']?.toString(),
      // Security: unknown/missing role hamesha 'user' — subAdmin default
      // rakhtay to koi bhi missing-role doc elevate ho sakta tha.
      orElse: () => UserRole.user,
    ),
  );
}
