
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a secure password that's at least 6 characters
  String generateSecurePassword(String phoneNumber) {
    // Remove any '+' from the phone number
    String cleanPhone = phoneNumber.replaceAll('+', '');

    // Ensure the base is at least 6 characters
    String base = cleanPhone.padRight(6, '0');

    // Add a random suffix to make it more secure
    String randomSuffix = Random().nextInt(999999).toString().padLeft(6, '0');

    return base + randomSuffix;
  }

  // Check if user exists in Firestore
  Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      String formattedPhoneNumber = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';

      var userQuery = await _firestore
          .collection('users')
          .where('last_name', isEqualTo: formattedPhoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return {
          ...userQuery.docs.first.data(),
          'docId': userQuery.docs.first.id,
        };
      }
      return null;
    } catch (e) {
      log('Error checking user existence: $e');
      return null;
    }
  }

  // Create or update user in Firestore
  Future<String> saveUserToFirestore(String uid, String phoneNumber, String password) async {
    try {
      final nextId = await userService.getNextUserId();
      String formattedPhoneNumber = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';

      Map<String, dynamic> userData = {
        'uid': uid,
        'email': '${phoneNumber.replaceAll('+', '')}@phone.user',
        'first_name': 'User',
        'last_name': formattedPhoneNumber,
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString(),
        'id': nextId,
        'profile_image': 'https://awnyapp.com/images/user/user.png',
        'password': password // Store password for future authentication
      };

      await _firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));
      return uid;
    } catch (e) {
      log('Error saving user to Firestore: $e');
      throw 'Failed to save user data';
    }
  }

  // Main authentication method
  Future<Map<String, dynamic>> authenticatePhoneUser(String phoneNumber) async {
    try {
      String email = '${phoneNumber.replaceAll('+', '')}@phone.user';

      // First check if user exists
      final existingUser = await getUserByPhone(phoneNumber);
      UserCredential? userCredential;

      if (existingUser != null) {
        // For existing users
        String password = existingUser['password'] ?? generateSecurePassword(phoneNumber);

        try {
          // Try to sign in with existing password
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          // If sign in fails, update password and try again
          password = generateSecurePassword(phoneNumber);

          // Update password in Firestore
          await _firestore.collection('users').doc(existingUser['docId']).update({
            'password': password,
            'updated_at': DateTime.now().toString()
          });

          // Create new auth if needed
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (e) {
            // User might exist in Auth but not in Firestore
            if (!e.toString().contains('email-already-in-use')) {
              throw e;
            }
          }

          // Sign in with new password
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        // New user flow
        final nextId = await userService.getNextUserId();
        String uid = nextId.toString();
        String password = generateSecurePassword(phoneNumber);

        // Create new user
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save to Firestore with password
        await saveUserToFirestore(uid, phoneNumber, password);
      }

      if (userCredential?.user == null) throw 'Authentication failed';

      // Sync with backend
      Map<String, dynamic> request = {
        'username': phoneNumber.replaceAll('+', ''),
        'password': userCredential.user!.uid,
        'login_type': 'phone',
        'contact_number': phoneNumber,
        'email': email,
        'first_name': 'User',
        'last_name': phoneNumber,
      };

      var loginResponse = await loginUser(request, isSocialLogin: true);
      await saveUserData(loginResponse.userData!);
      await appStore.setLoginType('phone');

      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': existingUser == null,
        'userData': loginResponse.userData
      };

    } catch (e) {
      log('Phone authentication error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toString();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      log('Error updating profile: $e');
      throw 'Failed to update profile';
    }
  }
}