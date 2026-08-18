import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/collections.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import 'request_repository.dart';
import 'team_repository.dart';

class ChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final List<ChatMessage> _messages = [];
  bool _loaded = false;
  final _revisionController = StreamController<int>.broadcast();

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  List<ChatMessage> get all => List.unmodifiable(_messages);

  /// Fix #1 (scoped reads): chat sirf un channels ki load hoti hai jo user
  /// access kar sakta hai (support, admin, subadmins, team, request).
  /// NOTE: load() se pehle requests + team load hona zaroori hai (channels
  /// unhi se derive hoti hain) — initializeRepositoriesProvider is sequence
  /// maintain karta hai.
  Future<void> load({required UserModel user}) async {
    if (_loaded) return;
    final db = FirebaseFirestore.instance;
    final snaps = <QuerySnapshot<Map<String, dynamic>>>[];
    // Pagination (cost control): chat per channel latest 100, CEO total 500.
    if (user.isSuperAdmin) {
      try {
        snaps.add(await db.collection(Collections.messages).limit(500).get());
      } catch (_) {
        // Ek bhi message ka rules evaluation error poori query gira deta hai
        // — fallback: saare accessible channels (support, admin, request:*)
        // alag alag load karo taake chats kabhi dead na dikhen aur request
        // chats bhi rahen.
        for (final c in _accessibleChannels(user)) {
          try {
            snaps.add(await db
                .collection(Collections.messages)
                .where('channel', isEqualTo: c)
                .limit(100)
                .get());
          } catch (_) {
            // us channel ko skip (empty rahega)
          }
        }
      }
    } else {
      for (final c in _accessibleChannels(user)) {
        try {
          snaps.add(await db
              .collection(Collections.messages)
              .where('channel', isEqualTo: c)
              .limit(100)
              .get());
        } catch (_) {
          // permission/network — us channel ko skip (empty rahega)
        }
      }
    }
    _messages
      ..clear()
      ..addAll(snaps.expand((s) => s.docs.map((d) => ChatMessage.fromJson(d.data()))));
    _loaded = true;
    _bump();
  }

  /// User jis channels ka data padh sakta hai — LocalDb.channelsFor ke
  /// mutabiq + request: channels.
  List<String> _accessibleChannels(UserModel user) {
    final channels = <String>{'support'};
    if (user.isAdmin) channels.add('admin');
    if (user.role == UserRole.subAdmin) {
      channels.add('subadmins');
      if (TeamRepository.instance.subTeamOf(user.email).isNotEmpty) {
        channels.add('team:${user.email}');
      }
    }
    for (final entry in TeamRepository.instance.subTeams.entries) {
      if (entry.value.any((m) => m.email == user.email)) {
        channels.add('team:${entry.key}');
      }
    }
    for (final r in RequestRepository.instance.all) {
      if (user.isSuperAdmin ||
          r.userEmail == user.email ||
          r.assignedTo == user.email) {
        channels.add('request:${r.id}');
      }
    }
    return channels.toList();
  }

  List<ChatMessage> messagesForChannel(String channel) =>
      _messages.where((m) => m.channel == channel).toList();

  // SEC-03 (rate-limit): message throttle — spam/flood se bachao. Server-side
  // enforcement Cloud Function (Blaze) se — Action-Items #SEC-03 mein noted.
  static const _minSendInterval = Duration(seconds: 2);
  DateTime? _lastSendAt;

  Future<void> addMessage(ChatMessage message) async {
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < _minSendInterval) {
      throw StateError('Please wait a moment before sending the next message');
    }
    await FirebaseFirestore.instance
        .collection(Collections.messages)
        .doc(message.id)
        .set(message.toJson());
    _lastSendAt = now;
    _messages.add(message);
    _bump();
  }

  Future<void> clear() async {
    final snap = await FirebaseFirestore.instance
        .collection(Collections.messages)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
    _messages.clear();
    _bump();
  }

  void resetLoaded() => _loaded = false;
}
