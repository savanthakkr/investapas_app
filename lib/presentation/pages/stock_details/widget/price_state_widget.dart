import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:investapas/core/constants/constants.dart';
import '../../../../data/models/chart_data.dart';

class PriceStateWidget extends StatelessWidget {
  final List<ChartCandle> candles;
  const PriceStateWidget({super.key, this.candles = const []});

  @override
  Widget build(BuildContext context) {
    // Compute OHLC from candles
    double open      = 0, high = 0, low = 0, prevClose = 0;
    double weekHigh  = 0, weekLow = double.maxFinite;

    if (candles.isNotEmpty) {
      open      = candles.first.open;
      high      = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      low       = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      prevClose = candles.last.close;

      // 52W high/low from all candles
      weekHigh = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      weekLow  = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    }

    String fmt(double v) {
      if (v == 0 || v == double.maxFinite || v.isInfinite || v.isNaN) return '—';
      return v.toStringAsFixed(2);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.sp),
        color: Colorz.bottomPillBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Stats",
            style: AppTextStyles.semiBold.copyWith(color: Colorz.textColor, fontSize: SizeConfig.headerThreeFont),
          ),
          SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
          _row([
            _stat("Open",  fmt(open)),
            _stat("High",  fmt(high),  Colorz.greenColor),
            _stat("Low",   fmt(low),   Colorz.redColor),
          ]),
          SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 0.5),
          Divider(color: Colorz.textFieldBorderColor),
          SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 0.5),
          _row([
            _stat("Prev Close", fmt(prevClose)),
            _stat("52W High",   fmt(weekHigh), Colorz.greenColor),
            _stat("52W Low",    fmt(weekLow),  Colorz.redColor),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: children.map((w) => Expanded(child: w)).toList(),
  );

  Widget _stat(String label, String value, [Color? valueColor]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.medium.copyWith(color: Colorz.textColor)),
      SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 0.5),
      Text(value, style: AppTextStyles.medium.copyWith(color: valueColor ?? Colorz.hintTextColor)),
    ],
  );
}
