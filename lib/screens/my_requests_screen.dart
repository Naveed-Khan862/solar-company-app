import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';
import '../providers.dart';
import '../widgets/glass_tilt_card.dart';
import 'new_request_screen.dart';
import 'request_detail_screen.dart';
import '../theme/app_theme.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const MyRequestsScreen({super.key, required this.user});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  Future<void> _openNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NewRequestScreen(user: widget.user)),
    );
    if (created == true && mounted) {
      ref.invalidate(userRequestsProvider);
    }
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
    if (mounted) {
      ref.invalidate(userRequestsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(userRequestsProvider(widget.user));
    final categoryFilter = ref.watch(requestCategoryFilterProvider);
    final statusFilter = ref.watch(requestStatusFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _filters(categoryFilter, statusFilter),
          Expanded(child: _list(requests)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00A86B),
        foregroundColor: Colors.white,
        onPressed: _openNew,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _filters(RequestCategory? categoryFilter, RequestStatus? statusFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _glassChip(
            'All',
            categoryFilter == null && statusFilter == null,
            () {
              ref.read(requestCategoryFilterProvider.notifier).state = null;
              ref.read(requestStatusFilterProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
          ...RequestCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _glassChip(c.label, categoryFilter == c, () {
                  ref.read(requestCategoryFilterProvider.notifier).state =
                      categoryFilter == c ? null : c;
                }),
              )),
          const SizedBox(width: 4),
          for (final s in RequestStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _glassChip(s.label, statusFilter == s, () {
                ref.read(requestStatusFilterProvider.notifier).state =
                    statusFilter == s ? null : s;
              }, color: s.color),
            ),
        ],
      ),
    );
  }

  Widget _glassChip(String label, bool selected, VoidCallback onTap,
      {Color color = const Color(0xFF00A86B)}) {
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppPalette.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _list(List<ServiceRequest> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Color(0xFF9AB3A4)),
            SizedBox(height: 12),
            Text(
              'No requests yet\nCreate your first request via "+ New Request"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textMuted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
      itemCount: items.length,
      itemBuilder: (context, i) => RequestCard(
        request: items[i],
        showUser: false,
        onTap: () => _openDetail(items[i]),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final bool showUser;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.showUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(request.category);
    return GestureDetector(
      onTap: onTap,
      child: GlassTiltCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: catColor.withValues(alpha: 0.14),
                  ),
                  child:
                      Icon(request.category.icon, color: catColor, size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category.label +
                            (request.subCategory.isNotEmpty
                                ? ' — ${request.subCategory}'
                                : ''),
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (showUser)
                        Text(
                          request.userName,
                          style: TextStyle(
                              color: AppPalette.textMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (request.priority == 'Urgent')
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFE53935), size: 19),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: request.status.color.withValues(alpha: 0.12),
                    border: Border.all(
                        color: request.status.color.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    request.status.label,
                    style: TextStyle(
                      color: request.status.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppPalette.textSecondary, fontSize: 13.5),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: AppPalette.textFaint),
                SizedBox(width: 5),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(color: AppPalette.textFaint, fontSize: 12),
                ),
                const Spacer(),
                if (showUser && request.assignedByName.isNotEmpty) ...[
                  const Icon(Icons.person_pin_rounded,
                      size: 13, color: Color(0xFF00A86B)),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      request.assignedByName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Color(0xFF00A86B), fontSize: 11.5),
                    ),
                  ),
                ] else if (showUser)
                  Text(request.userEmail,
                      style: TextStyle(
                          color: AppPalette.textFaint, fontSize: 11.5)),
                const SizedBox(width: 6),
                if (onTap != null)
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: Color(0xFF00A86B)),
              ],
            ),
            if (request.isRated) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < request.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFB300),
                      size: 16,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    request.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _catColor(RequestCategory c) {
    switch (c) {
      case RequestCategory.complaint:
        return const Color(0xFFFFB300);
      case RequestCategory.inspection:
        return const Color(0xFF00838F);
      case RequestCategory.panelWashing:
        return const Color(0xFF2E7D32);
    }
  }

  String _formatDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }
}