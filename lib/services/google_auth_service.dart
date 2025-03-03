import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../model/user_data_model.dart';
import '../network/network_utils.dart';
import '../network/rest_apis.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<String?> getPhoneNumber(UserData userData) async {
    // Check if user has phone number in Firestore
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userData.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['contact_number'] as String?;
      }
    } catch (e) {
      log('Error getting phone number: $e');
    }
    return null;
  }

  Future<void> updateUserPhone(String uid, String phoneNumber) async {
    try {
      // Update in Firestore
      await _firestore.collection('users').doc(uid).set({
        'contact_number': phoneNumber,
        //'updated_at': FieldValue.serverTimestamp(),
      });

      // Update in backend
      Map<String, dynamic> request = {
        'uid': uid,
        'contact_number': phoneNumber,
      };

      await handleResponse(await buildHttpResponse('update-user-phone',
          request: request, method: HttpMethodType.POST));
    } catch (e) {
      log('Error updating phone: $e');
      throw 'Failed to update phone number';
    }
  }

  /// Sign in with Google and get user data
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'User cancelled the sign-in process';
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) throw 'Failed to sign in with Google';

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Return user data
      return {
        'user': user,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'isNewUser': isNewUser,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
        'googleUser': googleUser,
      };
    } catch (e) {
      log('Google Sign-In Error: $e');
      throw e.toString();
    }
  }

  /// Save or update user in Firestore
  Future<void> saveUserToFirestore(User user) async {
    try {
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'firstName': user.displayName?.split(' ').first,
        'lastName': ((user.displayName?.split(' ').length ?? 1) > 1)
            ? user.displayName?.split(' ').sublist(1).join(' ')
            : '',
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Check if user already exists
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Update existing user
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'email': user.email,
          'photoURL': user.photoURL,
          'displayName': user.displayName,
        });
      } else {
        // Create new user
        await _firestore.collection('users').doc(user.uid).set(userData);
      }
    } catch (e) {
      log('Error saving user to Firestore: $e');
      throw 'Failed to save user data: ${e.toString()}';
    }
  }

  /// Handle Google user authentication with backend
  Future<Map<String, dynamic>> handleGoogleUser(Map<String, dynamic> userData) async {
    try {
      final User user = userData['user'];

      // Get name components from Google data
      String firstName = '';
      String lastName = '';

      if (user.displayName != null) {
        List<String> nameParts = user.displayName!.split(' ');
        firstName = nameParts.first;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }

      // Return data for registration
      return {
        'success': true,
        'registrationData': {
          'first_name': firstName.validate(),
          'last_name': lastName.validate(),
          'username': user.email?.split('@').first.replaceAll('.', '').toLowerCase() ?? '',
          'email': user.email.validate(),
          'social_image': user.photoURL.validate(),
          'login_type': LOGIN_TYPE_GOOGLE,
          'user_type': USER_TYPE_USER,
          'password': user.uid, // Use Firebase UID as password
        },
        'isNewUser': userData['isNewUser'],
      };
    } catch (e) {
      log('Error handling Google user: $e');
      throw 'Authentication failed: ${e.toString()}';
    }
  }  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log('Error signing out: $e');
      throw 'Failed to sign out';
    }
  }
}