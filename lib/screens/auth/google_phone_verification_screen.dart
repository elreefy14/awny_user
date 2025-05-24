import 'dart:async';
import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/services/whats_app_otp_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class GooglePhoneVerificationScreen extends StatefulWidget {
  final User googleUser;
  final String firstName;
  final String lastName;
  final String email;

  const GooglePhoneVerificationScreen({
    Key? key,
    required this.googleUser,
    required this.firstName,
    required this.lastName,
    required this.email,
  }) : super(key: key);

  @override
  _GooglePhoneVerificationScreenState createState() =>
      _GooglePhoneVerificationScreenState();
}

class _GooglePhoneVerificationScreenState
    extends State<GooglePhoneVerificationScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  late Country selectedCountry;
  String? errorText;
  String? currentOTP;
  bool isCodeSent = false;
  bool isResendEnabled = false;
  int resendTimer = 60;
  Timer? _timer;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    selectedCountry = getEgyptCountry();

    // Initialize animations
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

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

  bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    try {
      String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      if (countryCode == 'EG') {
        if (cleaned.length > 0 && cleaned[0] == '0') {
          cleaned = cleaned.substring(1);
        }
        if (cleaned.length != 10) return false;
        return RegExp(r'^(10|11|12|15)').hasMatch(cleaned);
      } else if (countryCode == 'SA') {
        if (cleaned.length > 0 && cleaned[0] == '0') {
          cleaned = cleaned.substring(1);
        }
        if (cleaned.length != 9) return false;
        return cleaned.startsWith('5');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String formatPhoneNumber(String phoneNumber, String countryCode) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length > 0 && cleaned[0] == '0') {
      cleaned = cleaned.substring(1);
    }
    return '+${selectedCountry.phoneCode}$cleaned';
  }

  void changeCountry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(language.selectCountry, style: boldTextStyle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCountryTile('Egypt (+20)', 'EG', getEgyptCountry()),
              Divider(height: 1, color: context.dividerColor),
              _buildCountryTile(
                  'Saudi Arabia (+966)', 'SA', getSaudiArabiaCountry()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryTile(String title, String code, Country country) {
    bool isSelected = selectedCountry.countryCode == code;
    return ListTile(
      title: Text(title, style: primaryTextStyle()),
      trailing: isSelected ? Icon(Icons.check, color: primaryColor) : null,
      selected: isSelected,
      selectedColor: primaryColor,
      onTap: () {
        selectedCountry = country;
        setState(() {});
        finish(context);
      },
    );
  }

  void startResendTimer() {
    isResendEnabled = false;
    resendTimer = 60;
    _timer?.cancel();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendTimer > 0) {
        setState(() => resendTimer--);
      } else {
        setState(() => isResendEnabled = true);
        timer.cancel();
      }
    });
  }

  Future<void> sendOTP() async {
    if (phoneController.text.isEmpty) {
      setState(() => errorText = language.phoneNumberRequired);
      return;
    }

    if (!isValidPhoneNumber(
        phoneController.text, selectedCountry.countryCode)) {
      setState(() => errorText = selectedCountry.countryCode == 'EG'
          ? language.invalidEgyptianPhoneNumber
          : language.invalidSaudiPhoneNumber);
      return;
    }

    try {
      appStore.setLoading(true);
      setState(() => errorText = null);

      String formattedPhone =
          formatPhoneNumber(phoneController.text, selectedCountry.countryCode);
      currentOTP = WhatsAppOTPService.generateOTP();

      bool success =
          await WhatsAppOTPService.sendOTP(formattedPhone, currentOTP!);

      if (success) {
        setState(() {
          isCodeSent = true;
          errorText = null;
        });

        // Start slide animation for OTP section
        _slideController.forward();
        startResendTimer();

        toast('تم إرسال رمز التحقق عبر واتساب', gravity: ToastGravity.CENTER);
      } else {
        throw 'فشل في إرسال رمز التحقق. يرجى المحاولة مرة أخرى';
      }
    } catch (e) {
      setState(() => errorText = e.toString());
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> resendOTP() async {
    if (!isResendEnabled) return;

    try {
      appStore.setLoading(true);

      String formattedPhone =
          formatPhoneNumber(phoneController.text, selectedCountry.countryCode);
      currentOTP = WhatsAppOTPService.generateOTP();

      bool success =
          await WhatsAppOTPService.sendOTP(formattedPhone, currentOTP!);

      if (success) {
        startResendTimer();
        toast('تم إعادة إرسال رمز التحقق', gravity: ToastGravity.CENTER);
      } else {
        throw 'فشل في إعادة إرسال رمز التحقق';
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> verifyOTP() async {
    if (otpController.text.length != 6) {
      toast('يرجى إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    if (currentOTP == null) {
      toast('يرجى طلب رمز التحقق أولاً');
      return;
    }

    if (otpController.text != currentOTP) {
      toast('رمز التحقق غير صحيح');
      return;
    }

    try {
      appStore.setLoading(true);

      // Complete Google Sign-In with phone verification
      String formattedPhone =
          formatPhoneNumber(phoneController.text, selectedCountry.countryCode);

      Map<String, dynamic> request = {
        'email': widget.email,
        'login_type': LOGIN_TYPE_GOOGLE,
        'first_name': widget.firstName,
        'last_name': widget.lastName,
        'username':
            widget.email.split('@').first.replaceAll('.', '').toLowerCase(),
        'user_type': 'user',
        'display_name': '${widget.firstName} ${widget.lastName}',
        'uid': widget.googleUser.uid,
        'social_image': widget.googleUser.photoURL,
        'contact_number': formattedPhone,
        'phone_verified': true,
      };

      try {
        var loginResponse = await loginUser(request, isSocialLogin: true);
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        _navigateToSuccess();
      } catch (e) {
        if (e.toString().contains('User not found')) {
          var signupResponse = await createUser(request);
          await saveUserData(signupResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

          _navigateToSuccess();
        } else {
          throw e;
        }
      }
    } catch (e) {
      toast('حدث خطأ أثناء التحقق: ${e.toString()}');
    } finally {
      appStore.setLoading(false);
    }
  }

  void _navigateToSuccess() {
    toast('تم تسجيل الدخول بنجاح!', gravity: ToastGravity.CENTER);

    // Navigate to dashboard
    Future.delayed(Duration(milliseconds: 500), () {
      DashboardScreen().launch(context,
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackWidget(iconColor: context.iconColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness:
              appStore.isDarkMode ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),

                    40.height,

                    // Phone Input Section
                    if (!isCodeSent) _buildPhoneInputSection(),

                    // OTP Verification Section
                    if (isCodeSent) _buildOTPSection(),

                    32.height,

                    // Action Button
                    _buildActionButton(),

                    24.height,

                    // Security Info
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          Observer(
            builder: (_) => appStore.isLoading
                ? Container(
                    color: Colors.black26,
                    child: LoaderWidget().center(),
                  )
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome back message
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security, color: primaryColor, size: 24),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً ${widget.firstName}!',
                      style: boldTextStyle(size: 18),
                    ),
                    4.height,
                    Text(
                      'نحتاج للتحقق من رقم هاتفك لإكمال عملية تسجيل الدخول',
                      style: secondaryTextStyle(size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        24.height,

        Text(
          isCodeSent ? 'أدخل رمز التحقق' : 'أضف رقم هاتفك',
          style: boldTextStyle(size: 24),
        ),
        8.height,
        Text(
          isCodeSent
              ? 'تم إرسال رمز التحقق إلى واتساب ${formatPhoneNumber(phoneController.text, selectedCountry.countryCode)}'
              : 'سيتم إرسال رمز التحقق عبر واتساب',
          style: secondaryTextStyle(size: 16),
        ),
      ],
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('رقم الهاتف', style: boldTextStyle(size: 16)),
        12.height,
        Row(
          children: [
            // Country Selector
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: context.dividerColor),
                borderRadius: BorderRadius.circular(12),
                color: context.cardColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${selectedCountry.phoneCode}',
                    style: boldTextStyle(),
                  ),
                  8.width,
                  Icon(Icons.arrow_drop_down, color: context.iconColor),
                ],
              ),
            ).onTap(() => changeCountry()),

            16.width,

            // Phone Input
            Expanded(
              child: AppTextField(
                controller: phoneController,
                textFieldType: TextFieldType.PHONE,
                decoration: InputDecoration(
                  hintText: selectedCountry.example,
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  if (errorText != null) {
                    setState(() => errorText = null);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رمز التحقق', style: boldTextStyle(size: 16)),
          12.height,

          // WhatsApp info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF25D366).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF25D366).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                8.width,
                Expanded(
                  child: Text(
                    'تحقق من رسائل واتساب الخاصة بك',
                    style:
                        secondaryTextStyle(size: 12, color: Color(0xFF25D366)),
                  ),
                ),
              ],
            ),
          ),

          16.height,

          // OTP Input
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: otpController,
            obscureText: false,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 55,
              fieldWidth: 45,
              activeFillColor: primaryColor.withOpacity(0.1),
              inactiveFillColor: context.cardColor,
              selectedFillColor: primaryColor.withOpacity(0.2),
              activeColor: primaryColor,
              inactiveColor: context.dividerColor,
              selectedColor: primaryColor,
            ),
            enableActiveFill: true,
            animationDuration: Duration(milliseconds: 300),
            onCompleted: (value) {
              verifyOTP();
            },
            onChanged: (value) {},
          ),

          16.height,

          // Resend Option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('لم تتلق الرمز؟ ', style: secondaryTextStyle()),
              if (isResendEnabled)
                TextButton(
                  onPressed: resendOTP,
                  child: Text(
                    'إعادة الإرسال',
                    style: boldTextStyle(color: primaryColor),
                  ),
                )
              else
                Text(
                  'إعادة الإرسال خلال ${resendTimer}s',
                  style: secondaryTextStyle(color: primaryColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return AppButton(
      text: isCodeSent ? 'تحقق من الرمز' : 'إرسال رمز التحقق',
      color: primaryColor,
      textColor: Colors.white,
      width: double.infinity,
      height: 52,
      shapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: isCodeSent ? verifyOTP : sendOTP,
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield, color: primaryColor, size: 20),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آمان وخصوصية',
                  style: boldTextStyle(size: 14),
                ),
                4.height,
                Text(
                  'رقم هاتفك آمن ولن يتم مشاركته مع أي طرف ثالث. يُستخدم فقط لأغراض التحقق والأمان.',
                  style: secondaryTextStyle(size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
