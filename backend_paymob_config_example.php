<?php
// Example backend configuration for PayMob with integration IDs as array
// Based on your backend response: "paymob_integration_id": "[5005804 , 5005899 , 5005900 , 5005898 , 5005803]"

class PayMobConfig {
    
    public function getPayMobConfiguration() {
        // These integration IDs should come from your PayMob dashboard
        // The array contains both card and wallet integration IDs
        $integrationIds = [
            '5005804', // Card integration ID (Visa/MasterCard)
            '5005899', // Wallet integration ID (Vodafone Cash)
            '5005900', // Wallet integration ID (Orange Cash)
            '5005898', // Wallet integration ID (Etisalat Cash)
            '5005803'  // Another wallet integration ID
        ];
        
        // Convert array to string format as your backend is doing
        $integrationIdsString = '[' . implode(' , ', $integrationIds) . ']';
        
        $config = [
            'paymob_api_key' => env('PAYMOB_API_KEY', 'your_api_key_here'),
            
            // Integration IDs as array string (as your backend is sending)
            'paymob_integration_id' => $integrationIdsString,
            
            // Primary iframe ID (usually for cards)
            'paymob_iframe_id' => env('PAYMOB_IFRAME_ID', '789012'),
            
            // Optional fields
            'paymob_hmac' => env('PAYMOB_HMAC', ''),
            'paymob_callback_url' => env('PAYMOB_CALLBACK_URL', 'https://yoursite.com/paymob/callback'),
        ];
        
        return $config;
    }
    
    // Alternative method: Return as actual array (recommended)
    public function getPayMobConfigurationAsArray() {
        $integrationIds = [
            '5005804', // Card integration ID
            '5005899', // Vodafone Cash
            '5005900', // Orange Cash
            '5005898', // Etisalat Cash
            '5005803'  // Another wallet
        ];
        
        $config = [
            'paymob_api_key' => env('PAYMOB_API_KEY', 'your_api_key_here'),
            
            // Integration IDs as actual array (better approach)
            'paymob_integration_id' => $integrationIds,
            
            'paymob_iframe_id' => env('PAYMOB_IFRAME_ID', '789012'),
            'paymob_hmac' => env('PAYMOB_HMAC', ''),
            'paymob_callback_url' => env('PAYMOB_CALLBACK_URL', 'https://yoursite.com/paymob/callback'),
        ];
        
        return $config;
    }
    
    public function getPaymentGatewayResponse() {
        // Use the string format as your backend is currently doing
        $paymobConfig = $this->getPayMobConfiguration();
        
        return [
            'id' => 1,
            'title' => 'PayMob',
            'type' => 'paymob',
            'status' => 1,
            'is_test' => 1, // Set to 0 for live mode
            'value' => $paymobConfig,      // Test configuration
            'live_value' => $paymobConfig  // Live configuration
        ];
    }
    
    // Example of what your current backend response looks like
    public function getCurrentBackendResponse() {
        return [
            'id' => 1,
            'title' => 'PayMob',
            'type' => 'paymob',
            'status' => 1,
            'is_test' => 1,
            'value' => [
                'paymob_api_key' => 'your_api_key',
                'paymob_integration_id' => '[5005804 , 5005899 , 5005900 , 5005898 , 5005803]',
                'paymob_iframe_id' => '789012',
                'paymob_hmac' => '',
                'paymob_callback_url' => 'https://yoursite.com/paymob/callback'
            ]
        ];
    }
}

// Example usage in your API endpoint
$payMobConfig = new PayMobConfig();
$response = $payMobConfig->getPaymentGatewayResponse();

// Return this in your payment gateways API response
echo json_encode($response);

/*
IMPORTANT NOTES:
1. The integration IDs array should contain:
   - First ID: Card integration (Visa/MasterCard)
   - Remaining IDs: Wallet integrations (Vodafone Cash, Orange Cash, etc.)

2. Make sure these integration IDs are configured in your PayMob dashboard:
   - Go to PayMob Dashboard > Integrations
   - Create separate integrations for cards and each wallet type
   - Copy the integration IDs and use them in this array

3. The Flutter app will now automatically:
   - Parse the array from string format
   - Use all integration IDs to create payment keys
   - Show both card and wallet options in the payment iframe

4. Test with actual PayMob integration IDs from your dashboard
*/
?> 