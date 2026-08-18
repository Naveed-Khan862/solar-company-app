import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/collections.dart';
import '../models/profile.dart';
import '../models/user.dart';
import 'local_storage.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  final Map<String, ProfileInfo> _profiles = {};
  SettingsData _settings = SettingsData();
  bool _loaded = false;
  final _revisionController = StreamController<int>.broadcast();

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  Map<String, ProfileInfo> get profiles => Map.unmodifiable(_profiles);
  SettingsData get settings => _settings;

  String? photoFor(String email) => _profiles[email]?.photo;
  String displayName(UserModel user) {
    final p = _profiles[user.email];
    return (p?.name != null && p!.name!.isNotEmpty) ? p.name! : user.name;
  }
  String displayPhone(String email, String fallback) {
    final p = _profiles[email];
    return (p?.phone != null && p!.phone!.isNotEmpty) ? p.phone! : fallback;
  }

  /// Fix #1 (scoped reads): admin → sab profiles, normal user → sirf apni
  /// profile (doc ID = email). Rules bhi yahi enforce karte hain.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    // Settings pehle load karo (LocalStorage) — Firestore se pehle, taake
    // login screen par (auth se pehle) fingerprint/lastEmail available ho.
    // Yeh bhi zaroori: settings load hotay hi _bump() karo taake cold start
    // par providers update hon aur fingerprint button nazar aaye — warna
    // (agar Firestore auth se pehle fail ho jaye) button kabhi nahi aata.
    _settings = await LocalStorage.instance.getSettings();
    _bump();
    final db = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> query = db.collection(Collections.profiles);
    if (!user.isAdmin) {
      query = query.where(FieldPath.documentId, isEqualTo: user.email);
    }
    final profSnap = await query.get();
    _profiles
      ..clear()
      ..addAll({
        for (final d in profSnap.docs) d.id: _profileFromJson(d.data()),
      });
    _loaded = true;
    _bump();
  }

  Future<void> saveProfile({
    required String email,
    String? name,
    String? phone,
    String? photo,
  }) async {
    final old = _profiles[email];
    final newProfile = ProfileInfo(
      name: name ?? old?.name,
      phone: phone ?? old?.phone,
      photo: photo ?? old?.photo,
    );
    await FirebaseFirestore.instance
        .collection(Collections.profiles)
        .doc(email)
        .set({
      'name': newProfile.name,
      'phone': newProfile.phone,
      'photo': newProfile.photo,
    });
    _profiles[email] = newProfile;
    _bump();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    // Old password verify karna zaroori hai — directly update karne se
    // Firebase invalid-credential dega, aur user ko pata hi nahi chalta.
    final credential =
        EmailAuthProvider.credential(email: email, password: oldPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Har setter disk ki current settings par ek hi field badalta hai — koi
  // setter doosri setting wipe nahi kar sakta, aur off-on dono sahi save
  // hote hain.
  Future<void> setFingerprint(bool enabled) async {
    _settings =
        (await LocalStorage.instance.getSettings()).copyWith(fingerprint: enabled);
    await LocalStorage.instance.saveSettings(_settings);
    _bump();
  }

  Future<void> setLastEmail(String email) async {
    _settings =
        (await LocalStorage.instance.getSettings()).copyWith(lastEmail: email);
    await LocalStorage.instance.saveSettings(_settings);
    _bump();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings =
        (await LocalStorage.instance.getSettings()).copyWith(notifications: enabled);
    await LocalStorage.instance.saveSettings(_settings);
    _bump();
  }

  Future<void> clear() async {
    final snap = await FirebaseFirestore.instance
        .collection(Collections.profiles)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
    _profiles.clear();
    _bump();
  }

  void resetLoaded() => _loaded = false;

  ProfileInfo _profileFromJson(Map<String, dynamic> json) => ProfileInfo(
        name: json['name'],
        phone: json['phone'],
        photo: json['photo'],
      );
}
