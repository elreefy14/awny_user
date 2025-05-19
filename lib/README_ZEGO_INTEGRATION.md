# Zego Call Integration for Provider App

This document explains how to implement the provider side of the Zego call system to enable cross-app calling from the 3awney user app.

## Overview

The user app (3awney_user_app) initiates calls to providers using Zego Cloud voice calling service. When a user clicks the "اتصال" (Call) button, the app creates a call using the provider's phone number as the identifier. To receive these calls, the provider app needs to implement the corresponding Zego service.

## Required Setup in Provider App

### 1. Install Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  zego_uikit: ^2.28.12
  zego_uikit_prebuilt_call: ^3.20.0
  zego_uikit_signaling_plugin: ^2.8.3
```

### 2. Zego Configuration

Create a `zego_config.dart` file with these credentials (must match user app):

```dart
class ZegoConfig {
  // IMPORTANT: Use the same credentials as the user app
  static const int appID = 1538232199;
  static const String appSign = '67f1a7967199be0d29fedde50d65895d26e40d2a617d743f4d8c0f081bc6fb5b';
}
```

### 3. Create Zego Call Service

Create a file `zego_call_service.dart` with this implementation:

```dart
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:provider_app/utils/zego_config.dart'; // Update with your import path
import 'package:provider_app/main.dart'; // Update with your import path

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();

  factory ZegoCallService() => _instance;

  ZegoCallService._internal();

  // Initialize ZegoCloud services
  Future<void> initialize() async {
    await ZegoUIKit().init(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
    );
    log('ZegoCloud initialized successfully in provider app');
  }

  // Setup for the provider when they login
  Future<void> setupProvider(ProviderModel provider) async {
    // Use phone number as unique ID (remove any non-numeric characters)
    String providerID = provider.contactNumber.validate().replaceAll(RegExp(r'[^0-9]'), '');
    String providerName = provider.displayName.validate();

    if (providerID.isEmpty) {
      log('Warning: Provider phone number is empty, using ID instead');
      providerID = provider.id.toString();
    } else {
      log('Using provider phone number as ID: $providerID');
    }

    initCallInvitationService(providerID, providerName);
  }

  void initCallInvitationService(String providerID, String providerName) {
    try {
      final signalingPlugin = ZegoUIKitSignalingPlugin();

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: providerID,
        userName: providerName,
        plugins: [signalingPlugin],
        ringtoneConfig: ZegoRingtoneConfig(
          // Add your ringtone files to assets
          incomingCallPath: "assets/sounds/incoming.mp3",
          outgoingCallPath: "assets/sounds/outgoing.mp3",
        ),
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallReceived: (_, __, ___, ____, _____) {
            log('Provider received incoming call from user app');
          },
          onIncomingCallCanceled: (_, __, ___) {
            log('Incoming call canceled');
          },
          onOutgoingCallDeclined: (_, __, ___) {
            log('Call declined by user');
          },
        ),
      );

      log('Call invitation service initialized for provider: $providerName ($providerID)');
    } catch (e) {
      log('Error initializing call invitation service: $e');
    }
  }

  // Widget to handle incoming calls - add to your app's UI
  Widget getIncomingCallWidget() {
    return Container(); // The invitation UI is automatically added by the service
  }

  // Call this when provider logs out
  Future<void> uninitialize() async {
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
```

### 4. Initialize in Main.dart

Add to your `main.dart`:

```dart
// Declare at top level
ZegoCallService zegoCallService = ZegoCallService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Zego
  await zegoCallService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    zegoCallService.uninitialize();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Your app config
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Show call UI when provider is logged in
            if (providerStore.isLoggedIn)
              zegoCallService.getIncomingCallWidget(),
          ],
        );
      },
    );
  }
}
```

### 5. Set Up Provider on Login

In your provider login logic:

```dart
// When a provider logs in
Future<void> loginProvider(ProviderModel provider) async {
  // Your existing login code
  
  // Set up Zego call service
  await zegoCallService.setupProvider(provider);
}
```

### 6. Add Required Permissions

#### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

#### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>For voice calls with users</string>
```

## How It Works

1. User app calls a provider using the provider's phone number as the identifier
2. Zego service routes the call to the provider app where that phone number is registered
3. Provider app displays incoming call notification
4. Provider can accept or decline the call
5. If accepted, both parties connect for a voice call

## Testing

1. Ensure both apps have identical Zego credentials
2. Verify phone numbers are formatted consistently
3. Make test calls from user app to provider app
4. Verify ringtones play properly
5. Test call acceptance, rejection and audio quality

## Troubleshooting

- If calls aren't connecting, check logs for "Using provider phone number as ID: [number]"
- Ensure you have matching appID and appSign in both apps
- Check ringtone file paths are correct
- Verify permissions are granted on both devices

For more information, see the [Zego UIKit documentation](https://docs.zegocloud.com/article/13912). 