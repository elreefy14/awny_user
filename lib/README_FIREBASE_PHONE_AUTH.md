# Firebase Phone Authentication Setup

## 1. Add SHA-1 Certificate to Firebase Project

Make sure you've added your SHA-1 certificate fingerprint to your Firebase project:

```
SHA1: 07:D2:68:B1:21:91:B0:77:88:3D:65:38:31:BF:FF:57:0A:B7:07:E8
```

## 2. Update AndroidManifest.xml

Add the following inside the `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Firebase Phone Auth -->
<meta-data
    android:name="com.google.firebase.components:com.google.firebase.auth.FirebaseAuthRegistrar"
    android:value="com.google.firebase.components.ComponentRegistrar" />

<!-- Automatically captures verification SMS on the device -->
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

## 3. Update build.gradle (app level)

Ensure the following dependencies are in your `android/app/build.gradle` file:

```gradle
dependencies {
    // Firebase Auth
    implementation 'com.google.firebase:firebase-auth:22.3.0'  
    // Google Play Services
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

## 4. Testing Phone Authentication

For testing:

1. Use the Firebase Phone Auth test numbers:
   - +20 650-555-3434 (Egypt)
   - +966 505-555-3434 (Saudi Arabia)

2. Use the fixed verification code: 123456

## 5. Troubleshooting

If you encounter issues with Firebase Phone Auth:

1. Verify SHA-1 fingerprint is correctly added to Firebase project
2. Check internet connectivity
3. Ensure Google Play Services is up to date on test devices
4. For real devices, make sure the phone number is correctly formatted with country code
5. Check Firebase console for any authentication errors or restrictions 