import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AssetSwitcher extends StatelessWidget {
  const AssetSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kAssets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final asset = kAssets[i];
          final selected = asset.symbol == state.asset.symbol;
          return ChoiceChip(
            label: Text(asset.symbol),
            selected: selected,
            onSelected: (_) => context.read<AppState>().setAsset(asset),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceAlt,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
            ),
          );
        },
      ),
    );
  }
}

class TimeframeSelector extends StatelessWidget {
  const TimeframeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tf in kTimeframes)
            GestureDetector(
              onTap: () => context.read<AppState>().setTimeframe(tf),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tf.label == state.timeframe.label ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tf.label,
                  style: TextStyle(
                    color: tf.label == state.timeframe.label ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
