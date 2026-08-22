import 'package:flutter/material.dart';

/// The six custom price-action / candlestick wick rules.
enum SignalType {
  upperWickRejection,
  lowerWickRejection,
  equalSymmetricalWicks,
  insideBar,
  structuralExhaustionBear,
  structuralExhaustionBull,
  extremeHighCross,
  extremeLowCross,
}

extension SignalTypeMeta on SignalType {
  String get label {
    switch (this) {
      case SignalType.upperWickRejection:
        return 'Upper Wick Rejection';
      case SignalType.lowerWickRejection:
        return 'Lower Wick Rejection';
      case SignalType.equalSymmetricalWicks:
        return 'Equal & Symmetrical Wicks';
      case SignalType.insideBar:
        return 'Inside Bar / Contraction';
      case SignalType.structuralExhaustionBear:
        return 'Structural Exhaustion (Bearish)';
      case SignalType.structuralExhaustionBull:
        return 'Structural Exhaustion (Bullish)';
      case SignalType.extremeHighCross:
        return 'Extreme High Touch (X)';
      case SignalType.extremeLowCross:
        return 'Extreme Low Touch (X)';
    }
  }

  String get bias {
    switch (this) {
      case SignalType.upperWickRejection:
      case SignalType.structuralExhaustionBear:
      case SignalType.extremeHighCross:
        return 'Bearish';
      case SignalType.lowerWickRejection:
      case SignalType.structuralExhaustionBull:
      case SignalType.extremeLowCross:
        return 'Bullish';
      case SignalType.equalSymmetricalWicks:
        return 'Volatility';
      case SignalType.insideBar:
        return 'Contraction';
    }
  }

  Color get color {
    switch (this) {
      case SignalType.upperWickRejection:
        return const Color(0xFFEF5350);
      case SignalType.lowerWickRejection:
        return const Color(0xFF26A69A);
      case SignalType.equalSymmetricalWicks:
        return const Color(0xFFFBC02D);
      case SignalType.insideBar:
        return const Color(0xFF42A5F5);
      case SignalType.structuralExhaustionBear:
        return const Color(0xFFAB47BC);
      case SignalType.structuralExhaustionBull:
        return const Color(0xFF7E57C2);
      case SignalType.extremeHighCross:
      case SignalType.extremeLowCross:
        return const Color(0xFFFFFFFF);
    }
  }

  IconData get icon {
    switch (this) {
      case SignalType.upperWickRejection:
        return Icons.arrow_downward_rounded;
      case SignalType.lowerWickRejection:
        return Icons.arrow_upward_rounded;
      case SignalType.equalSymmetricalWicks:
        return Icons.compress_rounded;
      case SignalType.insideBar:
        return Icons.crop_square_rounded;
      case SignalType.structuralExhaustionBear:
      case SignalType.structuralExhaustionBull:
        return Icons.waves_rounded;
      case SignalType.extremeHighCross:
      case SignalType.extremeLowCross:
        return Icons.close_rounded; // rendered as "X" on chart + list
    }
  }
}

/// A detected signal event anchored to a candle.
class SignalEvent {
  final DateTime time;
  final SignalType type;
  final double price; // anchor price for plotting (e.g. high/low +/- offset)
  final double close; // candle close, shown in history list

  const SignalEvent({
    required this.time,
    required this.type,
    required this.price,
    required this.close,
  });
}
