import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/signal.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SignalHistorySheet extends StatelessWidget {
  const SignalHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const SignalHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final signals = state.recentSignals;
    final timeFmt = DateFormat('MMM d, HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Signal History Â· ${state.asset.symbol}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('${signals.length} recent',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: signals.isEmpty
                  ? const Center(
                      child: Text('No signals detected in the current window.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: signals.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, i) {
                        final s = signals[i];
                        return _SignalTile(signal: s, timeLabel: timeFmt.format(s.time));
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SignalTile extends StatelessWidget {
  final SignalEvent signal;
  final String timeLabel;
  const _SignalTile({required this.signal, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final color = signal.type.color == Colors.white ? AppColors.accent : signal.type.color;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(signal.type.icon, color: color, size: 18),
      ),
      title: Text(signal.type.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      subtitle: Text('${signal.type.bias} Â· $timeLabel',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Text(
        signal.close.toStringAsFixed(signal.close < 5 ? 5 : 2),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
