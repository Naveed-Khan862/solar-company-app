import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'admin_dashboard.dart';
import 'admin_requests_screen.dart';
import 'chats_screen.dart';
import 'login_screen.dart';
import 'my_requests_screen.dart';
import 'notifications_screen.dart';
import 'profile_view.dart';
import 'team_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final String? notice;

  const HomeScreen({super.key, required this.user, this.notice});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set the current user in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentUserProvider.notifier).state = widget.user;
      // Data loads after login (Firestore requires authentication).
      ref.invalidate(initializeRepositoriesProvider);
      unawaited(
        ref.read(initializeRepositoriesProvider.future).catchError((_) {}),
      );
      if (widget.notice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.notice!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF00838F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    // Load is handled by initializeRepositoriesProvider
    setState(() => _loading = false);
  }

  void _logout() {
    ref.read(currentUserProvider.notifier).state = null;
    // NOTE: SecureCredentials intentionally NOT cleared here — fingerprint
    // login ka poora maqsad hai ke logout ke baad bhi fingerprint se login
    // ho sake. Credentials sirf Settings mein fingerprint OFF karne par
    // clear hote hain (settings_screen.dart).
    AuthService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _Header(user: user, onLogout: _logout),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00A86B)),
                    )
                  : IndexedStack(
                      index: _selectedIndex,
                      children: _tabs(user),
                    ),
            ),
            _GlassNav(
              user: user,
              selected: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabs(UserModel user) {
    if (user.role == UserRole.superAdmin) {
      return [
        AdminDashboard(user: user),
        AdminRequestsScreen(user: user),
        ChatsScreen(user: user),
        TeamView(user: user),
        ProfileView(user: user),
      ];
    }
    if (user.role == UserRole.subAdmin) {
      return [
        AdminRequestsScreen(user: user),
        ChatsScreen(user: user),
        TeamView(user: user),
        ProfileView(user: user),
      ];
    }
    return [
      MyRequestsScreen(user: user),
      ChatsScreen(user: user),
      ProfileView(user: user),
    ];
  }
}

class _Header extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _Header({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = user.isAdmin;
    final displayName = ref.watch(displayNameProvider(user));
    final unread = ref.watch(unreadNotificationsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF00A86B), Color(0xFF00C853)],
              ),
            ),
            child: const Icon(Icons.solar_power_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isAdmin ? 'Admin' : 'Client',
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.notifications_none_rounded,
            badge: unread,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(user: user),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _IconButton(
            icon: Icons.logout_rounded,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppPalette.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppPalette.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(icon, color: AppPalette.textSecondary, size: 21),
            ),
            if (badge > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final UserModel user;
  final int selected;
  final ValueChanged<int> onSelect;

  const _GlassNav({
    required this.user,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = _items();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                icon: items[i].icon,
                label: items[i].label,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }

  List<({IconData icon, String label})> _items() {
    if (user.role == UserRole.superAdmin) {
      return [
        (icon: Icons.space_dashboard_rounded, label: 'Home'),
        (icon: Icons.assignment_rounded, label: 'Requests'),
        (icon: Icons.chat_bubble_rounded, label: 'Chats'),
        (icon: Icons.group_rounded, label: 'Team'),
        (icon: Icons.person_rounded, label: 'Profile'),
      ];
    }
    if (user.role == UserRole.subAdmin) {
      return [
        (icon: Icons.assignment_rounded, label: 'Requests'),
        (icon: Icons.chat_bubble_rounded, label: 'Chats'),
        (icon: Icons.group_rounded, label: 'Team'),
        (icon: Icons.person_rounded, label: 'Profile'),
      ];
    }
    return [
      (icon: Icons.receipt_long_rounded, label: 'Requests'),
      (icon: Icons.chat_bubble_rounded, label: 'Chats'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00A86B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: selected ? Colors.white : AppPalette.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
