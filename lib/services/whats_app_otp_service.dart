import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';

class WhatsAppOTPService {
  // curl --location --request POST 'https://sender.smartplanb.com/api/create-message' \
  // --form 'appkey="0b30ad84-16e7-42cc-9724-718504204d8e"' \
  // --form 'authkey="QLUcZls5RoKjREtgv04nocx6vhQOkiQh8GdKqT6vhgGxnrOXp9"' \
  // --form 'to="RECEIVER_NUMBER"' \
  // --form 'message="Example message"' \

  static const String APP_KEY = "0b30ad84-16e7-42cc-9724-718504204d8e";
  static const String AUTH_KEY = "QLUcZls5RoKjREtgv04nocx6vhQOkiQh8GdKqT6vhgGxnrOXp9";
  static const String API_URL = "https://sender.smartplanb.com/api/create-message";

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: API_URL,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    contentType: 'multipart/form-data',
  ));

  static Future<bool> sendOTP(String phoneNumber, String otp) async {
    try {
      FormData formData = FormData.fromMap({
        'appkey': APP_KEY,
        'authkey': AUTH_KEY,
        'to': phoneNumber,
        'message': 'Your OTP code is: $otp',
      });

      Response response = await _dio.post(
        '',  // Empty string since baseUrl is set
        data: formData,
      );

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse['message_status'] == 'Success';
      }
      return false;
    } on DioException catch (e) {
      print('Dio Error sending WhatsApp OTP: ${e.message}');
      // You can handle different types of Dio errors here
      if (e.response != null) {
        print('Error Response: ${e.response?.data}');
        print('Error Status: ${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      print('Error sending WhatsApp OTP: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>> verifyOTPWithTemplate(String phoneNumber, String otp) async {
    try {
      FormData formData = FormData.fromMap({
        'appkey': APP_KEY,
        'authkey': AUTH_KEY,
        'to': phoneNumber,
        'template_id': 'YOUR_TEMPLATE_ID', // Replace with your template ID
        'variables[code]': otp,
      });

      Response response = await _dio.post(
        '',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['message_status'] == 'Success',
          'data': response.data['data'],
        };
      }
      return {'success': false, 'error': 'Failed to send OTP'};
    } on DioException catch (e) {
      print('Dio Error in template OTP: ${e.message}');
      return {'success': false, 'error': e.message};
    }
  }

  static String generateOTP() {
    Random random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  // Add this utility function to handle phone number formatting
  String formatPhoneNumber(String phoneNumber, String countryCode) {
    // Remove any non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (countryCode == 'EG') {
      // For Egypt (+20)
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1); // Remove leading zero
      }

      // Egyptian numbers should be 10 digits without the leading zero
      if (cleaned.length != 10) {
        throw 'Invalid phone number length for Egypt';
      }

      // Validate that it starts with valid Egyptian prefixes (11, 12, 15, etc.)
      if (!RegExp(r'^(10|11|12|15)').hasMatch(cleaned)) {
        throw 'Invalid Egyptian phone number prefix';
      }

    } else if (countryCode == 'SA') {
      // For Saudi Arabia (+966)
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1); // Remove leading zero if present
      }

      // Saudi numbers should be 9 digits without the leading zero
      if (cleaned.length != 9) {
        throw 'Invalid phone number length for Saudi Arabia';
      }

      // Validate that it starts with 5 for mobile numbers
      if (!cleaned.startsWith('5')) {
        throw 'Invalid Saudi phone number prefix';
      }
    }

    return cleaned;
  }

// Validation function
  bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    try {
      formatPhoneNumber(phoneNumber, countryCode);
      return true;
    } catch (e) {
      return false;
    }
  }

// Build the complete phone number with country code
  String buildPhoneNumberWithCountryCode(String phoneNumber, String countryCode) {
    String formattedNumber = formatPhoneNumber(phoneNumber, countryCode);
    String prefix = countryCode == 'EG' ? '20' : '966';
    return '$prefix-$formattedNumber';
  }
  // Helper method to format phone numbers

  // Method to handle response error messages
  static String getErrorMessage(DioException error) {
    if (error.response?.data != null && error.response?.data['message'] != null) {
      return error.response?.data['message'];
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Server error (${error.response?.statusCode})';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error occurred';
    }
  }
}