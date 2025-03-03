import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for handling account linking scenarios
class AccountLinkingUtility {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if email exists with a different auth method
  static Future<Map<String, dynamic>?> checkEmailExists(String email) async {
    try {
      QuerySnapshot result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        DocumentSnapshot doc = result.docs.first;
        return {
          'exists': true,
          'loginType': doc.data().toString().contains('login_type')
              ? doc['login_type']
              : 'unknown',
          'uid': doc['uid'],
        };
      }

      return {'exists': false};
    } catch (e) {
      log('Error checking email existence: $e');
      return null;
    }
  }

  /// Get user auth methods for an email (Firebase Auth)
  static Future<List<String>> getSignInMethodsForEmail(String email) async {
    try {
      return await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    } catch (e) {
      log('Error fetching sign-in methods: $e');
      return [];
    }
  }

  /// Show account linking dialog
  static void showAccountLinkingDialog(BuildContext context, String email, String existingMethod) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
         // title: Text(language.accountExists),
          //content: Text('${language.emailAlreadyUsed} $email\n${language.useAnotherMethod} $existingMethod.'),
          title: Text('الحساب موجود'),
          content: Text('البريد الإلكتروني $email\nاستخدم طريقة أخرى $existingMethod.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  /// Link accounts if possible
  static Future<bool> linkAccounts(User currentUser, AuthCredential newCredential) async {
    try {
      await currentUser.linkWithCredential(newCredential);
      return true;
    } catch (e) {
      log('Error linking accounts: $e');
      return false;
    }
  }
}