import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/candle.dart';

enum AssetClass { crypto, stock, forex }

class AssetOption {
  final String symbol; // display symbol, e.g. "BTCUSDT", "AAPL", "EURUSD"
  final String name;
  final AssetClass assetClass;
  const AssetOption(this.symbol, this.name, this.assetClass);
}

class Timeframe {
  final String label; // "1m", "5m", "15m", "1h", "4h", "1d"
  final String binanceInterval;
  final Duration duration;
  const Timeframe(this.label, this.binanceInterval, this.duration);
}

const kTimeframes = <Timeframe>[
  Timeframe('1m', '1m', Duration(minutes: 1)),
  Timeframe('5m', '5m', Duration(minutes: 5)),
  Timeframe('15m', '15m', Duration(minutes: 15)),
  Timeframe('1h', '1h', Duration(hours: 1)),
  Timeframe('4h', '4h', Duration(hours: 4)),
  Timeframe('1d', '1d', Duration(days: 1)),
];

const kAssets = <AssetOption>[
  AssetOption('BTCUSDT', 'Bitcoin / USDT', AssetClass.crypto),
  AssetOption('ETHUSDT', 'Ethereum / USDT', AssetClass.crypto),
  AssetOption('SOLUSDT', 'Solana / USDT', AssetClass.crypto),
  AssetOption('XRPUSDT', 'XRP / USDT', AssetClass.crypto),
  AssetOption('AAPL', 'Apple Inc.', AssetClass.stock),
  AssetOption('TSLA', 'Tesla Inc.', AssetClass.stock),
  AssetOption('NVDA', 'NVIDIA Corp.', AssetClass.stock),
  AssetOption('EURUSD', 'Euro / US Dollar', AssetClass.forex),
  AssetOption('GBPUSD', 'British Pound / US Dollar', AssetClass.forex),
];

/// Fetches OHLCV candles for the selected asset/timeframe.
///
/// Crypto uses Binance's free, keyless public REST API directly. Stocks and
/// forex do not have a reliable free+keyless+CORS-safe REST endpoint, so
/// this app ships a deterministic, realistic random-walk simulator for those
/// asset classes for demo purposes â€” swap [_fetchSimulated] for a real
/// provider (e.g. Twelve Data, Alpha Vantage, Polygon.io) by adding your API
/// key and following the same "return List<Candle>" contract.
class DataService {
  static const _binanceBase = 'https://api.binance.com/api/v3/klines';

  Future<List<Candle>> fetchCandles({
    required AssetOption asset,
    required Timeframe timeframe,
    int limit = 300,
  }) async {
    if (asset.assetClass == AssetClass.crypto) {
      return _fetchBinance(asset.symbol, timeframe.binanceInterval, limit);
    }
    return _fetchSimulated(asset.symbol, timeframe.duration, limit);
  }

  Future<List<Candle>> _fetchBinance(String symbol, String interval, int limit) async {
    final uri = Uri.parse('$_binanceBase?symbol=$symbol&interval=$interval&limit=$limit');
    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Binance API error: ${resp.statusCode}');
    }
    final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((k) => Candle.fromBinanceKline(k as List<dynamic>)).toList();
  }

  /// Deterministic per-symbol random walk so repeated loads for the same
  /// asset look consistent within a session, while still varying candle to
  /// candle like a real market (including occasional wick-heavy bars so the
  /// signal engine has real patterns to find).
  Future<List<Candle>> _fetchSimulated(String symbol, Duration step, int limit) async {
    await Future.delayed(const Duration(milliseconds: 300)); // feel like a network call
    final seed = symbol.codeUnits.fold<int>(0, (a, b) => a + b);
    final rnd = math.Random(seed);
    final now = DateTime.now();
    final candles = <Candle>[];

    double price = symbol == 'EURUSD' || symbol == 'GBPUSD'
        ? 1.05 + rnd.nextDouble() * 0.1
        : (symbol.length <= 5 ? 150 + rnd.nextDouble() * 100 : 100 + rnd.nextDouble() * 50);

    final volScale = price < 5 ? price * 0.004 : price * 0.006;

    for (int i = limit - 1; i >= 0; i--) {
      final time = now.subtract(step * i);
      final drift = (rnd.nextDouble() - 0.5) * volScale;
      final open = price;
      double close = open + drift;

      // Occasionally inject a strong wick-rejection or symmetrical-wick bar
      // so the demo data exercises all six rules realistically.
      final roll = rnd.nextDouble();
      double high, low;
      if (roll < 0.08) {
        // long upper wick
        high = math.max(open, close) + volScale * (2.5 + rnd.nextDouble() * 2);
        low = math.min(open, close) - volScale * 0.2;
      } else if (roll < 0.16) {
        // long lower wick
        high = math.max(open, close) + volScale * 0.2;
        low = math.min(open, close) - volScale * (2.5 + rnd.nextDouble() * 2);
      } else if (roll < 0.22) {
        // symmetrical doji-like
        final wick = volScale * (1.5 + rnd.nextDouble());
        close = open + (rnd.nextDouble() - 0.5) * volScale * 0.3;
        high = math.max(open, close) + wick;
        low = math.min(open, close) - wick;
      } else {
        high = math.max(open, close) + rnd.nextDouble() * volScale * 0.8;
        low = math.min(open, close) - rnd.nextDouble() * volScale * 0.8;
      }

      final volume = 1000 + rnd.nextDouble() * 9000;
      candles.add(Candle(time: time, open: open, high: high, low: low, close: close, volume: volume));
      price = close;
    }

    return candles;
  }
}
