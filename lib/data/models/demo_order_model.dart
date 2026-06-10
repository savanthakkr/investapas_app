class DemoOrderModel {
  final int id;
  final String securityId;
  final String tradingSymbol;
  final String exchangeSegment;
  final String transactionType;
  final String orderType;      // MARKET | LIMIT | SUPER
  final int quantity;
  final double price;
  final double targetPrice;
  final double stopLossPrice;
  final double trailingJump;
  final String orderStatus;
  final String createdAt;

  const DemoOrderModel({
    required this.id,
    required this.securityId,
    required this.tradingSymbol,
    required this.exchangeSegment,
    required this.transactionType,
    required this.orderType,
    required this.quantity,
    required this.price,
    this.targetPrice   = 0,
    this.stopLossPrice = 0,
    this.trailingJump  = 0,
    required this.orderStatus,
    required this.createdAt,
  });

  bool get isBuy    => transactionType == 'BUY';
  bool get isTraded => orderStatus == 'TRADED';
  bool get isSuper  => orderType == 'SUPER';
  double get amount => price * quantity;

  factory DemoOrderModel.fromJson(Map<String, dynamic> j) => DemoOrderModel(
    id:              j['id'] as int? ?? 0,
    securityId:      j['security_id']?.toString() ?? '',
    tradingSymbol:   j['trading_symbol']?.toString() ?? '',
    exchangeSegment: j['exchange_segment']?.toString() ?? '',
    transactionType: j['transaction_type']?.toString() ?? '',
    orderType:       j['order_type']?.toString() ?? 'MARKET',
    quantity:        int.tryParse(j['quantity']?.toString() ?? '0') ?? 0,
    price:           double.tryParse(j['price']?.toString() ?? '0') ?? 0.0,
    targetPrice:     double.tryParse(j['target_price']?.toString() ?? '0') ?? 0.0,
    stopLossPrice:   double.tryParse(j['stop_loss_price']?.toString() ?? '0') ?? 0.0,
    trailingJump:    double.tryParse(j['trailing_jump']?.toString() ?? '0') ?? 0.0,
    orderStatus:     j['order_status']?.toString() ?? '',
    createdAt:       j['created_at']?.toString() ?? '',
  );
}

class DemoPositionModel {
  final String securityId;
  final String tradingSymbol;
  final String exchangeSegment;
  final int netQuantity;
  final double avgBuyPrice;

  // Filled by frontend from LivePriceService
  double currentLtp;

  DemoPositionModel({
    required this.securityId,
    required this.tradingSymbol,
    required this.exchangeSegment,
    required this.netQuantity,
    required this.avgBuyPrice,
    this.currentLtp = 0,
  });

  double get unrealizedPnl  => (currentLtp - avgBuyPrice) * netQuantity;
  double get investedAmount => avgBuyPrice * netQuantity;
  double get currentValue   => currentLtp * netQuantity;
  double get pnlPercent     =>
      avgBuyPrice > 0 ? ((currentLtp - avgBuyPrice) / avgBuyPrice) * 100 : 0;

  factory DemoPositionModel.fromJson(Map<String, dynamic> j) => DemoPositionModel(
    securityId:      j['securityId']?.toString() ?? '',
    tradingSymbol:   j['tradingSymbol']?.toString() ?? '',
    exchangeSegment: j['exchangeSegment']?.toString() ?? '',
    netQuantity:     int.tryParse(j['netQuantity']?.toString() ?? '0') ?? 0,
    avgBuyPrice:     double.tryParse(j['avgBuyPrice']?.toString() ?? '0') ?? 0.0,
  );
}

// Represents a closed position — used for all-time realized P&L display
class DemoClosedPositionModel {
  final String securityId;
  final String tradingSymbol;
  final String exchangeSegment;
  final int qty;
  final double avgBuyPrice;
  final double avgSellPrice;
  final double pnl;
  final bool isToday;

  const DemoClosedPositionModel({
    required this.securityId,
    required this.tradingSymbol,
    required this.exchangeSegment,
    required this.qty,
    required this.avgBuyPrice,
    required this.avgSellPrice,
    required this.pnl,
    this.isToday = false,
  });

  bool get isProfit => pnl >= 0;
  double get pnlPercent =>
      avgBuyPrice > 0 ? ((avgSellPrice - avgBuyPrice) / avgBuyPrice) * 100 : 0;

  factory DemoClosedPositionModel.fromJson(Map<String, dynamic> j) =>
      DemoClosedPositionModel(
        securityId:      j['securityId']?.toString() ?? '',
        tradingSymbol:   j['tradingSymbol']?.toString() ?? '',
        exchangeSegment: j['exchangeSegment']?.toString() ?? '',
        qty:             int.tryParse(j['qty']?.toString() ?? '0') ?? 0,
        avgBuyPrice:     double.tryParse(j['avgBuyPrice']?.toString() ?? '0') ?? 0.0,
        avgSellPrice:    double.tryParse(j['avgSellPrice']?.toString() ?? '0') ?? 0.0,
        pnl:             double.tryParse(j['pnl']?.toString() ?? '0') ?? 0.0,
        isToday:         j['isToday'] == true || j['isToday'] == 1,
      );
}
