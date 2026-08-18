import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../models/user.dart';
import '../providers.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_tilt_card.dart';
import 'request_detail_screen.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const NotificationsScreen({super.key, required this.user});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.request:
        return Icons.add_alert_rounded;
      case NotificationType.assignment:
        return Icons.person_pin_rounded;
      case NotificationType.status:
        return Icons.update_rounded;
      case NotificationType.team:
        return Icons.group_add_rounded;
      case NotificationType.rating:
        return Icons.star_rounded;
      case NotificationType.system:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.request:
        return const Color(0xFF00838F);
      case NotificationType.assignment:
        return const Color(0xFF1976D2);
      case NotificationType.status:
        return const Color(0xFFF57C00);
      case NotificationType.team:
        return const Color(0xFF7B1FA2);
      case NotificationType.rating:
        return const Color(0xFFFFB300);
      case NotificationType.system:
        return const Color(0xFF00A86B);
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  Future<void> _open(NotificationItem n) async {
    await ref.read(notificationRepositoryProvider).markRead(n.id);
    if (!mounted) return;
    if (n.requestId.isNotEmpty) {
      final reqs = ref.read(requestRepositoryProvider).all;
      final match = reqs.where((r) => r.id == n.requestId).toList();
      if (match.isNotEmpty) {
        unawaited(Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(request: match.first, user: widget.user),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationRepositoryProvider).all;
    final unreadCount = ref.watch(unreadNotificationsProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppPalette.textPrimary, size: 20),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(notificationRepositoryProvider).markAllRead(lastEmail: widget.user.email);
                        },
                        icon: const Icon(Icons.done_all_rounded,
                            size: 17, color: Color(0xFF00A86B)),
                        label: const Text(
                          'Sab padh li',
                          style: TextStyle(
                              color: Color(0xFF00A86B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppPalette.surfaceSoft,
                              ),
                              child: Icon(Icons.notifications_off_rounded,
                                  color: AppPalette.textFaint, size: 36),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                  color: AppPalette.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final n = items[i];
                          final color = _colorFor(n.type);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => _open(n),
                              child: GlassTiltCard(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        color: color.withValues(alpha: 0.13),
                                      ),
                                      child: Icon(_iconFor(n.type),
                                          color: color, size: 19),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n.title,
                                                  style: TextStyle(
                                                    color: const Color(
                                                        0xFF1B2E24),
                                                    fontSize: 14,
                                                    fontWeight: n.read
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              if (!n.read)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: color,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            n.body,
                                            style: TextStyle(
                                              color: AppPalette.textSecondary,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            _timeAgo(n.time),
                                            style: TextStyle(
                                                color: AppPalette.textFaint,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}