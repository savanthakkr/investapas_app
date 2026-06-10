# Super Orders Integration - Visual Architecture

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     INVESTAPAS FLUTTER APP                       │
└─────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            ┌───────▼────────┐        ┌──────▼──────────┐
            │   ORDER PAGE   │        │ OTHER PAGES     │
            │  (order_page)  │        │                 │
            └───────┬────────┘        └─────────────────┘
                    │
       ┌────────────┼────────────┐
       │            │            │
    ┌──▼──┐   ┌─────▼────┐  ┌───▼────┐
    │List │   │ Details  │  │ Dialogs│
    │View │   │  Sheet   │  │        │
    └─────┘   └─────┬────┘  └───┬────┘
              ┌──────┼──────────┐
              │      │          │
              │  Modify  Cancel
              │  Dialog   Leg
              │           Dialog
              │
     ┌────────▼──────────────┐
     │   ORDER BLOC          │
     │  (order_bloc.dart)    │
     │                       │
     │ Events:              │
     │ - LoadOrders         │
     │ - LoadSuperOrders    │
     │ - ModifySuperOrder   │
     │ - CancelOrderLeg     │
     │ - ChangeOrderTab     │
     │ - ClearActionMsg     │
     └────────┬──────────────┘
              │
     ┌────────▼──────────────┐
     │   ORDER STATE         │
     │ (order_state.dart)    │
     │                       │
     │ - allOrders[]         │
     │ - superOrders[]       │
     │ - activeTab           │
     │ - isLoading           │
     │ - isActionLoading     │
     │ - actionMessage       │
     │ - actionSuccess       │
     └────────┬──────────────┘
              │
     ┌────────▼──────────────┐
     │   API SERVICE         │
     │ (api_service.dart)    │
     │                       │
     │ - get()              │
     │ - post()             │
     │ - put()              │
     │ - delete() [UPDATED] │
     └────────┬──────────────┘
              │
     ┌────────▼──────────────┐
     │   HTTP REQUESTS       │
     │                       │
     │ Headers:             │
     │ - Authorization      │
     │ - Content-Type       │
     │ - access-token       │
     └────────┬──────────────┘
              │
     ┌────────▼──────────────────────────────────┐
     │  DHAN API SERVER (Node.js Backend)        │
     │                                           │
     │  POST   /dhan/orders                      │
     │  POST   /dhan/super-orders                │
     │  PUT    /dhan/super-orders/:orderId       │
     │  DELETE /dhan/super-orders/:orderId/:leg  │
     └─────────────────────────────────────────┘
```

---

## 📊 Data Flow Diagram

### Loading Orders Flow
```
User Opens Order Page
    │
    ├─ OrderBloc receives LoadOrders event
    │  └─ Fetches from /dhan/orders
    │     └─ Returns List<OrderModel>
    │
    └─ OrderBloc receives LoadSuperOrders event
       └─ Fetches from /dhan/super-orders
          └─ Returns List<OrderModel> with legs
              │
              ├─ leg.displayName (Entry, Target, SL)
              ├─ leg.isPending (check status)
              └─ leg.legOrderId (for cancellation)

    Emits OrderState with:
    ├─ allOrders
    ├─ superOrders
    ├─ currentOrders (filtered by tab)
    └─ isLoading = false

    UI Renders Order List
    ├─ Regular orders
    └─ Super orders with badge
```

### Modify Order Flow
```
User Taps "Modify Order"
    │
    └─ ModifyDialog opens
       │
       ├─ Pre-fills with current values:
       │  ├─ quantity
       │  ├─ price
       │  ├─ targetPrice
       │  └─ stopLossPrice
       │
       └─ User edits and taps "Update"
          │
          └─ OrderBloc receives ModifySuperOrder
             │
             ├─ Builds payload with new values
             ├─ Adds dhanAccessToken
             │
             └─ Sends PUT /dhan/super-orders/:orderId
                │
                ├─ Success Response:
                │  └─ Emits actionSuccess = true
                │     └─ Auto-closes dialog
                │        └─ Triggers LoadSuperOrders
                │           └─ Order list refreshes
                │
                └─ Error Response:
                   └─ Emits actionSuccess = false
                      └─ Shows error message
                         └─ Dialog stays open
```

### Cancel Order Leg Flow
```
User Taps "Cancel Order Leg"
    │
    └─ Leg Selection Dialog opens
       │
       ├─ Shows pending legs only:
       │  ├─ Entry Leg
       │  ├─ Target Leg
       │  └─ Stop Loss Leg
       │
       └─ User selects leg
          │
          └─ OrderBloc receives CancelOrderLeg
             │
             ├─ Gets orderId and legOrderId
             │
             └─ Sends DELETE /dhan/super-orders/:orderId/:legOrderId
                │
                ├─ Success Response:
                │  └─ Emits actionSuccess = true
                │     └─ Shows success message
                │        └─ Closes details sheet
                │           └─ Triggers LoadSuperOrders
                │              └─ Order list refreshes
                │                 └─ Cancelled leg gone
                │
                └─ Error Response:
                   └─ Emits actionSuccess = false
                      └─ Shows error message
                         └─ Dialog stays open
```

---

## 🎨 UI Component Hierarchy

```
OrderPage (StatefulWidget)
│
├─ AppBackground
│  └─ Scaffold
│     │
│     ├─ Header
│     │  ├─ Back Button
│     │  ├─ Title "Orders"
│     │  └─ Tabs Widget
│     │     ├─ Tab "Open"
│     │     └─ Tab "Executed"
│     │
│     └─ Body (BLocBuilder<OrderBloc>)
│        │
│        ├─ Loading State
│        │  └─ CircularProgressIndicator
│        │
│        ├─ Error State
│        │  └─ Error Message
│        │
│        ├─ Empty State
│        │  ├─ Icon
│        │  ├─ "No orders" text
│        │  └─ Help message
│        │
│        └─ Data State
│           └─ ListView (Orders)
│              │
│              ├─ _OrderRow
│              │  ├─ BUY/SELL Badge
│              │  ├─ Symbol with "Super" badge
│              │  ├─ Type & Exchange
│              │  ├─ Quantity & Price
│              │  └─ Status Badge
│              │     └─ [TAP] → OrderDetailsSheet
│              │
│              └─ OrderDetailsSheet (StatefulWidget)
│                 │
│                 ├─ Header (Close Button)
│                 ├─ Order Info Card
│                 ├─ Basic Details
│                 ├─ [IF SUPER] Super Order Details
│                 │  └─ Order Legs
│                 │     └─ _LegRow (with cancel button)
│                 │
│                 └─ Action Buttons
│                    ├─ [IF SUPER] Modify Button → ModifyDialog
│                    └─ Cancel Leg Button → CancelLegDialog
│
├─ ModifyDialog (AlertDialog)
│  ├─ Close Button
│  ├─ Form Fields:
│  │  ├─ Quantity TextField
│  │  ├─ Price TextField
│  │  ├─ Target TextField
│  │  └─ Stop Loss TextField
│  │
│  └─ Update Button (Loading state)
│     └─ [SUBMIT] → OrderBloc.ModifySuperOrder
│
└─ CancelLegDialog (AlertDialog)
   ├─ Leg Selection List
   │  └─ Each leg as TextButton
   │     └─ [SELECT] → OrderBloc.CancelOrderLeg
   │
   └─ Cancel Button
```

---

## 🔄 State Management Flow

```
OrderState
├─ isLoading (bool)
│  ├─ true during initial fetch
│  └─ false when done
│
├─ allOrders (List<OrderModel>)
│  └─ Regular Dhan orders
│
├─ superOrders (List<OrderModel>)
│  └─ Super orders with legs
│
├─ activeTab (OrderTab enum)
│  ├─ open → shows pending/transit
│  └─ executed → shows traded/cancelled
│
├─ error (String)
│  └─ Error message from API
│
├─ isActionLoading (bool)
│  ├─ true during modify/cancel
│  └─ false when done
│
├─ actionMessage (String)
│  └─ Success/error from action
│
└─ actionSuccess (bool)
   ├─ true if last action succeeded
   └─ false if failed

Helper Getters:
├─ _combined → superOrders + allOrders
├─ openOrders → isOpen orders
├─ executedOrders → isExecuted orders
└─ currentOrders → filtered by activeTab
```

---

## 📱 Screen Breakdown

### Screen 1: Order List View
```
┌──────────────────────────────┐
│ ◄  ORDERS                    │
├──────────────────────────────┤
│   [OPEN]  [EXECUTED]         │
├──────────────────────────────┤
│                              │
│ ●   SBIN-EQ         Qty: 10 │
│ BUY • NSE           ₹450.50 │
│                     [PENDING]│
│                              │
│ ─────────────────────────────│
│                              │
│ ●   RELIANCE-EQ Super        │ ◄ Tap to see details
│     BUY • NSE       Qty: 5   │
│                     ₹2450    │
│                    [TRANSIT] │
│                              │
└──────────────────────────────┘
```

### Screen 2: Order Details (Bottom Sheet)
```
┌────────────────────────────────┐
│ ORDER DETAILS            ✕     │
├────────────────────────────────┤
│                                │
│  ● RELIANCE-EQ    Super [OPEN] │
│    BUY • NSE                   │
│                                │
│ Order ID: 789012               │
│ Quantity: 5                    │
│ Price: ₹2450                   │
│ Created: 2024-05-06 10:30      │
│                                │
│ SUPER ORDER DETAILS            │
│ ─────────────────────────────  │
│ Target Price: ₹2550            │
│ Stop Loss: ₹2400               │
│ Trailing Jump: 1.5%            │
│                                │
│ ORDER LEGS                     │
│ ─────────────────────────────  │
│ ▸ Entry      Qty: 5   [TRANSIT]│
│   ₹2450      [Cancel]          │
│                                │
│ ▸ Target     Qty: 5   [PENDING]│
│   ₹2550      [Cancel]          │
│                                │
│ ▸ Stop Loss  Qty: 5   [PENDING]│
│   ₹2400      [Cancel]          │
│                                │
│ ┌──────────────────────────────┐
│ │ [MODIFY ORDER]               │
│ ├──────────────────────────────┤
│ │ [CANCEL ORDER LEG]           │
│ └──────────────────────────────┘
│                                │
└────────────────────────────────┘
```

### Screen 3: Modify Order Dialog
```
┌─────────────────────────────┐
│ MODIFY ORDER           ✕    │
├─────────────────────────────┤
│                             │
│ Quantity                    │
│ [━━━━━━━━━5━━━━━━━━━]      │
│                             │
│ Price                       │
│ [━━━━━━2450━━━━━━━━━]      │
│                             │
│ Target Price                │
│ [━━━━━━2550━━━━━━━━━]      │
│                             │
│ Stop Loss                   │
│ [━━━━━━2400━━━━━━━━━]      │
│                             │
│ ┌─────────────────────────┐ │
│ │  [UPDATE ORDER]         │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

### Screen 4: Cancel Leg Dialog
```
┌──────────────────────────────┐
│ CANCEL ORDER LEG             │
├──────────────────────────────┤
│                              │
│ Select which order leg       │
│ to cancel:                   │
│                              │
│ [Entry]                      │ ← Tap to cancel
│ [Target]                     │ ← Tap to cancel
│ [Stop Loss]                  │ ← Tap to cancel
│                              │
│                 [Cancel]     │
│                              │
└──────────────────────────────┘
```

---

## 🎯 Key Integration Points

### 1. **Order Page Initialization**
```dart
@override
void initState() {
  super.initState();
  context.read<OrderBloc>().add(const LoadOrders());
  context.read<OrderBloc>().add(const LoadSuperOrders());
}
```
→ Loads both order types on page open

### 2. **Tapping Order Row**
```dart
InkWell(
  onTap: () => _showOrderDetails(context, order),
  child: _OrderRow(order: order),
)
```
→ Opens details sheet bottom sheet

### 3. **Modify Order Submission**
```dart
context.read<OrderBloc>().add(ModifySuperOrder(
  orderId: orderId,
  payload: {
    'quantity': qty,
    'price': price,
    'targetPrice': target,
    'stopLossPrice': sl,
  },
))
```
→ Triggers BLoC event with new values

### 4. **Cancel Leg Action**
```dart
context.read<OrderBloc>().add(CancelOrderLeg(
  orderId: orderId,
  orderLeg: legOrderId,
))
```
→ Sends deletion request for specific leg

---

## ✅ Implementation Status

```
COMPLETED TASKS:
✅ Order loading (regular + super)
✅ Order details UI
✅ Modify order functionality
✅ Cancel order leg functionality
✅ Design-consistent UI
✅ Error handling
✅ Loading states
✅ Status color coding
✅ Super order badge
✅ Order legs display
✅ User feedback (toasts)
✅ API integration
✅ BLoC pattern implementation

TESTED WORKFLOWS:
✅ View orders
✅ View details
✅ Modify parameters
✅ Cancel legs
✅ Status updates
✅ Error scenarios

READY FOR:
✅ User testing
✅ API validation
✅ UI refinement
✅ Performance optimization
```

---

**Last Updated**: May 6, 2026 | **Status**: Complete & Ready for Testing
