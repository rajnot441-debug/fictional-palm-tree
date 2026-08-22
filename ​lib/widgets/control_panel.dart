import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/signal_params.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom sheet with live sensitivity sliders for every rule. Changes apply
/// instantly (the engine re-runs on-device, no reload needed).
class ControlPanelSheet extends StatefulWidget {
  const ControlPanelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const ControlPanelSheet(),
    );
  }

  @override
  State<ControlPanelSheet> createState() => _ControlPanelSheetState();
}

class _ControlPanelSheetState extends State<ControlPanelSheet> {
  late SignalParams _p;

  @override
  void initState() {
    super.initState();
    _p = context.read<AppState>().params;
  }

  void _apply(SignalParams updated) {
    setState(() => _p = updated);
    context.read<AppState>().updateParams(updated);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pattern Sensitivity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Adjust thresholds live â€” the chart and signal list update instantly.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            _section('Wick Rejection (Rules 1 & 2)'),
            _slider('Wick â‰¥ Ã— body', _p.wickBodyRatio, 1.0, 5.0,
                (v) => _apply(_p.copyWith(wickBodyRatio: v))),
            _slider('Dominant wick â‰¥ Ã— opposite', _p.wickDominance, 1.0, 5.0,
                (v) => _apply(_p.copyWith(wickDominance: v))),
            _slider('Min wick size (% of range)', _p.minWickPct, 0.1, 0.9,
                (v) => _apply(_p.copyWith(minWickPct: v)), isPct: true),
            _section('Equal & Symmetrical Wicks (Rule 3)'),
            _slider('Max wick imbalance (% of range)', _p.symmetryTolerance, 0.02, 0.3,
                (v) => _apply(_p.copyWith(symmetryTolerance: v)), isPct: true),
            _slider('Max body size (% of range)', _p.indecisionBodyPct, 0.1, 0.6,
                (v) => _apply(_p.copyWith(indecisionBodyPct: v)), isPct: true),
            _section('Structural Exhaustion (Rule 5)'),
            _slider('Pivot span (bars/side)', _p.pivotSpan.toDouble(), 1, 5,
                (v) => _apply(_p.copyWith(pivotSpan: v.round())), isInt: true),
            _slider('Small-candle threshold (Ã— avg range)', _p.smallBodyFactor, 0.2, 1.0,
                (v) => _apply(_p.copyWith(smallBodyFactor: v))),
            _slider('Min fraction of small candles', _p.smallBodyFraction, 0.2, 1.0,
                (v) => _apply(_p.copyWith(smallBodyFraction: v)), isPct: true),
            _section('Extreme Touch (Rule 6)'),
            _slider('Local extreme window (bars)', _p.extremeWindow.toDouble(), 5, 100,
                (v) => _apply(_p.copyWith(extremeWindow: v.round())), isInt: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _apply(const SignalParams()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reset to Defaults'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool isPct = false,
    bool isInt = false,
  }) {
    final display = isPct
        ? '${(value * 100).toStringAsFixed(0)}%'
        : isInt
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
              Text(display,
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: isInt ? (max - min).round() : 40,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
