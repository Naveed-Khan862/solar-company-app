import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_tilt_card.dart';
import '../widgets/stat_row.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AdminDashboard extends ConsumerWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(allRequestsProvider).length;
    final pending = ref.watch(pendingCountProvider(user));
    final inProgress = ref.watch(inProgressCountProvider(user));
    final resolved = ref.watch(resolvedCountProvider(user));
    final displayName = ref.watch(displayNameProvider(user));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        GlassTiltCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
                ),
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 26),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.roleLabel,
                      style: const TextStyle(
                          color: Color(0xFF00A86B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatRow(
          stats: [
            StatData('Total', '$total', Icons.assignment_rounded,
                const Color(0xFF00A86B)),
            StatData('Pending', '$pending', Icons.pending_actions_rounded,
                const Color(0xFFFFB300)),
          ],
        ),
        const SizedBox(height: 14),
        StatRow(
          stats: [
            StatData('In Progress', '$inProgress',
                Icons.hourglass_top_rounded, const Color(0xFF2196F3)),
            StatData('Resolved', '$resolved',
                Icons.check_circle_rounded, Color(0xFF2E7D32)),
          ],
        ),
        SizedBox(height: 20),
        GlassTiltCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              _actionTile(
                icon: Icons.bar_chart_rounded,
                color: Color(0xFF00A86B),
                label: 'Reports & Charts',
                subtitle: 'Weekly chart, status, categories, CSV export',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportsScreen(subAdminScope: false),
                  ),
                ),
              ),
              Divider(height: 20, color: AppPalette.track),
              _actionTile(
                icon: Icons.settings_rounded,
                color: const Color(0xFF1976D2),
                label: 'Settings',
                subtitle: 'Notifications, fingerprint, reset demo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: AppPalette.textFaint, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0BDB5), size: 20),
          ],
        ),
      ),
    );
  }
}
