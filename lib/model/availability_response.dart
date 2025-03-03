// 1. Create a specific model for the availability response
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../network/network_utils.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../utils/constant.dart';

class AvailabilityResponse {
  bool? exists;

  AvailabilityResponse({this.exists});

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponse(
      exists: json['exists'],
    );
  }
}

// 2. Update the service function to use the specific model
// 3. Update the checkLocationAndShowDialog method
