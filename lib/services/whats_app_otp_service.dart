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

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(API_URL));

      // Add required fields
      request.fields['appkey'] = APP_KEY;
      request.fields['authkey'] = AUTH_KEY;
      request.fields['to'] = formattedPhone;
      request.fields['message'] = message;

      _debugLog("Sending request to smartplanb.com API");
      _debugLog("Request details: ${request.fields.toString()}");

      // Send the request
      var response = await request.send().timeout(Duration(seconds: 30));
      var responseData = await response.stream.bytesToString();

      _debugLog("Raw API Response: $responseData");

      // Store response in SharedPreferences for debugging
      await setValue('last_whatsapp_api_response', responseData);
      await setValue(
          'last_whatsapp_api_status', response.statusCode.toString());

      // Try to parse as JSON
      try {
        var jsonResponse = json.decode(responseData);
        _debugLog("JSON Response: $jsonResponse");

        // Check if the message was sent successfully
        if (response.statusCode == 200 &&
            jsonResponse['message_status'] == 'Success') {
          _debugLog("✓ OTP sent successfully");
          return true;
        } else {
          String errorMsg = jsonResponse['message'] ?? 'Unknown error';
          _debugLog(
              "✗ Failed to send OTP. Status: ${response.statusCode}, Error: $errorMsg");
          await setValue('last_whatsapp_api_error', errorMsg);
          return false;
        }
      } catch (e) {
        _debugLog("✗ Failed to parse JSON response: $e");
        _debugLog("Raw response was: $responseData");
        await setValue('last_whatsapp_api_error', "JSON parse error: $e");
        return false;
      }
    } catch (e) {
      _debugLog("✗ Exception during OTP sending: $e");
      return false;
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
