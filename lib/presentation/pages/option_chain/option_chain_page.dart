import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:investapas/presentation/bloc/option_chain/option_chain_bloc.dart';
import 'package:investapas/presentation/bloc/option_chain/option_chain_state.dart';
import 'package:investapas/presentation/bloc/option_chain/option_change_event.dart';
import 'package:investapas/presentation/pages/option_chain/widget/option_info_widget.dart';
import 'package:investapas/presentation/pages/option_chain/widget/option_ltp_widget.dart';
import 'package:investapas/presentation/pages/option_chain/widget/option_oi_widget.dart';

import '../../../Widgets/Widgets.dart';
import '../../../Widgets/app_background.dart';
import '../../../Widgets/circle_widget.dart';
import '../../../Widgets/common_dropdown.dart';
import '../../../data/models/market_item.dart';
import '../../../Widgets/common_textfield.dart';
import '../../../Widgets/live_price_widget.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/navigationService.dart';
import '../../../data/models/option_chain_model.dart';
import '../../../routes/appRoutes.dart';
import '../trade_sheet/trade_sheet.dart';
import '../../bloc/stock_details/stock_details_bloc.dart';
import '../../bloc/stock_details/stock_details_event.dart';
import '../../bloc/stock_details/stock_details_state.dart';

class OptionChainPage extends StatefulWidget {
  const OptionChainPage({super.key});

  @override
  State<OptionChainPage> createState() => _OptionChainPageState();
}

class _OptionChainPageState extends State<OptionChainPage> {
  late final TextEditingController searchController;

  // Selected option (CE or PE from a row tap)
  String? _selectedSecId;
  String? _selectedName;
  String? _selectedExchangeSegment;
  bool _selectedIsCe = true;

  void _selectCe(OptionChainModel item, StockDetailsState sState) {
    if (item.callSecId.isEmpty) return;
    setState(() {
      _selectedSecId = item.callSecId;
      _selectedName  = '${_underlying(sState)} ${item.strike} CE';
      _selectedExchangeSegment = _getApiSegment(sState.marketItem?.exchange ?? '', sState.exchangeSegment);
      _selectedIsCe  = true;
    });
  }

  void _selectPe(OptionChainModel item, StockDetailsState sState) {
    if (item.putSecId.isEmpty) return;
    setState(() {
      _selectedSecId = item.putSecId;
      _selectedName  = '${_underlying(sState)} ${item.strike} PE';
      _selectedExchangeSegment = _getApiSegment(sState.marketItem?.exchange ?? '', sState.exchangeSegment);
      _selectedIsCe  = false;
    });
  }

  String _underlying(StockDetailsState s) =>
      s.displayName.split(' ').first;

  String _getApiSegment(String exchange, String segment) {
    final exch = exchange.toUpperCase();
    final seg  = segment.toUpperCase();
    if (seg == 'BSE_FNO' || seg == 'NSE_FNO') return seg;
    if (seg == 'D' && exch == 'BSE') return 'BSE_FNO';
    if (seg == 'D') return 'NSE_FNO';
    return 'NSE_FNO';
  }

  void _onBuy(StockDetailsState sState) {
    if (_selectedSecId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a CE or PE row to select an option first')));
      return;
    }
    final item = MarketItem(
      securityId: _selectedSecId!,
      name: _selectedName ?? '',
      symbol: _selectedName ?? '',
      exchangeSegment: _selectedExchangeSegment ?? 'NSE_FNO',
      exchange: sState.marketItem?.exchange ?? 'NSE',
      lotSize: sState.marketItem?.lotSize ?? '1',
      isUp: true,
    );
    TradeSheet.show(context, item: item, isBuy: true);
  }

  void _onSell(StockDetailsState sState) {
    if (_selectedSecId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a CE or PE row to select an option first')));
      return;
    }
    final item = MarketItem(
      securityId: _selectedSecId!,
      name: _selectedName ?? '',
      symbol: _selectedName ?? '',
      exchangeSegment: _selectedExchangeSegment ?? 'NSE_FNO',
      exchange: sState.marketItem?.exchange ?? 'NSE',
      lotSize: sState.marketItem?.lotSize ?? '1',
      isUp: false,
    );
    TradeSheet.show(context, item: item, isBuy: false);
  }

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sBloc = context.read<StockDetailsBloc>();
      // Always reload expiry dates when this page opens
      sBloc.add(LoadExpiryDatesEvent());
      // If option chain already loaded, sync immediately
      if (sBloc.state.optionStrikes.isNotEmpty) {
        _syncData(sBloc.state);
      }
    });
    searchController.addListener(() {
      context.read<OptionChainBloc>().add(
        SearchOptionList(searchController.text),
      );
    });
  }

  void _syncData(StockDetailsState s) {
    final items = s.optionStrikes.map((strike) {
      return OptionChainModel(
        strike: strike.strike.toStringAsFixed(0),
        callOi:     _fmt(strike.ce?['oi']),
        putOi:      _fmt(strike.pe?['oi']),
        callVolume: _fmt(strike.ce?['last_price']),  // LTP tab uses callVolume as CE ltp
        putVolume:  _fmt(strike.pe?['last_price']),  // LTP tab uses putVolume as PE ltp
        callSecId:  strike.ce?['security_id']?.toString() ?? '',
        putSecId:   strike.pe?['security_id']?.toString() ?? '',
        changeOi:   _fmtChange(strike.ce?['oi'], strike.ce?['previous_oi']),
        isAtm: s.lastPrice > 0 && (strike.strike - s.lastPrice).abs() < 200,
      );
    }).toList();
    context.read<OptionChainBloc>().add(SetOptionData(items));
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = (v as num).toDouble();
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000)   return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)     return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
  }

  String _fmtChange(dynamic current, dynamic previous) {
    if (current == null || previous == null) return '—';
    final diff = (current as num) - (previous as num);
    return diff >= 0 ? '+${diff.toInt()}' : diff.toInt().toString();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: BlocConsumer<StockDetailsBloc, StockDetailsState>(
            listenWhen: (prev, curr) =>
                prev.optionStrikes != curr.optionStrikes &&
                curr.optionStrikes.isNotEmpty,
            listener: (context, sState) => _syncData(sState),
            builder: (context, sState) {
              return BlocBuilder<OptionChainBloc, OptionChainState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(top: 50.sp),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Back button
                              InkWell(
                                onTap: () => NavigatorService.goBack(),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
                                  child: CircleWidget(
                                    backgroundColor: Colorz.white,
                                    child: Icon(Icons.arrow_back_rounded, color: Colorz.hintTextColor2),
                                  ),
                                ),
                              ),
                              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),

                              // ── Title + expiry picker
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Option Chain",
                                              style: AppTextStyles.semiBold.copyWith(
                                                  fontSize: SizeConfig.headerTwoFont,
                                                  color: Colorz.textColor)),
                                          Text("See full Option Chain for free",
                                              style: AppTextStyles.semiBold.copyWith(
                                                  fontSize: SizeConfig.smallFont,
                                                  color: Colorz.primary,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: Colorz.primary)),
                                        ],
                                      ),
                                    ),
                                    // Expiry dropdown — uses real dates from StockDetailsBloc
                                    if (sState.availableExpiries.isNotEmpty)
                                      SizedBox(
                                        width: 110.sp,
                                        child: CustomDropdown(
                                          selectedValue: sState.availableExpiries.contains(sState.selectedExpiry)
                                              ? sState.selectedExpiry
                                              : sState.availableExpiries.first,
                                          hintText: "Expiry",
                                          borderColor: Colorz.dividerColor,
                                          items: sState.availableExpiries.map((e) =>
                                              DropdownMenuItem<String>(
                                                value: e,
                                                child: Text(_shortExpiry(e),
                                                    style: AppTextStyles.medium.copyWith(
                                                        fontSize: SizeConfig.smallFont)),
                                              )
                                          ).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              context.read<StockDetailsBloc>().add(ChangeOptionExpiryEvent(value));
                                            }
                                          },
                                        ),
                                      )
                                    else if (sState.isOptionChainLoading)
                                      SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colorz.primary),
                                      ),
                                  ],
                                ),
                              ),
                              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),

                              // ── Search bar
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
                                child: CommonTextfield(
                                  controller: searchController,
                                  hintText: "Search strike...",
                                  prefixWidget: SvgPicture.asset(Assets.searchSvg, width: 15.sp, height: 15.sp),
                                  suffixWidget: sState.lastPrice > 0
                                      ? Text(sState.lastPrice.toStringAsFixed(2),
                                          style: AppTextStyles.semiBold.copyWith(
                                              color: Colorz.greenColor,
                                              fontSize: SizeConfig.smallerFont))
                                      : null,
                                  onChanged: (value) =>
                                      context.read<OptionChainBloc>().add(SearchOptionList(value)),
                                ),
                              ),

                              // ── Expiry date tabs (filter by expiry)
                              if (sState.availableExpiries.isNotEmpty)
                                _buildExpiryTabs(context, sState),
                              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 0.5),

                              // ── LTP / OI / Info tabs
                              _buildTopTabs(context, state),
                              SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),

                              // ── Tab content
                              Expanded(
                                child: sState.isOptionChainLoading
                                    ? const Center(
                                  child: CircularProgressIndicator(color: Colorz.primary),
                                )

                                    : sState.optionChainError.isNotEmpty
                                    ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        sState.optionChainError,
                                        style: AppTextStyles.medium.copyWith(
                                          color: Colorz.redColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizeConfig.verticalSpace(
                                        height: SizeConfig.spaceBetween,
                                      ),

                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<StockDetailsBloc>().add(
                                            LoadOptionChainEvent(
                                              sState.selectedExpiry,
                                            ),
                                          );
                                        },
                                        child: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                )

                                    : state.visibleItems.isEmpty
                                    ? Center(
                                  child: Text(
                                    "No Option Chain Data",
                                    style: AppTextStyles.medium.copyWith(
                                      color: Colorz.textColor,
                                    ),
                                  ),
                                )

                                    : _buildTabView(state, sState),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom bar (same as original)
                      Container(
                        decoration: BoxDecoration(
                          color: Colorz.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36.sp),
                            topRight: Radius.circular(36.sp),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween),
                              child: Text(
                                // Show selected option name, else current stock
                                _selectedName ?? (sState.displayName.isNotEmpty ? sState.displayName : "Select an option"),
                                style: AppTextStyles.medium.copyWith(
                                    fontSize: SizeConfig.largeFont, color: Colorz.textColor),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween),
                              child: Row(
                                children: [
                                  Text("NFO  ",
                                      style: AppTextStyles.medium.copyWith(
                                          fontSize: SizeConfig.smallFont, color: Colorz.textColor)),
                                  // Show live price of selected option
                                  if (_selectedSecId != null)
                                    LivePriceWidget(
                                      securityId: _selectedSecId!,
                                      style: AppTextStyles.semiBold.copyWith(
                                          fontSize: SizeConfig.smallFont,
                                          color: _selectedIsCe ? Colorz.greenColor : Colorz.redColor),
                                    )
                                  else if (sState.securityId.isNotEmpty)
                                    LivePriceWidget(
                                      securityId: sState.securityId,
                                      style: AppTextStyles.semiBold.copyWith(
                                          fontSize: SizeConfig.smallFont, color: Colorz.primary),
                                    )
                                  else
                                    Text("Tap a row to select",
                                        style: AppTextStyles.medium.copyWith(
                                            fontSize: SizeConfig.smallFont, color: Colorz.hintTextColor)),
                                ],
                              ),
                            ),
                            SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
                            Divider(color: Colorz.dividerColor),
                            SizeConfig.verticalSpace(height: SizeConfig.spaceBetween),
                            _buildBottomTabs(),
                            SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Button(
                                      text: 'Sell', isOutlined: true, isBig: true, radius: 100,
                                      valueColor: Colorz.primary, textColor: Colorz.primary,
                                      buttonColor: Colors.transparent,
                                      onPressed: () => _onSell(sState),
                                    ),
                                  ),
                                  SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween * 0.5),
                                  Expanded(
                                    child: Button(
                                      text: 'Buy', isOutlined: false, isBig: true, radius: 100,
                                      gradient: Colorz.primaryButtonGradient,
                                      onPressed: () => _onBuy(sState),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizeConfig.verticalSpace(height: SizeConfig.spaceBetween * 2),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Converts "2026-05-26" → "26 May"
  String _shortExpiry(String expiry) {
    try {
      final date = DateTime.parse(expiry.split('T').first);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return expiry.split('T').first;
    }
  }

  // ── Expiry date horizontal tabs ──────────────────────────────────────────
  Widget _buildExpiryTabs(BuildContext context, StockDetailsState sState) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 2),
        itemCount: sState.availableExpiries.length,
        separatorBuilder: (_, __) => SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween * 0.5),
        itemBuilder: (context, i) {
          final expiry   = sState.availableExpiries[i];
          final isActive = sState.selectedExpiry == expiry ||
              (sState.selectedExpiry.startsWith(expiry) || expiry.startsWith(sState.selectedExpiry));
          final label    = _shortExpiry(expiry);

          return GestureDetector(
            onTap: () {
              context.read<StockDetailsBloc>().add(ChangeOptionExpiryEvent(expiry));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colorz.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? Colorz.primary : Colorz.dividerColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.semiBold.copyWith(
                  color: isActive ? Colorz.white : Colorz.hintTextColor,
                  fontSize: SizeConfig.smallFont,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context, OptionChainState state) {
    Widget tab(String text, optionTab t) {
      final active = state.marketTab == t;
      return Expanded(
        child: InkWell(
          onTap: () => context.read<OptionChainBloc>().add(ChangeOptionTab(t)),
          child: Column(
            children: [
              Text(text, style: AppTextStyles.semiBold.copyWith(
                  color: active ? Colorz.textColor : Colorz.hintTextColor,
                  fontSize: SizeConfig.largeFont)),
              const SizedBox(height: 8),
              AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 3, width: double.infinity,
                  color: active ? Colorz.primary : Colors.transparent),
            ],
          ),
        ),
      );
    }

    return Row(children: [
      tab("LTP", optionTab.ltp),
      tab("OI", optionTab.oi),
      tab("Info", optionTab.info),
    ]);
  }

  Widget _buildTabView(OptionChainState state, StockDetailsState sState) {
    switch (state.marketTab) {
      case optionTab.ltp:
        return OptionLtpWidget(
          optionChainState: state,
          onTapCe: (item) => _selectCe(item, sState),
          onTapPe: (item) => _selectPe(item, sState),
          selectedSecId: _selectedSecId,
        );
      case optionTab.oi:
        return OptionOiWidget(
          optionChainState: state,
          onTapCe: (item) => _selectCe(item, sState),
          onTapPe: (item) => _selectPe(item, sState),
          selectedSecId: _selectedSecId,
        );
      case optionTab.info:
        return OptionInfoWidget(optionChainState: state);
    }
  }

  Widget _buildBottomTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.sp),
      child: Row(
        children: [
          _item(Assets.ordersSvg, "Charts", 15,
              onTap: () => NavigatorService.goBack()), // go back to stock details chart
          _item(Assets.linkSvg, "Option Chain", 15,
              onTap: () {}), // already on this page
          _item(Assets.watchlistSvg, "Watchlist", 15,
              onTap: () => NavigatorService.pushNamed(AppRoutes.watchListPage)),
        ],
      ),
    );
  }

  Widget _item(String svgIcon, String text, double size, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colorz.textColor, width: 1)),
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.spaceBetween * 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(svgIcon, height: size, width: size, fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(Colorz.hintTextColor2, BlendMode.srcIn)),
              SizeConfig.horizontalSpace(width: SizeConfig.spaceBetween * 0.5),
              Text(text, style: AppTextStyles.medium.copyWith(
                  fontSize: SizeConfig.smallFont, color: Colorz.hintTextColor2)),
            ],
          ),
        ),
      ),
    );
  }
}
