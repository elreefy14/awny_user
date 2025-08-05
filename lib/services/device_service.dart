import 'package:firebase_database/firebase_database.dart';
import 'package:booking_system_flutter/model/device_model.dart';

class DeviceService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Helper method to recursively convert Map<Object?, Object?> to Map<String, dynamic>
  static Map<String, dynamic> _convertMap(Map<dynamic, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        result[key.toString()] = _convertMap(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  // Get device data from Firebase Realtime Database
  static Stream<DeviceModel?> getDeviceStream(String deviceId) {
    print('🔍 Fetching device data for ID: $deviceId');
    return _database.child(deviceId).onValue.map((event) {
      print('📡 Firebase event received for device $deviceId');
      print('📊 Event snapshot exists: ${event.snapshot.exists}');
      print('📊 Event snapshot value: ${event.snapshot.value}');

      if (event.snapshot.value != null) {
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          print('📋 Raw data: $data');

          // Convert all nested maps recursively
          final convertedData = _convertMap(data);
          print('🔄 Converted data: $convertedData');

          final deviceModel = DeviceModel.fromJson(deviceId, convertedData);
          print('✅ Device model created successfully: ${deviceModel.deviceId}');
          print(
              '📊 Sensors: Current=${deviceModel.sensors.current}, Volt=${deviceModel.sensors.volt}');

          return deviceModel;
        } catch (e) {
          print('❌ Error parsing device data: $e');
          print('❌ Error stack trace: ${StackTrace.current}');
          return null;
        }
      } else {
        print('⚠️ No data found for device $deviceId');
        return null;
      }
    }).handleError((error) {
      print('❌ Error in device stream: $error');
      throw error;
    });
  }

  // Get device data once
  static Future<DeviceModel?> getDeviceData(String deviceId) async {
    try {
      print('🔍 Fetching device data once for ID: $deviceId');
      final snapshot = await _database.child(deviceId).get();
      print('📊 Snapshot exists: ${snapshot.exists}');
      print('📊 Snapshot value: ${snapshot.value}');

      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print('📋 Raw data: $data');

        // Convert all nested maps recursively
        final convertedData = _convertMap(data);
        print('🔄 Converted data: $convertedData');

        final deviceModel = DeviceModel.fromJson(deviceId, convertedData);
        print('✅ Device model created successfully: ${deviceModel.deviceId}');
        return deviceModel;
      }
      return null;
    } catch (e) {
      print('❌ Error getting device data: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Check if device exists
  static Future<bool> deviceExists(String deviceId) async {
    try {
      print('🔍 Checking if device exists: $deviceId');
      final snapshot = await _database.child(deviceId).get();
      final exists = snapshot.value != null;
      print('📊 Device $deviceId exists: $exists');
      return exists;
    } catch (e) {
      print('❌ Error checking device existence: $e');
      return false;
    }
  }

  // Get all devices (for admin purposes)
  static Stream<Map<String, DeviceModel>> getAllDevicesStream() {
    return _database.onValue.map((event) {
      final Map<String, DeviceModel> devices = {};
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value != null) {
            // Convert nested maps recursively
            final convertedValue = _convertMap(value as Map<dynamic, dynamic>);

            devices[key.toString()] = DeviceModel.fromJson(
              key.toString(),
              convertedValue,
            );
          }
        });
      }
      return devices;
    });
  }

  // Update device settings
  static Future<bool> updateDeviceSettings(
      String deviceId, DeviceSettings settings) async {
    try {
      await _database
          .child(deviceId)
          .child('Setting')
          .update(settings.toJson());
      return true;
    } catch (e) {
      print('Error updating device settings: $e');
      return false;
    }
  }

  // Get device sensors data only
  static Stream<DeviceSensors?> getDeviceSensorsStream(String deviceId) {
    return _database.child(deviceId).child('Sensors').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        // Convert nested maps recursively
        final convertedData = _convertMap(data);
        return DeviceSensors.fromJson(convertedData);
      }
      return null;
    });
  }

  // Get device state data only
  static Stream<DeviceState?> getDeviceStateStream(String deviceId) {
    return _database.child(deviceId).child('State').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        // Convert nested maps recursively
        final convertedData = _convertMap(data);
        return DeviceState.fromJson(convertedData);
      }
      return null;
    });
  }
}
