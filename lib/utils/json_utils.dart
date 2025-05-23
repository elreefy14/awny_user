import 'dart:convert';
import 'package:flutter/services.dart';

/// Utility class for loading and parsing JSON data from files
class JsonUtils {
  /// Load JSON data from a file in the assets folder
  static Future<Map<String, dynamic>> loadJsonFromAsset(
      String assetPath) async {
    final String jsonString = await rootBundle.loadString(assetPath);
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Load JSON data from a local file
  static Future<Map<String, dynamic>> loadJsonFromFile(String filePath) async {
    final String jsonString = await rootBundle.loadString(filePath);
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}
