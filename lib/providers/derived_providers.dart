import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../services/local_db.dart';
import 'repository_providers.dart';
import 'ui_providers.dart';

final userRequestsProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final requests = ref.read(requestRepositoryProvider).forUser(user.email);
  final categoryFilter = ref.watch(requestCategoryFilterProvider);
  final statusFilter = ref.watch(requestStatusFilterProvider);

  return requests.where((r) {
    if (categoryFilter != null && r.category != categoryFilter) return false;
    if (statusFilter != null && r.status != statusFilter) return false;
    return true;
  }).toList();
});

final adminRequestsProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final requests = user.role == UserRole.subAdmin
      ? ref.read(requestRepositoryProvider).assignedTo(user.email)
      : ref.read(requestRepositoryProvider).all;
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
  ref.watch(requestRevisionsProvider);
  final scope = user.isSuperAdmin
      ? ref.read(requestRepositoryProvider).all
      : user.isSubAdmin
          ? ref.read(requestRepositoryProvider).assignedTo(user.email)
          : ref.read(requestRepositoryProvider).forUser(user.email);
  return scope.where((r) => r.status == RequestStatus.pending).length;
});

final inProgressCountProvider = Provider.family<int, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final scope = user.isSuperAdmin
      ? ref.read(requestRepositoryProvider).all
      : user.isSubAdmin
          ? ref.read(requestRepositoryProvider).assignedTo(user.email)
          : ref.read(requestRepositoryProvider).forUser(user.email);
  return scope.where((r) => r.status == RequestStatus.inProgress).length;
});

final resolvedCountProvider = Provider.family<int, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final scope = user.isSuperAdmin
      ? ref.read(requestRepositoryProvider).all
      : user.isSubAdmin
          ? ref.read(requestRepositoryProvider).assignedTo(user.email)
          : ref.read(requestRepositoryProvider).forUser(user.email);
  return scope.where((r) => r.status == RequestStatus.resolved).length;
});

final avgRatingProvider = Provider.family<double, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final scope = user.isSuperAdmin
      ? ref.read(requestRepositoryProvider).all
      : user.isSubAdmin
          ? ref.read(requestRepositoryProvider).assignedTo(user.email)
          : ref.read(requestRepositoryProvider).forUser(user.email);
  final rated = scope.where((r) => r.isRated).map((r) => r.rating).toList();
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
  return ref.read(localDbProvider).channelsFor(user);
});

final weeklyChartDataProvider = Provider.family<List<ServiceRequest>, UserModel>((ref, user) {
  ref.watch(requestRevisionsProvider);
  final scope = user.isSuperAdmin
      ? ref.read(requestRepositoryProvider).all
      : user.isSubAdmin
          ? ref.read(requestRepositoryProvider).assignedTo(user.email)
          : ref.read(requestRepositoryProvider).forUser(user.email);
  return scope;
});


