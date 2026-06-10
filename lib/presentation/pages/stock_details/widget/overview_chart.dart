import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../../../core/constants/constants.dart';
import '../../../../data/models/chart_data.dart';
import '../../../../data/services/live_price_service.dart';
import '../../../../presentation/bloc/trading_terminal/terminal_bloc.dart';
import '../../../../presentation/bloc/trading_terminal/terminal_state.dart';

class OverviewChart extends StatefulWidget {
  final List<ChartCandle> candles;
  final bool isLoading;
  final String securityId;

  const OverviewChart({
    super.key,
    required this.candles,
    this.isLoading = false,
    this.securityId = '',
  });

  @override
  State<OverviewChart> createState() => _OverviewChartState();
}

class _OverviewChartState extends State<OverviewChart> {
  bool _showCandles = true;
  ChartCandle? _hovered;
  double _scrollOffset = 0;

  static const double _candleW = 8.0;
  static const double _candleGap = 2.0;
  static const double _step = _candleW + _candleGap;
  static const double _labelW = 58.0;

  @override
  void didUpdateWidget(OverviewChart old) {
    super.didUpdateWidget(old);
    if (old.candles.length != widget.candles.length && widget.candles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Scroll to show newest candles on the right
        final chartW = (context.size?.width ?? 350) - _labelW;
        final visible = (chartW / _step).floor();
        final maxScroll = math.max(0.0, (widget.candles.length - visible) * _step);
        setState(() => _scrollOffset = maxScroll);
      });
    }
  }

  double _getLivePrice(BuildContext ctx) {
    try {
      final p = ctx.read<TerminalBloc>().state.livePrices[widget.securityId];
      if (p != null && p > 0) return p;
    } catch (_) {}
    final d = LivePriceService.instance.priceOf(widget.securityId);
    return d > 0 ? d : 0;
  }

  List<ChartCandle> _withLiveCandle(BuildContext ctx, List<ChartCandle> candles) {
    if (candles.isEmpty) return candles;
    final live = _getLivePrice(ctx);
    if (live <= 0) return candles;
    final last = candles.last;
    return [
      ...candles.sublist(0, candles.length - 1),
      ChartCandle(
        time:   last.time,
        open:   last.open,
        high:   live > last.high ? live : last.high,
        low:    live < last.low  ? live : last.low,
        close:  live,
        volume: last.volume,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TerminalBloc, TerminalState>(
      buildWhen: (p, c) =>
          (p.livePrices[widget.securityId]) != (c.livePrices[widget.securityId]),
      builder: (ctx, _) {
        final live    = _getLivePrice(ctx);
        final candles = _withLiveCandle(ctx, widget.candles);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn('Candle', Icons.candlestick_chart_outlined, _showCandles,   () => setState(() => _showCandles = true)),
                  const SizedBox(width: 6),
                  _Btn('Line',   Icons.show_chart_rounded,          !_showCandles, () => setState(() => _showCandles = false)),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Chart area
            SizedBox(
              height: 240.sp,
              child: widget.isLoading
                  ? const Center(child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colorz.primary)))
                  : candles.isEmpty
                      ? Center(child: Text('No chart data',
                          style: AppTextStyles.medium.copyWith(color: Colorz.hintTextColor)))
                      : _showCandles
                          ? _candleView(candles, live)
                          : _lineView(candles, live),
            ),
          ],
        );
      },
    );
  }

  // ── Candlestick view ────────────────────────────────────────────────────────
  Widget _candleView(List<ChartCandle> candles, double live) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          final chartW = (context.size?.width ?? 350) - _labelW;
          final maxScroll = math.max(0.0, (candles.length - (chartW / _step).floor()) * _step);
          _scrollOffset = (_scrollOffset - d.delta.dx).clamp(0.0, maxScroll);
        });
      },
      onTapUp: (d) {
        final start = (_scrollOffset / _step).floor();
        final idx   = start + (d.localPosition.dx / _step).floor();
        if (idx >= 0 && idx < candles.length) setState(() => _hovered = candles[idx]);
        else setState(() => _hovered = null);
      },
      child: Stack(
        children: [
          // Chart painter
          Positioned.fill(
            child: CustomPaint(
              painter: _CandlePainter(
                candles:      candles,
                livePrice:    live > 0 ? live : null,
                scrollOffset: _scrollOffset,
                hovered:      _hovered,
                candleW:      _candleW,
                gap:          _candleGap,
                labelW:       _labelW,
              ),
            ),
          ),

          // OHLC tooltip on tap
          if (_hovered != null)
            Positioned(
              top: 4, left: 8,
              child: _OhlcTooltip(candle: _hovered!),
            ),

          // Live price badge (top-right)
          if (live > 0)
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colorz.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  live.toStringAsFixed(2),
                  style: AppTextStyles.semiBold.copyWith(
                    color: Colors.white,
                    fontSize: SizeConfig.smallFont,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Line view ───────────────────────────────────────────────────────────────
  Widget _lineView(List<ChartCandle> candles, double live) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _LinePainter(candles: candles, livePrice: live > 0 ? live : null, labelW: _labelW),
          ),
        ),
        if (live > 0)
          Positioned(
            top: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colorz.primary, borderRadius: BorderRadius.circular(4)),
              child: Text(live.toStringAsFixed(2),
                  style: AppTextStyles.semiBold.copyWith(color: Colors.white, fontSize: SizeConfig.smallFont)),
            ),
          ),
      ],
    );
  }
}

// ── Candlestick painter ───────────────────────────────────────────────────────
class _CandlePainter extends CustomPainter {
  final List<ChartCandle> candles;
  final double? livePrice;
  final double scrollOffset;
  final ChartCandle? hovered;
  final double candleW;
  final double gap;
  final double labelW;

  const _CandlePainter({
    required this.candles,
    this.livePrice,
    required this.scrollOffset,
    this.hovered,
    required this.candleW,
    required this.gap,
    required this.labelW,
  });

  static const double _volRatio = 0.20;
  static const double _pad      = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final step   = candleW + gap;
    final chartW = size.width - labelW;
    final chartH = size.height * (1 - _volRatio);
    final volH   = size.height * _volRatio;

    final startIdx = (scrollOffset / step).floor().clamp(0, candles.length - 1);
    final visible  = (chartW / step).ceil() + 2;
    final endIdx   = math.min(startIdx + visible, candles.length);
    final sub      = candles.sublist(startIdx, endIdx);
    if (sub.isEmpty) return;

    // Price range
    double hi = sub.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double lo = sub.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (livePrice != null) { hi = math.max(hi, livePrice!); lo = math.min(lo, livePrice!); }
    final range = (hi - lo).abs();
    if (range < 0.01) return;

    double yP(double v) => _pad + (1 - (v - lo) / range) * (chartH - _pad * 2);

    // Max volume
    final maxVol = sub.fold<double>(0, (m, c) => c.volume > m ? c.volume.toDouble() : m);

    // ── Grid
    final gridP = Paint()..color = Colors.grey.withValues(alpha: 0.08)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = _pad + (chartH - _pad * 2) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridP);
      final price = hi - range * i / 4;
      _text(canvas, price.toStringAsFixed(2), Offset(chartW + 2, y - 7), 8.5, Colors.grey);
    }

    // ── Candles
    final xOffset = scrollOffset.remainder(step) > 0 ? step - scrollOffset.remainder(step) : 0.0;

    for (int i = 0; i < sub.length; i++) {
      final c    = sub[i];
      final cx   = xOffset + i * step + candleW / 2;
      if (cx < 0 || cx > chartW) continue;
      final isUp = c.close >= c.open;
      final col  = isUp ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
      final p    = Paint()..color = col;

      // Wick
      canvas.drawLine(Offset(cx, yP(c.high)), Offset(cx, yP(c.low)),
          Paint()..color = col..strokeWidth = 1.2);

      // Body
      final top  = yP(isUp ? c.close : c.open);
      final bot  = yP(isUp ? c.open  : c.close);
      final bh   = math.max(bot - top, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - candleW / 2, top, candleW, bh), const Radius.circular(1)),
        p,
      );

      // Volume bar
      if (maxVol > 0 && c.volume > 0) {
        final vh = (c.volume / maxVol) * (volH - 2);
        canvas.drawRect(
          Rect.fromLTWH(cx - candleW / 2, chartH + (volH - vh), candleW, vh),
          Paint()..color = col.withValues(alpha: 0.35),
        );
      }

      // Hovered highlight
      if (hovered != null && hovered!.time == c.time) {
        canvas.drawLine(Offset(cx, _pad), Offset(cx, chartH),
            Paint()..color = Colors.grey.withValues(alpha: 0.4)..strokeWidth = 1);
        canvas.drawLine(Offset(0, yP(c.close)), Offset(chartW, yP(c.close)),
            Paint()..color = col.withValues(alpha: 0.5)..strokeWidth = 0.7..style = PaintingStyle.stroke);
      }
    }

    // ── Live price dashed line
    if (livePrice != null && livePrice! > 0) {
      final y     = yP(livePrice!);
      final isUp  = candles.isNotEmpty && livePrice! >= candles.last.open;
      final lCol  = isUp ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
      _dashed(canvas, Offset(0, y), Offset(chartW, y), lCol);
      // Price label on right axis
      final rect = Rect.fromLTWH(chartW + 1, y - 9, labelW - 3, 18);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = lCol);
      _text(canvas, livePrice!.toStringAsFixed(2), Offset(chartW + 3, y - 7), 8.5, Colors.white, bold: true);
    }
  }

  void _dashed(Canvas c, Offset s, Offset e, Color col) {
    final p = Paint()..color = col..strokeWidth = 1;
    double d = 0; const dash = 4.0, gap2 = 3.0;
    while (d < e.dx - s.dx) {
      c.drawLine(Offset(s.dx + d, s.dy), Offset(s.dx + math.min(d + dash, e.dx - s.dx), s.dy), p);
      d += dash + gap2;
    }
  }

  void _text(Canvas c, String t, Offset o, double sz, Color col, {bool bold = false}) {
    (TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: col, fontSize: sz,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, o);
  }

  @override
  bool shouldRepaint(_CandlePainter o) =>
      o.candles != candles || o.livePrice != livePrice ||
      o.scrollOffset != scrollOffset || o.hovered != hovered;
}

// ── Line painter ──────────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List<ChartCandle> candles;
  final double? livePrice;
  final double labelW;

  const _LinePainter({required this.candles, this.livePrice, required this.labelW});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.length < 2) return;
    final w = size.width - labelW;
    final prices = candles.map((c) => c.close).toList();
    double hi = prices.reduce((a, b) => a > b ? a : b);
    double lo = prices.reduce((a, b) => a < b ? a : b);
    if (livePrice != null) { hi = math.max(hi, livePrice!); lo = math.min(lo, livePrice!); }
    final range = (hi - lo).abs();
    if (range < 0.01) return;

    const pad = 8.0;
    double x(int i)    => i / (prices.length - 1) * w;
    double y(double v) => pad + (1 - (v - lo) / range) * (size.height - pad * 2);

    final isUp = prices.last >= prices.first;
    final col  = isUp ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

    // Grid
    for (int i = 0; i <= 4; i++) {
      final yy = pad + (size.height - pad * 2) * i / 4;
      canvas.drawLine(Offset(0, yy), Offset(w, yy),
          Paint()..color = Colors.grey.withValues(alpha: 0.08)..strokeWidth = 0.5);
      _text(canvas, (hi - range * i / 4).toStringAsFixed(2), Offset(w + 2, yy - 7));
    }

    final path = Path()..moveTo(x(0), y(prices[0]));
    for (int i = 1; i < prices.length; i++) { path.lineTo(x(i), y(prices[i])); }

    final fill = Path()..moveTo(0, size.height)..lineTo(x(0), y(prices[0]));
    for (int i = 1; i < prices.length; i++) { fill.lineTo(x(i), y(prices[i])); }
    fill.lineTo(w, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(colors: [col.withValues(alpha: 0.3), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, w, size.height))
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = col..strokeWidth = 1.5..style = PaintingStyle.stroke);

    if (livePrice != null && livePrice! > 0) {
      final yy   = y(livePrice!);
      final lCol = livePrice! >= prices.first ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
      _dashed(canvas, Offset(0, yy), Offset(w, yy), lCol);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w + 1, yy - 9, labelW - 3, 18), const Radius.circular(3)),
          Paint()..color = lCol);
      _text(canvas, livePrice!.toStringAsFixed(2), Offset(w + 3, yy - 7), color: Colors.white, bold: true);
    }
  }

  void _dashed(Canvas c, Offset s, Offset e, Color col) {
    final p = Paint()..color = col..strokeWidth = 1;
    double d = 0;
    while (d < e.dx - s.dx) {
      c.drawLine(Offset(s.dx + d, s.dy), Offset(s.dx + math.min(d + 4, e.dx - s.dx), s.dy), p);
      d += 7;
    }
  }

  void _text(Canvas c, String t, Offset o, {double sz = 8.5, Color color = Colors.grey, bool bold = false}) {
    (TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: color, fontSize: sz, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, o);
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.candles != candles || o.livePrice != livePrice;
}

// ── OHLC tooltip ──────────────────────────────────────────────────────────────
class _OhlcTooltip extends StatelessWidget {
  final ChartCandle candle;
  const _OhlcTooltip({required this.candle});

  @override
  Widget build(BuildContext context) {
    final isUp  = candle.close >= candle.open;
    final color = isUp ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colorz.bottomPillBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colorz.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell('O', candle.open,  color),
          const SizedBox(width: 8),
          _cell('H', candle.high,  const Color(0xFF26A69A)),
          const SizedBox(width: 8),
          _cell('L', candle.low,   const Color(0xFFEF5350)),
          const SizedBox(width: 8),
          _cell('C', candle.close, color),
        ],
      ),
    );
  }

  Widget _cell(String label, double val, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
        Text(val.toStringAsFixed(2), style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────
class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Btn(this.label, this.icon, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colorz.primary : Colorz.bottomPillBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : Colorz.hintTextColor),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.medium.copyWith(
              fontSize: SizeConfig.smallerFont,
              color: active ? Colors.white : Colorz.hintTextColor,
            )),
          ],
        ),
      ),
    );
  }
}
