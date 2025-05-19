import 'package:flutter/foundation.dart';

class ZegoConfig {
  // ZegoCloud credentials
  static const int appID = 1538232199;
  static const String appSign = '67f1a7967199be0d29fedde50d65895d26e40d2a617d743f4d8c0f081bc6fb5b';
  
  // The userID and userName for the local user
  static String getLocalUserID() {
    // Generate a userID based on timestamp to ensure uniqueness
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Call ID generator
  static String generateCallID(String targetUserID) {
    // Create a unique call ID that combines caller and callee information
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return "call_${targetUserID}_$timestamp";
  }
}
