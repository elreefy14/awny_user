import 'dart:convert';
import 'package:booking_system_flutter/model/home_response.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/utils/json_utils.dart';
import 'package:nb_utils/nb_utils.dart';

/// Service class for managing home data
class HomeService {
  /// Base URL for API requests
  final String baseUrl;

  /// Constructor
  HomeService({required this.baseUrl});

  /// Fetch home data from the API
  Future<HomeResponse> getHomeData() async {
    final response = await handleResponse(
      await buildHttpResponse('${baseUrl}/api/home',
          method: HttpMethodType.GET),
    );

    return HomeResponse.fromJson(response);
  }

  /// Load home data from a local JSON file
  Future<HomeResponse> loadHomeDataFromFile(String filePath) async {
    try {
      final Map<String, dynamic> jsonData =
          await JsonUtils.loadJsonFromFile(filePath);
      return HomeResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load home data from file: $e');
    }
  }

  /// Parse home data from a JSON string
  HomeResponse parseHomeData(String jsonString) {
    try {
      final Map<String, dynamic> jsonData =
          json.decode(jsonString) as Map<String, dynamic>;
      return HomeResponse.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to parse home data: $e');
    }
  }
}
