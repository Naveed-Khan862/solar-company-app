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

  /// #13 (privacy): only the team lists the user can access are loaded —
  /// superAdmin → everything; subAdmin → their own team; a member (normal
  /// user) → only the sub_teams they belong to (collectionGroup).
  /// The rest of the app (chat channels, team_view) works off these scoped
  /// lists, so the UI looks the same.
  ///
  /// Each part sits in its own try/catch: if one query fails (permission,
  /// malformed doc, network) the whole team load must not stop. Until `_bump()`
  /// runs, the UI keeps showing the previous (empty) list — so we always
  /// bump in finally so that whatever did load shows up.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    final db = FirebaseFirestore.instance;
    _team.clear();
    _subTeams.clear();

    // The team (subAdmins) list loads for ALL roles — the chat
    // participant staff list is built from it (before, it stayed empty
    // for a subAdmin → sending to the admin/subadmins chat was denied).
    try {
      final teamSnap = await db.collection(Collections.team).get();
      _team.addAll(teamSnap.docs.map((d) => _userFromJson(d.data())));
    } catch (_) {
      // permission/network — the team list stays empty, let the other steps run
    }

    try {
      if (user.isSuperAdmin) {
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
            // if one sub-team's members fail, the rest should still load
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
      // if the team list itself fails nothing loads — memberships are tried
      // below, and the finally always bumps.
    }

    // A normal user / subAdmin belongs to some department — load their
    // memberships from the collectionGroup (rules: own member doc only).
    // A failure here does not break the team list — hence a separate try/catch.
    try {
      final myMemberships = await db
          .collectionGroup('members')
          .where('email', isEqualTo: user.email)
          .get();
      for (final d in myMemberships.docs) {
        final owner = d.reference.parent.parent!.id;
        final list = _subTeams[owner] ??= [];
        // dedupe: a subAdmin who is also a member of their team must not repeat
        if (list.every((m) => m.email != user.email)) {
          list.add(_userFromJson(d.data()));
        }
      }
    } catch (_) {
      // memberships n/a or permission — the team list has already loaded
    } finally {
      _loaded = true;
      _bump();
    }
  }

  // users doc guarantee — rules getRole() reads the role from here.
  // It is created directly for Google-login accounts too, with no
  // "registered" check needed (the admin decides that).
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

  /// Whether the email has signed up — via the `signedUp: true` flag on the
  /// users doc (only `_resolveUser` sets it, on login/signup). A doc without
  /// the flag (provisioned/pending) or a missing doc = no account yet.
  Future<String?> _checkRegistered(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(email.toLowerCase())
          .get();
      if (!doc.exists || doc.data()?['signedUp'] != true) {
        return 'This email is not registered yet — no account exists for it. '
            'Ask this person to sign up or log in with this email first.';
      }
      return null;
    } catch (_) {
      return 'Network issue — could not verify the sign-up status. Please try again';
    }
  }

  Future<String?> addTeamMember(UserModel member) async {
    // Duplicate check: the same email cannot become a subAdmin twice.
    if (_team.any((u) => u.email == member.email)) {
      return 'This email is already in the team';
    }
    // Only an email that already has an account can be added.
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
    // Unassign all requests assigned to the removed subAdmin — otherwise they
    // stay 'assigned' under their name and keep showing up for the removed
    // user.
    await RequestRepository.instance.unassignAll(email);
    _team.removeWhere((u) => u.email == email);
    _bump();
  }

  Future<String?> addSubTeamMember(String subAdminEmail, UserModel member) async {
    // Duplicate check: the same member cannot be added to the team twice.
    final existing = _subTeams[subAdminEmail] ?? const [];
    if (existing.any((u) => u.email == member.email)) {
      return 'This member is already in your team';
    }
    // Only an email that already has an account can be added.
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

  /// Defensive parse: any old/malformed doc (missing name/email/phone)
  /// use default values instead of throwing — otherwise one bad doc took
  /// down the whole team list (exception inside addAll).
  UserModel _userFromJson(Map<String, dynamic> json) => UserModel(
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role']?.toString(),
      // Security: an unknown/missing role is always 'user' — never defaulting
      // to subAdmin, otherwise any doc missing a role could have been elevated.
      orElse: () => UserRole.user,
    ),
  );
}
