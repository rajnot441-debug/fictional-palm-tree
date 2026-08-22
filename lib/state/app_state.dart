import 'package:flutter/foundation.dart';

import '../engine/signal_engine.dart';
import '../engine/signal_params.dart';
import '../models/candle.dart';
import '../models/signal.dart';
import '../services/data_service.dart';

enum LoadStatus { idle, loading, ready, error }

/// Single source of truth for the dashboard: current asset/timeframe
/// selection, loaded candles, detected signals, and sensitivity params.
///
/// Kept deliberately simple (ChangeNotifier + Provider) for instant,
/// predictable rebuilds â€” recomputing signals is O(n) and runs on every
/// slider change with no visible jank for typical candle-window sizes.
class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();

  AssetOption _asset = kAssets.first;
  Timeframe _timeframe = kTimeframes[3]; // 1h default
  SignalParams _params = const SignalParams();

  List<Candle> _candles = [];
  List<SignalEvent> _signals = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  AssetOption get asset => _asset;
  Timeframe get timeframe => _timeframe;
  SignalParams get params => _params;
  List<Candle> get candles => List.unmodifiable(_candles);
  List<SignalEvent> get signals => List.unmodifiable(_signals);
  LoadStatus get status => _status;
  String? get error => _error;

  List<SignalEvent> get recentSignals =>
      _signals.reversed.take(100).toList(growable: false);

  SignalEvent? get latestSignal => _signals.isEmpty ? null : _signals.last;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final candles = await _dataService.fetchCandles(asset: _asset, timeframe: _timeframe);
      _candles = candles;
      _recompute();
      _status = LoadStatus.ready;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void setAsset(AssetOption asset) {
    if (asset.symbol == _asset.symbol) return;
    _asset = asset;
    load();
  }

  void setTimeframe(Timeframe tf) {
    if (tf.label == _timeframe.label) return;
    _timeframe = tf;
    load();
  }

  /// Updates sensitivity parameters and re-runs the (cheap) detection engine
  /// immediately â€” no network round trip needed.
  void updateParams(SignalParams params) {
    _params = params;
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    _signals = SignalEngine.detect(_candles, _params);
  }
}
