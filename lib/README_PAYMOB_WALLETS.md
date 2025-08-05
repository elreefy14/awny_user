# PayMob Integration with Electronic Wallets (محافظ الاكترونيه)

This guide explains how to integrate PayMob payment gateway with support for both credit cards and electronic wallets in your Flutter application.

## Overview

The updated PayMob integration now supports:
- **Credit Cards** (Visa, MasterCard, etc.)
- **Electronic Wallets** (محافظ الاكترونيه) like Vodafone Cash, Orange Cash, etc.

## Backend Configuration

Your backend API should return PayMob configuration including wallet integration IDs:

```json
{
  "paymob_config": {
    "paymob_api_key": "your_api_key",
    "paymob_integration_id": "card_integration_id",
    "paymob_iframe_id": "card_iframe_id", 
    "paymob_wallet_integration_id": "wallet_integration_id",
    "paymob_wallet_iframe_id": "wallet_iframe_id"
  },
  "amount": 100.0
}
```

## Key Changes Made

### 1. Updated PayMobConfig Model
```dart
class PayMobConfig {
  final String apiKey;
  final String integrationId; // For credit cards
  final String iframeId; // For credit cards
  final String? walletIntegrationId; // For electronic wallets
  final String? walletIframeId; // For electronic wallets iframe
  bool isTest;

  // Helper methods to get arrays of IDs
  List<String> getAllIntegrationIds() { ... }
  List<String> getAllIframeIds() { ... }
}
```

### 2. Enhanced PayMobService
Added new method `createPaymentUrlWithWallets()` that:
- Creates payment keys for multiple integration IDs
- Supports both card and wallet payment methods
- Returns a single URL that shows all payment options

### 3. Updated Payment Gateway Response Model
Added wallet-specific fields:
```dart
String? paymobWalletIntegrationId;
String? paymobWalletIframeId;
```

## Usage Example

```dart
// Step 1: Get PayMob configuration from your backend
final paymobConfig = await getPayMobConfigFromBackend();

// Step 2: Initialize PayMob service
final payMobService = PayMobService(
  config: PayMobConfig(
    apiKey: paymobConfig['paymob_api_key'],
    integrationId: paymobConfig['paymob_integration_id'],
    iframeId: paymobConfig['paymob_iframe_id'],
    walletIntegrationId: paymobConfig['paymob_wallet_integration_id'],
    walletIframeId: paymobConfig['paymob_wallet_iframe_id'],
    isTest: true,
  ),
);

await payMobService.initialize();

// Step 3: Create payment URL with wallet support
List<String> integrationIds = [
  paymobConfig['paymob_integration_id'],      // Cards
  paymobConfig['paymob_wallet_integration_id'] // Wallets
];

String paymentUrl = await payMobService.createPaymentUrlWithWallets(
  amount: amount * 100, // Amount in cents
  currency: 'EGP',
  integrationIds: integrationIds, // Array as requested
  billingData: billingData,
  primaryIframeId: paymobConfig['paymob_iframe_id'],
);

// Step 4: Launch payment URL
await launchUrl(Uri.parse(paymentUrl));
```

## Integration IDs Array

As requested, the integration IDs are sent as an array:
```dart
List<String> integrationIds = [
  "card_integration_id",    // For credit cards
  "wallet_integration_id"   // For electronic wallets
];
```

## PayMob Dashboard Configuration

Make sure your PayMob dashboard is configured with:

1. **Card Integration**: For Visa, MasterCard payments
2. **Wallet Integration**: For electronic wallets (Vodafone Cash, Orange Cash, etc.)
3. **Iframe Configuration**: Both card and wallet iframes should be set up

## Important Notes

- The payment URL will show both card and wallet options automatically
- PayMob determines which payment methods to display based on your dashboard configuration
- Amount should be sent in cents (multiply by 100)
- The primary iframe ID is used for the payment URL
- Electronic wallets will appear alongside credit card options

## Error Handling

```dart
try {
  String paymentUrl = await payMobService.createPaymentUrlWithWallets(...);
  await launchUrl(Uri.parse(paymentUrl));
} catch (e) {
  print('PayMob Error: $e');
  // Handle error appropriately
}
```

## Testing

1. Use test integration IDs from PayMob dashboard
2. Set `isTest: true` in PayMobConfig
3. Test with both card and wallet payment methods
4. Verify that both options appear in the payment iframe

## Files Modified

- `lib/model/paymob_config.dart` - Added wallet integration fields
- `lib/model/payment_gateway_response.dart` - Added wallet fields to LiveValue
- `lib/services/paymob_service.dart` - Added createPaymentUrlWithWallets method
- `lib/screens/payment/payment_screen.dart` - Updated to use wallet support
- `lib/screens/payment/paymob_wallet_example.dart` - Example implementation

## Support

For PayMob-specific configuration questions, refer to:
- PayMob documentation
- PayMob dashboard settings
- PayMob support team 