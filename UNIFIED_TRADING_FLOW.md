# Unified Trading Flow Implementation Guide
**Goal**: Single buy/sell/modify flow for both Real (Dhan) and Demo trading

---

## Overview
Instead of maintaining separate screens and logic, we'll:
1. **Keep existing screens** (no UI changes)
2. **Create a unified service layer** that routes API calls
3. **Use demo mode flag** to decide: call Dhan API or Demo API
4. **Share portfolio, order management across both modes**

---

## Architecture Pattern

```
BuyScreen/SellScreen/PortfolioScreen
        ↓
  UnifiedTradingService
        ↓
    ┌───┴───┐
    ↓       ↓
  Real API  Demo API
 (Dhan)    (Local DB)
```

---

## Implementation Steps

### Step 1: Create Unified Trading Service
**File**: `lib/core/services/unified_trading_service.dart`

This service will:
- Check if demo mode is active
- Route all order operations (buy, sell, modify) to appropriate API
- Return unified response objects
- Manage portfolio data from both sources

```dart
class UnifiedTradingService {
  final DemoModeService _demoMode;
  final DhanService _dhanService;
  final DemoTradingService _demoService;

  // BUY ORDER
  Future<OrderResponse> buyOrder({
    required String symbol,
    required int quantity,
    required double price,
    required String orderType,
    required String? targetPrice,
    required String? stopLossPrice,
  }) async {
    if (_demoMode.isActive) {
      return _demoService.createOrder(
        type: 'BUY',
        symbol: symbol,
        quantity: quantity,
        price: price,
        orderType: orderType,
        targetPrice: targetPrice,
        stopLossPrice: stopLossPrice,
      );
    } else {
      return _dhanService.placeOrder(
        type: 'BUY',
        symbol: symbol,
        quantity: quantity,
        price: price,
        orderType: orderType,
        targetPrice: targetPrice,
        stopLossPrice: stopLossPrice,
      );
    }
  }

  // SELL ORDER
  Future<OrderResponse> sellOrder({
    required String symbol,
    required int quantity,
    required double price,
    required String orderType,
  }) async {
    if (_demoMode.isActive) {
      return _demoService.createOrder(
        type: 'SELL',
        symbol: symbol,
        quantity: quantity,
        price: price,
        orderType: orderType,
      );
    } else {
      return _dhanService.placeOrder(
        type: 'SELL',
        symbol: symbol,
        quantity: quantity,
        price: price,
        orderType: orderType,
      );
    }
  }

  // MODIFY ORDER
  Future<OrderResponse> modifyOrder({
    required String orderId,
    required double newPrice,
    required int newQuantity,
  }) async {
    if (_demoMode.isActive) {
      return _demoService.modifyOrder(orderId, newPrice, newQuantity);
    } else {
      return _dhanService.modifyOrder(orderId, newPrice, newQuantity);
    }
  }

  // CANCEL ORDER
  Future<bool> cancelOrder(String orderId) async {
    if (_demoMode.isActive) {
      return _demoService.cancelOrder(orderId);
    } else {
      return _dhanService.cancelOrder(orderId);
    }
  }

  // GET PORTFOLIO (Positions)
  Future<List<Position>> getPortfolio() async {
    if (_demoMode.isActive) {
      return _demoService.getPositions();
    } else {
      return _dhanService.getPositions();
    }
  }

  // GET ORDERS
  Future<List<Order>> getOrders({String status = 'ALL'}) async {
    if (_demoMode.isActive) {
      return _demoService.getOrders(status);
    } else {
      return _dhanService.getOrders(status);
    }
  }

  // GET ORDER DETAILS
  Future<Order> getOrderDetails(String orderId) async {
    if (_demoMode.isActive) {
      return _demoService.getOrderDetails(orderId);
    } else {
      return _dhanService.getOrderDetails(orderId);
    }
  }
}
```

---

### Step 2: Update Backend API Endpoints

**Create unified endpoint prefix**: Instead of `/dhan/*` and `/demo/*`, create:
- `/api/trading/buy` - Routes to Dhan/Demo based on `mode` param
- `/api/trading/sell` - Routes to Dhan/Demo based on `mode` param
- `/api/trading/modify` - Routes to Dhan/Demo based on `mode` param
- `/api/trading/portfolio` - Routes to Dhan/Demo based on `mode` param

**File**: `routes/trading.js` (NEW)

```javascript
router.post('/trading/buy', async (req, res) => {
  const { mode, userId, symbol, quantity, price, orderType, targetPrice, stopLossPrice } = req.body;
  
  if (mode === 'DEMO') {
    // Call DemoController.createOrder()
    return DemoController.createOrder(req, res);
  } else {
    // Call DhanController.placeOrder()
    return DhanController.placeOrder(req, res);
  }
});

router.post('/trading/sell', async (req, res) => {
  const { mode } = req.body;
  if (mode === 'DEMO') {
    return DemoController.createOrder(req, res);
  } else {
    return DhanController.placeOrder(req, res);
  }
});

router.post('/trading/modify', async (req, res) => {
  const { mode, orderId, newPrice, newQuantity } = req.body;
  if (mode === 'DEMO') {
    return DemoController.modifyOrder(req, res);
  } else {
    return DhanController.modifyOrder(req, res);
  }
});

router.get('/trading/portfolio', async (req, res) => {
  const { mode, userId } = req.query;
  if (mode === 'DEMO') {
    return DemoController.getPortfolio(req, res);
  } else {
    return DhanController.getPortfolio(req, res);
  }
});

router.get('/trading/orders', async (req, res) => {
  const { mode } = req.query;
  if (mode === 'DEMO') {
    return DemoController.getOrders(req, res);
  } else {
    return DhanController.getOrders(req, res);
  }
});
```

---

### Step 3: Update Flutter Screens to Use Unified Service

**BUY SCREEN** - `lib/presentation/screens/buy_screen.dart`

```dart
class BuyScreen extends StatelessWidget {
  final UnifiedTradingService _tradingService;

  Future<void> _placeBuyOrder(String symbol, int qty, double price) async {
    try {
      final response = await _tradingService.buyOrder(
        symbol: symbol,
        quantity: qty,
        price: price,
        orderType: 'MARKET',
        targetPrice: targetPrice, // Optional
        stopLossPrice: stopLossPrice, // Optional
      );
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed successfully'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }
}
```

**SELL SCREEN** - `lib/presentation/screens/sell_screen.dart`

```dart
class SellScreen extends StatelessWidget {
  final UnifiedTradingService _tradingService;

  Future<void> _placeSellOrder(String symbol, int qty, double price) async {
    final response = await _tradingService.sellOrder(
      symbol: symbol,
      quantity: qty,
      price: price,
      orderType: 'MARKET',
    );
    // Handle response
  }
}
```

**PORTFOLIO SCREEN** - `lib/presentation/screens/portfolio_screen.dart`

```dart
class PortfolioScreen extends StatefulWidget {
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final UnifiedTradingService _tradingService = UnifiedTradingService();
  late Future<List<Position>> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _refreshPortfolio();
  }

  void _refreshPortfolio() {
    setState(() {
      _portfolioFuture = _tradingService.getPortfolio();
    });
  }

  Future<void> _navigateToSell(Position position) async {
    // Open sell screen with pre-filled position details
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellScreen(position: position),
      ),
    );
    
    if (result == true) {
      _refreshPortfolio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Position>>(
      future: _portfolioFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final position = snapshot.data![index];
              return ListTile(
                title: Text(position.symbol),
                subtitle: Text('Qty: ${position.quantity}'),
                trailing: ElevatedButton(
                  onPressed: () => _navigateToSell(position),
                  child: Text('SELL'),
                ),
              );
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

**ORDER DETAILS SCREEN** - `lib/presentation/screens/order_details_screen.dart`

```dart
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  
  const OrderDetailsScreen({required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final UnifiedTradingService _tradingService = UnifiedTradingService();
  late Future<Order> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    _orderDetailsFuture = _tradingService.getOrderDetails(widget.orderId);
  }

  Future<void> _modifyOrder(double newPrice, int newQty) async {
    final response = await _tradingService.modifyOrder(
      orderId: widget.orderId,
      newPrice: newPrice,
      newQuantity: newQty,
    );
    
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order modified successfully'))
      );
      setState(() {
        _orderDetailsFuture = _tradingService.getOrderDetails(widget.orderId);
      });
    }
  }

  Future<void> _cancelOrder() async {
    final result = await _tradingService.cancelOrder(widget.orderId);
    if (result) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: FutureBuilder<Order>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final order = snapshot.data!;
            return Column(
              children: [
                ListTile(title: Text('Symbol: ${order.symbol}')),
                ListTile(title: Text('Quantity: ${order.quantity}')),
                ListTile(title: Text('Price: ${order.price}')),
                ListTile(title: Text('Status: ${order.status}')),
                if (order.status == 'PENDING')
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _modifyOrder(order.price + 5, order.quantity),
                        child: Text('MODIFY'),
                      ),
                      ElevatedButton(
                        onPressed: _cancelOrder,
                        child: Text('CANCEL'),
                      ),
                    ],
                  ),
              ],
            );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
```

---

### Step 4: Demo Mode Toggle (Already Exists - No Changes Needed)

Your existing `DemoModeService` will work perfectly:

```dart
// In your app settings or dashboard
ListenableBuilder(
  listenable: DemoModeService.instance,
  builder: (context, child) {
    return Switch(
      value: DemoModeService.instance.isActive,
      onChanged: (value) {
        DemoModeService.instance.setActive(value);
        // Automatically routes future API calls to demo/real
      },
    );
  },
)
```

---

## Data Flow Diagram

```
User toggles Demo Mode ON/OFF
        ↓
DemoModeService._active = true/false
        ↓
UnifiedTradingService checks mode
        ↓
┌───────────────────┐
Demo Mode = true    Demo Mode = false
    ↓                   ↓
Demo API Routes      Dhan API Routes
(DemoController)     (DhanController)
    ↓                   ↓
demo_orders table   Dhan API endpoints
    ↓                   ↓
Simulated profit    Real market prices
    ↓                   ↓
Deduct from coins   Deduct from wallet
```

---

## Key Benefits

✅ **Same UI screens** - No duplication  
✅ **Single logic flow** - Easier to maintain  
✅ **Conditional API calls** - Demo/Real seamless switch  
✅ **Shared portfolio screens** - Works for both modes  
✅ **Buy → Sell → Modify** - Same flow everywhere  
✅ **Challenge integration** - Works on top of real trading  

---

## Implementation Checklist

- [ ] Create `UnifiedTradingService` class
- [ ] Create unified backend routes (`/api/trading/*`)
- [ ] Update `BuyScreen` to use `UnifiedTradingService`
- [ ] Update `SellScreen` to use `UnifiedTradingService`
- [ ] Update `PortfolioScreen` to display positions from unified service
- [ ] Update `OrderDetailsScreen` to show modify/cancel options
- [ ] Add `mode` parameter to all API requests
- [ ] Test: Buy in demo mode → Check coins deducted
- [ ] Test: Buy in real mode → Check Dhan API called
- [ ] Test: Sell from portfolio → Check both modes work
- [ ] Test: Modify order → Check both modes work
- [ ] Test: Switch modes → Verify correct API called

---

## Testing Scenarios

| Scenario | Expected Result |
|----------|-----------------|
| Buy 1 share (DEMO ON) | Coins deducted, demo_orders created |
| Buy 1 share (DEMO OFF) | Dhan API called, real order placed |
| Sell position (DEMO ON) | Coins returned, position closed |
| Sell position (DEMO OFF) | Dhan API called, position sold |
| Modify order (DEMO ON) | demo_orders updated |
| Modify order (DEMO OFF) | Dhan API modification called |
| Switch DEMO ON→OFF | Next order uses Dhan API |
| Portfolio load | Shows correct positions for active mode |

---

## Files to Modify/Create

### NEW FILES
- `lib/core/services/unified_trading_service.dart`
- `routes/trading.js` (or add to existing routes)

### MODIFY FILES
- `lib/presentation/screens/buy_screen.dart`
- `lib/presentation/screens/sell_screen.dart`
- `lib/presentation/screens/portfolio_screen.dart`
- `lib/presentation/screens/order_details_screen.dart`
- `app.js` (add new routes)

### NO CHANGES NEEDED
- `DemoModeService` ✅ (already exists)
- Database schema ✅ (already supports both)
- Challenge system ✅ (already integrated)

---

## Next Steps

1. **Start with UnifiedTradingService** - This is the core layer
2. **Update backend routes** - Add routing logic
3. **Update screens one by one** - BuyScreen → SellScreen → PortfolioScreen
4. **Test each screen** in both modes
5. **Deploy with confidence** - Same code, different APIs!

Would you like me to implement any of these files? Just let me know which one to start with!
