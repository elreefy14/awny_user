# PayMob Array Integration - Flutter App

## Overview
This Flutter application now supports PayMob integration with multiple integration IDs (array format) to handle both card and wallet payments seamlessly.

## Backend Configuration

### Required Integration IDs
Your PayMob dashboard should have the following integrations configured:
- **Card Integration ID**: For credit/debit card payments
- **Wallet Integration IDs**: For electronic wallets (Vodafone Cash, Orange Money, etc.)

### Backend Response Format
The backend should return integration IDs in this format:
```json
{
  "paymob_integration_id": "[5005804, 5005899, 5005900, 5005898, 5005803]",
  "paymob_api_key": "your_api_key",
  "paymob_iframe_id": "your_iframe_id",
  "paymob_wallet_iframe_id": "your_wallet_iframe_id"
}
```

### Environment Variables (.env)
```env
PAYMOB_API_KEY=your_api_key_here
PAYMOB_INTEGRATION_ID=5005804,5005899,5005900,5005898,5005803
PAYMOB_IFRAME_ID=your_iframe_id
PAYMOB_WALLET_IFRAME_ID=your_wallet_iframe_id
PAYMOB_HMAC=your_hmac_secret
PAYMOB_CALLBACK_URL=https://yourapp.com/paymob/callback
```

## Flutter App Implementation

### Key Features
1. **Array Parsing**: Handles integration IDs as both string arrays and JSON arrays
2. **Multiple Payment Methods**: Supports cards and wallets automatically
3. **Fallback Handling**: Falls back to card-only if wallet IDs are missing
4. **Debug Logging**: Comprehensive logging for troubleshooting

### Code Structure

#### PayMobConfig Model
```dart
class PayMobConfig {
  final String integrationId;           // Primary integration ID
  final List<String>? allIntegrationIds; // All integration IDs array
  final String apiKey;
  final String iframeId;
  final String? walletIframeId;
  
  // Helper methods
  List<String> getAllIntegrationIds();
  List<String> getAllIframeIds();
  bool hasWalletSupport();
  String getPrimaryIntegrationId();
  List<String> getWalletIntegrationIds();
}
```

#### Integration ID Parsing
The app automatically parses integration IDs from various formats:
- String array: `"[5005804, 5005899, 5005900]"`
- JSON array: `["5005804", "5005899", "5005900"]`
- Comma-separated: `"5005804,5005899,5005900"`

## PayMob Dashboard Setup

### 1. Create Card Integration
1. Login to PayMob dashboard
2. Go to Developers → Payment Integrations
3. Create new integration for "Online Card Payments"
4. Note the Integration ID (e.g., 5005804)

### 2. Create Wallet Integrations
1. Create new integration for "Accept Wallet"
2. Enable wallet types:
   - Vodafone Cash
   - Orange Money
   - Etisalat Cash
   - CIB Wallet
3. Note each Integration ID (e.g., 5005899, 5005900, etc.)

### 3. Configure iFrames
1. Create iframe for card payments
2. Create iframe for wallet payments
3. Note both iframe IDs

## Testing

### Debug Output
When properly configured, you should see:
```
PayMob Config Debug:
✓ Integration IDs: [5005804, 5005899, 5005900, 5005898, 5005803]
✓ Primary ID: 5005804
✓ Wallet Support: true
✓ Wallet IDs: [5005899, 5005900, 5005898, 5005803]
✓ All iframe IDs: [iframe_id, wallet_iframe_id]
```

### Payment Flow
1. App fetches configuration from backend
2. Parses integration IDs array
3. Creates payment URLs for all integration types
4. Displays payment options (cards + wallets)
5. User selects payment method
6. Redirects to appropriate PayMob iframe

## Troubleshooting

### Common Issues

#### Only Cards Showing
**Cause**: Missing wallet integration IDs
**Solution**: 
- Check PayMob dashboard for wallet integrations
- Verify backend returns wallet IDs in array
- Ensure `paymob_wallet_iframe_id` is configured

#### Empty Integration IDs
**Cause**: Backend configuration missing
**Solution**:
- Update environment variables
- Check database configuration
- Verify API response format

#### Payment Fails
**Cause**: Invalid integration IDs
**Solution**:
- Verify IDs in PayMob dashboard
- Check integration status (active/inactive)
- Validate iframe IDs

### Debug Commands
```bash
# Check backend response
curl -X GET "your_api_endpoint/payment-gateways"

# Verify environment variables
php artisan config:show | grep PAYMOB
```

## Backend Implementation Example

See `backend_paymob_config_example.php` for complete implementation example.

### Key Points
1. Store integration IDs as array in database
2. Convert to string format for API response
3. Include all required fields (API key, iframe IDs)
4. Handle environment variables properly

## Security Notes

1. **Never expose API keys** in client-side code
2. **Use HTTPS** for all API communications
3. **Validate HMAC** signatures for callbacks
4. **Store sensitive data** in environment variables
5. **Implement proper** error handling

## Support

For issues related to:
- **PayMob Integration**: Contact PayMob support
- **Flutter Implementation**: Check debug logs and configuration
- **Backend Setup**: Verify environment variables and database

---

**Last Updated**: December 2024
**Version**: 2.0 (Array Integration Support) 