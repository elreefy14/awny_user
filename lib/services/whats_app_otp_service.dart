import 'dart:convert';
import 'dart:math';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

/// Service for sending and verifying OTP codes via WhatsApp using the smartplanb.com API
class WhatsAppOTPService {
  // API configuration
  static const String API_URL =
      'https://sender.smartplanb.com/api/create-message';
  static const String APP_KEY = '0b30ad84-16e7-42cc-9724-718504204d8e';
  static const String AUTH_KEY =
      'QLUcZls5RoKjREtgv04nocx6vhQOkiQh8GdKqT6vhgGxnrOXp9';

  // Debug helper
  void _log(String message) {
    print('⚡ WhatsAppOTPService: $message');
  }

  // Debug logging helper
  static void _debugLog(String message) {
    log('📱 WhatsAppOTP: $message');
  }

  /// Generate a random 6-digit OTP code
  static String generateOTP() {
    Random random = Random();
    int otp = random.nextInt(900000) + 100000; // Ensures a 6-digit number
    return otp.toString();
  }

  /// Send an OTP message via WhatsApp
  /// Returns true if the message was sent successfully
  static Future<bool> sendOTP(String phoneNumber, String otp) async {
    try {
      _debugLog("Starting OTP sending process to $phoneNumber with code $otp");

      // Format phone number (ensure it has country code without +)
      String formattedPhone = phoneNumber;
      if (formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.substring(1);
        _debugLog("Removed + from phone number: $formattedPhone");
      }

      // Additional validation to ensure phone number is in correct format
      if (!formattedPhone.contains(RegExp(r'^\d{10,14}$'))) {
        _debugLog(
            "WARNING: Phone number format may be incorrect: $formattedPhone");

        // Try to fix common issues
        formattedPhone = formattedPhone.replaceAll(RegExp(r'[^\d]'), '');
        _debugLog("Cleaned phone number: $formattedPhone");

        if (formattedPhone.length < 10) {
          _debugLog(
              "ERROR: Phone number too short after cleaning: $formattedPhone");
          return false;
        }
      }

      // Prepare message text with improved formatting
      String message =
          "رمز التحقق الخاص بك في تطبيق عوني هو: *$otp*\n\nكود التفعيل صالح لمدة دقيقتين. لا تشارك هذا الرمز مع أي شخص.";

      _debugLog("Preparing API request with formatted phone: $formattedPhone");

      // Create multipart request with improved error handling
      var request = http.MultipartRequest('POST', Uri.parse(API_URL));

      // Add required fields
      request.fields['appkey'] = APP_KEY;
      request.fields['authkey'] = AUTH_KEY;
      request.fields['to'] = formattedPhone;
      request.fields['message'] = message;

      // Add timeout and retry logic
      _debugLog("Sending request to smartplanb.com API");
      _debugLog("Request details: ${request.fields.toString()}");

      // Send the request with better timeout handling
      http.StreamedResponse? response;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          response = await request.send().timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw 'Request timeout after 30 seconds';
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          _debugLog("Attempt $retryCount failed: $e");

          if (retryCount >= maxRetries) {
            _debugLog("All retry attempts failed");
            throw 'حدث خطأ في الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: 2 * retryCount));

          // Create a new request for retry
          request = http.MultipartRequest('POST', Uri.parse(API_URL));
          request.fields['appkey'] = APP_KEY;
          request.fields['authkey'] = AUTH_KEY;
          request.fields['to'] = formattedPhone;
          request.fields['message'] = message;
        }
      }

      if (response == null) {
        _debugLog("Response is null after all retries");
        throw 'فشل في الاتصال بالخادم';
      }

      var responseData = await response.stream.bytesToString();
      _debugLog("Raw API Response: $responseData");
      _debugLog("Response Status Code: ${response.statusCode}");

      // Store response in SharedPreferences for debugging
      await setValue('last_whatsapp_api_response', responseData);
      await setValue(
          'last_whatsapp_api_status', response.statusCode.toString());
      await setValue('last_whatsapp_api_timestamp',
          DateTime.now().millisecondsSinceEpoch.toString());

      // Handle different status codes
      if (response.statusCode != 200) {
        String errorMsg = 'HTTP Error ${response.statusCode}';
        _debugLog("HTTP Error: $errorMsg");
        _debugLog("Response body: $responseData");

        // Store detailed error for debugging
        await setValue('last_whatsapp_api_error', "$errorMsg - $responseData");

        // Handle specific error codes
        switch (response.statusCode) {
          case 400:
            throw 'طلب غير صحيح. يرجى التحقق من رقم الهاتف والمحاولة مرة أخرى.';
          case 401:
            throw 'خطأ في التحقق من صحة الطلب. يرجى المحاولة مرة أخرى لاحقاً.';
          case 403:
            throw 'غير مسموح بإرسال الرسالة لهذا الرقم.';
          case 429:
            throw 'تم تجاوز الحد المسموح من الطلبات. يرجى الانتظار قبل المحاولة مرة أخرى.';
          case 500:
            throw 'خطأ الخادم الداخلي. يرجى المحاولة مرة أخرى بعد قليل.';
          default:
            throw 'حدث خطأ غير متوقع ($errorMsg). يرجى المحاولة مرة أخرى.';
        }
      }

      // Try to parse as JSON with better error handling
      try {
        if (responseData.isEmpty) {
          _debugLog("Empty response received");
          throw 'تم استلام رد فارغ من الخادم';
        }

        var jsonResponse = json.decode(responseData);
        _debugLog("JSON Response: $jsonResponse");

        // Check if the message was sent successfully
        if (jsonResponse['message_status'] == 'Success') {
          _debugLog("✓ OTP sent successfully");
          await setValue('last_successful_otp_send',
              DateTime.now().millisecondsSinceEpoch.toString());
          return true;
        } else {
          String errorMsg =
              jsonResponse['message']?.toString() ?? 'Unknown error from API';
          String statusMsg =
              jsonResponse['message_status']?.toString() ?? 'Unknown status';

          _debugLog(
              "✗ Failed to send OTP. Status: $statusMsg, Error: $errorMsg");
          await setValue('last_whatsapp_api_error', "$statusMsg: $errorMsg");

          // Handle specific API error messages
          if (errorMsg.toLowerCase().contains('invalid number') ||
              errorMsg.toLowerCase().contains('invalid phone')) {
            throw 'رقم الهاتف غير صحيح. يرجى التحقق من الرقم والمحاولة مرة أخرى.';
          } else if (errorMsg.toLowerCase().contains('rate limit') ||
              errorMsg.toLowerCase().contains('too many')) {
            throw 'تم إرسال عدد كبير من الرسائل. يرجى الانتظار قبل المحاولة مرة أخرى.';
          } else if (errorMsg.toLowerCase().contains('whatsapp') &&
              errorMsg.toLowerCase().contains('not')) {
            throw 'لا يمكن إرسال الرسالة عبر واتساب لهذا الرقم. تأكد أن واتساب مفعل على هذا الرقم.';
          } else {
            throw 'فشل في إرسال رمز التحقق: $errorMsg';
          }
        }
      } catch (e) {
        if (e is FormatException) {
          _debugLog("✗ Failed to parse JSON response: $e");
          _debugLog("Raw response was: $responseData");
          await setValue('last_whatsapp_api_error', "JSON parse error: $e");

          // If it's not JSON, maybe it's HTML error page or plain text
          if (responseData.toLowerCase().contains('error') ||
              responseData.toLowerCase().contains('invalid') ||
              responseData.toLowerCase().contains('fail')) {
            throw 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى بعد قليل.';
          } else {
            throw 'تم استلام رد غير متوقع من الخادم. يرجى المحاولة مرة أخرى.';
          }
        } else {
          // Re-throw custom error messages
          rethrow;
        }
      }
    } catch (e) {
      _debugLog("✗ Exception during OTP sending: $e");

      // Store error for debugging
      await setValue('last_whatsapp_api_error', e.toString());
      await setValue('last_whatsapp_api_error_timestamp',
          DateTime.now().millisecondsSinceEpoch.toString());

      // Handle different types of exceptions
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        throw 'انتهت مهلة الاتصال. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      } else if (e.toString().contains('Certificate') ||
          e.toString().contains('SSL') ||
          e.toString().contains('TLS')) {
        throw 'مشكلة في الأمان والتشفير. يرجى المحاولة مرة أخرى.';
      } else if (e is String &&
          (e.startsWith('خطأ') || e.startsWith('فشل') || e.startsWith('حدث'))) {
        // It's already a localized error message
        throw e;
      } else {
        throw 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      }
    }
  }

  /// Verify OTP with template (this is a placeholder - in a real implementation, this would verify the code)
  /// In the case of smartplanb.com, verification is done client-side by comparing the entered OTP
  static Future<Map<String, dynamic>> verifyOTPWithTemplate(
      String phoneNumber, String otp) async {
    try {
      // This is just a dummy verification - in a real implementation with server-side verification,
      // you would call an API to verify the OTP
      _debugLog("Verifying OTP $otp for $phoneNumber");

      return {
        'success': true,
        'message': 'OTP verified successfully',
      };
    } catch (e) {
      _debugLog("Error verifying OTP: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Format phone number for a specific country
  static String formatPhoneNumber(String phoneNumber, String countryCode) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    _debugLog(
        "Formatting phone number: $phoneNumber for country: $countryCode, cleaned: $cleaned");

    if (countryCode == 'EG') {
      // For Egypt (+20)
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1);
        _debugLog("Removed leading zero for Egypt number: $cleaned");
      }
      if (cleaned.length != 10) {
        _debugLog(
            "Invalid phone number length for Egypt: $cleaned (should be 10 digits)");
        throw 'Invalid phone number length for Egypt';
      }
      if (!RegExp(r'^(10|11|12|15)').hasMatch(cleaned)) {
        _debugLog("Invalid Egyptian phone number prefix: $cleaned");
        throw 'Invalid Egyptian phone number prefix';
      }
    } else if (countryCode == 'SA') {
      // For Saudi Arabia (+966)
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1);
        _debugLog("Removed leading zero for Saudi number: $cleaned");
      }
      if (cleaned.length != 9) {
        _debugLog(
            "Invalid phone number length for Saudi Arabia: $cleaned (should be 9 digits)");
        throw 'Invalid phone number length for Saudi Arabia';
      }
      if (!cleaned.startsWith('5')) {
        _debugLog("Invalid Saudi phone number prefix: $cleaned");
        throw 'Invalid Saudi phone number prefix';
      }
    }

    _debugLog("Formatted phone number result: $cleaned");
    return cleaned;
  }

  /// Build the complete phone number with country code
  static String buildPhoneNumberWithCountryCode(
      String phoneNumber, String countryCode) {
    String formattedNumber = formatPhoneNumber(phoneNumber, countryCode);
    String prefix = countryCode == 'EG' ? '20' : '966';
    String result = '+$prefix$formattedNumber';
    _debugLog("Built complete phone number: $result");
    return result;
  }
}
