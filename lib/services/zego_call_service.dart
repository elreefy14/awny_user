import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/zego_config.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();

  factory ZegoCallService() => _instance;

  ZegoCallService._internal();

  // Debug helper method to format and log call participants
  void _logCallParticipants({
    required String event,
    required String senderID,
    required String senderName,
    String? receiverID,
    String? receiverName,
    String? callID,
  }) {
    final logSeparator = '=' * 50;

    log('\n$logSeparator');
    log('📞 ZEGO CALL DEBUG: $event');
    log('📱 SENDER: $senderName (ID: $senderID)');
    if (receiverID != null) {
      log('📲 RECEIVER: ${receiverName ?? "Unknown"} (ID: $receiverID)');
    }
    if (callID != null) {
      log('🔑 CALL ID: $callID');
    }
    log('⏰ TIMESTAMP: ${DateTime.now()}');
    log(logSeparator);
  }

  // Initialize ZegoCloud services
  Future<void> initialize() async {
    await ZegoUIKit().init(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
    );
    log('ZegoCloud initialized successfully');
  }

  // Setup for the current user when they login
  Future<void> setupUser(UserData userData) async {
    String userID =
        userData.contactNumber.validate().replaceAll(RegExp(r'[^0-9]'), '');
    String userName = userData.displayName.validate();

    if (userID.isEmpty) {
      userID = userData.id.toString();
      log('No phone number found, using user ID instead: $userID');
    } else {
      log('Using phone number as user ID: $userID');
    }

    _logCallParticipants(
      event: 'USER SETUP',
      senderID: userID,
      senderName: userName,
    );

    initCallInvitationService(userID, userName);
  }

  void initCallInvitationService(String userID, String userName) {
    try {
      final signalingPlugin = ZegoUIKitSignalingPlugin();

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: userID,
        userName: userName,
        plugins: [signalingPlugin],
        ringtoneConfig: ZegoRingtoneConfig(
          incomingCallPath: "assets/sounds/booking_alert.mp3",
          outgoingCallPath: "assets/sounds/booking_alert.mp3",
        ),
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallReceived: (callID, caller, callType, callData, list) {
            log('Incoming call received from another app');
            _logCallParticipants(
              event: 'INCOMING CALL RECEIVED',
              senderID: caller.id,
              senderName: caller.name,
              receiverID: userID,
              receiverName: userName,
              callID: callID,
            );
          },
          onIncomingCallCanceled: (callID, caller, callData) {
            log('Incoming call canceled');
            _logCallParticipants(
              event: 'INCOMING CALL CANCELED',
              senderID: caller.id,
              senderName: caller.name,
              receiverID: userID,
              receiverName: userName,
              callID: callID,
            );
          },
          // Commenting out as it's causing compatibility issues with SDK version
          // onOutgoingCallAccepted: (_, __, ___) {
          //   log('Call accepted by provider');
          // },
          onOutgoingCallDeclined: (callID, caller, callData) {
            log('Call declined by provider');
            _logCallParticipants(
              event: 'OUTGOING CALL DECLINED',
              senderID: userID,
              senderName: userName,
              receiverID: caller.id,
              receiverName: caller.name,
              callID: callID,
            );
          },
        ),
      );

      log('Call invitation service initialized for user: $userName ($userID)');
    } catch (e) {
      log('Error initializing call invitation service: $e');
    }
  }

  // Start a one-on-one video call
  void startVideoCall(BuildContext context, UserData targetUser) {
    if (targetUser.id == null) {
      toast(language.somethingWentWrong);
      return;
    }

    // Use phone number as target ID (remove any non-numeric characters)
    String targetUserID =
        targetUser.contactNumber.validate().replaceAll(RegExp(r'[^0-9]'), '');
    String targetUserName = targetUser.displayName.validate();

    if (targetUserID.isEmpty) {
      toast("Provider's phone number is required for calling");
      return;
    }

    log('Starting video call with provider: $targetUserName (Phone: $targetUserID)');

    String callID = "call_${DateTime.now().millisecondsSinceEpoch}";

    try {
      ZegoUIKitPrebuiltCallConfig callConfig =
          ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
      callConfig.turnOnCameraWhenJoining = true;
      callConfig.useSpeakerWhenJoining = true;

      // Use current user's phone number as caller ID if available
      String callerID = appStore.userContactNumber
          .validate()
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (callerID.isEmpty) {
        callerID = appStore.userId.toString();
      }

      _logCallParticipants(
        event: 'STARTING VIDEO CALL',
        senderID: callerID,
        senderName: appStore.userFullName,
        receiverID: targetUserID,
        receiverName: targetUserName,
        callID: callID,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZegoUIKitPrebuiltCall(
            appID: ZegoConfig.appID,
            appSign: ZegoConfig.appSign,
            callID: callID,
            userID: callerID,
            userName: appStore.userFullName,
            config: callConfig,
            plugins: [ZegoUIKitSignalingPlugin()],
          ),
        ),
      );
    } catch (e) {
      toast('Error making video call: $e');
      log('Error making video call: $e');
    }
  }

  // Start a one-on-one voice call
  void startVoiceCall(BuildContext context, UserData targetUser) {
    if (targetUser.id == null) {
      toast(language.somethingWentWrong);
      return;
    }

    // Use phone number as target ID (remove any non-numeric characters)
    String targetUserID =
        targetUser.contactNumber.validate().replaceAll(RegExp(r'[^0-9]'), '');
    String targetUserName = targetUser.displayName.validate();

    if (targetUserID.isEmpty) {
      toast("Provider's phone number is required for calling");
      return;
    }

    log('Starting voice call with provider: $targetUserName (Phone: $targetUserID)');

    // Create a unique call ID that includes both caller and target info to ensure unique sessions
    String callID = "call_${DateTime.now().millisecondsSinceEpoch}";

    try {
      // For cross-app communication, we use the call invitation service
      // Get caller ID (phone number preferred)
      String callerID = appStore.userContactNumber
          .validate()
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (callerID.isEmpty) {
        callerID = appStore.userId.toString();
      }

      _logCallParticipants(
        event: 'STARTING VOICE CALL',
        senderID: callerID,
        senderName: appStore.userFullName,
        receiverID: targetUserID,
        receiverName: targetUserName,
        callID: callID,
      );

      // Method 1: Direct call implementation using ZegoUIKitPrebuiltCall
      ZegoUIKitPrebuiltCallConfig callConfig =
          ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
      callConfig.turnOnCameraWhenJoining = false;
      callConfig.useSpeakerWhenJoining = true;

      // This is enough for the current SDK version
      // We don't need onOnlySelfInRoom which isn't available in this version

      // This opens a call interface in the user app
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZegoUIKitPrebuiltCall(
            appID: ZegoConfig.appID,
            appSign: ZegoConfig.appSign,
            callID: callID,
            userID: callerID,
            userName: appStore.userFullName,
            config: callConfig,
            plugins: [ZegoUIKitSignalingPlugin()],
          ),
        ),
      );

      // Log the call attempt for debugging
      log('Voice call initiated to provider with ID: $targetUserID');
      log('Using call ID: $callID');
    } catch (e) {
      toast('Error making voice call: $e');
      log('Error making voice call: $e');
    }
  }

  // Get a widget that can be used to handle incoming calls
  Widget getIncomingCallWidget() {
    return Container(); // In version 2.28.12, the invitation UI is automatically added by the service
  }

  // Uninitialize when user logs out
  Future<void> uninitialize() async {
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
