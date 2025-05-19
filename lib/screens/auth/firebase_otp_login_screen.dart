import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../component/loader_widget.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../dashboard/dashboard_screen.dart';

class FirebaseOTPLoginScreen extends StatefulWidget {
  const FirebaseOTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseOTPLoginScreen> createState() => _FirebaseOTPLoginScreenState();
}

class _FirebaseOTPLoginScreenState extends State<FirebaseOTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController numberController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  FocusNode phoneNumberFocus = FocusNode();
  FocusNode otpFocus = FocusNode();

  Country selectedCountry = defaultCountry();

  bool isCodeSent = false;
  bool isLoading = false;
  bool isResendEnabled = false;

  int resendTimer = 30;
  String? verificationId;
  int? resendToken;

  FirebasePhoneAuthService phoneAuthService = FirebasePhoneAuthService();

  // Country helpers
  static Country defaultCountry() {
    return Country(
      phoneCode: '20',
      countryCode: 'EG',
      e164Sc: 20,
      geographic: true,
      level: 1,
      name: 'Egypt',
      example: '1001234567',
      displayName: 'Egypt',
      displayNameNoCountryCode: 'EG',
      e164Key: '20-EG-0',
    );
  }

  // Get Saudi Arabia Country
  Country getSaudiArabiaCountry() {
    return Country(
      phoneCode: '966',
      countryCode: 'SA',
      e164Sc: 966,
      geographic: true,
      level: 1,
      name: 'Saudi Arabia',
      example: '501234567',
      displayName: 'Saudi Arabia',
      displayNameNoCountryCode: 'SA',
      e164Key: '966-SA-0',
    );
  }

  @override
  void initState() {
    super.initState();
    selectedCountry = defaultCountry();
  }

  @override
  void dispose() {
    numberController.dispose();
    otpController.dispose();
    phoneNumberFocus.dispose();
    otpFocus.dispose();
    super.dispose();
  }

  // Timer for resend
  void startResendTimer() {
    setState(() {
      isResendEnabled = false;
      resendTimer = 30;
    });

    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (resendTimer > 0) {
            resendTimer--;
          } else {
            isResendEnabled = true;
          }
        });
      }
      return resendTimer > 0;
    });
  }

  // Send OTP via Firebase
  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      setState(() {
        isLoading = true;
      });

      try {
        // Format phone number for international format
        String phoneNumber =
            FirebasePhoneAuthService.buildInternationalPhoneNumber(
                numberController.text.trim(),
                selectedCountry.countryCode,
                selectedCountry.phoneCode);

        log('Sending OTP to: $phoneNumber');

        await phoneAuthService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          onVerificationCompleted: (PhoneAuthCredential credential) async {
            log('Auto verification completed');
            // Auto sign-in for Android only
            await handleVerificationCompleted(credential, phoneNumber);
          },
          onVerificationFailed: (FirebaseAuthException e) {
            log('Verification failed: ${e.message}');
            setState(() {
              isLoading = false;
            });
            toast(e.message ?? language.somethingWentWrong);
          },
          onCodeSent: (String verId, int? token) {
            log('Code sent successfully');
            setState(() {
              isLoading = false;
              isCodeSent = true;
              verificationId = verId;
              resendToken = token;
            });

            // Start resend timer
            startResendTimer();

            // Focus on OTP field
            otpFocus.requestFocus();

            toast(language.otpCodeIsSentToYourMobileNumber);
          },
          onCodeAutoRetrievalTimeout: (String verId) {
            log('Auto retrieval timeout');
            verificationId = verId;
          },
          context: context,
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        toast(e.toString());
      }
    }
  }

  // Handle verification completed (mostly for Android auto-retrieval)
  Future<void> handleVerificationCompleted(
      PhoneAuthCredential credential, String phoneNumber) async {
    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await phoneAuthService.syncUserWithBackend(userCredential, phoneNumber);

      setState(() {
        isLoading = false;
      });

      onLoginSuccess();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      toast(e.toString());
    }
  }

  // Verify entered OTP
  Future<void> verifyOTP() async {
    hideKeyboard(context);

    if (otpController.text.trim().length != OTP_TEXT_FIELD_LENGTH) {
      return toast(language.pleaseEnterValidOTP);
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get the international phone number
      String phoneNumber =
          FirebasePhoneAuthService.buildInternationalPhoneNumber(
              numberController.text.trim(),
              selectedCountry.countryCode,
              selectedCountry.phoneCode);

      // Create credential and sign in
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId!, smsCode: otpController.text.trim());

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Sync with backend
      await phoneAuthService.syncUserWithBackend(userCredential, phoneNumber);

      setState(() {
        isLoading = false;
      });

      onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      if (e.code == 'invalid-verification-code') {
        toast(language.invalidOTP);
      } else {
        toast(e.message ?? language.somethingWentWrong);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      toast(e.toString());
    }
  }

  void onLoginSuccess() {
    DashboardScreen().launch(context,
        isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackWidget(),
        centerTitle: true,
        title: Text("Phone Verification", style: boldTextStyle(size: 20)),
      ),
      body: Form(
        key: formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  32.height,
                  Text(
                    isCodeSent
                        ? "OTP Verification"
                        : "Sign In with Phone Number",
                    style: primaryTextStyle(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  24.height,
                  if (!isCodeSent)
                    buildPhoneNumberWidget()
                  else
                    buildOTPWidget(),
                  16.height,
                  if (!isCodeSent)
                    AppButton(
                      text: language.btnSendOtp,
                      color: primaryColor,
                      textColor: white,
                      width: context.width(),
                      onTap: sendOTP,
                    )
                  else
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Didn't receive OTP?",
                                style: secondaryTextStyle()),
                            8.width,
                            Text(
                              isResendEnabled
                                  ? "Resend OTP"
                                  : 'Resend OTP in $resendTimer seconds',
                              style: boldTextStyle(
                                  color: isResendEnabled
                                      ? primaryColor
                                      : textSecondaryColorGlobal),
                            ).onTap(() {
                              if (isResendEnabled) {
                                sendOTP();
                              }
                            }),
                          ],
                        ),
                        16.height,
                        AppButton(
                          text: language.confirmOTP,
                          color: primaryColor,
                          textColor: white,
                          width: context.width(),
                          onTap: verifyOTP,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Observer(builder: (context) => LoaderWidget().visible(isLoading)),
          ],
        ),
      ),
    );
  }

  Widget buildPhoneNumberWidget() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: radius(),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border:
                      Border(right: BorderSide(color: context.dividerColor)),
                ),
                child: Row(
                  children: [
                    Text('+${selectedCountry.phoneCode}',
                        style: primaryTextStyle()),
                    4.width,
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ).onTap(() {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  onSelect: (Country country) {
                    setState(() {
                      selectedCountry = country;
                    });
                  },
                );
              }),
              8.width,
              AppTextField(
                controller: numberController,
                focus: phoneNumberFocus,
                textFieldType: TextFieldType.PHONE,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: language.lblEnterPhnNumber,
                ),
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Please enter phone number";
                  }
                  return null;
                },
              ).expand(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildOTPWidget() {
    return Column(
      children: [
        Text(
          'OTP sent to your phone number +${selectedCountry.phoneCode} ${numberController.text.trim()}',
          style: secondaryTextStyle(),
          textAlign: TextAlign.center,
        ),
        16.height,
        Text("Enter OTP", style: boldTextStyle()),
        16.height,
        PinCodeTextField(
          appContext: context,
          length: OTP_TEXT_FIELD_LENGTH,
          controller: otpController,
          focusNode: otpFocus,
          keyboardType: TextInputType.number,
          enableActiveFill: true,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: radius(),
            fieldHeight: 50,
            fieldWidth: 45,
            activeColor: primaryColor,
            selectedColor: context.cardColor,
            selectedFillColor: context.cardColor,
            activeFillColor: context.cardColor,
            inactiveFillColor: context.cardColor,
            inactiveColor: context.dividerColor,
          ),
          onCompleted: (v) {
            verifyOTP();
          },
          onChanged: (String value) {},
        ),
      ],
    );
  }
}
