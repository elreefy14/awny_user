import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nb_utils/nb_utils.dart';

import 'base_services.dart';

class UserService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  UserService() {
    ref = fireStore.collection(USER_COLLECTION);
  }

  Future<void> createUserInFirestore({
    required String uid,
     String email = '',
     String firstName = '',
     String lastName = '',
    String profileImage = 'https://awnyapp.com/images/user/user.png',
    required int id,
  }) async {
    final now = DateTime.now();

    await ref!.doc(uid).set({
      'created_at': now.toString(),
      'updated_at': now.toString(),
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'uid': uid,
      'id': id,
    });
  }

  Future<int> getNextUserId() async {
    try {
      final QuerySnapshot result = await ref!
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        return 1; // Start with ID 1 if no users exist
      }

      final int lastId = result.docs.first['id'] as int;
      return lastId + 1;
    } catch (e) {
      print('Error generating next user ID: $e');
      throw e;
    }
  }

  Future<UserData> getUser({String? key, String? email}) {
    return ref!.where(key ?? "email", isEqualTo: email).limit(1).get().then((value) {
      if (value.docs.isNotEmpty) {
        return UserData.fromJson(value.docs.first.data() as Map<String, dynamic>);
      } else {
        throw language.userNotFound;
      }
    });
  }

  Future<UserData?> getUserNull({String? key, String? email}) {
    return ref!.where(key ?? "email", isEqualTo: email).limit(1).get().then((value) {
      if (value.docs.isNotEmpty) {
        return UserData.fromJson(value.docs.first.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  Stream<List<UserData>> users({String? searchText}) {
    return ref!.where('caseSearch', arrayContains: searchText.validate().isEmpty ? null : searchText!.toLowerCase()).snapshots().map((x) {
      return x.docs.map((y) {
        return UserData.fromJson(y.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<UserData> userByEmail(String? email) async {
    return await ref!.where('email', isEqualTo: email).limit(1).get().then((value) {
      if (value.docs.isNotEmpty) {
        return UserData.fromJson(value.docs.first.data() as Map<String, dynamic>);
      } else {
        throw '${language.lblNoUserFound}';
      }
    });
  }

  Stream<UserData> singleUser(String? id, {String? searchText}) {
    return ref!.where('uid', isEqualTo: id).limit(1).snapshots().map((event) {
      return UserData.fromJson(event.docs.first.data() as Map<String, dynamic>);
    });
  }

  Future<UserData> userByMobileNumber(String? phone) async {
    log("Phone $phone");
    return await ref!.where('phoneNumber', isEqualTo: phone).limit(1).get().then(
          (value) {
        log(value);
        if (value.docs.isNotEmpty) {
          return UserData.fromJson(value.docs.first.data() as Map<String, dynamic>);
        } else {
          throw "${language.lblNoUserFound}";
        }
      },
    );
  }

  Future<void> saveToContacts({required String senderId, required String receiverId}) async {
    return ref!.doc(senderId).collection(CONTACT_COLLECTION).doc(receiverId).update({
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch
    }).catchError((e) {
      throw "${language.lblUserNotCreated}";
    });
  }

  Future<bool> isReceiverInContacts({required String senderUserId, required String receiverUserId}) async {
    final contactRef = ref!.doc(senderUserId).collection(CONTACT_COLLECTION).doc(receiverUserId);
    final contactSnapshot = await contactRef.get();
    return contactSnapshot.exists;
  }

  Future<void> deleteUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.currentUser!.delete().then((value) async {
        // Delete user document from Firestore
        String uid = FirebaseAuth.instance.currentUser!.uid;
        await ref!.doc(uid).delete();
      }).catchError((e) {
        toast(e.toString(), print: true);
      });
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toString();
    await ref!.doc(uid).update(data);
  }

  Future<void> updateUserProfileImage(String uid, String profileImage) async {
    await updateUserData(uid, {
      'profile_image': profileImage,
    });
  }

  // Helper method to prepare user data for search
  List<String> _generateSearchKeywords(String text) {
    List<String> keywords = [];
    String word = '';

    for (int i = 0; i < text.length; i++) {
      word = word + text[i].toLowerCase();
      keywords.add(word);
    }
    return keywords;
  }

  // Method to update search keywords when user data changes
  Future<void> updateUserSearchKeywords(String uid, String firstName, String lastName) async {
    List<String> nameKeywords = _generateSearchKeywords('$firstName $lastName');

    await updateUserData(uid, {
      'caseSearch': nameKeywords,
    });
  }
}

// Initialize UserService globally
final userService = UserService();