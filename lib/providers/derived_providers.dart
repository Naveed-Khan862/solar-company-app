import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../repositories/team_repository.dart';
import 'repository_providers.dart';
import 'ui_providers.dart';

// ─────────────────────────────────────────────────────────────────────
// Single source of truth for user-scoped requests.
// Every provider that previously repeated
//   isSuperAdmin → all / isSubAdmin → assignedTo / else → forUser
// now just does:  ref.watch(scopedRequestsProvider(user))
// ─────────────────────────────────────────────────────────────────────
final scopedRequestsProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final repo = ref.read(requestRepositoryProvider);
  if (user.isSuperAdmin) return repo.all;
  if (user.isSubAdmin) return repo.assignedTo(user.email);
  return repo.forUser(user.email);
});

final userRequestsProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  final requests = ref.watch(scopedRequestsProvider(user));
  final categoryFilter = ref.watch(requestCategoryFilterProvider);
  final statusFilter = ref.watch(requestStatusFilterProvider);

  return requests.where((r) {
    if (categoryFilter != null && r.category != categoryFilter) return false;
    if (statusFilter != null && r.status != statusFilter) return false;
    return true;
  }).toList();
});

final adminRequestsProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  final requests = ref.watch(scopedRequestsProvider(user));
  final statusFilter = ref.watch(adminStatusFilterProvider);

  return requests.where((r) {
    if (statusFilter != null && r.status != statusFilter) return false;
    return true;
  }).toList();
});

final allRequestsProvider = Provider<List<ServiceRequest>>((ref) {
  ref.watch(requestRevisionsProvider);
  return ref.read(requestRepositoryProvider).all;
});

final pendingCountProvider = Provider.family<int, UserModel>((ref, user) {
  return ref.watch(scopedRequestsProvider(user))
      .where((r) => r.status == RequestStatus.pending).length;
});

final inProgressCountProvider = Provider.family<int, UserModel>((ref, user) {
  return ref.watch(scopedRequestsProvider(user))
      .where((r) => r.status == RequestStatus.inProgress).length;
});

final resolvedCountProvider = Provider.family<int, UserModel>((ref, user) {
  return ref.watch(scopedRequestsProvider(user))
      .where((r) => r.status == RequestStatus.resolved).length;
});

final avgRatingProvider = Provider.family<double, UserModel>((ref, user) {
  final rated = ref.watch(scopedRequestsProvider(user))
      .where((r) => r.isRated)
      .map((r) => r.rating)
      .toList();
  if (rated.isEmpty) return 0;
  return rated.reduce((a, b) => a + b) / rated.length;
});

final unreadNotificationsProvider = Provider<int>((ref) {
  ref.watch(notificationRevisionsProvider);
  return ref.read(notificationRepositoryProvider).unreadCount;
});

final displayNameProvider = Provider.family<String, UserModel>((ref, user) {
  ref.watch(profileRevisionsProvider);
  return ref.read(profileRepositoryProvider).displayName(user);
});

final displayPhoneProvider = Provider.family<String, UserModel>((ref, user) {
  ref.watch(profileRevisionsProvider);
  return ref.read(profileRepositoryProvider).displayPhone(user.email, user.phone);
});

final photoProvider = Provider.family<String?, UserModel>((ref, user) {
  ref.watch(profileRevisionsProvider);
  return ref.read(profileRepositoryProvider).photoFor(user.email);
});

final fingerprintEnabledProvider = Provider<bool>((ref) {
  ref.watch(profileRevisionsProvider);
  return ref.read(profileRepositoryProvider).settings.fingerprint;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  ref.watch(profileRevisionsProvider);
  return ref.read(profileRepositoryProvider).settings.notifications;
});

final teamMembersProvider = Provider<List<UserModel>>((ref) {
  ref.watch(teamRevisionsProvider);
  return ref.read(teamRepositoryProvider).team;
});

final subTeamProvider = Provider.family<List<UserModel>, String>((ref, email) {
  ref.watch(teamRevisionsProvider);
  return ref.read(teamRepositoryProvider).subTeamOf(email);
});

final messagesProvider = Provider.family<List<ChatMessage>, String>((ref, channel) {
  ref.watch(chatRevisionsProvider);
  return ref.read(chatRepositoryProvider).messagesForChannel(channel);
});

final channelsProvider = Provider.family<List<ChatChannelInfo>, UserModel>((ref, user) {
  ref.watch(teamRevisionsProvider);
  final teamRepo = ref.read(teamRepositoryProvider);
  return _channelsFor(user, teamRepo);
});

/// Build channel list for a user — moved from LocalDb.channelsFor.
List<ChatChannelInfo> _channelsFor(UserModel user, TeamRepository teamRepo) {
  final result = <ChatChannelInfo>[
    const ChatChannelInfo(
      id: 'support',
      title: 'Support Chat',
      subtitle: 'CEO \u00b7 Sub Admins \u00b7 Clients',
    ),
  ];
  if (user.isAdmin) {
    result.add(const ChatChannelInfo(
      id: 'admin',
      title: 'Admin Chat',
      subtitle: 'CEO and Sub Admins only',
    ));
  }
  if (user.role == UserRole.subAdmin) {
    result.add(const ChatChannelInfo(
      id: 'subadmins',
      title: 'Sub Admin Chat',
      subtitle: 'Sub Admins only',
    ));
    final subTeam = teamRepo.subTeamOf(user.email);
    if (subTeam.isNotEmpty) {
      result.add(ChatChannelInfo(
        id: 'team:${user.email}',
        title: 'My Team Chat',
        subtitle: '${subTeam.length} members',
      ));
    }
  }
  for (final entry in teamRepo.subTeams.entries) {
    if (entry.value.any((m) => m.email == user.email)) {
      result.add(ChatChannelInfo(
        id: 'team:${entry.key}',
        title: 'Team Chat',
        subtitle: 'Team of ${entry.key}',
      ));
    }
  }
  return result;
}

/// Chat channel metadata.
class ChatChannelInfo {
  final String id;
  final String title;
  final String subtitle;

  const ChatChannelInfo({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

final weeklyChartDataProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  return ref.watch(scopedRequestsProvider(user));
});


