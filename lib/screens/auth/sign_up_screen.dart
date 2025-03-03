import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/dashboard_screen.dart';

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/dashboard_screen.dart';

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? countryCode;
  final bool isOTPLogin;
  final String? uid;
  final int? tokenForOTPCredentials;

  SignUpScreen({
    Key? key,
    this.phoneNumber,
    this.isOTPLogin = false,
    this.countryCode,
    this.uid,
    this.tokenForOTPCredentials
  }) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Country selectedCountry; // Changed to late initialization

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isAcceptedTc = false;
  bool isFirstTimeValidation = true;
  ValueNotifier _valueNotifier = ValueNotifier(true);

  Country getEgyptCountry() {
    return Country(
      phoneCode: '20',
      countryCode: 'EG',
      e164Sc: 20,
      geographic: true,
      level: 1,
      name: 'Egypt',
      example: '1097051812',
      displayName: 'Egypt (EG) [+20]',
      displayNameNoCountryCode: 'Egypt',
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
      displayName: 'Saudi Arabia (SA) [+966]',
      displayNameNoCountryCode: 'Saudi Arabia',
      e164Key: '966-SA-0',
    );
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
    selectedCountry = getEgyptCountry(); // Initialize here
    init();
  }

  void init() async {
    if (widget.phoneNumber != null) {
      String countryCode = widget.countryCode.validate(value: 'EG');
      selectedCountry =
      countryCode == 'SA' ? getSaudiArabiaCountry() : getEgyptCountry();

      mobileCont.text = widget.phoneNumber ?? "";
      passwordCont.text = widget.phoneNumber ?? "";
      userNameCont.text = widget.phoneNumber ?? "";
    }
  }

  String buildMobileNumber() {
    try {
      String formattedNumber = formatPhoneNumber(
          mobileCont.text.trim(), selectedCountry.countryCode);
      return '${selectedCountry.phoneCode}-$formattedNumber';
    } catch (e) {
      toast(e.toString());
      return '';
    }
  }

  Future<void> changeCountry() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.scaffoldBackgroundColor,
          title: Text(language.selectCountry, style: boldTextStyle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Egypt (+20)', style: primaryTextStyle()),
                onTap: () {
                  selectedCountry = getEgyptCountry();
                  setState(() {});
                  finish(context);
                },
                selected: selectedCountry.countryCode == 'EG',
                selectedColor: context.primaryColor,
              ),
              ListTile(
                title: Text('Saudi Arabia (+966)', style: primaryTextStyle()),
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
  }

  Widget _buildPhoneInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 48.0,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Center(
            child: ValueListenableBuilder(
              valueListenable: _valueNotifier,
              builder: (context, value, child) =>
                  Row(
                    children: [
                      Text(
                        "+${selectedCountry.phoneCode}",
                        style: primaryTextStyle(size: 12),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: textSecondaryColorGlobal),
                    ],
                  ).paddingOnly(left: 8, right: 8),
            ),
          ),
        ).onTap(() => changeCountry()),
        10.width,
        AppTextField(
          textFieldType: TextFieldType.PHONE,
          controller: mobileCont,
          focus: mobileFocus,
          nextFocus: passwordFocus,
          maxLength: selectedCountry.countryCode == 'EG' ? 11 : 10,
          buildCounter: (_,
              {required int currentLength, required bool isFocused, required int? maxLength}) {
            return Offstage();
          },
          decoration: inputDecoration(
              context, labelText: language.hintContactNumberTxt).copyWith(
            hintText: selectedCountry.example,
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
        ).expand(),
      ],
    );
  }

  Widget _buildTopWidget() {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          padding: EdgeInsets.all(16),
          child: ic_profile2.iconImage(color: Colors.white),
          decoration: boxDecorationDefault(
              shape: BoxShape.circle, color: primaryColor),
        ),
        16.height,
        Text(language.lblHelloUser, style: boldTextStyle(size: 22)).center(),
        16.height,
        Text(
            language.lblSignUpSubTitle,
            style: secondaryTextStyle(size: 14),
            textAlign: TextAlign.center
        ).center().paddingSymmetric(horizontal: 32),
      ],
    );
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        32.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: fNameCont,
          focus: fNameFocus,
          nextFocus: lNameFocus,
          errorThisFieldRequired: language.requiredText,
          decoration: inputDecoration(
              context, labelText: language.hintFirstNameTxt),
          suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: lNameCont,
          focus: lNameFocus,
          nextFocus: userNameFocus,
          errorThisFieldRequired: language.requiredText,
          decoration: inputDecoration(
              context, labelText: language.hintLastNameTxt),
          suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: userNameCont,
          focus: userNameFocus,
          nextFocus: emailFocus,
          readOnly: widget.isOTPLogin,
          errorThisFieldRequired: language.requiredText,
          decoration: inputDecoration(
              context, labelText: language.hintUserNameTxt),
          suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.EMAIL_ENHANCED,
          controller: emailCont,
          focus: emailFocus,
          errorThisFieldRequired: language.requiredText,
          nextFocus: mobileFocus,
          decoration: inputDecoration(
              context, labelText: language.hintEmailTxt),
          suffix: ic_message.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        _buildPhoneInput(),
        if (!widget.isOTPLogin) ...[
          16.height,
          AppTextField(
            textFieldType: TextFieldType.PASSWORD,
            controller: passwordCont,
            focus: passwordFocus,
            readOnly: widget.isOTPLogin,
            errorThisFieldRequired: language.requiredText,
            decoration: inputDecoration(
                context, labelText: language.hintPasswordTxt),
            suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(
                14),
            suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10)
                .paddingAll(14),
            onFieldSubmitted: (s) {
              if (widget.isOTPLogin) {
                registerWithOTP();
              } else {
                registerUser();
              }
            },
          ),
        ],
        16.height,
        _buildTcAcceptWidget(),
        16.height,
        AppButton(
          text: language.signUp,
          color: primaryColor,
          textColor: Colors.white,
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            if (widget.isOTPLogin) {
              registerWithOTP();
            } else {
              registerUser();
            }
          },
        ),
      ],
    );
  }

  Widget _buildTcAcceptWidget() {
    return Row(
      children: [
        Checkbox(
          activeColor: primaryColor,
          value: isAcceptedTc,
          onChanged: (bool? value) {
            isAcceptedTc = value.validate();
            setState(() {});
          },
        ),
        RichTextWidget(
          list: [
            //iAgree
            //acceptTermsCondition


            //
            TextSpan(text: '${language.iAgree} ', style: secondaryTextStyle()),
            TextSpan(
              text: language.termsCondition,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Handle Terms & Conditions tap
                },
            ),
          ],
        ).expand(),
      ],
    );
  }

  Widget _buildFooterWidget() {
    return Column(
      children: [
        16.height,
        RichTextWidget(
          list: [
            TextSpan(text: "${language.alreadyHaveAccountTxt} ? ",
                style: secondaryTextStyle()),
            TextSpan(
              text: language.signIn,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  finish(context);
                },
            ),
          ],
        ),
        30.height,
      ],
    );
  }

  void registerUser() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      if (isAcceptedTc) {
        isFirstTimeValidation = false;
        appStore.setLoading(true);

        String mobileNumber = buildMobileNumber();
        if (mobileNumber.isEmpty) {
          appStore.setLoading(false);
          return;
        }

        Map<String, dynamic> request = {
          'first_name': fNameCont.text.trim(),
          'last_name': lNameCont.text.trim(),
          'username': userNameCont.text.trim(),
          'email': emailCont.text.trim(),
          'password': passwordCont.text.trim(),
          'contact_number': mobileNumber,
          'user_type': LOGIN_TYPE_USER,
          'login_type': LOGIN_TYPE_USER,
        };

        createUser(request).then((response) async {
          appStore.setLoading(false);

          // Store password for auto-login
          await setValue(USER_PASSWORD, passwordCont.text.trim());
          await setValue(IS_REMEMBERED, true);

          // Save user data and login
          await saveUserData(response.userData!);
          await appStore.setLoginType(LOGIN_TYPE_USER);
          // Verify Firebase connection
          authService.verifyFirebaseUser();
          // Navigate to dashboard
          DashboardScreen().launch(context,
              isNewTask: true,
              pageRouteAnimation: PageRouteAnimation.Fade
          );
        }).catchError((error) {
          appStore.setLoading(false);
          toast(error.toString());
        });
      } else {
        toast(language.acceptTermsCondition);
      }
    } else {
      isFirstTimeValidation = false;
      setState(() {});
    }
  }

  void registerWithOTP() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      if (isAcceptedTc) {
        // Add your OTP registration logic here
        if (widget.uid
            .validate()
            .isNotEmpty) {
          appStore.setLoading(true);

          String mobileNumber = buildMobileNumber();
          if (mobileNumber.isNotEmpty) {
            Map<String, dynamic> request = {
              'username': userNameCont.text.trim(),
              'first_name': fNameCont.text.trim(),
              'last_name': lNameCont.text.trim(),
              'email': emailCont.text.trim(),
              'password': passwordCont.text.trim(),
              'contact_number': mobileNumber,
              'user_type': LOGIN_TYPE_USER,
              'uid': widget.uid.validate(),
              'token_for_otp_credentials': widget.tokenForOTPCredentials,
              'login_type': LOGIN_TYPE_OTP,
            };
            // Call your registration API or service here
          }
        }
      } else {
        toast(language.acceptTermsCondition);
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    fNameCont.dispose();
    lNameCont.dispose();
    emailCont.dispose();
    userNameCont.dispose();
    mobileCont.dispose();
    passwordCont.dispose();

    fNameFocus.dispose();
    lNameFocus.dispose();
    emailFocus.dispose();
    userNameFocus.dispose();
    mobileFocus.dispose();
    passwordFocus.dispose();

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
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: appStore.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
              statusBarColor: context.scaffoldBackgroundColor
          ),
        ),
        body: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Form(
              key: formKey,
              autovalidateMode: isFirstTimeValidation
                  ? AutovalidateMode.disabled
                  : AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTopWidget(),
                    _buildFormWidget(),
                    8.height,
                    _buildFooterWidget(),
                  ],
                ),
              ),
            ),
            Observer(
                builder: (_) =>
                    LoaderWidget().center().visible(appStore.isLoading)
            ),
          ],
        ),
      ),
    );
  }
}