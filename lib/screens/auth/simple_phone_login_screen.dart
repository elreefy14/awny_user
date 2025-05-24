import 'dart:async';
import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/services/whats_app_auth_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../component/loader_widget.dart';

class SimplePhoneLoginScreen extends StatefulWidget {
  final bool? isFromDashboard;
  final bool? isFromLogin;
  final bool returnExpected;

  SimplePhoneLoginScreen({
    this.isFromDashboard,
    this.isFromLogin,
    this.returnExpected = true,
  });

  @override
  _SimplePhoneLoginScreenState createState() => _SimplePhoneLoginScreenState();
}

class _SimplePhoneLoginScreenState extends State<SimplePhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final WhatsAppAuthService _authService = WhatsAppAuthService();

  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Country selectedCountry = Country(
    phoneCode: '20',
    countryCode: 'EG',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Egypt',
    example: '1001234567',
    displayName: 'Egypt (EG)',
    displayNameNoCountryCode: 'Egypt',
    e164Key: '',
  );

  FocusNode phoneFocus = FocusNode();
  FocusNode otpFocus = FocusNode();

  bool isCodeSent = false;
  bool isLoading = false;
  String? errorMessage;

  // Timer for OTP countdown
  Timer? _timer;
  int _remainingTime = 120; // 2 minutes in seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    _animationController.forward();

    afterBuildCreated(() async {
      // Initialize the WhatsApp Auth Service
      await _authService.initialize();
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    phoneFocus.dispose();
    otpFocus.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Start countdown timer for OTP
  void _startOtpTimer() {
    _remainingTime = 120;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // Format remaining time as mm:ss
  String get _formattedTime {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Phone number validation and formatting
  bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    try {
      formatPhoneNumber(phoneNumber, countryCode);
      return true;
    } catch (e) {
      return false;
    }
  }

  String formatPhoneNumber(String phoneNumber, String countryCode) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (countryCode == 'EG') {
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1);
      }
      if (cleaned.length != 10) {
        throw 'Invalid phone number length for Egypt';
      }
      if (!RegExp(r'^(10|11|12|15)').hasMatch(cleaned)) {
        throw 'Invalid Egyptian phone number prefix';
      }
    } else if (countryCode == 'SA') {
      if (cleaned.length > 0 && cleaned[0] == '0') {
        cleaned = cleaned.substring(1);
      }
      if (cleaned.length != 9) {
        throw 'Invalid phone number length for Saudi Arabia';
      }
      if (!cleaned.startsWith('5')) {
        throw 'Invalid Saudi phone number prefix';
      }
    }

    return cleaned;
  }

  // Get complete phone number with country code
  String getCompleteNumber() {
    try {
      String cleaned = formatPhoneNumber(
          phoneController.text.trim(), selectedCountry.countryCode);
      return '+${selectedCountry.phoneCode}${cleaned}';
    } catch (e) {
      return '+${selectedCountry.phoneCode}${phoneController.text.trim()}';
    }
  }

  // Get Egypt country details
  Country getEgyptCountry() {
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

  // Get Saudi Arabia country details
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

  // Send OTP
  void sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate phone number format
    if (!isValidPhoneNumber(
        phoneController.text.trim(), selectedCountry.countryCode)) {
      setState(() {
        errorMessage = selectedCountry.countryCode == 'EG'
            ? 'Enter valid Egyptian mobile number'
            : 'Enter valid Saudi mobile number';
      });
      toast(errorMessage);
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      isCodeSent = false;
      isLoading = true;
      errorMessage = null;
    });

    String phoneNumber = getCompleteNumber();

    try {
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        onOTPSent: (success) {
          setState(() {
            // Update local variable
            isCodeSent = true;
            isLoading = false;

            // Start timer for resend functionality
            _startOtpTimer();
          });

          // Focus on OTP field
          otpFocus.requestFocus();

          // Animate transition
          _animationController.reset();
          _animationController.forward();

          // Show success toast
          toast(language.otpCodeIsSentToYourMobileNumber);
        },
        onError: (errorMsg) {
          setState(() {
            isLoading = false;
            errorMessage = errorMsg;
          });
          toast(errorMessage);
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      toast(errorMessage);
    }
  }

  // Resend OTP
  void resendOTP() async {
    if (!_canResend) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.resendOTP(
        phoneNumber: getCompleteNumber(),
        onOTPSent: (success) {
          setState(() {
            isLoading = false;
            errorMessage = null;
          });

          // Reset OTP timer
          _startOtpTimer();

          toast(language.otpCodeIsSentToYourMobileNumber);
        },
        onError: (errorMsg) {
          setState(() {
            isLoading = false;
            errorMessage = errorMsg;
          });
          toast(errorMessage);
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = language.failedToSendOTP + ': $e';
      });
      toast(errorMessage);
    }
  }

  // Verify OTP
  void verifyOTP() async {
    if (otpController.text.trim().length != 6) {
      setState(() {
        errorMessage = language.pleaseEnterValidOTP;
      });
      toast(errorMessage);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Verify OTP with safe null handling
      String enteredOTP = otpController.text.trim();
      if (enteredOTP.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = language.pleaseEnterValidOTP;
        });
        toast(errorMessage);
        return;
      }

      bool isVerified = await _authService.verifyOTP(enteredOTP);

      if (isVerified) {
        try {
          // Process authenticated user
          var result =
              await _authService.processAuthenticatedUser(getCompleteNumber());

          if (result['success']) {
            setState(() {
              isLoading = false;
            });

            // Navigate based on return expectation
            if (widget.returnExpected) {
              finish(context, true);
            } else {
              // Navigate to dashboard
              DashboardScreen().launch(context,
                  isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
            }
          } else {
            setState(() {
              isLoading = false;

              // Handle specific error cases with user-friendly messages
              String errorString = result['error'].toString().toLowerCase();

              if (errorString.contains("already been taken")) {
                // This is the case where there's a contradiction in the API responses
                errorMessage =
                    "هناك مشكلة في تسجيل الدخول، جاري المحاولة مرة أخرى...";

                // Automatically retry once with a slight delay
                Future.delayed(Duration(milliseconds: 800), () {
                  setState(() {
                    isLoading = true;
                  });

                  // Try the alternate method in the service directly
                  _authService
                      .processAuthenticatedUserAlternate(getCompleteNumber())
                      .then((retryResult) {
                    setState(() {
                      isLoading = false;
                    });

                    if (retryResult['success']) {
                      // Navigate after successful retry
                      if (widget.returnExpected) {
                        finish(context, true);
                      } else {
                        DashboardScreen().launch(context,
                            isNewTask: true,
                            pageRouteAnimation: PageRouteAnimation.Fade);
                      }
                    } else {
                      setState(() {
                        errorMessage =
                            "فشل تسجيل الدخول. يرجى المحاولة مرة أخرى لاحقاً.";
                      });
                      toast(errorMessage);
                    }
                  }).catchError((e) {
                    setState(() {
                      isLoading = false;
                      errorMessage =
                          "حدث خطأ أثناء المحاولة البديلة: ${e.toString()}";
                    });
                    toast(errorMessage);
                  });
                });
              } else if (errorString.contains("user not found")) {
                errorMessage =
                    "لا يمكن العثور على المستخدم. يرجى التحقق من رقم الهاتف.";
              } else {
                errorMessage = result['error'] ?? language.signInFailed;
              }
            });

            if (errorMessage != null &&
                errorMessage!.isNotEmpty &&
                !errorMessage!.contains("جاري المحاولة")) {
              toast(errorMessage);
            }
          }
        } catch (e) {
          setState(() {
            isLoading = false;
            errorMessage = "Error processing user: ${e.toString()}";
          });
          toast(errorMessage);
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = language.invalidOTP;
        });
        toast(errorMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Verification error: ${e.toString()}";
      });
      toast(errorMessage);
    }
  }

  // Show country selection dialog
  Future<void> changeCountry() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.selectCountry, style: boldTextStyle(size: 20)),
              Divider(height: 20),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                title: Row(
                  children: [
                    Text('Egypt', style: primaryTextStyle()),
                    8.width,
                    Text('(+20)', style: secondaryTextStyle()),
                  ],
                ),
                subtitle: Text('Example: 1001234567',
                    style: secondaryTextStyle(size: 12)),
                trailing: selectedCountry.countryCode == 'EG'
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : null,
                onTap: () {
                  selectedCountry = getEgyptCountry();
                  setState(() {});
                  finish(context);
                },
                selected: selectedCountry.countryCode == 'EG',
                selectedColor: context.primaryColor,
              ),
              Divider(height: 0),
              ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                title: Row(
                  children: [
                    Text('Saudi Arabia', style: primaryTextStyle()),
                    8.width,
                    Text('(+966)', style: secondaryTextStyle()),
                  ],
                ),
                subtitle: Text('Example: 501234567',
                    style: secondaryTextStyle(size: 12)),
                trailing: selectedCountry.countryCode == 'SA'
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : null,
                onTap: () {
                  selectedCountry = getSaudiArabiaCountry();
                  setState(() {});
                  finish(context);
                },
                selected: selectedCountry.countryCode == 'SA',
                selectedColor: context.primaryColor,
              ),
            ],
          ),
        );
      },
    );

    // Clear phone number when country changes
    if (phoneController.text.isNotEmpty) {
      phoneController.clear();
      if (_formKey.currentState != null) {
        _formKey.currentState!.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            appStore.isDarkMode ? bottomNavBarDarkBgColor : orangePrimaryColor,
        elevation: 0,
        leading: BackWidget(iconColor: Colors.white),
        centerTitle: true,
        title: Text(
          isCodeSent ? language.confirmOTP : language.lblSignInWithOTP,
          style: boldTextStyle(color: Colors.white),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appStore.isDarkMode
              ? bottomNavBarDarkBgColor
              : orangePrimaryColor,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              context.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),

                        // App Logo with shadow
                        Center(
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                appLogo,
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // Title with WhatsApp branding for OTP screen
                        Container(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3, color: primaryColor),
                            ),
                          ),
                          child: Text(
                            isCodeSent
                                ? language.confirmOTP
                                : language.lblSignInWithOTP,
                            style: boldTextStyle(size: 28),
                            textAlign: TextAlign.start,
                          ),
                        ),

                        SizedBox(height: 12),

                        // Subtitle with WhatsApp mention
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            isCodeSent
                                ? 'OTP has been sent to your WhatsApp on ${getCompleteNumber()}'
                                : language.pleaseAddPhoneNumber,
                            style: secondaryTextStyle(size: 16),
                          ),
                        ),

                        SizedBox(height: 40),

                        // Phone input or OTP input based on state
                        if (!isCodeSent) ...[
                          // Phone number input
                          Text(language.hintContactNumberTxt,
                              style: boldTextStyle(size: 16)),
                          SizedBox(height: 8),

                          // Enhanced phone input field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country code selector with improved design
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: radiusOnly(
                                      topLeft: 12,
                                      bottomLeft: 12,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '+${selectedCountry.phoneCode}',
                                        style: boldTextStyle(),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down,
                                          color: primaryColor)
                                    ],
                                  ),
                                ).onTap(() => changeCountry()),

                                // Vertical divider
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: primaryColor.withOpacity(0.2),
                                ),

                                // Phone number field
                                Expanded(
                                  child: TextFormField(
                                    controller: phoneController,
                                    focusNode: phoneFocus,
                                    keyboardType: TextInputType.phone,
                                    style: primaryTextStyle(),
                                    textDirection: TextDirection
                                        .ltr, // Always LTR for phone numbers
                                    textAlign:
                                        appStore.selectedLanguageCode == 'ar'
                                            ? TextAlign.right
                                            : TextAlign.left,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: selectedCountry.example,
                                      hintStyle: secondaryTextStyle(),
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return language.phoneNumberRequired;
                                      }
                                      if (!isValidPhoneNumber(
                                          value, selectedCountry.countryCode)) {
                                        return selectedCountry.countryCode ==
                                                'EG'
                                            ? 'Enter valid Egyptian mobile number'
                                            : 'Enter valid Saudi mobile number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error message
                          if (errorMessage != null) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style:
                                          secondaryTextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 40),

                          // Continue button with app theme colors
                          AppButton(
                            onTap: sendOTP,
                            color: primaryColor,
                            width: context.width(),
                            text: 'Send OTP via WhatsApp',
                            textStyle: boldTextStyle(color: Colors.white),
                            shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            height: 55,
                          ),

                          SizedBox(height: 24),

                          // WhatsApp Security note with improved design
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withOpacity(0.05),
                                  primaryColor.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.security,
                                      color: primaryColor, size: 24),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("WhatsApp OTP Verification",
                                          style: boldTextStyle(size: 16)),
                                      SizedBox(height: 8),
                                      Text(
                                        "You'll receive a verification code on WhatsApp. Make sure your WhatsApp is active and connected.",
                                        style: secondaryTextStyle(size: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (isCodeSent) ...[
                          // OTP verification UI with theme branding
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.message,
                                    color: primaryColor, size: 22),
                              ),
                              16.width,
                              Text("WhatsApp Verification Code",
                                  style: boldTextStyle(size: 18)),
                            ],
                          ),

                          SizedBox(height: 24),

                          // WhatsApp OTP explanation with improved design
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
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Enter the 6-digit verification code sent to your WhatsApp number ${getCompleteNumber()}",
                                    style: secondaryTextStyle(
                                      color: textPrimaryColorGlobal,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32),

                          // OTP input field with enhanced design
                          Directionality(
                            textDirection:
                                TextDirection.ltr, // Always LTR for OTP
                            child: PinCodeTextField(
                              appContext: context,
                              length: 6,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              animationType: AnimationType.fade,
                              controller: otpController,
                              focusNode: otpFocus,
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(10),
                                fieldHeight: 55,
                                fieldWidth: 48,
                                activeFillColor: context.cardColor,
                                inactiveFillColor:
                                    primaryColor.withOpacity(0.03),
                                selectedFillColor:
                                    primaryColor.withOpacity(0.08),
                                activeColor: primaryColor,
                                inactiveColor: primaryColor.withOpacity(0.3),
                                selectedColor: primaryColor,
                              ),
                              animationDuration: Duration(milliseconds: 300),
                              backgroundColor: Colors.transparent,
                              enableActiveFill: true,
                              onChanged: (value) {
                                // Auto-submit when 6 digits entered
                                if (value.length == 6) {
                                  hideKeyboard(context);
                                }
                              },
                              onCompleted: (value) {
                                verifyOTP();
                              },
                              beforeTextPaste: (text) {
                                // Allow only numbers
                                return text != null &&
                                    text.contains(RegExp(r'^[0-9]+$'));
                              },
                            ),
                          ),

                          // Timer and resend option
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _canResend ? Icons.refresh : Icons.timer,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                8.width,
                                Text(
                                  _canResend
                                      ? "Didn't receive code?"
                                      : "Resend code in $_formattedTime",
                                  style: secondaryTextStyle(),
                                ),
                                if (_canResend)
                                  TextButton(
                                    onPressed: resendOTP,
                                    child: Text(
                                      "Resend",
                                      style: boldTextStyle(color: primaryColor),
                                    ),
                                  ),
                              ],
                            ),
                          ).center(),

                          // Error message
                          if (errorMessage != null) ...[
                            SizedBox(height: 24),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style:
                                          secondaryTextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 32),

                          // Verify button
                          AppButton(
                            onTap: verifyOTP,
                            color: primaryColor,
                            width: context.width(),
                            text: language.confirmOTP,
                            textStyle: boldTextStyle(color: Colors.white),
                            shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            height: 55,
                          ),

                          SizedBox(height: 24),

                          // Change number option
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios,
                                    size: 16, color: primaryColor),
                                8.width,
                                Text(
                                  "Change Phone Number",
                                  style: boldTextStyle(
                                    color: primaryColor,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ).center().onTap(() {
                            setState(() {
                              isCodeSent = false;
                              otpController.clear();
                              errorMessage = null;
                              _timer?.cancel();
                            });

                            // Animate transition
                            _animationController.reset();
                            _animationController.forward();
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading indicator
            AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: isLoading
                  ? Container(
                      color: Colors.black26,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: primaryColor),
                              SizedBox(height: 20),
                              Text(
                                isCodeSent
                                    ? "Verifying OTP..."
                                    : "Sending WhatsApp OTP...",
                                style: boldTextStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color:
            appStore.isDarkMode ? bottomNavBarDarkBgColor : orangePrimaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© ${DateTime.now().year} 3awney',
              style: secondaryTextStyle(color: Colors.white),
            ),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  language.helpSupport,
                  style: secondaryTextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
