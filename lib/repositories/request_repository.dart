import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/collections.dart';
import '../models/service_request.dart';
import '../models/user.dart';

class RequestRepository {
  RequestRepository._();

  static final RequestRepository instance = RequestRepository._();

  final List<ServiceRequest> _requests = [];
  bool _loaded = false;
  final _revisionController = StreamController<int>.broadcast();

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  /// Fix #1 (scoped reads): user → sirf apni requests, subAdmin → sirf
  /// assigned, CEO (superAdmin) → sab. Rules bhi yahi enforce karte hain.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(Collections.requests);
    if (!user.isSuperAdmin) {
      query = user.isSubAdmin
          ? query.where('assignedTo', isEqualTo: user.email)
          : query.where('userEmail', isEqualTo: user.email);
    }
    // Pagination (cost control): latest 200 — free tier reads khatam na hon.
    // NOTE: (assignedTo/userEmail + createdAt) composite indexes chahiye —
    // app mein query fail hone par error link se ek click mein ban jate hain.
    query = query.orderBy('createdAt', descending: true).limit(200);
    final snap = await query.get();
    _requests
      ..clear()
      ..addAll(snap.docs.map((d) => ServiceRequest.fromJson({
        ...d.data(),
        // Doc ka ASLI id use karo — legacy docs mein 'id' field doc ID se
        // alag ho sakta hai, aur chat channel/updates doc id par chalti
        // hain. Warna rules `requests/{id}` par doc dhoond kar deny kar
        // deta tha (permission denied on request chat).
        'id': d.id,
      })));
    _loaded = true;
    _bump();
  }

  List<ServiceRequest> forUser(String email) =>
      _requests.where((r) => r.userEmail == email).toList();

  List<ServiceRequest> assignedTo(String email) =>
      _requests.where((r) => r.assignedTo == email).toList();

  int countFor(String email, RequestStatus status) =>
      _requests.where((r) => r.userEmail == email && r.status == status).length;

  int countAll(RequestStatus status) =>
      _requests.where((r) => r.status == status).length;

  // SEC-03 (rate-limit): client throttle — free tier par cost DoS se bachao.
  // Rules emailVerified enforce karti hain; ye app-level limits normal spam
  // rokti hain. Server-side enforcement ke liye Cloud Function chahiye
  // (Blaze) — Action-Items #SEC-03 mein noted.
  static const _minCreateInterval = Duration(seconds: 20);
  static const _maxPending = 10;
  DateTime? _lastCreateAt;

  /// Returns null on success, otherwise user-facing error message.
  Future<String?> add(ServiceRequest request) async {
    // Ek ke baad ek jaldi-jaldi requests band.
    final now = DateTime.now();
    if (_lastCreateAt != null &&
        now.difference(_lastCreateAt!) < _minCreateInterval) {
      return 'Please wait a moment before submitting another request';
    }
    final pending = _requests
        .where((r) =>
            r.userEmail == request.userEmail && r.status == RequestStatus.pending)
        .length;
    if (pending >= _maxPending) {
      return 'You already have $_maxPending pending requests — please wait for them to be processed';
    }
    try {
      await FirebaseFirestore.instance
          .collection(Collections.requests)
          .doc(request.id)
          .set(request.toJson());
    } catch (e) {
      return 'Request submit fail hua — $e';
    }
    _lastCreateAt = now;
    _requests.insert(0, request);
    _bump();
    return null;
  }

  /// CEO ne subAdmin remove kiya — uski saari assigned requests unassign
  /// (assignedTo/assignedByName clear), taake removed user ko wo requests na
  /// dikhen aur requests dobara assign ki ja saken.
  Future<void> unassignAll(String email) async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection(Collections.requests)
        .where('assignedTo', isEqualTo: email)
        .get();
    final batch = db.batch();
    final ids = <String>{};
    for (final d in snap.docs) {
      batch.update(d.reference, {'assignedTo': '', 'assignedByName': ''});
      ids.add(d.id);
    }
    if (snap.docs.isNotEmpty) await batch.commit();
    for (var i = 0; i < _requests.length; i++) {
      if (ids.contains(_requests[i].id)) {
        _requests[i] =
            _requests[i].copyWith(assignedTo: '', assignedByName: '');
      }
    }
    _bump();
  }

  Future<void> updateStatus(String id, RequestStatus status) async {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i] = _requests[i].copyWith(status: status);
      await FirebaseFirestore.instance
          .collection(Collections.requests)
          .doc(id)
          .set(_requests[i].toJson());
      _bump();
    }
  }

  Future<void> assign(String id, String email, String name) async {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i] = _requests[i].copyWith(assignedTo: email, assignedByName: name);
      await FirebaseFirestore.instance
          .collection(Collections.requests)
          .doc(id)
          .set(_requests[i].toJson());
      _bump();
    }
  }

  Future<void> rate(String id, double rating, String review) async {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    // Fix #11: ek request = ek rating — pehle se rated request ko dobara
    // rate karke statistics manipulate nahi kar sakte.
    if (_requests[i].isRated) return;
    _requests[i] = _requests[i].copyWith(
      rating: rating,
      review: review,
      ratedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection(Collections.requests)
        .doc(id)
        .set(_requests[i].toJson());
    _bump();
  }

  Future<void> clear() async {
    final snap = await FirebaseFirestore.instance
        .collection(Collections.requests)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
    _requests.clear();
    _bump();
  }

  void resetLoaded() => _loaded = false;
}
