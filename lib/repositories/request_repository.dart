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

  /// Fix #1 (scoped reads): user → only their own requests, subAdmin → only
  /// assigned ones, CEO (superAdmin) → all. The rules enforce the same.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(Collections.requests);
    if (!user.isSuperAdmin) {
      query = user.isSubAdmin
          ? query.where('assignedTo', isEqualTo: user.email)
          : query.where('userEmail', isEqualTo: user.email);
    }
    // Pagination (cost control): latest 200 — so free-tier reads are not exhausted.
    // NOTE: (assignedTo/userEmail + createdAt) composite indexes are needed —
    // in the app link to the error, so the index is one click to create.
    query = query.orderBy('createdAt', descending: true).limit(200);
    final snap = await query.get();
    _requests
      ..clear()
      ..addAll(snap.docs.map((d) => ServiceRequest.fromJson({
        ...d.data(),
        // Use the doc's REAL id — in legacy docs the 'id' field can differ
        // from the doc ID, and the chat channel/updates depend on the doc
        // id. Otherwise the rules looked up doc `requests/{id}` and denied
        // it (permission denied on request chat).
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

  // SEC-03 (rate-limit): client throttle — guards free-tier cost against DoS.
  // The rules enforce emailVerified; these app-level limits stop ordinary
  // spam. Server-side enforcement needs a Cloud Function
  // (Blaze) — noted in Action-Items #SEC-03.
  static const _minCreateInterval = Duration(seconds: 20);
  static const _maxPending = 10;
  DateTime? _lastCreateAt;

  /// Returns null on success, otherwise user-facing error message.
  Future<String?> add(ServiceRequest request) async {
    // Stops sending requests one right after another.
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
      return 'Could not submit the request — $e';
    }
    _lastCreateAt = now;
    _requests.insert(0, request);
    _bump();
    return null;
  }

  /// The CEO removed a subAdmin — unassign all their assigned requests
  /// (clear assignedTo/assignedByName) so the removed user no longer sees
  /// those requests and they can be assigned again.
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
      // Field-scoped update — a full .set() used to overwrite concurrent writes
      // from another device (assign/rating) — a last-write-wins race.
      await FirebaseFirestore.instance
          .collection(Collections.requests)
          .doc(id)
          .update({'status': status.name});
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
          .update({'assignedTo': email, 'assignedByName': name});
      _bump();
    }
  }

  Future<void> rate(String id, double rating, String review) async {
    final i = _requests.indexWhere((r) => r.id == id);
    if (i == -1) return;
    // Fix #11: one request = one rating — an already rated request cannot
    // be rated again to manipulate the statistics.
    if (_requests[i].isRated) return;
    _requests[i] = _requests[i].copyWith(
      rating: rating,
      review: review,
      ratedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection(Collections.requests)
        .doc(id)
        .update({
      'rating': rating,
      'review': review,
      'ratedAt': _requests[i].ratedAt!.toIso8601String(),
    });
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
