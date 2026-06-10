# Super Orders Implementation Guide

## Overview
This document describes the implementation of Dhan Super Orders API integration in the InvestAPAS Flutter application. The implementation allows users to:
- View all orders and super orders
- View detailed order information
- Modify super order parameters (quantity, price, target, stop loss)
- Cancel order legs for super orders
- Track order status and execution

## Architecture

### Project Structure
```
lib/
├── presentation/
│   ├── pages/
│   │   └── orders/
│   │       └── order_page.dart (Main UI with details sheet)
│   └── bloc/
│       └── orders/
│           ├── order_bloc.dart (Business logic)
│           ├── order_event.dart (Events)
│           └── order_state.dart (State)
├── data/
│   └── models/
│       └── order_model.dart (Order and OrderLeg models)
├── core/
│   ├── network/
│   │   ├── api_endpoints.dart (API endpoints)
│   │   └── api_service.dart (HTTP helper)
│   └── utils/
│       └── shared_prefs_helper.dart (Token management)
```

## Key Components

### 1. OrderBloc
**File**: `lib/presentation/bloc/orders/order_bloc.dart`

Handles all order-related operations:
- `LoadOrders`: Fetches regular orders from `/dhan/orders`
- `LoadSuperOrders`: Fetches super orders from `/dhan/super-orders`
- `ModifySuperOrder`: Modifies super order parameters via PUT request
- `CancelOrderLeg`: Cancels a specific order leg via DELETE request
- `ChangeOrderTab`: Switches between "Open" and "Executed" tabs
- `ClearActionMessage`: Clears status messages

### 2. OrderState
**File**: `lib/presentation/bloc/orders/order_state.dart`

Maintains application state:
- `isLoading`: Loading state for initial data fetch
- `allOrders`: Regular orders
- `superOrders`: Super orders  
- `activeTab`: Current tab (open/executed)
- `error`: Error message for fetch failures
- `isActionLoading`: Loading state for modify/cancel operations
- `actionMessage`: Success/error message for actions
- `actionSuccess`: Whether last action was successful

### 3. UI Components

#### Order Page (`order_page.dart`)
Main page displaying orders in tabs:
- **Header**: Title with back button
- **Tabs**: "Open" and "Executed" orders
- **List View**: Displays order rows with summary information
  - Shows "Super" badge for super orders
  - Displays BUY/SELL indicator
  - Shows quantity, price, and status
- **Tap to View Details**: Tapping an order opens details sheet

#### Order Details Sheet
Displayed as a draggable bottom sheet:
- **Basic Info**: Order ID, quantity, price, timestamps
- **Super Order Details** (if applicable):
  - Target price
  - Stop loss price
  - Trailing jump percentage
  - Order legs with individual status
- **Action Buttons**:
  - "Modify Order" - Opens modification dialog
  - "Cancel Order Leg" - Shows leg selection for cancellation

#### Modify Order Dialog
Allows updating super order parameters:
- Quantity
- Price
- Target Price
- Stop Loss Price

Validation and API call happen on submission.

#### Cancel Order Leg Dialog
Shows list of pending order legs to cancel. User selects which leg to cancel.

## API Endpoints

### 1. Get All Orders
**Endpoint**: `POST /dhan/orders`
**Request Body**:
```json
{
  "dhanAccessToken": "user_access_token"
}
```
**Response**:
```json
{
  "status": true,
  "data": [
    {
      "orderId": "123456",
      "orderStatus": "PENDING",
      "tradingSymbol": "SBIN-EQ",
      "quantity": 10,
      "price": 450.5,
      "orderType": "LIMIT",
      "exchangeSegment": "NSE",
      "transactionType": "BUY"
    }
  ]
}
```

### 2. Get Super Orders
**Endpoint**: `POST /dhan/super-orders`
**Request Body**:
```json
{
  "dhanAccessToken": "user_access_token"
}
```
**Response**:
```json
{
  "status": true,
  "data": [
    {
      "orderId": "789012",
      "orderStatus": "PENDING",
      "tradingSymbol": "RELIANCE-EQ",
      "quantity": 5,
      "targetPrice": 2500,
      "stopLossPrice": 2400,
      "trailingJump": 1.5,
      "legs": [
        {
          "legName": "ENTRY_LEG",
          "legOrderId": "789012_1",
          "orderStatus": "TRANSIT",
          "price": 2450,
          "quantity": 5
        },
        {
          "legName": "TARGET_LEG",
          "legOrderId": "789012_2",
          "orderStatus": "PENDING",
          "price": 2500,
          "quantity": 5
        },
        {
          "legName": "STOPLOSS_LEG",
          "legOrderId": "789012_3",
          "orderStatus": "PENDING",
          "price": 2400,
          "quantity": 5
        }
      ]
    }
  ]
}
```

### 3. Modify Super Order
**Endpoint**: `PUT /dhan/super-orders/:orderId`
**Request Body**:
```json
{
  "quantity": 10,
  "price": 2450,
  "targetPrice": 2550,
  "stopLossPrice": 2350,
  "dhanAccessToken": "user_access_token"
}
```
**Response**:
```json
{
  "status": true,
  "data": { "orderId": "789012", "message": "Order modified successfully" }
}
```

### 4. Cancel Order Leg
**Endpoint**: `DELETE /dhan/super-orders/:orderId/:orderLeg`
**Request Body**:
```json
{
  "dhanAccessToken": "user_access_token"
}
```
**Response**:
```json
{
  "status": true,
  "data": { "message": "Order leg cancelled successfully" }
}
```

## Data Models

### OrderModel
```dart
class OrderModel {
  final String orderId;
  final String orderStatus;
  final String tradingSymbol;
  final int quantity;
  final double price;
  final double targetPrice;      // Super order only
  final double stopLossPrice;    // Super order only
  final double trailingJump;     // Super order only
  final bool isSuperOrder;
  final List<OrderLeg> legs;     // Super order only
  
  bool get isOpen => 
    orderStatus == 'PENDING' || 
    orderStatus == 'TRANSIT' || 
    orderStatus == 'PART_TRADED';
    
  bool get isExecuted =>
    orderStatus == 'TRADED' ||
    orderStatus == 'CANCELLED' ||
    orderStatus == 'REJECTED';
}

class OrderLeg {
  final String legName;      // ENTRY_LEG, TARGET_LEG, STOPLOSS_LEG
  final String legStatus;
  final String legOrderId;
  final double price;
  final int quantity;
  
  bool get isPending => legStatus == 'PENDING' || legStatus == 'TRANSIT';
  
  String get displayName {
    switch (legName) {
      case 'ENTRY_LEG': return 'Entry';
      case 'TARGET_LEG': return 'Target';
      case 'STOPLOSS_LEG': return 'Stop Loss';
      default: return legName;
    }
  }
}
```

## Usage Flow

### 1. View Orders
```
User opens Order Page
  ↓
OrderBloc receives LoadOrders & LoadSuperOrders events
  ↓
Fetch from API endpoints with access token
  ↓
Orders displayed in tabs (Open/Executed)
  ↓
Super orders show "Super" badge
```

### 2. View Order Details
```
User taps an order row
  ↓
Bottom sheet slides up with full details
  ↓
For super orders: shows legs and target/SL
```

### 3. Modify Super Order
```
User taps "Modify Order" button
  ↓
Dialog opens with current values
  ↓
User updates quantity/price/target/SL
  ↓
Submit triggers ModifySuperOrder event
  ↓
PUT request sent to API
  ↓
Success/error message shown
  ↓
Orders refreshed
```

### 4. Cancel Order Leg
```
User taps "Cancel Order Leg" button
  ↓
Dialog shows pending legs
  ↓
User selects leg to cancel
  ↓
DELETE request sent to API
  ↓
Success/error message shown
  ↓
Orders refreshed
```

## Error Handling

### Network Errors
- Timeout errors show "Timeout Error" toast
- HTTP errors (500, 401, 403) handled globally
- Custom errors show error message from API response

### Action Errors
- Modify/Cancel operations show error in SnackBar
- User can retry without reloading entire page
- Action state clears automatically after 2 seconds

### Validation
- API validates all parameters server-side
- UI shows loading state during operations
- Buttons disabled while action is in progress

## Design Consistency

### Colors & Typography
- Uses existing design system (Colorz, AppTextStyles, SizeConfig)
- Primary color for super orders badge
- Red for cancel actions
- Green for success messages
- Status-based colors (green=traded, red=cancelled, amber=pending)

### Layout
- Consistent padding and spacing using SizeConfig
- Responsive design using flutter_screenutil
- Smooth animations (200ms curve)
- Material Design 3 compliant

### Status Flow
- PENDING/TRANSIT → Open (amber)
- TRADED → Executed (green)
- CANCELLED/REJECTED → Executed (red)

## Testing Checklist

- [ ] Load orders page - displays both regular and super orders
- [ ] Super orders show "Super" badge
- [ ] Tap order - details sheet opens
- [ ] Scroll details sheet - smooth scrolling
- [ ] Modify order - updates successfully
- [ ] Cancel leg - leg cancels successfully
- [ ] Error handling - shows appropriate error messages
- [ ] Network timeout - handles gracefully
- [ ] Auth failure (401) - redirects to login
- [ ] Status filters - open/executed tabs work correctly

## Future Enhancements

1. **Order History**: Archive and view historical orders
2. **Order Notifications**: Push notifications on order status changes
3. **Partial Fills**: Show partial execution details
4. **Order Comments**: Allow users to add notes to orders
5. **Quick Modify**: Swipe actions for quick modifications
6. **Order Analytics**: Charts and statistics for order patterns
7. **Batch Operations**: Modify multiple orders at once
8. **Export Orders**: PDF/CSV export functionality

## Troubleshooting

### Orders not loading
- Check access token in SharedPreferences
- Verify API endpoint in ApiEndpoints
- Check network connectivity
- Review server logs for API errors

### Modify/Cancel fails
- Verify order is in open state
- Check that dhanAccessToken is valid
- Verify order parameters are valid
- Check API server status

### UI issues
- Clear app cache and rebuild
- Check for conflicting styles/themes
- Verify all assets are properly imported
- Check flutter version compatibility

## Code References

- **Order Page**: `/lib/presentation/pages/orders/order_page.dart`
- **Order Bloc**: `/lib/presentation/bloc/orders/order_bloc.dart`
- **Order Model**: `/lib/data/models/order_model.dart`
- **API Service**: `/lib/core/network/api_service.dart`
- **API Endpoints**: `/lib/core/network/api_endpoints.dart`
