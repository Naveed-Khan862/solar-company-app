import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';
import '../providers.dart';
import 'my_requests_screen.dart';
import 'reports_screen.dart';
import 'request_detail_screen.dart';
import '../theme/app_theme.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const AdminRequestsScreen({super.key, required this.user});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  Future<void> _setStatus(ServiceRequest r, RequestStatus s) async {
    await ref.read(requestRepositoryProvider).updateStatus(r.id, s);
    ref.invalidate(adminRequestsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(inProgressCountProvider);
    ref.invalidate(resolvedCountProvider);
  }

  Future<void> _openDetail(ServiceRequest request) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          request: request,
          user: widget.user,
        ),
      ),
    );
    ref.invalidate(adminRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminRequestsProvider(widget.user));
    final statusFilter = ref.watch(adminStatusFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _filters(statusFilter),
          Expanded(child: _list(requests)),
        ],
      ),
    );
  }

  Widget _filters(RequestStatus? statusFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('All', statusFilter == null, () {
            ref.read(adminStatusFilterProvider.notifier).state = null;
          }),
          for (final s in RequestStatus.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _chip(s.label, statusFilter == s, () {
                ref.read(adminStatusFilterProvider.notifier).state =
                    statusFilter == s ? null : s;
              }, color: s.color),
            ),
          if (widget.user.role == UserRole.subAdmin) ...[
            const SizedBox(width: 8),
            _chip('Reports', false, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportsScreen(
                    subAdminScope: true,
                    email: widget.user.email,
                  ),
                ),
              );
            }, icon: Icons.bar_chart_rounded),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Color color = const Color(0xFF00A86B), IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: selected ? null : AppPalette.surface.withValues(alpha: 0.8),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : AppPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppPalette.textSecondary),
              SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppPalette.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<ServiceRequest> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          widget.user.role == UserRole.subAdmin
              ? 'No requests assigned yet'
              : 'No requests yet',
          style: TextStyle(color: AppPalette.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      itemCount: items.length,
      itemBuilder: (context, i) => _AdminCard(
        request: items[i],
        onStatus: (s) => _setStatus(items[i], s),
        onTap: () => _openDetail(items[i]),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final ServiceRequest request;
  final ValueChanged<RequestStatus> onStatus;
  final VoidCallback onTap;

  const _AdminCard({
    required this.request,
    required this.onStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RequestCard(request: request, showUser: true, onTap: onTap),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            transform: Matrix4.translationValues(0, -14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: AppPalette.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9EB5A8).withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (request.status == RequestStatus.pending)
                  _action('Start', RequestStatus.inProgress,
                      const Color(0xFF00838F), Icons.play_arrow_rounded),
                if (request.status != RequestStatus.resolved)
                  _action('Resolve', RequestStatus.resolved,
                      const Color(0xFF2E7D32), Icons.check_circle_rounded),
                if (request.status == RequestStatus.inProgress)
                  _action('Pending', RequestStatus.pending,
                      const Color(0xFFB28704), Icons.replay_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _action(String label, RequestStatus s, Color color, IconData icon) {
    return TextButton.icon(
      onPressed: () => onStatus(s),
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12.5),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}