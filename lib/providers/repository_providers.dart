import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/chat_repository.dart';
import '../repositories/local_storage.dart';
import '../repositories/notification_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/request_repository.dart';
import '../repositories/team_repository.dart';
import '../services/local_db.dart';
import 'ui_providers.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage.instance);

final requestRepositoryProvider = Provider<RequestRepository>((ref) => RequestRepository.instance);

final teamRepositoryProvider = Provider<TeamRepository>((ref) => TeamRepository.instance);

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository.instance);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository.instance);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository.instance);

final localDbProvider = Provider<LocalDb>((ref) => LocalDb.instance);

// Rebuild triggers — emitted whenever a repository mutates.
final requestRevisionsProvider = StreamProvider<int>((ref) => ref.watch(requestRepositoryProvider).revision);

final teamRevisionsProvider = StreamProvider<int>((ref) => ref.watch(teamRepositoryProvider).revision);

final chatRevisionsProvider = StreamProvider<int>((ref) => ref.watch(chatRepositoryProvider).revision);

final notificationRevisionsProvider = StreamProvider<int>((ref) => ref.watch(notificationRepositoryProvider).revision);

final profileRevisionsProvider = StreamProvider<int>((ref) => ref.watch(profileRepositoryProvider).revision);

// Keeps the app usable when a load fails (offline, permission gaps).
Future<void> _safeLoad(Future<void> Function() load) async {
  try {
    await load();
  } catch (_) {
    // Empty state will show; retry happens on next refresh.
  }
}

final initializeRepositoriesProvider = FutureProvider<void>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  // Scoped reads (Fix #1): naye user ke saath dobara load zaroori hai,
  // warna purane user ka cached data dikhega. Isliye pehle reset karo.
  ref.read(requestRepositoryProvider).resetLoaded();
  ref.read(teamRepositoryProvider).resetLoaded();
  ref.read(chatRepositoryProvider).resetLoaded();
  ref.read(profileRepositoryProvider).resetLoaded();
  ref.read(notificationRepositoryProvider).resetLoaded();
  await Future.wait([
    _safeLoad(() => ref.read(requestRepositoryProvider).load(user: user)),
    _safeLoad(() => ref.read(teamRepositoryProvider).load(user: user)),
    _safeLoad(() => ref.read(profileRepositoryProvider).load(user: user)),
    _safeLoad(
      () => ref.read(notificationRepositoryProvider).load(
            lastEmail: user.email,
          ),
    ),
  ]);
  // Chat ki channels requests + team se derive hoti hain — isliye baad mein.
  await _safeLoad(() => ref.read(chatRepositoryProvider).load(user: user));
  ref.read(notificationRepositoryProvider).unreadNotifier.value =
      ref.read(notificationRepositoryProvider).unreadCount;
});