import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';

class DirectPhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _resendToken;
  String? _verificationId; // Store verification ID as class property
  String? _smsCode;

  // Debug logging helper
  void _debugLog(String message) {
    print('🔐 PhoneAuth: $message');
  }

  // Initialize the FirebaseAuth settings
  Future<void> initializeAuth() async {
    try {
      // For testing purposes, we can disable app verification
      // This should be removed in production
      if (isWeb || isDesktop) {
        // Web environments don't support this setting
        return;
      }

      // Reset any existing auth state to prevent issues
      if (_auth.currentUser != null) {
        await _auth.signOut();
        _debugLog("Signed out existing user to prevent session state issues");
      }

      if (kDebugMode) {
        await _auth.setSettings(
          appVerificationDisabledForTesting:
              false, // Set to true only for testing
          phoneNumber: "+201203204500", // Test phone number for Egypt
          smsCode: "123456", // Test OTP code
        );
      }
    } catch (e) {
      _debugLog("Failed to initialize auth settings: $e");
    }
  }

  /// Request OTP verification for a phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    Function? onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        _debugLog("Auto verification completed");
        // Store SMS code from credential if available
        _smsCode = credential.smsCode;
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        _debugLog("Verification failed: ${e.message}");
        onVerificationFailed(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _debugLog("Code sent to $phoneNumber");

        // Store verification ID securely
        _verificationId = verificationId;
        _debugLog("Stored verification ID: $_verificationId");

        // Notify caller
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _debugLog("Auto retrieval timeout for $verificationId");

        // We should still keep the verification ID in case the user
        // manually enters the code after the timeout
        _verificationId = verificationId;

        if (onCodeAutoRetrievalTimeout != null) {
          onCodeAutoRetrievalTimeout();
        }
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // Resend OTP with token
  Future<void> resendOTP({
    required String phoneNumber,
    required BuildContext context,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    _debugLog("Resending OTP to $phoneNumber");

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        forceResendingToken: _resendToken,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          _debugLog("New verification code sent to $phoneNumber");
          _verificationId = verificationId; // Store verification ID
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _debugLog("Auto retrieval timeout for resend");
          _verificationId = verificationId; // Update verification ID on timeout
        },
      );
    } catch (e) {
      _debugLog("Error resending OTP: $e");
      throw "Failed to resend verification code: $e";
    }
  }

  /// Sign in with OTP
  Future<UserCredential> signInWithOTP(
      String? verificationId, String smsCode) async {
    try {
      // First check if the provided verificationId is valid
      final effectiveVerificationId =
          (verificationId != null && verificationId.isNotEmpty)
              ? verificationId
              : _verificationId;

      // If we still don't have a valid verification ID, throw an error
      if (effectiveVerificationId == null || effectiveVerificationId.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'No verification ID available. Please request OTP again.',
        );
      }

      // Create the credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: effectiveVerificationId,
        smsCode: smsCode,
      );

      // Sign in with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'session-expired') {
        log('Session expired');
      }
      rethrow;
    }
  }

  /// Sign in with credential
  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    try {
      _debugLog("Signing in with credential");
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      _debugLog("Error signing in with credential: $e");
      rethrow;
    }
  }

  // Get current verification ID
  String? getCurrentVerificationId() {
    return _verificationId;
  }

  // Process the authenticated user and integrate with your backend
  Future<Map<String, dynamic>> processAuthenticatedUser(
      UserCredential userCredential, String phoneNumber) async {
    try {
      _debugLog("Processing authenticated user");
      final user = userCredential.user;

      if (user == null) {
        throw 'No user found after authentication';
      }

      // Check if user is new or existing
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      _debugLog("Is new user: $isNewUser");

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
        'uid': user.uid,
      };

      // Integrate with your backend
      try {
        var loginResponse = await loginUser(request, isSocialLogin: true);
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_OTP);

        _debugLog("User successfully logged in");

        return {
          'success': true,
          'user': user,
          'isNewUser': isNewUser,
          'userData': loginResponse.userData
        };
      } catch (e) {
        _debugLog("Backend integration failed: $e");
        return {'success': false, 'error': e.toString()};
      }
    } catch (e) {
      _debugLog("User processing failed: $e");
      return {'success': false, 'error': e.toString()};
    }
  }
}
