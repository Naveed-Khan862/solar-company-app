import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/service_request.dart';
import '../providers.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_tilt_card.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final bool subAdminScope;
  final String? email;

  const ReportsScreen({
    super.key,
    this.subAdminScope = false,
    this.email,
  });

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Future<void> _exportCsv(WidgetRef ref, BuildContext context, List<ServiceRequest> requests) async {
    final messenger = ScaffoldMessenger.of(context);
    String _escapeCsv(String s) {
      // Formula injection (Fix #8): Excel mein `=`, `+`, `-`, `@` se shuru
      // hone wale cells formula ban jate hain — prefix `'` se neutralize karo.
      var out = s;
      if (out.startsWith('=') ||
          out.startsWith('+') ||
          out.startsWith('-') ||
          out.startsWith('@')) {
        out = "'$out";
      }
      if (out.contains('"') || out.contains(',') || out.contains('\n')) {
        return '"${out.replaceAll('"', '""')}"';
      }
      return out;
    }

    final buffer = StringBuffer()
      ..writeln(
          'ID,Client Email,Client Name,Category,Sub Category,Priority,Status,Assigned To,Address,Phone,Created At,Rating,Review');
    for (final r in requests) {
      buffer.writeln(
          '${_escapeCsv(r.id)},${_escapeCsv(r.userEmail)},${_escapeCsv(r.userName)},${_escapeCsv(r.category.label)},${_escapeCsv(r.subCategory)},${_escapeCsv(r.priority)},${_escapeCsv(r.status.label)},${_escapeCsv(r.assignedByName)},${_escapeCsv(r.address)},${_escapeCsv(r.phone)},${_escapeCsv(r.createdAt.toIso8601String())},${_escapeCsv(r.rating.toString())},${_escapeCsv(r.review)}');
    }
    final now = DateTime.now();
    final file = File(
        '${Directory.systemTemp.path}/solar_report_${now.day}_${now.month}_${now.year}_${now.hour}${now.minute}${now.second}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Solar Reports',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          requests.isEmpty
              ? 'No data yet — create requests first'
              : 'CSV file created — save/share it in any app (Drive, Gmail, Files)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A86B)));
    }
    
    final requests = widget.subAdminScope
        ? ref.watch(weeklyChartDataProvider(user))
        : ref.watch(allRequestsProvider);
    final total = requests.length;
    final pending = ref.watch(pendingCountProvider(user));
    final inProgress = ref.watch(inProgressCountProvider(user));
    final resolved = ref.watch(resolvedCountProvider(user));
    final avgRating = ref.watch(avgRatingProvider(user));

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
                        'Reports & Charts',
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _exportCsv(ref, context, requests),
                      icon: const Icon(Icons.ios_share_rounded,
                          color: Color(0xFF00A86B)),
                      tooltip: 'CSV Export',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Row(
                      children: [
                        _summary('Total', '$total', Icons.assignment_rounded,
                            const Color(0xFF00A86B)),
                        const SizedBox(width: 10),
                        _summary('Pending', '$pending',
                            Icons.pending_actions_rounded,
                            const Color(0xFFFFB300)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _summary('In Progress', '$inProgress',
                            Icons.hourglass_top_rounded,
                            const Color(0xFF1976D2)),
                        const SizedBox(width: 10),
                        _summary('Resolved', '$resolved',
                            Icons.check_circle_rounded,
                            const Color(0xFF2E7D32)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassTiltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart_rounded,
                                  color: Color(0xFF00A86B), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Last 7 Days',
                                style: TextStyle(
                                  color: AppPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Spacer(),
                              if (avgRating > 0)
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Color(0xFFFFB300), size: 17),
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: TextStyle(
                                          color: AppPalette.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      ' avg',
                                      style: TextStyle(
                                          color: AppPalette.textFaint,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _WeeklyChart(requests: requests),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    GlassTiltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Distribution',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _distributionRow('Pending', pending, total,
                              const Color(0xFFFFB300)),
                          const SizedBox(height: 10),
                          _distributionRow('In Progress', inProgress, total,
                              const Color(0xFF1976D2)),
                          const SizedBox(height: 10),
                          _distributionRow('Resolved', resolved, total,
                              Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    GlassTiltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 12),
                          for (final c in RequestCategory.values) ...[
                            _categoryRow(c, requests),
                            SizedBox(height: 10),
                          ],
                          Text(
                            'Priority',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _priorityRow(
                              'Urgent',
                              requests
                                  .where((r) => r.priority == 'Urgent')
                                  .length,
                              requests.length,
                              const Color(0xFFE53935)),
                          const SizedBox(height: 10),
                          _priorityRow(
                              'Normal',
                              requests
                                  .where((r) => r.priority != 'Urgent')
                                  .length,
                              requests.length,
                              const Color(0xFF00A86B)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassTiltCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.13),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: AppPalette.textFaint, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _distributionRow(
      String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: AppPalette.track,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct == 0 ? 0.001 : pct,
                child: Container(color: color),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(RequestCategory c, List<ServiceRequest> requests) {
    final count = requests.where((r) => r.category == c).length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: c.icon == Icons.report_problem_outlined
                ? const Color(0xFFFFB300).withValues(alpha: 0.13)
                : c.icon == Icons.search_outlined
                    ? const Color(0xFF00838F).withValues(alpha: 0.12)
                    : const Color(0xFF2E7D32).withValues(alpha: 0.12),
          ),
          child: Icon(c.icon,
              size: 17,
              color: c.icon == Icons.report_problem_outlined
                  ? Color(0xFFFFB300)
                  : c.icon == Icons.search_outlined
                      ? Color(0xFF00838F)
                      : Color(0xFF2E7D32)),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            c.label,
            style: TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _priorityRow(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: AppPalette.track,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct == 0 ? 0.001 : pct,
                child: Container(color: color),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<ServiceRequest> requests;

  const _WeeklyChart({required this.requests});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final dayReqs =
          requests.where((r) =>
              r.createdAt.year == d.year &&
              r.createdAt.month == d.month &&
              r.createdAt.day == d.day);
      return (
        label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1],
        pending: dayReqs.where((r) => r.status == RequestStatus.pending).length,
        inProgress:
            dayReqs.where((r) => r.status == RequestStatus.inProgress).length,
        resolved:
            dayReqs.where((r) => r.status == RequestStatus.resolved).length,
      );
    }).toList();

    final maxCount = days.fold<int>(0, (m, d) {
      final sum = d.pending + d.inProgress + d.resolved;
      return sum > m ? sum : m;
    }).clamp(1, 999999);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (i) {
          final d = days[i];
          final total = d.pending + d.inProgress + d.resolved;
          final h = total == 0 ? 3.0 : (total / maxCount) * 110;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (total > 0)
                    Text(
                      '$total',
                      style: TextStyle(
                          color: AppPalette.textFaint, fontSize: 9.5),
                    ),
                  const SizedBox(height: 2),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (d.resolved > 0)
                        _segment(h * d.resolved / total, Color(0xFF2E7D32)),
                      if (d.inProgress > 0)
                        _segment(
                            h * d.inProgress / total, Color(0xFF1976D2)),
                      if (d.pending > 0)
                        _segment(h * d.pending / total, Color(0xFFFFB300)),
                      if (total == 0)
                        Container(
                          width: 14,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppPalette.track,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    d.label,
                    style: TextStyle(
                        color: AppPalette.textFaint, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _segment(double height, Color color) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}