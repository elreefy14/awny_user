import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../utils/constant.dart';
import '../network/rest_apis.dart';

class FirebasePhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  // Start phone verification process
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
    BuildContext? context,
  }) async {
    try {
      log('Verifying phone number: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      log('Error in verifyPhoneNumber: $e');
      throw e.toString();
    }
  }

  // Sign in with verification code
  Future<UserCredential> signInWithOTP(String otp) async {
    try {
      log('Signing in with OTP: $otp');

      if (_verificationId == null) {
        throw 'Verification ID is null. Please request OTP first.';
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      log('Error in signInWithOTP: $e');
      throw e.toString();
    }
  }

  // Sync user with backend after successful phone auth
  Future<void> syncUserWithBackend(
      UserCredential credential, String phoneNumber) async {
    try {
      final user = credential.user;
      if (user == null) throw 'No user found';

      // Get user's display name from phone number if not available
      String displayName = user.displayName ??
          'User ${phoneNumber.substring(phoneNumber.length - 4)}';

      // Prepare user data for Firestore
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'phone_number': phoneNumber,
        'email': user.email ?? '$phoneNumber@phone.user',
        'display_name': displayName,
        'last_login': FieldValue.serverTimestamp(),
        'created_at': user.metadata.creationTime != null
            ? Timestamp.fromDate(user.metadata.creationTime!)
            : FieldValue.serverTimestamp(),
      };

      // Update or create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );

      // Sync with backend API
      Map<String, dynamic> backendRequest = {
        'firebase_uid': user.uid,
        'phone_number': phoneNumber,
        'username': phoneNumber.replaceAll('+', '').replaceAll(' ', ''),
        'email': userData['email'],
        'first_name': displayName.split(' ').first,
        'last_name': displayName.split(' ').length > 1
            ? displayName.split(' ').sublist(1).join(' ')
            : '',
        'display_name': displayName,
        'login_type': LOGIN_TYPE_OTP,
        'user_type': USER_TYPE_USER,
      };

      // Attempt to login, if fails then register
      try {
        var response = await loginUser(backendRequest, isSocialLogin: true);
        await saveUserData(response.userData!);
      } catch (e) {
        if (e.toString().contains('User not found')) {
          var signupResponse = await createUser(backendRequest);
          await saveUserData(signupResponse.userData!);
        } else {
          throw e;
        }
      }

      await appStore.setLoginType(LOGIN_TYPE_OTP);
    } catch (e) {
      log('Error syncing user with backend: $e');
      throw e.toString();
    }
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Format phone number for verification
  static String formatPhoneNumber(String phoneNumber, String countryCode) {
    // Remove any non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle specific country formatting
    if (countryCode == 'EG') {
      // For Egypt (+20)
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1); // Remove leading zero
      }
    } else if (countryCode == 'SA') {
      // For Saudi Arabia (+966)
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1); // Remove leading zero
      }
    }

    return cleaned;
  }

  // Build the complete international phone number
  static String buildInternationalPhoneNumber(
      String phoneNumber, String countryCode, String dialCode) {
    String formattedNumber = formatPhoneNumber(phoneNumber, countryCode);
    return '+$dialCode$formattedNumber';
  }
}
