import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/paymob_config.dart';

class PayMobService {
  final PayMobConfig config;
  String? authToken;
  String? orderId;
  String? paymentKey;

  PayMobService({required this.config});

  static const String _baseUrl = 'https://accept.paymob.com/api';

  Future<void> initialize() async {
    await _getAuthToken();
  }

  Future<void> _getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/tokens'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_key': config.apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        authToken = data['token'];
      } else {
        throw 'فشل في الحصول على رمز المصادقة';
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
      // 1. Create Order
      final orderResponse = await http.post(
        Uri.parse('$_baseUrl/ecommerce/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'amount_cents': (amount * 100).round(),
          'currency': currency,
          'delivery_needed': false,
        }),
      );

      final orderData = json.decode(orderResponse.body);
      orderId = orderData['id'].toString();

      // 2. Get Payment Key
      final paymentKeyResponse = await http.post(
        Uri.parse('$_baseUrl/acceptance/payment_keys'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'amount_cents': (amount * 100).round(),
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': billingData,
          'currency': currency,
          'integration_id': integrationId,
          'lock_order_when_paid': false
        }),
      );

      final paymentKeyData = json.decode(paymentKeyResponse.body);
      return paymentKeyData['token'];
    } catch (e) {
      throw 'خطأ في إنشاء مفتاح الدفع: $e';
    }
  }
} 