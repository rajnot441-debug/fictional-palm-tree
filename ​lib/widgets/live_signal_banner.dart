import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Compact horizontal strip of badges for every signal active on the most
/// recent candle â€” the "real-time triggered signals" summary panel.
class LiveSignalBanner extends StatelessWidget {
  const LiveSignalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.candles.isEmpty) return const SizedBox.shrink();

    final lastTime = state.candles.last.time;
    final active = state.signals.where((s) => s.time == lastTime).toList();

    if (active.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.radar_rounded, color: AppColors.textSecondary, size: 16),
            SizedBox(width: 8),
            Text('No signal on the latest candle', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: active.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final s = active[i];
            final color = s.type.color == Colors.white ? AppColors.accent : s.type.color;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.type.icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(s.type.label,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
