# Link Device Feature - Flutter App

## Overview
This feature allows users to link IoT devices to the Flutter app by scanning QR codes or manually entering device IDs. Users can then view real-time telemetry data from their connected devices.

## Features
- **QR Code Scanning**: Scan device QR codes for quick linking
- **Manual Device ID Entry**: Enter device ID manually (e.g., 56348699)
- **Real-time Telemetry**: View live sensor data, settings, and device state
- **Multi-language Support**: Available in English, Arabic, French, German, and Hindi
- **Error Handling**: Comprehensive error handling and user feedback
- **Debug Tools**: Built-in debugging tools for troubleshooting

## Technical Implementation

### Database Schema
The Firebase Realtime Database stores device data directly under `/{deviceId}` with the following structure:

```json
{
  "56348699": {
    "Sensors": {
      "Current": 2.5,
      "Door": 0,
      "Humidity": 65,
      "Main Realy": 1,
      "T1": "25.5",
      "T2": 26.8,
      "T3": 24.2,
      "T4": "23.1",
      "T5": "22.9",
      "Volt": 220.5
    },
    "Setting": {
      "Delay": 10,
      "Door open Time": 5,
      "High Volt": 240,
      "LOW Volt": 190,
      "Max Current": 20,
      "Setpoint Time": 50,
      "T1 Max": 70,
      "T2 Max": 80
    },
    "State": {
      "LOW T1": "15.0",
      "LOW T2": 16.2,
      "LOW T3": 14.8,
      "LOW T4": "13.5",
      "LOW T5": "12.9"
    }
  }
}
```

### Files Added/Modified

#### New Files:
1. **`lib/model/device_model.dart`** - Data models for device telemetry
2. **`lib/services/device_service.dart`** - Firebase Realtime Database service
3. **`lib/screens/device/link_device_screen.dart`** - Device linking UI
4. **`lib/screens/device/device_telemetry_screen.dart`** - Telemetry display UI
5. **`README_DEVICE_LINKING.md`** - This documentation

#### Modified Files:
1. **`pubspec.yaml`** - Added Firebase Database and QR scanner dependencies
2. **`lib/screens/dashboard/dashboard_screen.dart`** - Added Link Device navigation
3. **`lib/locale/languages.dart`** - Added linkDevice localization
4. **`lib/locale/language_en.dart`** - English translation
5. **`lib/locale/language_ar.dart`** - Arabic translation
6. **`lib/locale/languages_fr.dart`** - French translation
7. **`lib/locale/language_hi.dart`** - Hindi translation
8. **`lib/locale/languages_de.dart`** - German translation
9. **`lib/firebase_options.dart`** - Added database URL

### Dependencies Added
```yaml
firebase_database: ^11.0.0
qr_code_scanner: ^1.0.1
mobile_scanner: ^3.5.6
```

## UI Components

### Link Device Screen
- **Header Section**: Orange-themed section with device icon and instructions
- **QR Scanner**: Camera-based QR code scanner with close button
- **Manual Entry**: Text field for device ID input with validation
- **Help Section**: Instructions for device linking process

### Device Telemetry Screen
- **Status Indicator**: Green indicator showing device connection status
- **Sensor Grid**: 2x3 grid displaying sensor readings (Current, Voltage, Humidity, Door, T2, T3)
- **Settings Card**: Device configuration parameters
- **State Card**: Device state information
- **Debug Button**: Bug icon for manual data testing

## Data Models

### DeviceModel
```dart
class DeviceModel {
  final String deviceId;
  final DeviceSensors sensors;
  final DeviceSettings settings;
  final DeviceState state;
}
```

### DeviceSensors
```dart
class DeviceSensors {
  final double current;
  final int door;
  final int humidity;
  final int mainRelay;
  final String? t1;
  final double? t2;
  final double? t3;
  final String? t4;
  final String? t5;
  final double volt;
}
```

### DeviceSettings
```dart
class DeviceSettings {
  final int delay;
  final int doorOpenTime;
  final int highVolt;
  final int lowVolt;
  final int maxCurrent;
  final int setpointTime;
  final int t1Max;
  final int t2Max;
}
```

### DeviceState
```dart
class DeviceState {
  final String? lowT1;
  final double? lowT2;
  final double? lowT3;
  final String? lowT4;
  final String? lowT5;
}
```

## Firebase Service Methods

### DeviceService
- `getDeviceStream(String deviceId)` - Real-time device data stream
- `getDeviceData(String deviceId)` - One-time device data fetch
- `deviceExists(String deviceId)` - Check if device exists
- `getAllDevicesStream()` - Stream of all devices (admin)
- `updateDeviceSettings(String deviceId, DeviceSettings settings)` - Update device settings
- `getDeviceSensorsStream(String deviceId)` - Sensors-only stream
- `getDeviceStateStream(String deviceId)` - State-only stream

## Usage Instructions

### For Users:
1. Navigate to the "Link Device" tab in the bottom navigation
2. Choose between QR scanning or manual entry
3. For QR scanning: Tap "Open Scanner" and scan the device QR code
4. For manual entry: Enter the 8-digit device ID (e.g., 56348699)
5. Tap "Link Device" to connect
6. View real-time telemetry data in the device screen

### For Developers:
1. Ensure Firebase is properly configured with Realtime Database
2. Verify the database URL is set in `firebase_options.dart`
3. Test with the provided device ID: `56348699`
4. Use the debug button (bug icon) for troubleshooting

## Error Handling

### Common Issues:
1. **Device Not Found**: Verify device ID exists in Firebase
2. **Connection Errors**: Check internet connection and Firebase configuration
3. **Data Parsing Errors**: Verify JSON structure matches expected format
4. **Permission Issues**: Ensure camera permissions for QR scanning

### Debug Tools:
- **Console Logs**: Detailed logging with emoji indicators
- **Debug Button**: Manual data fetch testing
- **Error Messages**: User-friendly error messages in Arabic
- **Loading States**: Visual feedback during operations

## Testing Steps

### 1. Basic Functionality Test
```bash
# Run the app
flutter run

# Navigate to Link Device tab
# Enter device ID: 56348699
# Verify data loads correctly
```

### 2. QR Scanner Test
```bash
# Create a QR code with device ID: 56348699
# Test scanning functionality
# Verify automatic navigation to telemetry screen
```

### 3. Error Handling Test
```bash
# Test with invalid device ID
# Verify appropriate error messages
# Test network disconnection scenarios
```

### 4. Debug Testing
```bash
# Use debug button in telemetry screen
# Check console logs for detailed information
# Verify data parsing and display
```

## Troubleshooting

### If Device Data Doesn't Display:

1. **Check Firebase Configuration**:
   ```dart
   // Verify database URL in firebase_options.dart
   databaseURL: 'https://hanakol-eah-71378-default-rtdb.europe-west1.firebasedatabase.app'
   ```

2. **Check Database Path**:
   - Device data is stored directly under `/{deviceId}` (not `/devices/{deviceId}`)
   - Example: `https://hanakol-eah-71378-default-rtdb.europe-west1.firebasedatabase.app/56348699`

3. **Check Console Logs**:
   - Look for 🔍, 📡, 📊, ✅, ❌ emoji indicators
   - Verify device ID is being fetched correctly
   - Check for parsing errors

4. **Test Database Connection**:
   ```dart
   // Use debug button in telemetry screen
   // Check if data exists in Firebase console
   ```

5. **Verify Device ID**:
   - Ensure device ID exists in Firebase Realtime Database
   - Check JSON structure matches expected format
   - Verify device is online and sending data

### Common Solutions:

1. **Add Database URL**: If missing, add to `firebase_options.dart`
2. **Check Permissions**: Ensure camera permissions for QR scanning
3. **Verify Internet**: Check network connectivity
4. **Restart App**: Sometimes needed after Firebase configuration changes
5. **Database Path**: Ensure using correct path (direct device ID, not under 'devices' node)

## Security Considerations

1. **Device Access Control**: Consider implementing user-device associations
2. **Data Validation**: Validate device data before processing
3. **Error Logging**: Avoid logging sensitive device information
4. **Network Security**: Use HTTPS for all Firebase communications

## Future Enhancements

1. **Device Management**: Add/remove devices from user account
2. **Historical Data**: Store and display historical telemetry
3. **Alerts/Notifications**: Device status alerts and notifications
4. **Device Control**: Remote device control capabilities
5. **Data Export**: Export telemetry data to various formats
6. **Multi-device Dashboard**: View multiple devices simultaneously

## Support

For issues or questions:
1. Check console logs for detailed error information
2. Use the debug button for manual testing
3. Verify Firebase configuration and database structure
4. Test with the provided device ID: `56348699`

## Changelog

### Version 1.0.1
- Fixed database path issue: Device data is stored directly under `/{deviceId}` not `/devices/{deviceId}`
- Fixed duplicate Firebase initialization error
- Updated documentation to reflect correct database structure

### Version 1.0.0
- Initial implementation of Link Device feature
- QR code scanning and manual device ID entry
- Real-time telemetry display
- Multi-language support
- Comprehensive error handling and debugging tools 