import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/collections.dart';
import '../models/notification_item.dart';
import '../utils/ids.dart';
import 'local_storage.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  final List<NotificationItem> _notifications = [];
  final ValueNotifier<int> unreadNotifier = ValueNotifier<int>(0);
  final _revisionController = StreamController<int>.broadcast();
  bool _loaded = false;
  bool _notificationsEnabled = true;

  Stream<int> get revision => _revisionController.stream;

  void _bump() => _revisionController.add(1);

  List<NotificationItem> get all => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> load({required String lastEmail}) async {
    if (_loaded) return;
    final settings = await LocalStorage.instance.getSettings();
    _notificationsEnabled = settings.notifications;

    if (lastEmail.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection(Collections.notifications)
          .where('forEmail', whereIn: ['', lastEmail])
          .orderBy('time', descending: true)
          .limit(100)
          .get();
      _notifications
        ..clear()
        ..addAll(snap.docs.map((d) => NotificationItem.fromJson(d.data())));
    }
    unreadNotifier.value = unreadCount;
    _loaded = true;
    _bump();
  }

  Future<void> notify({
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    String requestId = '',
    String forEmail = '',
  }) async {
    if (!_notificationsEnabled) return;
    final item = NotificationItem(
      id: generateId(),
      type: type,
      title: title,
      body: body,
      time: DateTime.now(),
      requestId: requestId,
    );
    await FirebaseFirestore.instance
        .collection(Collections.notifications)
        .doc(item.id)
        .set({...item.toJson(), 'forEmail': forEmail});
    _notifications.insert(0, item);
    if (_notifications.length > 100) _notifications.removeLast();
    _bump();
    unreadNotifier.value = unreadCount;
  }

  Future<void> markAllRead({required String lastEmail}) async {
    if (lastEmail.isNotEmpty) {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection(Collections.notifications)
          .where('forEmail', whereIn: ['', lastEmail])
          .get();
      final batch = db.batch();
      for (final d in snap.docs) {
        if (!(d.data()['read'] ?? false)) batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    }
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    _bump();
    unreadNotifier.value = 0;
  }

  Future<void> markRead(String id) async {
    await FirebaseFirestore.instance
        .collection(Collections.notifications)
        .doc(id)
        .update({'read': true});
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1 && !_notifications[i].read) {
      _notifications[i] = _notifications[i].copyWith(read: true);
      _bump();
      unreadNotifier.value = unreadCount;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final settings = await LocalStorage.instance.getSettings();
    await LocalStorage.instance.saveSettings(SettingsData(
      fingerprint: settings.fingerprint,
      lastEmail: settings.lastEmail,
      notifications: enabled,
    ));
  }

  Future<void> clear() async {
    final snap = await FirebaseFirestore.instance
        .collection(Collections.notifications)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.delete(d.reference);
    await batch.commit();
    _notifications.clear();
    _bump();
    unreadNotifier.value = 0;
  }

  void resetLoaded() => _loaded = false;
}
