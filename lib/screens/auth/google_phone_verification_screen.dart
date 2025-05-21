import 'dart:async';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/services/whats_app_auth_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:lottie/lottie.dart';

class GooglePhoneVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> googleUserData;

  const GooglePhoneVerificationScreen({
    Key? key,
    required this.googleUserData,
  }) : super(key: key);

  @override
  _GooglePhoneVerificationScreenState createState() =>
      _GooglePhoneVerificationScreenState();
}

class _GooglePhoneVerificationScreenState
    extends State<GooglePhoneVerificationScreen> {
  // Form keys and controllers
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  // Country selection
  CountryCode selectedCountry =
      CountryCode.fromDialCode('+966'); // Default to Saudi Arabia

  // State variables
  bool isLoading = false;
  bool isOtpSent = false;
  bool isVerifying = false;
  int resendSeconds = 0;

  // Auth service
  WhatsAppAuthService _authService = WhatsAppAuthService();

  @override
  void initState() {
    super.initState();
    _authService.initialize();
  }

  // Format phone number
  String getFormattedPhoneNumber() {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }
    return "+${selectedCountry.dialCode}$phoneNumber";
  }

  // Send OTP handler
  Future<void> sendOTP() async {
    if (_phoneFormKey.currentState!.validate()) {
      hideKeyboard(context);
      setState(() {
        isLoading = true;
      });

      String phoneNumber = getFormattedPhoneNumber();

      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        onOTPSent: (success) {
          setState(() {
            isLoading = false;
            isOtpSent = success;
            if (success) {
              toast("تم إرسال رمز التحقق إلى رقم الجوال الخاص بك");
              startResendTimer();
            }
          });
        },
        onError: (error) {
          setState(() {
            isLoading = false;
          });
          toast(error);
        },
      );
    }
  }

  // Resend OTP handler
  Future<void> resendOTP() async {
    if (resendSeconds > 0) return;

    setState(() {
      isLoading = true;
    });

    String phoneNumber = getFormattedPhoneNumber();

    await _authService.resendOTP(
      phoneNumber: phoneNumber,
      onOTPSent: (success) {
        setState(() {
          isLoading = false;
          if (success) {
            toast("تم إرسال رمز التحقق إلى رقم الجوال الخاص بك");
            startResendTimer();
          }
        });
      },
      onError: (error) {
        setState(() {
          isLoading = false;
        });
        toast(error);
      },
    );
  }

  // Verify OTP handler
  Future<void> verifyOTP() async {
    if (_otpFormKey.currentState!.validate()) {
      hideKeyboard(context);
      setState(() {
        isVerifying = true;
      });

      try {
        bool isVerified =
            await _authService.verifyOTP(_otpController.text.trim());

        if (isVerified) {
          // Update the Google user data with the phone number
          Map<String, dynamic> updatedUserData =
              Map.from(widget.googleUserData);
          updatedUserData['contact_number'] = getFormattedPhoneNumber();

          try {
            // First try to login
            var loginResponse =
                await loginUser(updatedUserData, isSocialLogin: true);
            await saveUserData(loginResponse.userData!);
            await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

            navigateToDashboard();
          } catch (e) {
            // If login fails, try to register
            if (e.toString().contains('User not found')) {
              var signupResponse = await createUser(updatedUserData);
              await saveUserData(signupResponse.userData!);
              await appStore.setLoginType(LOGIN_TYPE_GOOGLE);
              navigateToDashboard();
            } else {
              throw e;
            }
          }
        } else {
          toast("رمز التحقق غير صحيح");
        }
      } catch (e) {
        toast(e.toString());
      } finally {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  // Navigate to dashboard
  void navigateToDashboard() {
    DashboardScreen().launch(context,
        isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  }

  // Start resend timer
  void startResendTimer() {
    resendSeconds = 60;
    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer timer) {
      if (resendSeconds == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {
          resendSeconds--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isOtpSent ? "التحقق من الرمز" : "التحقق من رقم الهاتف"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header logo/animation
                Container(
                  height: 180,
                  width: 180,
                  padding: EdgeInsets.all(16),
                  child: Lottie.network(
                    isOtpSent
                        ? 'https://assets3.lottiefiles.com/packages/lf20_cud6yxkz.json' // OTP verification animation
                        : 'https://assets3.lottiefiles.com/packages/lf20_cud6yxkz.json', // Phone verification animation
                    fit: BoxFit.cover,
                  ),
                ),

                // Welcome title
                Text(
                  isOtpSent
                      ? "التحقق من رقم الجوال"
                      : "أهلاً ${widget.googleUserData['first_name']}!",
                  style: boldTextStyle(size: 24),
                  textAlign: TextAlign.center,
                ),
                8.height,

                // Subtitle
                Text(
                  isOtpSent
                      ? "رجاءً أدخل رمز التحقق المرسل لرقم الواتساب الخاص بك"
                      : "أدخل رقم الجوال لإكمال عملية تسجيل الدخول",
                  style: secondaryTextStyle(size: 16),
                  textAlign: TextAlign.center,
                ),
                30.height,

                if (!isOtpSent)
                  // Phone number input form
                  Form(
                    key: _phoneFormKey,
                    child: Column(
                      children: [
                        Container(
                          decoration: boxDecorationWithRoundedCorners(
                            borderRadius: radius(8),
                            backgroundColor: context.cardColor,
                            border: Border.all(color: context.dividerColor),
                          ),
                          child: Row(
                            children: [
                              CountryCodePicker(
                                onChanged: (CountryCode country) {
                                  selectedCountry = country;
                                  setState(() {});
                                },
                                initialSelection: selectedCountry.code,
                                showCountryOnly: false,
                                showFlag: true,
                                showDropDownButton: true,
                                padding: EdgeInsets.zero,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                textStyle: primaryTextStyle(),
                                dialogTextStyle: primaryTextStyle(size: 14),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: context.dividerColor,
                              ),
                              8.width,
                              AppTextField(
                                controller: _phoneController,
                                textFieldType: TextFieldType.PHONE,
                                focus: FocusNode(),
                                nextFocus: FocusNode(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "رقم الجوال",
                                  hintStyle: secondaryTextStyle(size: 16),
                                ),
                                validator: (s) {
                                  if (s!.trim().isEmpty) {
                                    return "هذا الحقل مطلوب";
                                  } else if (s.trim().length < 9 ||
                                      s.trim().length > 12) {
                                    return "رقم جوال غير صحيح";
                                  }
                                  return null;
                                },
                              ).expand(),
                            ],
                          ),
                        ),
                        24.height,
                        AppButton(
                          text: "إرسال الرمز",
                          color: primaryColor,
                          width: context.width(),
                          onTap: isLoading ? null : sendOTP,
                        ),
                      ],
                    ),
                  )
                else
                  // OTP verification form
                  Form(
                    key: _otpFormKey,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: primaryColor, size: 20),
                              8.width,
                              Expanded(
                                child: Text(
                                  "تم إرسال رمز التحقق المكون من 6 أرقام إلى رقم الواتساب ${getFormattedPhoneNumber()}",
                                  style: secondaryTextStyle(
                                      color: textPrimaryColorGlobal, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        30.height,
                        AppTextField(
                          controller: _otpController,
                          textFieldType: TextFieldType.NUMBER,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: secondaryTextStyle(size: 20),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: radius(8),
                              borderSide:
                                  BorderSide(color: context.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: radius(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          autoFocus: true,
                          maxLength: 6,
                          validator: (s) {
                            if (s!.trim().isEmpty) return "هذا الحقل مطلوب";
                            if (s.length < 6)
                              return 'رمز التحقق يجب أن يكون 6 أرقام';
                            return null;
                          },
                          onFieldSubmitted: (s) => verifyOTP(),
                        ),
                        20.height,

                        // Verify button
                        AppButton(
                          text: "تحقق",
                          color: primaryColor,
                          width: context.width(),
                          onTap: isVerifying ? null : verifyOTP,
                        ),
                        16.height,

                        // Resend OTP link
                        TextButton(
                          onPressed: resendSeconds > 0 ? null : resendOTP,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "لم تتلقى الرمز؟ ",
                                  style: secondaryTextStyle(),
                                ),
                                TextSpan(
                                  text: resendSeconds > 0
                                      ? "إعادة الإرسال بعد (${resendSeconds.toString()})"
                                      : "إعادة الإرسال",
                                  style: boldTextStyle(
                                    color: resendSeconds > 0
                                        ? Colors.grey
                                        : primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        16.height,

                        // Change number link
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isOtpSent = false;
                              _otpController.clear();
                            });
                          },
                          child: Text(
                            'تغيير رقم الجوال',
                            style: boldTextStyle(
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          Visibility(
            visible: isLoading || isVerifying,
            child: Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
