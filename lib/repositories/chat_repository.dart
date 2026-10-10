import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/collections.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/chat_access.dart';
import 'team_repository.dart';

class ChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final List<ChatMessage> _messages = [];
  bool _loaded = false;
  final _revisionController = StreamController<int>.broadcast();

  /// Live listener — a message from someone else appears instantly (before,
  /// it only refreshed when the screen was reopened).
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _liveSub;

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  List<ChatMessage> get all => List.unmodifiable(_messages);

  /// A single query — the latest [_pageSize] messages of the collection (sentAt
  /// descending), sorted ascending in memory for display.
  ///
  /// FIX (old messages not showing): before, per-channel queries
  /// (`where('channel', ==)`) ran, but **legacy messages have no `channel`
  /// field at all** (ChatMessage.fromJson derives it from `requestId`/the
  /// default) — so that query never matched and opening the chat
  /// showed no old messages. When a new message arrived, the realtime
  /// listener read the whole collection (without a channel filter)
  /// and then the old messages suddenly appeared.
  /// The read rules are signedIn, so we read the collection directly.
  static const _pageSize = 200;

  Query<Map<String, dynamic>> get _messagesQuery => FirebaseFirestore.instance
      .collection(Collections.messages)
      .orderBy('sentAt', descending: true)
      .limit(_pageSize);

  /// Merges snapshot docs into the existing list (dedupe by doc id).
  /// Merge (not replace) so that older messages that fell outside the
  /// limit-window also stay in the cache.
  ///
  /// If a malformed/old doc fails to parse (missing/wrong `sentAt`), skip
  /// it — otherwise one bad doc empties the whole chat list.
  void _merge(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final byId = {for (final m in _messages) m.id: m};
    for (final d in docs) {
      try {
        byId[d.id] = _fromDoc(d.id, d.data());
      } catch (e) {
        debugPrint('ChatRepository: skipping message ${d.id} — parse failed ($e)');
      }
    }
    _messages
      ..clear()
      ..addAll(byId.values);
  }

  /// Load old messages as soon as the chat opens — then live updates.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    try {
      final snap = await _messagesQuery.get();
      _merge(snap.docs);
    } catch (_) {
      // permission/network — empty state; the next refresh fixes it
    }
    _sortByTime();
    _loaded = true;
    _bump();
    _listenLive();
  }

  ChatMessage _fromDoc(String id, Map<String, dynamic> data) =>
      ChatMessage.fromJson({...data, 'id': data['id'] ?? id});

  void _sortByTime() => _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

  /// Stop the previous listener (no await needed — it is just teardown).
  void _stopLive() {
    final Future<void>? closing = _liveSub?.cancel();
    _liveSub = null;
    if (closing != null) unawaited(closing);
  }

  /// Firestore realtime listener — update + bump the list as soon as a new
  /// message arrives, so every screen (chat + request detail) updates live.
  void _listenLive() {
    _stopLive();
    _liveSub = _messagesQuery.snapshots().listen(
      (snap) {
        // Merge (not replace) — messages outside the limit-window must not vanish.
        _merge(snap.docs);
        _sortByTime();
        _bump();
      },
      onError: (_) {
        // offline/permission — the next load/refresh will fix it
      },
    );
  }

  List<ChatMessage> messagesForChannel(String channel) => _messages
      .where((m) => m.channel == channel)
      .toList()
    ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  // SEC-03 (rate-limit): message throttle — guards against spam/flood.
  // Server-side enforcement needs a Cloud Function (Blaze) — Action-Items #SEC-03.
  static const _minSendInterval = Duration(seconds: 2);
  DateTime? _lastSendAt;

  Future<void> addMessage(ChatMessage message) async {
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < _minSendInterval) {
      throw StateError('Please wait a moment before sending the next message');
    }
    // Readers are built here (the rules gate the channel on them) — a sender
    // can never set participants himself.
    final msg = message.copyWith(
      participants: participantsFor(
        channel: message.channel,
        senderEmail: message.senderEmail,
        userEmail: message.userEmail,
        assignedTo: message.assignedTo,
        ceoEmails: AuthService.ceoEmails,
        subAdminEmails: TeamRepository.instance.team.map((u) => u.email),
        ownerEmail: message.ownerEmail,
        memberEmails: message.memberEmails ?? const [],
      ),
    );
    await FirebaseFirestore.instance
        .collection(Collections.messages)
        .doc(msg.id)
        .set(msg.toJson());
    _lastSendAt = now;
    _messages.add(msg);
    _sortByTime();
    _bump();
  }

  Future<void> clear() async {
    _stopLive();
    final snap = await FirebaseFirestore.instance
        .collection(Collections.messages)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
    _messages.clear();
    _bump();
  }

  /// After an account switch the previous user's chat cache must not show.
  void resetLoaded() {
    _stopLive();
    _messages.clear();
    _loaded = false;
  }

  bool _legacyMigrated = false;

  /// Legacy backfill: old messages (without a `participants` field) get the
  /// readers assigned. The rules only allow a superAdmin to update the
  /// participants field (currentUser is the CEO). The flag is set ONLY on
  /// success — before, it was set at the start, so after one failure
  /// (permission/network) the migration never ran again.
  Future<void> migrateLegacyParticipants() async {
    if (_legacyMigrated) return;
    final db = FirebaseFirestore.instance;
    while (true) {
      final snap = await db
          .collection(Collections.messages)
          .where('participants', isNull: true)
          .limit(500)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final d in snap.docs) {
        final m = ChatMessage.fromJson({...d.data(), 'id': d.id});
        batch.update(d.reference, {
          'participants': participantsFor(
            channel: m.channel,
            senderEmail: m.senderEmail,
            userEmail: m.userEmail,
            assignedTo: m.assignedTo,
            ceoEmails: AuthService.ceoEmails,
            subAdminEmails: TeamRepository.instance.team.map((u) => u.email),
            ownerEmail: m.ownerEmail,
            memberEmails: m.memberEmails ?? const [],
          ),
        });
      }
      await batch.commit();
      if (snap.docs.length < 500) break;
    }
    _legacyMigrated = true;
    _bump();
  }
}
