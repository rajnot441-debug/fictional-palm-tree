import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../theme/app_theme.dart';

/// Interactive candlestick chart with buttery-smooth pinch-to-zoom / panning
/// (Syncfusion's native GPU-accelerated renderer) plus overlay markers for
/// every detected signal type, and true "X" glyphs for extreme touch/cross
/// signals via chart annotations.
class TradingChart extends StatefulWidget {
  final List<Candle> candles;
  final List<SignalEvent> signals;
  final String symbolLabel;

  const TradingChart({
    super.key,
    required this.candles,
    required this.signals,
    required this.symbolLabel,
  });

  @override
  State<TradingChart> createState() => _TradingChartState();
}

class _TradingChartState extends State<TradingChart> {
  late final ZoomPanBehavior _zoomPanBehavior;
  late final TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      enableSelectionZooming: false,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: 0.02, // allows deep zoom into a handful of candles
    );
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
        color: AppColors.surfaceAlt,
        borderColor: AppColors.border,
        borderWidth: 1,
      ),
      lineType: TrackballLineType.vertical,
      lineColor: AppColors.textSecondary,
    );
  }

  List<SignalEvent> _byType(SignalType t) =>
      widget.signals.where((s) => s.type == t).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;
    if (candles.isEmpty) {
      return const Center(
        child: Text('No data loaded', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final crosses = [
      ..._byType(SignalType.extremeHighCross),
      ..._byType(SignalType.extremeLowCross),
    ];

    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.only(top: 6, bottom: 4, left: 4, right: 4),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        rangePadding: ChartRangePadding.additional,
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: const MajorGridLines(width: 0.4, color: AppColors.border),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      series: <CartesianSeries>[
        CandleSeries<Candle, DateTime>(
          dataSource: candles,
          xValueMapper: (c, _) => c.time,
          lowValueMapper: (c, _) => c.low,
          highValueMapper: (c, _) => c.high,
          openValueMapper: (c, _) => c.open,
          closeValueMapper: (c, _) => c.close,
          bearColor: AppColors.bear,
          bullColor: AppColors.bull,
          enableSolidCandles: true,
          name: widget.symbolLabel,
          animationDuration: 250,
        ),
        _markerSeries(
          SignalType.upperWickRejection,
          shape: DataMarkerType.triangle,
        ),
        _markerSeries(
          SignalType.lowerWickRejection,
          shape: DataMarkerType.invertedTriangle,
        ),
        _markerSeries(
          SignalType.equalSymmetricalWicks,
          shape: DataMarkerType.diamond,
        ),
        _markerSeries(
          SignalType.insideBar,
          shape: DataMarkerType.rectangle,
        ),
        _markerSeries(
          SignalType.structuralExhaustionBear,
          shape: DataMarkerType.pentagon,
        ),
        _markerSeries(
          SignalType.structuralExhaustionBull,
          shape: DataMarkerType.pentagon,
        ),
      ],
      annotations: [
        for (final cross in crosses)
          CartesianChartAnnotation(
            widget: _CrossBadge(bearish: cross.type == SignalType.extremeHighCross),
            coordinateUnit: CoordinateUnit.point,
            region: AnnotationRegion.chart,
            x: cross.time,
            y: cross.type == SignalType.extremeHighCross
                ? cross.price * 1.006
                : cross.price * 0.994,
          ),
      ],
    );
  }

  ScatterSeries<SignalEvent, DateTime> _markerSeries(
    SignalType type, {
    required DataMarkerType shape,
  }) {
    final data = _byType(type);
    return ScatterSeries<SignalEvent, DateTime>(
      dataSource: data,
      xValueMapper: (s, _) => s.time,
      yValueMapper: (s, _) => s.price,
      name: type.label,
      markerSettings: MarkerSettings(
        isVisible: true,
        shape: shape,
        color: type.color.withValues(alpha: 0.85),
        borderColor: Colors.black.withValues(alpha: 0.6),
        borderWidth: 1,
        width: 9,
        height: 9,
      ),
      animationDuration: 0,
    );
  }
}

/// A crisp, bold "X" badge for extreme high/low touch + rejection signals.
class _CrossBadge extends StatelessWidget {
  final bool bearish;
  const _CrossBadge({required this.bearish});

  @override
  Widget build(BuildContext context) {
    final color = bearish ? AppColors.bear : AppColors.bull;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: color, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        'âœ•',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
