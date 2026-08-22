/// A single OHLCV price bar.
class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  double get body => (close - open).abs();

  double get range {
    final r = high - low;
    return r == 0 ? 1e-9 : r;
  }

  double get upperWick => high - (open > close ? open : close);

  double get lowerWick => (open < close ? open : close) - low;

  bool get isBullish => close >= open;

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      time: DateTime.parse(json['time'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Parses a Binance kline REST array:
  /// [openTime, open, high, low, close, volume, closeTime, ...]
  factory Candle.fromBinanceKline(List<dynamic> k) {
    return Candle(
      time: DateTime.fromMillisecondsSinceEpoch(k[0] as int, isUtc: true).toLocal(),
      open: double.parse(k[1] as String),
      high: double.parse(k[2] as String),
      low: double.parse(k[3] as String),
      close: double.parse(k[4] as String),
      volume: double.parse(k[5] as String),
    );
  }
}
