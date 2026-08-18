import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/notification_item.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../repositories/chat_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/request_repository.dart';
import '../repositories/team_repository.dart';

/// Facade that maintains the exact same API as the old LocalDb
/// but delegates to the new repositories.
class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();

  final RequestRepository _requests = RequestRepository.instance;
  final TeamRepository _team = TeamRepository.instance;
  final ChatRepository _chat = ChatRepository.instance;
  final NotificationRepository _notifications = NotificationRepository.instance;
  final ProfileRepository _profiles = ProfileRepository.instance;

  // Delegated getters (match old API exactly)
  List<ServiceRequest> get requests => _requests.all;
  List<UserModel> get teamMembers => _team.team;
  List<NotificationItem> get notifications => _notifications.all;
  bool get fingerprintEnabled => _profiles.settings.fingerprint;
  bool get notificationsEnabled => _profiles.settings.notifications;
  String get lastEmail => _profiles.settings.lastEmail;
  ValueNotifier<int> get unreadNotifier => _notifications.unreadNotifier;
  int get unreadCount => _notifications.unreadCount;

  // Request methods
  Future<void> add(ServiceRequest request) async {
    await _requests.add(request);
    // ponytail: "New Request" broadcast notify user se hata diya (Fix #13 —
    // rules: broadcast sirf admins). Admin dashboard requests live dikhata
    // hai. Asli push notification Cloud Function (#19) se aayegi.
  }

  Future<void> updateStatus(String id, RequestStatus status) async {
    await _requests.updateStatus(id, status);
    final r = _requests.all.where((r) => r.id == id).firstOrNull;
    if (r != null) {
      await _notifications.notify(
        title: 'Request ${r.status.label}',
        body: 'Your request "${r.description.length > 40 ? '${r.description.substring(0, 40)}...' : r.description}" is now ${r.status.label}',
        type: NotificationType.status,
        requestId: id,
        forEmail: r.userEmail,
      );
      if (r.assignedTo.isNotEmpty && r.assignedTo != r.userEmail) {
        await _notifications.notify(
          title: 'Request ${r.status.label}',
          body: 'Request ${r.category.label} in your assignment is now ${r.status.label}',
          type: NotificationType.status,
          requestId: id,
          forEmail: r.assignedTo,
        );
      }
    }
  }

  Future<void> assignRequest(String id, String email, String name) async {
    await _requests.assign(id, email, name);
    final r = _requests.all.where((r) => r.id == id).firstOrNull;
    if (r != null) {
      if (email.isEmpty) {
        await _notifications.notify(
          title: 'Assignment hata di',
          body: 'Assignment removed from your request',
          type: NotificationType.assignment,
          requestId: id,
          forEmail: r.userEmail,
        );
      } else {
        await _notifications.notify(
          title: 'Request Assigned',
          body: 'Your request is now assigned to $name',
          type: NotificationType.assignment,
          requestId: id,
          forEmail: r.userEmail,
        );
        if (r.userEmail != email) {
          await _notifications.notify(
            title: 'New Assignment',
            body: 'Request ${r.category.label} has been assigned to you',
            type: NotificationType.assignment,
            requestId: id,
            forEmail: email,
          );
        }
      }
    }
  }

  Future<void> rateRequest(String id, double rating, String review) async {
    await _requests.rate(id, rating, review);
    // Fix #13: user-created notification rules allow nahi (spam). SubAdmin
    // apni assigned request ka rating detail mein dekh leta hai.
  }

  // Team methods
  Future<String?> addTeamMember(UserModel member) async {
    final err = await _team.addTeamMember(member);
    if (err == null) {
      await _notifications.notify(
        title: 'New Team Member',
        body: '${member.name} (${member.email}) joined the team',
        type: NotificationType.team,
      );
    }
    return err;
  }

  Future<void> removeTeamMember(String email) async {
    await _team.removeTeamMember(email);
  }

  List<UserModel> subTeamOf(String subAdminEmail) => _team.subTeamOf(subAdminEmail);

  Future<String?> addSubTeamMember(String subAdminEmail, UserModel member) async {
    return _team.addSubTeamMember(subAdminEmail, member);
  }

  Future<void> removeSubTeamMember(String subAdminEmail, String memberEmail) async {
    await _team.removeSubTeamMember(subAdminEmail, memberEmail);
  }

  // Chat methods
  Future<void> addMessage(ChatMessage message) async {
    await _chat.addMessage(message);
  }

  List<ChatMessage> messagesForChannel(String channel) =>
      _chat.messagesForChannel(channel);

  // Profile methods
  String displayName(UserModel user) => _profiles.displayName(user);
  String displayPhone(String email, String fallback) => _profiles.displayPhone(email, fallback);
  String? photoFor(String email) => _profiles.photoFor(email);

  Future<void> saveProfile({
    required String email,
    String? name,
    String? phone,
    String? photo,
  }) async {
    await _profiles.saveProfile(
      email: email,
      name: name,
      phone: phone,
      photo: photo,
    );
  }

  // Settings methods
  Future<void> setFingerprint(bool enabled) async {
    await _profiles.setFingerprint(enabled);
  }

  Future<void> setLastEmail(String email) async {
    await _profiles.setLastEmail(email);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _profiles.setNotificationsEnabled(enabled);
  }

  Future<void> markAllRead() async {
    await _notifications.markAllRead(lastEmail: lastEmail);
  }

  Future<void> markRead(String id) async {
    await _notifications.markRead(id);
  }

  // Channel access (unchanged)
  List<ChatChannelInfo> channelsFor(UserModel user) {
    final result = <ChatChannelInfo>[
      const ChatChannelInfo(
        id: 'support',
        title: 'Support Chat',
        subtitle: 'CEO · Sub Admins · Clients',
      ),
    ];
    if (user.isAdmin) {
      result.add(const ChatChannelInfo(
        id: 'admin',
        title: 'Admin Chat',
        subtitle: 'Sirf CEO aur Sub Admins',
      ));
    }
    if (user.role == UserRole.subAdmin) {
      result.add(const ChatChannelInfo(
        id: 'subadmins',
        title: 'Sub Admin Chat',
        subtitle: 'Sirf Sub Admins aapas me',
      ));
      final subTeam = _team.subTeamOf(user.email);
      if (subTeam.isNotEmpty) {
        result.add(ChatChannelInfo(
          id: 'team:${user.email}',
          title: 'My Team Chat',
          subtitle: '${subTeam.length} members',
        ));
      }
    }
    for (final entry in _team.subTeams.entries) {
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

  bool canAccessChannel(UserModel user, String channel) {
    return channelsFor(user).any((c) => c.id == channel);
  }

  // Query helpers
  List<ServiceRequest> forUser(String email) => _requests.forUser(email);
  List<ServiceRequest> assignedTo(String email) => _requests.assignedTo(email);
  List<ServiceRequest> all() => _requests.all;
  int countFor(String email, RequestStatus status) => _requests.countFor(email, status);
  int countAll(RequestStatus status) => _requests.countAll(status);
}

/// Re-export for backward compat
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