import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/services/whats_app_otp_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../network/rest_apis.dart';

class GooglePhoneCollectionScreen extends StatefulWidget {
  final User googleUser;
  final bool isFromDashboard;
  final bool isFromServiceBooking;
  final bool returnExpected;

  const GooglePhoneCollectionScreen({
    Key? key,
    required this.googleUser,
    this.isFromDashboard = false,
    this.isFromServiceBooking = false,
    this.returnExpected = false,
  }) : super(key: key);

  @override
  _GooglePhoneCollectionScreenState createState() =>
      _GooglePhoneCollectionScreenState();
}

class _GooglePhoneCollectionScreenState
    extends State<GooglePhoneCollectionScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  // Focus nodes
  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode otpFocus = FocusNode();

  // State variables
  Country selectedCountry = defaultCountry();
  bool isOTPSent = false;
  bool isVerifying = false;
  String currentOTP = '';
  bool isResendEnabled = false;
  int resendTimer = 30;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    init();
    setupAnimations();
  }

  void setupAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
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
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  void init() {
    selectedCountry = getEgyptCountry();

    // Pre-fill name fields from Google account
    if (widget.googleUser.displayName != null) {
      List<String> nameParts = widget.googleUser.displayName!.split(' ');
      firstNameController.text = nameParts.first;
      if (nameParts.length > 1) {
        lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
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
              _buildCountryOption('Egypt (+20)', getEgyptCountry()),
              _buildCountryOption(
                  'Saudi Arabia (+966)', getSaudiArabiaCountry()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryOption(String title, Country country) {
    bool isSelected = selectedCountry.countryCode == country.countryCode;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        border: Border.all(
          color: isSelected ? primaryColor : context.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(title, style: primaryTextStyle()),
        trailing:
            isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
        onTap: () {
          selectedCountry = country;
          setState(() {});
          finish(context);
        },
      ),
    );
  }

  Future<void> sendOTP() async {
    if (!formKey.currentState!.validate()) return;

    if (!isValidPhoneNumber(
        phoneController.text, selectedCountry.countryCode)) {
      toast(selectedCountry.countryCode == 'EG'
          ? language.invalidEgyptianPhoneNumber
          : language.invalidSaudiPhoneNumber);
      return;
    }

    try {
      appStore.setLoading(true);

      String formattedPhone =
          formatPhoneNumber(phoneController.text, selectedCountry.countryCode);
      currentOTP = WhatsAppOTPService.generateOTP();

      bool success =
          await WhatsAppOTPService.sendOTP(formattedPhone, currentOTP);

      if (success) {
        setState(() {
          isOTPSent = true;
        });
        startResendTimer();
        toast('تم إرسال رمز التحقق عبر واتساب');

        // Animate to OTP screen
        _slideController.reset();
        _slideController.forward();
      } else {
        toast('فشل في إرسال رمز التحقق. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> verifyOTPAndComplete() async {
    if (otpController.text.length != 6) {
      toast('يرجى إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    if (otpController.text != currentOTP) {
      toast('رمز التحقق غير صحيح');
      return;
    }

    try {
      appStore.setLoading(true);

      // Update user data in backend
      String formattedPhone =
          formatPhoneNumber(phoneController.text, selectedCountry.countryCode);

      Map<String, dynamic> request = {
        'email': widget.googleUser.email,
        'login_type': LOGIN_TYPE_GOOGLE,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'username': widget.googleUser.email
            ?.split('@')
            .first
            .replaceAll('.', '')
            .toLowerCase(),
        'user_type': 'user',
        'display_name':
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        'uid': widget.googleUser.uid,
        'social_image': widget.googleUser.photoURL,
        'phone_number': formattedPhone,
        'phone_verified': true,
      };

      try {
        var loginResponse = await loginUser(request, isSocialLogin: true);
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        // Update Firebase user profile
        await widget.googleUser.updateDisplayName(
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}');

        // Create or update Firestore user document using set with merge
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.googleUser.uid)
              .set({
            'uid': widget.googleUser.uid,
            'email': widget.googleUser.email,
            'first_name': firstNameController.text.trim(),
            'last_name': lastNameController.text.trim(),
            'display_name':
                '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
            'phone_number': formattedPhone,
            'phone_verified': true,
            'profile_image': widget.googleUser.photoURL ??
                'https://awnyapp.com/images/user/user.png',
            'login_type': LOGIN_TYPE_GOOGLE,
            'user_type': 'user',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✓ Firestore document created/updated successfully');
        } catch (firestoreError) {
          print('⚠️ Firestore update error (non-critical): $firestoreError');
          // Don't throw error here as the main login was successful
        }

        onLoginSuccessRedirection();
      } catch (e) {
        if (e.toString().contains('User not found')) {
          var signupResponse = await createUser(request);
          await saveUserData(signupResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

          // Create Firestore document for new user
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.googleUser.uid)
                .set({
              'uid': widget.googleUser.uid,
              'email': widget.googleUser.email,
              'first_name': firstNameController.text.trim(),
              'last_name': lastNameController.text.trim(),
              'display_name':
                  '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
              'phone_number': formattedPhone,
              'phone_verified': true,
              'profile_image': widget.googleUser.photoURL ??
                  'https://awnyapp.com/images/user/user.png',
              'login_type': LOGIN_TYPE_GOOGLE,
              'user_type': 'user',
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });

            print('✓ New user Firestore document created successfully');
          } catch (firestoreError) {
            print(
                '⚠️ Firestore creation error (non-critical): $firestoreError');
          }

          onLoginSuccessRedirection();
        } else {
          throw e;
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  void onLoginSuccessRedirection() {
    afterBuildCreated(() {
      appStore.setLoading(false);
      if (widget.isFromServiceBooking ||
          widget.isFromDashboard ||
          widget.returnExpected) {
        if (widget.isFromDashboard) {
          push(DashboardScreen(redirectToBooking: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          finish(context, true);
        }
      } else {
        DashboardScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      }
    });
  }

  Future<void> startResendTimer() async {
    setState(() {
      isResendEnabled = false;
      resendTimer = 30;
    });

    while (resendTimer > 0 && mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() {
          resendTimer--;
          if (resendTimer == 0) {
            isResendEnabled = true;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    phoneFocus.dispose();
    otpFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.scaffoldBackgroundColor,
          leading: BackWidget(iconColor: context.iconColor),
          title: Text(
            isOTPSent ? 'تحقق من رقم الهاتف' : 'إكمال الملف الشخصي',
            style: boldTextStyle(size: 18),
          ),
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                appStore.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarColor: context.scaffoldBackgroundColor,
          ),
        ),
        body: Stack(
          children: [
            Form(
              key: formKey,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderSection(),
                            32.height,
                            if (!isOTPSent) ...[
                              _buildPersonalInfoSection(),
                              24.height,
                              _buildPhoneSection(),
                              32.height,
                              _buildContinueButton(),
                            ] else ...[
                              _buildOTPSection(),
                              32.height,
                              _buildVerifyButton(),
                              16.height,
                              _buildResendSection(),
                            ],
                            24.height,
                            _buildSecurityNote(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Observer(
              builder: (_) => Loader().visible(appStore.isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.googleUser.photoURL != null
                  ? Image.network(
                      widget.googleUser.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person,
                            color: Colors.white, size: 40);
                      },
                    )
                  : Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          16.height,
          Text(
            isOTPSent
                ? 'تحقق من رقم هاتفك'
                : 'مرحباً ${widget.googleUser.displayName ?? 'بك'}!',
            style: boldTextStyle(size: 20),
            textAlign: TextAlign.center,
          ),
          8.height,
          Text(
            isOTPSent
                ? 'أدخل رمز التحقق المرسل عبر واتساب'
                : 'يرجى إكمال معلوماتك لإنهاء عملية التسجيل',
            style: secondaryTextStyle(size: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المعلومات الشخصية', style: boldTextStyle(size: 16)),
        16.height,
        Row(
          children: [
            Expanded(
              child: AppTextField(
                textFieldType: TextFieldType.NAME,
                controller: firstNameController,
                focus: firstNameFocus,
                nextFocus: lastNameFocus,
                errorThisFieldRequired: language.requiredText,
                decoration: inputDecoration(
                  context,
                  labelText: 'الاسم الأول',
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                ),
              ),
            ),
            16.width,
            Expanded(
              child: AppTextField(
                textFieldType: TextFieldType.NAME,
                controller: lastNameController,
                focus: lastNameFocus,
                nextFocus: phoneFocus,
                errorThisFieldRequired: language.requiredText,
                decoration: inputDecoration(
                  context,
                  labelText: 'الاسم الأخير',
                  prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('رقم الهاتف', style: boldTextStyle(size: 16)),
        8.height,
        Text('سنرسل لك رمز تحقق عبر واتساب',
            style: secondaryTextStyle(size: 12)),
        16.height,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerColor),
            color: context.cardColor,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border:
                      Border(right: BorderSide(color: context.dividerColor)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('+${selectedCountry.phoneCode}',
                        style: boldTextStyle()),
                    8.width,
                    Icon(Icons.arrow_drop_down, color: primaryColor),
                  ],
                ),
              ).onTap(() => changeCountry()),
              Expanded(
                child: AppTextField(
                  controller: phoneController,
                  focus: phoneFocus,
                  textFieldType: TextFieldType.PHONE,
                  decoration: InputDecoration(
                    hintText: selectedCountry.example,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        selectedCountry.countryCode == 'EG' ? 10 : 9),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('رمز التحقق', style: boldTextStyle(size: 16)),
        8.height,
        Text(
          'تم إرسال رمز التحقق إلى ${formatPhoneNumber(phoneController.text, selectedCountry.countryCode)}',
          style: secondaryTextStyle(size: 12),
        ),
        24.height,
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            controller: otpController,
            focusNode: otpFocus,
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
            animationDuration: Duration(milliseconds: 300),
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {});
            },
            onCompleted: (value) {
              verifyOTPAndComplete();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return AppButton(
      text: 'إرسال رمز التحقق',
      color: primaryColor,
      textColor: Colors.white,
      width: context.width(),
      height: 55,
      shapeBorder:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      onTap: sendOTP,
    );
  }

  Widget _buildVerifyButton() {
    bool isEnabled = otpController.text.length == 6;
    return AppButton(
      text: 'تحقق وإكمال التسجيل',
      color: isEnabled ? primaryColor : context.dividerColor,
      textColor: isEnabled ? Colors.white : context.iconColor,
      width: context.width(),
      height: 55,
      shapeBorder:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isEnabled ? 2 : 0,
      onTap: isEnabled ? verifyOTPAndComplete : null,
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('لم تستلم الرمز؟ ', style: secondaryTextStyle()),
        if (isResendEnabled)
          Text(
            'إعادة الإرسال',
            style: boldTextStyle(color: primaryColor),
          ).onTap(() => sendOTP())
        else
          Text(
            'إعادة الإرسال خلال ${resendTimer}s',
            style: secondaryTextStyle(),
          ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.security, color: primaryColor, size: 20),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('معلوماتك آمنة', style: boldTextStyle(size: 14)),
                4.height,
                Text(
                  'نحن نحمي خصوصيتك ولن نشارك معلوماتك مع أي طرف ثالث',
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
