import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_tilt_card.dart';

class StatData {
  final String label;
  final String count;
  final IconData icon;
  final Color color;

  const StatData(this.label, this.count, this.icon, this.color);
}

class StatRow extends StatelessWidget {
  final List<StatData> stats;

  const StatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) SizedBox(width: 14),
          Expanded(
            child: GlassTiltCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(stats[i].icon, color: stats[i].color, size: 24),
                  SizedBox(height: 10),
                  Text(
                    stats[i].count,
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    stats[i].label,
                    style: TextStyle(
                        color: AppPalette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
