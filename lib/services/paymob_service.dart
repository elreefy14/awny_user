import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../model/paymob_config.dart';
import 'package:flutter/foundation.dart';

class PayMobService {
  final PayMobConfig config;
  String? authToken;
  String? orderId;
  String? paymentKey;

  PayMobService({required this.config});

  static const String _baseUrl = 'https://accept.paymob.com/api';

  // Helper method to log API requests and responses
  void _logApiCall(
      {required String endpoint,
      required http.Response response,
      Map<String, dynamic>? requestBody,
      Map<String, String>? headers}) {
    debugPrint(
        '┌───────────────────────────────────────────────────────────────────────────────────────────────────────');
    debugPrint('Url:  $_baseUrl/$endpoint');
    debugPrint('Header:  ${jsonEncode(headers)}');
    if (requestBody != null) {
      debugPrint('Request:  ${jsonEncode(requestBody)}');
    } else {
      debugPrint('Request:  null');
    }
    debugPrint(
        'Response (${response.request?.method}) ${response.statusCode}: ${response.body}');
    debugPrint(
        '└───────────────────────────────────────────────────────────────────────────────────────────────────────');
  }

  Future<void> initialize() async {
    await _getAuthToken();
  }

  Future<void> _getAuthToken() async {
    try {
      final requestBody = {'api_key': config.apiKey};
      final headers = {'Content-Type': 'application/json'};

      debugPrint('Initializing PayMob payment with API Key: ${config.apiKey}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/tokens'),
        headers: headers,
        body: json.encode(requestBody),
      );

      _logApiCall(
          endpoint: 'auth/tokens',
          response: response,
          requestBody: requestBody,
          headers: headers);

      // Accept both 200 and 201 as valid response codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Enhanced token extraction logic
        String? token;

        // Method 1: Direct token property
        if (data.containsKey('token')) {
          token = data['token'];
          debugPrint('Found token directly in response');
        }
        // Method 2: Common alternative location
        else if (data.containsKey('auth_token')) {
          token = data['auth_token'];
          debugPrint('Found token as auth_token in response');
        }
        // Method 3: Check if inside a nested object
        else {
          // Log all top-level keys to help with debugging
          debugPrint(
              'PayMob Auth response top-level keys: ${data.keys.toList()}');

          // Check for common nested locations
          if (data.containsKey('data') && data['data'] is Map) {
            final nestedData = data['data'] as Map;
            if (nestedData.containsKey('token')) {
              token = nestedData['token'];
              debugPrint('Found token in data.token');
            }
          } else if (data.containsKey('response') && data['response'] is Map) {
            final nestedData = data['response'] as Map;
            if (nestedData.containsKey('token')) {
              token = nestedData['token'];
              debugPrint('Found token in response.token');
            }
          }

          // Try to extract from specific location in response
          // Based on the truncated response in logs, it seems we need to check alternative locations
          if (token == null && data.containsKey('profile')) {
            // Check if token might be elsewhere in the response
            if (data.containsKey('token')) {
              token = data['token'];
              debugPrint('Found token alongside profile data');
            }
          }
        }

        if (token != null) {
          authToken = token;
          debugPrint(
              'PayMob Auth Token received: ${token.substring(0, math.min(10, token.length))}...');
          return;
        }

        // If we got here, we couldn't find the token
        debugPrint(
            'PayMob Auth response structure: ${data.toString().substring(0, math.min(500, data.toString().length))}...');
        throw 'تم استلام استجابة ناجحة ولكن لم يتم العثور على رمز المصادقة في الاستجابة';
      } else {
        throw 'فشل في الحصول على رمز المصادقة: [${response.statusCode}] ${response.body}';
      }
    } catch (e) {
      throw 'خطأ في الاتصال: $e';
    }
  }

  Future<String> createPaymentKey({
    required double amount,
    required String currency,
    required String integrationId,
    required Map<String, dynamic> billingData,
  }) async {
    try {
      // Ensure amount is in cents as per PayMob requirements
      final int amountInCents = (amount).round();

      debugPrint(
          'Processing payment amount: $amount, amountInCents: $amountInCents');

      // 1. Create Order
      final orderRequestBody = {
        'amount_cents': amountInCents,
        'currency': currency,
        'delivery_needed': false,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      debugPrint(
          'Creating PayMob order with amount: $amount, currency: $currency');

      final orderResponse = await http.post(
        Uri.parse('$_baseUrl/ecommerce/orders'),
        headers: headers,
        body: json.encode(orderRequestBody),
      );

      _logApiCall(
          endpoint: 'ecommerce/orders',
          response: orderResponse,
          requestBody: orderRequestBody,
          headers: headers);

      if (orderResponse.statusCode != 200 && orderResponse.statusCode != 201) {
        throw 'خطأ في إنشاء الطلب: [${orderResponse.statusCode}] ${orderResponse.body}';
      }

      final orderData = json.decode(orderResponse.body);
      orderId = orderData['id'].toString();
      debugPrint('PayMob Order ID created: $orderId');

      // 2. Get Payment Key
      // Convert integration_id to integer as PayMob expects it
      final int integrationIdInt = int.tryParse(integrationId) ?? 0;
      if (integrationIdInt == 0) {
        throw 'Integration ID must be a valid integer: $integrationId';
      }

      final paymentKeyRequestBody = {
        'amount_cents': amountInCents,
        'expiration': 3600,
        'order_id': orderId,
        'billing_data': billingData,
        'currency': currency,
        'integration_id': integrationIdInt, // Send as integer
        'lock_order_when_paid': false
      };

      debugPrint('Requesting PayMob payment key for order ID: $orderId');
      debugPrint('Using integration ID as integer: $integrationIdInt');

      final paymentKeyResponse = await http.post(
        Uri.parse('$_baseUrl/acceptance/payment_keys'),
        headers: headers,
        body: json.encode(paymentKeyRequestBody),
      );

      _logApiCall(
          endpoint: 'acceptance/payment_keys',
          response: paymentKeyResponse,
          requestBody: paymentKeyRequestBody,
          headers: headers);

      if (paymentKeyResponse.statusCode != 200 &&
          paymentKeyResponse.statusCode != 201) {
        throw 'خطأ في إنشاء مفتاح الدفع: [${paymentKeyResponse.statusCode}] ${paymentKeyResponse.body}';
      }

      final paymentKeyData = json.decode(paymentKeyResponse.body);
      final token = paymentKeyData['token'];
      debugPrint('PayMob Payment key received: $token');
      return token;
    } catch (e) {
      throw 'خطأ في إنشاء مفتاح الدفع: $e';
    }
  }

  // Method to check payment status using transaction ID
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      if (authToken == null) {
        await _getAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      debugPrint(
          'Checking PayMob payment status for transaction: $transactionId');

      final response = await http.get(
        Uri.parse('$_baseUrl/acceptance/transactions/$transactionId'),
        headers: headers,
      );

      _logApiCall(
          endpoint: 'acceptance/transactions/$transactionId',
          response: response,
          headers: headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'خطأ في التحقق من حالة الدفع: [${response.statusCode}] ${response.body}';
      }

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw 'خطأ في التحقق من حالة الدفع: $e';
    }
  }

  // Process PayMob callback data
  static Map<String, dynamic> processCallback(
      Map<String, dynamic> callbackData) {
    debugPrint('Processing PayMob callback data: ${jsonEncode(callbackData)}');

    final success = callbackData['success'] == 'true';
    final String transactionId = callbackData['id']?.toString() ?? '';
    final pendingStatus = callbackData['pending'] == 'true';

    return {
      'success': success,
      'transaction_id': transactionId,
      'pending': pendingStatus,
      'amount_cents': callbackData['amount_cents'],
      'is_refunded': callbackData['is_refunded'],
      'error_occured': callbackData['error_occured'],
      'source_data': callbackData['source_data'],
      'raw_data': callbackData
    };
  }

  // Create payment URL with both card and wallet support
  Future<String> createPaymentUrlWithWallets({
    required double amount,
    required String currency,
    List<String>?
        integrationIds, // Optional - will use config.getAllIntegrationIds() if not provided
    required Map<String, dynamic> billingData,
    String? primaryIframeId, // Primary iframe ID to use for the URL
  }) async {
    try {
      // Use provided integration IDs or get them from config
      final List<String> idsToUse =
          integrationIds ?? config.getAllIntegrationIds();

      // Ensure amount is in cents as per PayMob requirements
      final int amountInCents = (amount).round();

      debugPrint('Creating PayMob payment with wallet support');
      debugPrint('Integration IDs: $idsToUse');
      debugPrint('Amount in cents: $amountInCents');

      // 1. Create Order
      final orderRequestBody = {
        'amount_cents': amountInCents,
        'currency': currency,
        'delivery_needed': false,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final orderResponse = await http.post(
        Uri.parse('$_baseUrl/ecommerce/orders'),
        headers: headers,
        body: json.encode(orderRequestBody),
      );

      _logApiCall(
          endpoint: 'ecommerce/orders',
          response: orderResponse,
          requestBody: orderRequestBody,
          headers: headers);

      if (orderResponse.statusCode != 200 && orderResponse.statusCode != 201) {
        throw 'خطأ في إنشاء الطلب: [${orderResponse.statusCode}] ${orderResponse.body}';
      }

      final orderData = json.decode(orderResponse.body);
      orderId = orderData['id'].toString();
      debugPrint('PayMob Order ID created: $orderId');

      // 2. Create payment keys for all integration IDs
      List<String> paymentTokens = [];

      for (String integrationId in idsToUse) {
        // Convert integration_id to integer as PayMob expects it
        final int integrationIdInt = int.tryParse(integrationId) ?? 0;
        if (integrationIdInt == 0) {
          debugPrint('Invalid integration ID: $integrationId, skipping...');
          continue; // Skip invalid integration IDs
        }

        final paymentKeyRequestBody = {
          'amount_cents': amountInCents,
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': billingData,
          'currency': currency,
          'integration_id': integrationIdInt, // Send as integer
          'lock_order_when_paid': false
        };

        debugPrint(
            'Creating payment key for integration ID: $integrationId (as integer: $integrationIdInt)');

        final paymentKeyResponse = await http.post(
          Uri.parse('$_baseUrl/acceptance/payment_keys'),
          headers: headers,
          body: json.encode(paymentKeyRequestBody),
        );

        _logApiCall(
            endpoint: 'acceptance/payment_keys',
            response: paymentKeyResponse,
            requestBody: paymentKeyRequestBody,
            headers: headers);

        if (paymentKeyResponse.statusCode != 200 &&
            paymentKeyResponse.statusCode != 201) {
          debugPrint(
              'Failed to create payment key for integration ID: $integrationId');
          continue; // Skip this integration ID and continue with others
        }

        final paymentKeyData = json.decode(paymentKeyResponse.body);
        final token = paymentKeyData['token'];
        if (token != null) {
          paymentTokens.add(token);
          debugPrint(
              'Payment key created for integration ID $integrationId: $token');
        }
      }

      if (paymentTokens.isEmpty) {
        throw 'فشل في إنشاء أي مفتاح دفع للطرق المطلوبة';
      }

      // Use the first payment token and primary iframe ID
      final primaryToken = paymentTokens.first;
      final iframeId = primaryIframeId ?? config.iframeId;

      // Create the payment URL with the primary iframe
      final paymentUrl =
          'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$primaryToken';

      debugPrint('PayMob payment URL created: $paymentUrl');
      debugPrint(
          'This URL will show both card and wallet options based on your PayMob dashboard configuration');
      debugPrint('Integration IDs used: $idsToUse');

      return paymentUrl;
    } catch (e) {
      throw 'خطأ في إنشاء رابط الدفع مع المحافظ الإلكترونية: $e';
    }
  }
}
