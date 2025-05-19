import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/services/whats_app_otp_service.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class WhatsAppAuthService {
  // Store OTP for verification
  String? _currentOTP;
  String? _currentPhoneNumber;
  int _maxRetries = 3;

  // Debug logging helper
  void _debugLog(String message) {
    log('🔰 WhatsAppAuth: $message');
  }

  // Initialize the service
  Future<void> initialize() async {
    _debugLog("WhatsApp Auth Service initialized");
    // Clear any existing OTP data to avoid stale data
    _currentOTP = null;
    _currentPhoneNumber = null;
  }

  /// Request OTP verification for a phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(bool success) onOTPSent,
    required Function(String error) onError,
  }) async {
    try {
      _debugLog("Sending WhatsApp OTP to $phoneNumber");

      // Validate phone number format
      if (!_isValidPhoneNumber(phoneNumber)) {
        _debugLog("Invalid phone number format: $phoneNumber");
        onError(
            "Invalid phone number format. Please check the number and try again.");
        return;
      }

      // Generate a random 6-digit OTP
      _currentOTP = WhatsAppOTPService.generateOTP();
      _currentPhoneNumber = phoneNumber;

      if (_currentOTP == null) {
        _debugLog("Failed to generate OTP");
        onError("Failed to generate verification code. Please try again.");
        return;
      }

      _debugLog("Generated OTP: $_currentOTP for phone: $phoneNumber");

      // Send OTP via WhatsApp - with retry logic
      bool success = false;
      int retries = 0;

      while (!success && retries < _maxRetries) {
        try {
          success = await WhatsAppOTPService.sendOTP(phoneNumber, _currentOTP!);
          if (success) break;
          retries++;
          if (retries < _maxRetries) {
            _debugLog("Retrying OTP send (attempt $retries of $_maxRetries)");
            await Future.delayed(Duration(seconds: 2)); // Wait before retry
          }
        } catch (e) {
          _debugLog("Error during OTP send attempt $retries: $e");
          retries++;
          if (retries >= _maxRetries) throw e;
          await Future.delayed(Duration(seconds: 2)); // Wait before retry
        }
      }

      if (success) {
        _debugLog("OTP sent successfully to $phoneNumber");
        onOTPSent(true);

        // Store OTP in shared preferences for recovery if app is killed
        await setValue('current_otp_value', _currentOTP);
        await setValue('current_otp_phone', _currentPhoneNumber);
        await setValue(
            'current_otp_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        _debugLog(
            "Failed to send OTP to $phoneNumber after $_maxRetries attempts");
        onError(
            "فشل إرسال رمز التحقق عبر واتساب. يرجى التأكد من رقم الهاتف وأن واتساب مفعل، ثم حاول مرة أخرى.");
        _currentOTP = null;
      }
    } catch (e) {
      _debugLog("Error in sendOTP: $e");
      onError("حدث خطأ أثناء إرسال رمز التحقق: ${e.toString()}");
      _currentOTP = null;
    }
  }

  /// Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(bool success) onOTPSent,
    required Function(String error) onError,
  }) async {
    try {
      _debugLog("Resending WhatsApp OTP to $phoneNumber");

      // Check if too many attempts
      if (getOTPSendCount(phoneNumber) > 3) {
        _debugLog("Too many OTP send attempts for $phoneNumber");
        onError(
            "لقد تجاوزت الحد المسموح به من المحاولات. يرجى الانتظار قليلاً قبل المحاولة مرة أخرى.");
        return;
      }

      // Generate a new OTP
      _currentOTP = WhatsAppOTPService.generateOTP();
      _currentPhoneNumber = phoneNumber;

      if (_currentOTP == null) {
        _debugLog("Failed to generate new OTP");
        onError("Failed to generate new verification code. Please try again.");
        return;
      }

      _debugLog("Generated new OTP: $_currentOTP for phone: $phoneNumber");

      // Send OTP via WhatsApp
      bool success =
          await WhatsAppOTPService.sendOTP(phoneNumber, _currentOTP!);

      if (success) {
        _debugLog("OTP resent successfully to $phoneNumber");
        incrementOTPSendCount(phoneNumber);
        onOTPSent(true);

        // Update stored OTP in shared preferences
        await setValue('current_otp_value', _currentOTP);
        await setValue('current_otp_phone', _currentPhoneNumber);
        await setValue(
            'current_otp_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        _debugLog("Failed to resend OTP to $phoneNumber");
        onError(
            "فشل إعادة إرسال رمز التحقق عبر واتساب. يرجى التأكد من رقم الهاتف وأن واتساب مفعل، ثم حاول مرة أخرى.");
      }
    } catch (e) {
      _debugLog("Error in resendOTP: $e");
      onError("حدث خطأ أثناء إعادة إرسال رمز التحقق: ${e.toString()}");
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String enteredOTP) async {
    try {
      _debugLog("Verifying OTP: entered=$enteredOTP, actual=$_currentOTP");

      // Check if current OTP is null - try to recover from shared preferences
      if (_currentOTP == null) {
        _debugLog(
            "No OTP stored in memory, trying to recover from preferences");
        _recoverStoredOTP();

        // If still null after recovery attempt, provide a more helpful message
        if (_currentOTP == null) {
          _debugLog(
              "Failed to recover stored OTP. This may be due to app restart or OTP expiration.");

          // Try to check if the entered OTP matches the one in preferences directly
          // This is a fallback in case the app state was lost but preferences still exist
          String? storedOTP = getStringAsync('current_otp_value');

          if (storedOTP != null &&
              storedOTP.isNotEmpty &&
              storedOTP == enteredOTP) {
            _debugLog("Direct comparison with stored OTP succeeded");

            // Clear stored OTP after successful verification
            await setValue('current_otp_value', null);
            await setValue('current_otp_phone', null);

            return true;
          }

          _debugLog("No valid OTP reference available for verification");
          return false;
        }
      }

      // Simple comparison for verification
      bool isValid = enteredOTP == _currentOTP;

      if (isValid) {
        _debugLog("OTP verification successful");
        // Clear stored OTP after successful verification
        await setValue('current_otp_value', null);
        await setValue('current_otp_phone', null);
      } else {
        _debugLog("OTP verification failed: $enteredOTP != $_currentOTP");
      }

      return isValid;
    } catch (e) {
      _debugLog("Error verifying OTP: $e");
      return false;
    }
  }

  /// Try to recover OTP from shared preferences if the app was killed and restarted
  void _recoverStoredOTP() {
    try {
      String? storedOTP = getStringAsync('current_otp_value');
      String? storedPhone = getStringAsync('current_otp_phone');
      int storedTimestamp = getIntAsync('current_otp_timestamp');

      // Check if we have stored values and they haven't expired (10 minutes max)
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      bool isExpired = (currentTime - storedTimestamp) > 600000; // 10 minutes

      if (storedOTP != null && storedOTP.isNotEmpty && !isExpired) {
        _debugLog(
            "Recovered OTP from storage: $storedOTP for phone: $storedPhone");
        _currentOTP = storedOTP;
        _currentPhoneNumber = storedPhone;
      } else {
        _debugLog("No valid stored OTP found or OTP has expired");
        // Clear any expired values
        setValue('current_otp_value', null);
        setValue('current_otp_phone', null);
      }
    } catch (e) {
      _debugLog("Error recovering stored OTP: $e");
    }
  }

  /// Process the authenticated user and integrate with backend
  Future<Map<String, dynamic>> processAuthenticatedUser(
      String phoneNumber) async {
    try {
      _debugLog("Processing authenticated user with phone: $phoneNumber");

      // Generate a unique ID for the user
      String uid = DateTime.now().millisecondsSinceEpoch.toString();

      // Prepare user data for backend integration
      Map<String, dynamic> request = {
        'username': phoneNumber.replaceAll('+', ''),
        'contact_number': phoneNumber,
        'email': '${phoneNumber.replaceAll('+', '')}@phone.user',
        'login_type': LOGIN_TYPE_OTP,
        'user_type': USER_TYPE_USER,
        'display_name': 'User ${phoneNumber.substring(phoneNumber.length - 4)}',
        'first_name': 'User',
        'last_name': phoneNumber.substring(phoneNumber.length - 4),
        'uid': uid,
      };

      _debugLog("Sending user data to backend: $request");

      // Integrate with your backend
      try {
        // First try to login to check if user exists
        var loginResponse = await loginUser(request, isSocialLogin: true);

        // Check the response to see if we need to create a user
        if (loginResponse.isUserExist == false) {
          _debugLog("User doesn't exist. Need to create a new user account");

          try {
            // Try to create a new user account
            var registerResponse = await createUser(request);

            if (registerResponse.userData != null) {
              _debugLog(
                  "New user registered successfully with ID: ${registerResponse.userData!.id}");
              await saveUserData(registerResponse.userData!);
              await appStore.setLoginType(LOGIN_TYPE_OTP);

              // Reset OTP after successful registration
              _currentOTP = null;
              setValue('current_otp_value', null);
              setValue('current_otp_phone', null);

              return {'success': true, 'userData': registerResponse.userData};
            } else {
              throw "Failed to create new user account. No user data returned after registration.";
            }
          } catch (registerError) {
            // If registration fails because username/email already exists
            if (registerError.toString().contains("already been taken")) {
              _debugLog(
                  "Registration failed because username/email already exists. Trying alternative approach.");

              // Modify the request to force a unique username for this login attempt
              Map<String, dynamic> modifiedRequest = Map.from(request);
              modifiedRequest['username'] =
                  "${phoneNumber.replaceAll('+', '')}_${uid.substring(uid.length - 4)}";
              modifiedRequest['email'] =
                  "${phoneNumber.replaceAll('+', '')}_${uid.substring(uid.length - 4)}@phone.user";

              // Try to create the user with modified credentials
              try {
                var altRegisterResponse = await createUser(modifiedRequest);

                if (altRegisterResponse.userData != null) {
                  _debugLog(
                      "User registered with modified credentials. ID: ${altRegisterResponse.userData!.id}");
                  await saveUserData(altRegisterResponse.userData!);
                  await appStore.setLoginType(LOGIN_TYPE_OTP);

                  // Reset OTP
                  _currentOTP = null;
                  setValue('current_otp_value', null);
                  setValue('current_otp_phone', null);

                  return {
                    'success': true,
                    'userData': altRegisterResponse.userData
                  };
                }
              } catch (altRegisterError) {
                _debugLog(
                    "Alternative registration also failed: $altRegisterError");

                // Last resort - try login again with original credentials
                // This might work if user exists but social-login endpoint had a bug
                try {
                  _debugLog("Trying direct login as last resort");
                  var finalLoginResponse = await loginUser({
                    'email': request['email'],
                    'username': request['username'],
                    'user_type': USER_TYPE_USER,
                    'login_type': LOGIN_TYPE_OTP,
                    'uid': uid,
                  }, isSocialLogin: true);

                  if (finalLoginResponse.userData != null) {
                    _debugLog("Final login attempt succeeded!");
                    await saveUserData(finalLoginResponse.userData!);
                    await appStore.setLoginType(LOGIN_TYPE_OTP);

                    // Reset OTP
                    _currentOTP = null;
                    setValue('current_otp_value', null);
                    setValue('current_otp_phone', null);

                    return {
                      'success': true,
                      'userData': finalLoginResponse.userData
                    };
                  }
                } catch (finalLoginError) {
                  _debugLog(
                      "Final login attempt also failed: $finalLoginError");
                  throw "Cannot log in or register user after multiple attempts";
                }
              }
            }

            // If we got here, all attempts failed
            _debugLog("All registration attempts failed: $registerError");
            throw registerError;
          }
        }
        // Handle the case where user exists and login succeeded
        else if (loginResponse.userData != null) {
          _debugLog(
              "User exists and login succeeded with ID: ${loginResponse.userData!.id}");
          await saveUserData(loginResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_OTP);

          // Reset OTP after successful login
          _currentOTP = null;
          setValue('current_otp_value', null);
          setValue('current_otp_phone', null);

          return {'success': true, 'userData': loginResponse.userData};
        }
        // Handle unexpected response format
        else {
          _debugLog("Unexpected response format: ${loginResponse.toJson()}");
          throw "Server returned an unexpected response format";
        }
      } catch (e) {
        _debugLog("Backend integration failed: $e");
        return {'success': false, 'error': e.toString()};
      }
    } catch (e) {
      _debugLog("User processing failed: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Alternative method for processing authenticated user when the standard approach fails
  /// This is specifically for cases where social-login indicates the user doesn't exist
  /// but registration fails because the username/email is already taken
  Future<Map<String, dynamic>> processAuthenticatedUserAlternate(
      String phoneNumber) async {
    try {
      _debugLog("Trying alternative authentication approach for: $phoneNumber");

      // Generate a unique ID for the user
      String uid = DateTime.now().millisecondsSinceEpoch.toString();
      String randomSuffix =
          uid.substring(uid.length - 6); // Use last 6 digits for uniqueness

      // 1. First try direct login with just username and password (no social login)
      try {
        _debugLog("Trying direct login with username and password");

        Map<String, dynamic> loginRequest = {
          'username': phoneNumber.replaceAll('+', ''),
          'password':
              randomSuffix, // Use random string as password - actual password won't matter for OTP
          'login_type':
              LOGIN_TYPE_USER, // Use regular login instead of social login
        };

        var loginResponse = await loginUser(loginRequest, isSocialLogin: false);

        if (loginResponse.userData != null) {
          _debugLog(
              "Direct login succeeded! UserID: ${loginResponse.userData!.id}");
          await saveUserData(loginResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_OTP);
          return {'success': true, 'userData': loginResponse.userData};
        }
      } catch (e) {
        _debugLog("Direct login failed: $e");
      }

      // 2. Try a completely different approach - modified registration with unique data
      try {
        _debugLog("Trying modified registration with unique fields");

        Map<String, dynamic> registerRequest = {
          'username': "${phoneNumber.replaceAll('+', '')}_$randomSuffix",
          'contact_number': phoneNumber,
          'email':
              "${phoneNumber.replaceAll('+', '')}_$randomSuffix@phone.user",
          'login_type': LOGIN_TYPE_OTP,
          'user_type': USER_TYPE_USER,
          'display_name':
              'User ${phoneNumber.substring(phoneNumber.length - 4)}',
          'first_name': 'User',
          'last_name': phoneNumber.substring(phoneNumber.length - 4),
          'password': randomSuffix, // Use random string as password
          'uid': uid,
        };

        var registerResponse = await createUser(registerRequest);

        if (registerResponse.userData != null) {
          _debugLog(
              "Modified registration succeeded! UserID: ${registerResponse.userData!.id}");
          await saveUserData(registerResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_OTP);
          return {'success': true, 'userData': registerResponse.userData};
        }
      } catch (e) {
        _debugLog("Modified registration also failed: $e");
      }

      // 3. Last resort - try a different endpoint or approach
      // This depends on your backend capabilities, but could include trying to
      // reset the user's password, or a special endpoint for OTP authentication

      return {
        'success': false,
        'error': 'All alternate authentication methods failed'
      };
    } catch (e) {
      _debugLog("Alternative authentication process failed: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper to validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // Must start with + followed by country code and number
    if (!phoneNumber.startsWith('+')) return false;

    // Remove the + and check if remaining chars are digits
    String numbersOnly = phoneNumber.substring(1);
    if (!numbersOnly.contains(RegExp(r'^\d{10,14}$'))) return false;

    return true;
  }

  // Track OTP send attempts for rate limiting
  int getOTPSendCount(String phoneNumber) {
    return getIntAsync('otp_send_count_$phoneNumber', defaultValue: 0);
  }

  void incrementOTPSendCount(String phoneNumber) {
    int currentCount = getOTPSendCount(phoneNumber);
    setValue('otp_send_count_$phoneNumber', currentCount + 1);

    // Set expiry for this count (reset after 1 hour)
    Future.delayed(Duration(hours: 1), () {
      setValue('otp_send_count_$phoneNumber', 0);
    });
  }
}
