import 'dart:math' as math;

import '../models/candle.dart';
import '../models/signal.dart';
import 'signal_params.dart';

/// Pure, stateless, side-effect-free signal detection engine.
///
/// Runs entirely on-device over the currently loaded candle window. Designed
/// to be cheap enough to re-run on every parameter change (O(n) plus a small
/// O(n) pivot scan for rule 5), so the UI stays instantly responsive when the
/// user drags a sensitivity slider.
class SignalEngine {
  /// Marks a pivot high/low at index i if candle[i] is the extreme value in
  /// the window [i-left, i+right] (and uniquely so).
  static List<bool> _findPivots(List<double> values, int left, int right, {required bool high}) {
    final n = values.length;
    final result = List<bool>.filled(n, false);
    for (int i = left; i < n - right; i++) {
      final windowStart = i - left;
      final windowEnd = i + right; // inclusive
      double extreme = values[windowStart];
      int extremeCount = 0;
      for (int j = windowStart; j <= windowEnd; j++) {
        final v = values[j];
        if (high ? v > extreme : v < extreme) {
          extreme = v;
        }
      }
      for (int j = windowStart; j <= windowEnd; j++) {
        if (values[j] == extreme) extremeCount++;
      }
      if (values[i] == extreme && extremeCount == 1) {
        result[i] = true;
      }
    }
    return result;
  }

  static List<double> _rollingMean(List<double> values, int window) {
    final n = values.length;
    final out = List<double>.filled(n, double.nan);
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += values[i];
      if (i >= window) sum -= values[i - window];
      final count = math.min(i + 1, window);
      if (count >= math.min(5, window)) {
        out[i] = sum / count;
      }
    }
    return out;
  }

  static List<double> _rollingMax(List<double> values, int window) {
    final n = values.length;
    final out = List<double>.filled(n, double.nan);
    for (int i = 0; i < n; i++) {
      final start = math.max(0, i - window + 1);
      if (i - start + 1 < math.min(5, window)) continue;
      double m = values[start];
      for (int j = start; j <= i; j++) {
        if (values[j] > m) m = values[j];
      }
      out[i] = m;
    }
    return out;
  }

  static List<double> _rollingMin(List<double> values, int window) {
    final n = values.length;
    final out = List<double>.filled(n, double.nan);
    for (int i = 0; i < n; i++) {
      final start = math.max(0, i - window + 1);
      if (i - start + 1 < math.min(5, window)) continue;
      double m = values[start];
      for (int j = start; j <= i; j++) {
        if (values[j] < m) m = values[j];
      }
      out[i] = m;
    }
    return out;
  }

  /// Runs all six rules over [candles] and returns the emitted signal events,
  /// each anchored to the triggering candle's timestamp.
  static List<SignalEvent> detect(List<Candle> candles, SignalParams p) {
    final n = candles.length;
    if (n < 5) return [];

    final events = <SignalEvent>[];

    final highs = candles.map((c) => c.high).toList();
    final lows = candles.map((c) => c.low).toList();
    final ranges = candles.map((c) => c.range).toList();
    final bodies = candles.map((c) => c.body).toList();
    final avgRange = _rollingMean(ranges, p.avgRangeWindow);
    final rollMax = _rollingMax(highs, p.extremeWindow);
    final rollMin = _rollingMin(lows, p.extremeWindow);

    // Rules 1, 2, 3 â€” per-candle wick geometry
    final upperRejection = List<bool>.filled(n, false);
    final lowerRejection = List<bool>.filled(n, false);
    final equalWicks = List<bool>.filled(n, false);

    for (int i = 0; i < n; i++) {
      final c = candles[i];
      final body = bodies[i] == 0 ? 1e-9 : bodies[i];
      final range = ranges[i];
      final uw = c.upperWick;
      final lw = c.lowerWick;
      final lwSafe = lw == 0 ? 1e-9 : lw;
      final uwSafe = uw == 0 ? 1e-9 : uw;

      upperRejection[i] = uw >= p.wickBodyRatio * body &&
          uw >= p.wickDominance * lwSafe &&
          uw >= p.minWickPct * range;

      lowerRejection[i] = lw >= p.wickBodyRatio * body &&
          lw >= p.wickDominance * uwSafe &&
          lw >= p.minWickPct * range;

      final bothSizable = uw >= p.minWickPct * range && lw >= p.minWickPct * range;
      final symmetrical = (uw - lw).abs() <= p.symmetryTolerance * range;
      final smallBody = bodies[i] <= p.indecisionBodyPct * range;
      equalWicks[i] = bothSizable && symmetrical && smallBody;

      if (upperRejection[i]) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.upperWickRejection,
          price: c.high,
          close: c.close,
        ));
      }
      if (lowerRejection[i]) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.lowerWickRejection,
          price: c.low,
          close: c.close,
        ));
      }
      if (equalWicks[i]) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.equalSymmetricalWicks,
          price: c.high,
          close: c.close,
        ));
      }
    }

    // Rule 4 â€” inside bar
    for (int i = 1; i < n; i++) {
      final c = candles[i];
      final prev = candles[i - 1];
      if (c.high <= prev.high && c.low >= prev.low) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.insideBar,
          price: (c.high + c.low) / 2,
          close: c.close,
        ));
      }
    }

    // Rule 5 â€” structural exhaustion via pivot sequences
    final pivotHighMask = _findPivots(highs, p.pivotSpan, p.pivotSpan, high: true);
    final pivotLowMask = _findPivots(lows, p.pivotSpan, p.pivotSpan, high: false);
    final pivotHighIdx = [for (int i = 0; i < n; i++) if (pivotHighMask[i]) i];
    final pivotLowIdx = [for (int i = 0; i < n; i++) if (pivotLowMask[i]) i];

    bool isSmallBody(int i) {
      final avg = avgRange[i];
      if (avg.isNaN) return false;
      return bodies[i] <= p.smallBodyFactor * avg;
    }

    for (int k = 2; k < pivotHighIdx.length; k++) {
      final i0 = pivotHighIdx[k - 2], i1 = pivotHighIdx[k - 1], i2 = pivotHighIdx[k];
      if (highs[i0] > highs[i1] && highs[i1] > highs[i2]) {
        final windowStart = math.max(0, i0 - 1);
        int smallCount = 0, total = 0;
        for (int j = windowStart; j <= i2; j++) {
          total++;
          if (isSmallBody(j)) smallCount++;
        }
        if (total > 0 && smallCount / total >= p.smallBodyFraction) {
          events.add(SignalEvent(
            time: candles[i2].time,
            type: SignalType.structuralExhaustionBear,
            price: highs[i2],
            close: candles[i2].close,
          ));
        }
      }
    }

    for (int k = 2; k < pivotLowIdx.length; k++) {
      final i0 = pivotLowIdx[k - 2], i1 = pivotLowIdx[k - 1], i2 = pivotLowIdx[k];
      if (lows[i0] < lows[i1] && lows[i1] < lows[i2]) {
        final windowStart = math.max(0, i0 - 1);
        int smallCount = 0, total = 0;
        for (int j = windowStart; j <= i2; j++) {
          total++;
          if (isSmallBody(j)) smallCount++;
        }
        if (total > 0 && smallCount / total >= p.smallBodyFraction) {
          events.add(SignalEvent(
            time: candles[i2].time,
            type: SignalType.structuralExhaustionBull,
            price: lows[i2],
            close: candles[i2].close,
          ));
        }
      }
    }

    // Rule 6 â€” extreme high/low touch combined with a wick rejection
    for (int i = 0; i < n; i++) {
      final c = candles[i];
      if (!rollMax[i].isNaN && c.high >= rollMax[i] && upperRejection[i]) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.extremeHighCross,
          price: c.high,
          close: c.close,
        ));
      }
      if (!rollMin[i].isNaN && c.low <= rollMin[i] && lowerRejection[i]) {
        events.add(SignalEvent(
          time: c.time,
          type: SignalType.extremeLowCross,
          price: c.low,
          close: c.close,
        ));
      }
    }

    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }
}
