import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_switcher.dart';
import '../widgets/control_panel.dart';
import '../widgets/live_signal_banner.dart';
import '../widgets/signal_history_sheet.dart';
import '../widgets/trading_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().load());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.bull]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.candlestick_chart_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Signal Scanner'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sensitivity',
            onPressed: () => ControlPanelSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Signal History',
            onPressed: () => SignalHistorySheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<AppState>().load(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const AssetSwitcher(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PriceHeader(),
                  const TimeframeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const LiveSignalBanner(),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.only(top: 6, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _ChartArea(state: state),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SignalHistorySheet.show(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.list_alt_rounded, size: 18),
        label: Text('${state.signals.length} signals'),
      ),
    );
  }
}

class _ChartArea extends StatelessWidget {
  final AppState state;
  const _ChartArea({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
      case LoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.bear, size: 32),
                const SizedBox(height: 10),
                Text(state.error ?? 'Failed to load data',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.read<AppState>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case LoadStatus.idle:
      case LoadStatus.ready:
        return TradingChart(
          candles: state.candles,
          signals: state.signals,
          symbolLabel: state.asset.symbol,
        );
    }
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.candles.isEmpty) {
      return Text(state.asset.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13));
    }
    final last = state.candles.last;
    final prev = state.candles.length > 1 ? state.candles[state.candles.length - 2] : last;
    final change = last.close - prev.close;
    final changePct = prev.close == 0 ? 0 : (change / prev.close) * 100;
    final up = change >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(state.asset.symbol,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Text(
              last.close.toStringAsFixed(last.close < 5 ? 5 : 2),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                color: up ? AppColors.bull : AppColors.bear, size: 18),
            Text(
              '${changePct.abs().toStringAsFixed(2)}%',
              style: TextStyle(
                  color: up ? AppColors.bull : AppColors.bear, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ],
        ),
      ],
    );
  }
}
