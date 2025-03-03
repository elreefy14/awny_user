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
import '../../network/rest_apis.dart';
import '../../services/phone_auth_service.dart';
import '../../services/whats_app_otp_service.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../dashboard/dashboard_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class OTPLoginScreenWithWhatsUpApi extends StatefulWidget {
  const OTPLoginScreenWithWhatsUpApi({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreenWithWhatsUpApi> createState() =>
      _OTPLoginScreenWithWhatsUpApiState();
}

class _OTPLoginScreenWithWhatsUpApiState
    extends State<OTPLoginScreenWithWhatsUpApi> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController numberController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  String currentOTP = '';
  String enteredOTP = '';
  bool isCodeSent = false;
  Country selectedCountry = defaultCountry();
  FocusNode _mobileNumberFocus = FocusNode();
  bool isResendEnabled = false;
  int resendTimer = 30;

  // Country selection helpers
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

  // Phone number validation and formatting
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

  bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    try {
      formatPhoneNumber(phoneNumber, countryCode);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedCountry = getEgyptCountry();
  }

  @override
  void dispose() {
    otpController.dispose();
    numberController.dispose();
    _mobileNumberFocus.dispose();
    super.dispose();
  }

  // Timer management
  Future<void> startResendTimer() {
    setState(() {
      isResendEnabled = false;
      resendTimer = 30;
    });

    return Future.doWhile(() async {
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

  // Firebase user management
  Future<UserCredential?> signInWithPhoneNumber(String phoneNumber) async {
    try {
      // Check if user exists in Firebase
      var userQuery = await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // Create new user in Firebase
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: '${phoneNumber.replaceAll('+', '')}@phone.user',
          password: phoneNumber, // You should generate a secure random password
        );

        return userCredential;
      } else {
        // Sign in existing user
        String email = userQuery.docs.first.get('email');
        String password = userQuery.docs.first.get('password');

        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      print('Firebase auth error: $e');
      return null;
    }
  }

  // Backend user management
  Future<void> syncUserWithBackend(
      UserCredential credential, String phoneNumber) async {
    try {
      final user = credential.user;
      if (user == null) throw 'No user found';

      // Prepare user data
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'phone_number': phoneNumber,
        'email': user.email,
        'last_login': FieldValue.serverTimestamp(),
      };

      // Update or create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );

      // Sync with backend
      Map<String, dynamic> backendRequest = {
        'firebase_uid': user.uid,
        'phone_number': phoneNumber,
        'email': user.email,
        'login_type': LOGIN_TYPE_OTP,
      };

      var response = await loginUser(backendRequest, isSocialLogin: true);
      await saveUserData(response.userData!);
      await appStore.setLoginType(LOGIN_TYPE_OTP);
    } catch (e) {
      print('Error syncing user: $e');
      throw e;
    }
  }

  // OTP Verification flow
  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      try {
        String formattedNumber = formatPhoneNumber(
            numberController.text.trim(), selectedCountry.countryCode);

        appStore.setLoading(true);
        currentOTP = WhatsAppOTPService.generateOTP();

        bool sent = await WhatsAppOTPService.sendOTP(
            "+${selectedCountry.phoneCode}${formattedNumber}", currentOTP);

        if (sent) {
          toast(language.otpCodeIsSentToYourMobileNumber);
          isCodeSent = true;
          startResendTimer();
          setState(() {});
        } else {
          toast(language.failedToSendOTP);
        }
      } catch (e) {
        toast(e.toString());
      } finally {
        appStore.setLoading(false);
      }
    }
  }

  Future<void> verifyOTP(String inputOTP) async {
    if (inputOTP.isEmpty) {
      toast('Please enter OTP');
      return;
    }

    if (currentOTP.isEmpty) {
      toast('Please request OTP first');
      return;
    }

    if (inputOTP == currentOTP) {
      try {
        appStore.setLoading(true);

        // Validate phone number
        if (numberController.text.trim().isEmpty ||
            selectedCountry.countryCode.isEmpty) {
          throw 'Invalid phone number';
        }

        String formattedNumber = formatPhoneNumber(
            numberController.text.trim(), selectedCountry.countryCode);

        String fullPhoneNumber =
            '+${selectedCountry.phoneCode}${formattedNumber}';

        final phoneAuthService = PhoneAuthService();
        final result =
            await phoneAuthService.authenticatePhoneUser(fullPhoneNumber);

        if (result['success'] == true) {
          // Save user data
          if (result['userData'] != null) {
            await saveUserData(result['userData']);
            await appStore.setLoginType('phone');

            // Show welcome message for new users
            if (result['isNewUser'] == true) {
              toast('Welcome to our app!');
            }

            // Navigate to dashboard
            DashboardScreen().launch(context, isNewTask: true);
          } else {
            throw 'User data not available';
          }
        } else {
          throw result['error'] ?? 'Verification failed';
        }
      } catch (e) {
        log('OTP Verification Error: $e');
        toast(e.toString());
      } finally {
        appStore.setLoading(false);
      }
    } else {
      toast(language.invalidOTP);
    }
  }

  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your mobile number',
            style: boldTextStyle(size: 24))
            .center(),
        32.height,
        Container(
          decoration: BoxDecoration(
            borderRadius: radius(),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              // Country Code Selector - Always LTR
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border:
                        Border(right: BorderSide(color: context.dividerColor)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+${selectedCountry.phoneCode}',
                          style: boldTextStyle()),
                      4.width,
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ).onTap(() => changeCountry()),
              ),
              16.width,
              // Phone Number Input - Always LTR
              Directionality(
                textDirection: TextDirection.ltr,
                child: AppTextField(
                  controller: numberController,
                  focus: _mobileNumberFocus,
                  textFieldType: TextFieldType.PHONE,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: selectedCountry.example,
                    hintStyle: secondaryTextStyle(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        selectedCountry.countryCode == 'EG' ? 10 : 9),
                  ],
                ).expand(),
              ),
            ],
          ),
        ),
        16.height,
        AppButton(
          //translate to arabic
          text: 'Send OTP',
          color: primaryColor,
          width: context.width(),
          onTap: () {
            if (formKey.currentState!.validate()) {
              sendOTP();
            }
          },
        ),
      ],
    );
  }

  Widget _buildOTPVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter OTP',
            style: boldTextStyle(size: 24))
            .center(),
        16.height,
        // Phone Number Display - Always LTR
        Directionality(
          textDirection: TextDirection.ltr,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '+${selectedCountry.phoneCode} ',
                    style: boldTextStyle()),
                TextSpan(
                    text: numberController.text.trim(), style: boldTextStyle()),
              ],
            ),
          ),
        ).center(),
        32.height,
        // OTP Input - Always LTR
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            controller: otpController,
            keyboardType: TextInputType.number,
            textStyle: boldTextStyle(color: context.primaryColor),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: radius(8),
              fieldHeight: 50,
              fieldWidth: 45,
              activeFillColor: context.cardColor,
              selectedFillColor: context.cardColor,
              inactiveFillColor: context.cardColor,
              borderWidth: 1.5,
            ),
            enableActiveFill: true,
            onChanged: (value) {
              enteredOTP = value;
              setState(() {});
            },
            onCompleted: (value) {
              verifyOTP(value);
            },
          ),
        ),
        32.height,
        _buildActionButtons(),
        16.height,
        if (enteredOTP.length == 6) _buildVerifyButton(),
      ],
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            "+${selectedCountry.phoneCode}",
            style: boldTextStyle(),
          ),
          8.width,
          Icon(Icons.arrow_drop_down, color: primaryColor),
        ],
      ),
    ).onTap(() => changeCountry());
  }

  Widget _buildPhoneNumberField() {
    return AppTextField(
      controller: numberController,
      focus: _mobileNumberFocus,
      textFieldType: TextFieldType.PHONE,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: '${language.lblExample}: ${selectedCountry.example}',
        hintStyle: secondaryTextStyle(),
      ),
      validator: (value) {
        if (value!.isEmpty) return language.requiredText;
        if (!isValidPhoneNumber(value, selectedCountry.countryCode)) {
          return selectedCountry.countryCode == 'EG'
              ? 'Enter valid Egyptian mobile number'
              : 'Enter valid Saudi mobile number';
        }
        return null;
      },
      onFieldSubmitted: (s) => sendOTP(),
    ).expand();
  }

  Widget _buildSendOTPButton() {
    return AppButton(
      onTap: sendOTP,
      text: language.btnSendOtp,
      textStyle: boldTextStyle(color: Colors.white),
      width: context.width(),
      elevation: 0,
      color: primaryColor,
      shapeBorder:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildOTPInputField() {
    return PinCodeTextField(
      appContext: context,
      length: 6,
      controller: otpController,
      obscureText: false,
      animationType: AnimationType.fade,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textStyle: boldTextStyle(
        size: 18,
        color: appStore.isDarkMode ? Colors.white : Colors.black,
      ),
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(8),
        fieldHeight: 45,
        fieldWidth: 45,
        activeFillColor: appStore.isDarkMode ? Colors.black : context.cardColor,
        inactiveFillColor:
            appStore.isDarkMode ? Colors.black12 : context.cardColor,
        selectedFillColor:
            appStore.isDarkMode ? Colors.black54 : context.cardColor,
        activeColor: primaryColor,
        inactiveColor: Colors.grey.withOpacity(0.2),
        selectedColor: primaryColor,
        borderWidth: 1.5,
      ),
      cursorColor: primaryColor,
      animationDuration: const Duration(milliseconds: 300),
      backgroundColor: Colors.transparent,
      enableActiveFill: true,
      keyboardType: TextInputType.number,
      onCompleted: (pin) {
        enteredOTP = pin;
        verifyOTP(pin);
      },
      onChanged: (value) {
        setState(() {
          enteredOTP = value;
        });
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            numberController.clear();
            otpController.clear();
            setState(() {
              isCodeSent = false;
              enteredOTP = '';
            });
          },
          child: Text(
            'Edit Number',
            style: boldTextStyle(color: primaryColor, size: 14),
          ),
        ),
        TextButton(
          onPressed: isResendEnabled
              ? () {
                  sendOTP();
                  startResendTimer();
                }
              : null,
          child: Text(
            isResendEnabled ? 'Resend OTP' : 'Resend OTP (${resendTimer}s)',
            style: boldTextStyle(
              color: isResendEnabled ? primaryColor : Colors.grey,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return AppButton(
      onTap: () {
        if (enteredOTP.length == 6) {
          verifyOTP(enteredOTP);
        } else {
          toast('Please enter complete OTP');
        }
      },
      text: language.confirm,
      textStyle: boldTextStyle(color: Colors.white),
      width: context.width(),
      elevation: 0,
      color: primaryColor,
      shapeBorder:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:  //TextDirection.rtl :
      TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.of(context).canPop()
              ? BackWidget(iconColor: context.iconColor)
              : null,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                appStore.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: isCodeSent
                        ? _buildOTPVerificationSection()
                        : _buildPhoneInputSection(),
                  ),
                ),
              ),
            ),
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
      ),
    );
  }

  Future<void> changeCountry() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: AlertDialog(
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
          ),
        );
      },
    );

    // Clear phone number when country changes
    if (numberController.text.isNotEmpty) {
      numberController.clear();
      if (formKey.currentState != null) {
        formKey.currentState!.validate();
      }
    }
  }
}
