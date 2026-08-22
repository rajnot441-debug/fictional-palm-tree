/// All thresholds are user-adjustable at runtime via the sensitivity sliders
/// in the control panel. Defaults are tuned to be reasonably selective.
class SignalParams {
  // Rules 1 & 2: wick rejection
  final double wickBodyRatio; // wick >= ratio * body
  final double wickDominance; // dominant wick >= ratio * opposite wick
  final double minWickPct; // wick >= pct * candle range

  // Rule 3: equal & symmetrical wicks
  final double symmetryTolerance; // |upperWick - lowerWick| <= tol * range
  final double indecisionBodyPct; // body <= pct * range

  // Rule 5: structural exhaustion
  final int pivotSpan; // bars on each side to confirm a swing pivot
  final double smallBodyFactor; // body <= factor * avgRange counts as "small"
  final double smallBodyFraction; // min fraction of small candles in a swing window
  final int avgRangeWindow; // rolling window for average true range proxy

  // Rule 6: extreme touch
  final int extremeWindow; // rolling lookback for local high/low

  const SignalParams({
    this.wickBodyRatio = 2.0,
    this.wickDominance = 2.0,
    this.minWickPct = 0.35,
    this.symmetryTolerance = 0.10,
    this.indecisionBodyPct = 0.30,
    this.pivotSpan = 2,
    this.smallBodyFactor = 0.6,
    this.smallBodyFraction = 0.5,
    this.avgRangeWindow = 14,
    this.extremeWindow = 20,
  });

  SignalParams copyWith({
    double? wickBodyRatio,
    double? wickDominance,
    double? minWickPct,
    double? symmetryTolerance,
    double? indecisionBodyPct,
    int? pivotSpan,
    double? smallBodyFactor,
    double? smallBodyFraction,
    int? avgRangeWindow,
    int? extremeWindow,
  }) {
    return SignalParams(
      wickBodyRatio: wickBodyRatio ?? this.wickBodyRatio,
      wickDominance: wickDominance ?? this.wickDominance,
      minWickPct: minWickPct ?? this.minWickPct,
      symmetryTolerance: symmetryTolerance ?? this.symmetryTolerance,
      indecisionBodyPct: indecisionBodyPct ?? this.indecisionBodyPct,
      pivotSpan: pivotSpan ?? this.pivotSpan,
      smallBodyFactor: smallBodyFactor ?? this.smallBodyFactor,
      smallBodyFraction: smallBodyFraction ?? this.smallBodyFraction,
      avgRangeWindow: avgRangeWindow ?? this.avgRangeWindow,
      extremeWindow: extremeWindow ?? this.extremeWindow,
    );
  }
}
