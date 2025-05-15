import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/firebase_otp_login_screen.dart';
import 'package:booking_system_flutter/screens/auth/forgot_password_screen.dart';
import 'package:booking_system_flutter/screens/auth/otp_login_screen.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/screens/auth/simple_phone_login_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/loader_widget.dart';
import '../../network/rest_apis.dart';

import '../../services/google_auth_service.dart';
// In lib/widgets/phone_collection_dialog.dart

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class PhoneCollectionDialog extends StatefulWidget {
  @override
  _PhoneCollectionDialogState createState() => _PhoneCollectionDialogState();
}

class _PhoneCollectionDialogState extends State<PhoneCollectionDialog> {
  TextEditingController phoneController = TextEditingController();
  late Country selectedCountry;
  String? errorText;

  @override
  void initState() {
    super.initState();
    selectedCountry = getEgyptCountry();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language.addPhoneNumber,
              style: boldTextStyle(size: 20),
            ),
            16.height,
            Text(
              language.pleaseAddPhoneNumber,
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
            20.height,
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('+${selectedCountry.phoneCode}',
                              style: boldTextStyle())
                          .paddingSymmetric(horizontal: 8),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ).onTap(() => changeCountry()),
                16.width,
                AppTextField(
                  controller: phoneController,
                  textFieldType: TextFieldType.PHONE,
                  decoration: InputDecoration(
                    hintText: selectedCountry.example,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ).expand(),
              ],
            ),
            20.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => finish(context),
                  child:
                      Text('الغاء', style: boldTextStyle(color: primaryColor)),
                ),
                8.width,
                AppButton(
                  text: 'حفظ',
                  textColor: Colors.white,
                  color: primaryColor,
                  onTap: () {
                    if (phoneController.text.isEmpty) {
                      setState(() => errorText = language.phoneNumberRequired);
                      return;
                    }

                    if (!isValidPhoneNumber(
                        phoneController.text, selectedCountry.countryCode)) {
                      setState(() => errorText =
                          selectedCountry.countryCode == 'EG'
                              ? language.invalidEgyptianPhoneNumber
                              : language.invalidSaudiPhoneNumber);
                      return;
                    }

                    finish(context, {
                      'phoneNumber': formatPhoneNumber(
                          phoneController.text, selectedCountry.countryCode)
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  final bool? isFromDashboard;
  final bool? isFromServiceBooking;
  final bool returnExpected;

  SignInScreen(
      {this.isFromDashboard,
      this.isFromServiceBooking,
      this.returnExpected = false});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isRemember = true;

  // Prevent double taps for Google Sign-in
  bool _isGoogleSignInProgress = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRemember = getBoolAsync(IS_REMEMBERED);
    if (isRemember) {
      emailCont.text = getStringAsync(USER_EMAIL);
      passwordCont.text = getStringAsync(USER_PASSWORD);
    }

    /// For Demo Purpose
    if (await isIqonicProduct) {
      emailCont.text = DEFAULT_EMAIL;
      passwordCont.text = DEFAULT_PASS;
    }
  }

  //region Methods

  void _handleLogin() {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  ///TODO: Add tsign in with facebook, google, apple and otp
  // Add this function to your _SignInScreenState class
  //  void facebookSignIn() async {
  //    try {
  //      appStore.setLoading(true);
  //
  //      // Trigger Facebook sign in
  //      final LoginResult loginResult = await FacebookAuth.instance.login(
  //        permissions: ['email', 'public_profile'],
  //      );
  //
  //      if (loginResult.status == LoginStatus.success) {
  //        // Get user data
  //        final userData = await FacebookAuth.instance.getUserData();
  //
  //        // Create Facebook credential
  //        final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(
  //          loginResult.accessToken!.token,
  //        );
  //
  //        // Sign in with Firebase
  //        final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  //        final User? user = authResult.user;
  //
  //        if (user == null) throw 'No user found';
  //
  //        // Extract name components
  //        String firstName = '';
  //        String lastName = '';
  //        if (userData['name'].toString().split(' ').length >= 1) {
  //          firstName = userData['name'].toString().splitBefore(' ');
  //        }
  //        if (userData['name'].toString().split(' ').length >= 2) {
  //          lastName = userData['name'].toString().splitAfter(' ');
  //        }
  //
  //        // Prepare request for backend
  //        Map<String, dynamic> request = {
  //          'first_name': firstName,
  //          'last_name': lastName,
  //          'email': userData['email'] ?? user.email,
  //          'username': (userData['email'] ?? user.email)?.splitBefore('@').replaceAll('.', '').toLowerCase(),
  //          'social_image': userData['picture']?['data']?['url'] ?? user.photoURL,
  //          'login_type': 'facebook',
  //          'user_type': 'user',
  //        };
  //
  //        // Login user through your backend
  //        var loginResponse = await loginUser(request, isSocialLogin: true);
  //        loginResponse.userData!.profileImage = userData['picture']?['data']?['url'] ?? user.photoURL;
  //
  //        await saveUserData(loginResponse.userData!);
  //        appStore.setLoginType('facebook');
  //
  //        authService.verifyFirebaseUser();
  //        onLoginSuccessRedirection();
  //
  //      } else if (loginResult.status == LoginStatus.cancelled) {
  //        toast(language.userCancelled);
  //      } else {
  //        toast(language.loginFailed);
  //      }
  //    } catch (e) {
  //      log('Facebook Sign-In Error: $e');
  //      if (e is FirebaseAuthException) {
  //        switch (e.code) {
  //          case 'account-exists-with-different-credential':
  //            toast(language.accountExistsWithDifferentCredential);
  //            break;
  //          case 'invalid-credential':
  //            toast(language.invalidCredentials);
  //            break;
  //          default:
  //            toast(language.authFailed);
  //        }
  //      } else {
  //        toast('${language.signInFailed}: ${e.toString()}');
  //      }
  //    } finally {
  //      appStore.setLoading(false);
  //    }
  //  }
  void facebookSignIn() async {
    print('Facebook Sign-In');
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);
    Map<String, dynamic> request = {
      'email': emailCont.text.trim(),
      'password': passwordCont.text.trim(),
      'login_type': LOGIN_TYPE_USER,
    };

    appStore.setLoading(true);
    try {
      final loginResponse = await loginUser(request, isSocialLogin: false);

      await saveUserData(loginResponse.userData!);

      await setValue(USER_PASSWORD, passwordCont.text);
      await setValue(IS_REMEMBERED, isRemember);
      await appStore.setLoginType(LOGIN_TYPE_USER);

      authService.verifyFirebaseUser();
      TextInput.finishAutofillContext();

      onLoginSuccessRedirection();
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  Future<void> googleSignIn() async {
    hideKeyboard(context);

    // Prevent duplicate calls while loading or in progress
    if (appStore.isLoading || _isGoogleSignInProgress) {
      debugPrint('Google sign-in already in progress, ignoring duplicate call');
      return;
    }

    try {
      // Set both loading flags to prevent double taps
      _isGoogleSignInProgress = true;
      appStore.setLoading(true);

      // Show immediate feedback to user
      toast('جاري تسجيل الدخول...', gravity: ToastGravity.CENTER);

      // Initialize the GoogleSignIn object with scopes and server client ID if needed
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // First, try to sign in silently for better UX
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      // If silent sign-in fails, try regular sign-in
      googleUser ??= await googleSignIn.signIn().timeout(
        Duration(seconds: 25),
        onTimeout: () {
          throw 'تجاوز وقت تسجيل الدخول المحدد. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
        },
      );

      if (googleUser == null) {
        // User canceled the sign-in process
        toast(language.userCancelled);
        appStore.setLoading(false);
        _isGoogleSignInProgress = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user == null) throw 'No user found';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (userDoc.docs.isEmpty) {
        final nextId = await userService.getNextUserId();

        await userService.createUserInFirestore(
          uid: user.uid,
          email: user.email ?? '',
          firstName: user.displayName?.split(' ').first ?? '',
          lastName: user.displayName?.split(' ').last ?? '',
          profileImage:
              user.photoURL ?? 'https://awnyapp.com/images/user/user.png',
          id: nextId,
        );
      }

      Map<String, dynamic> request = {
        'email': user.email,
        'login_type': LOGIN_TYPE_GOOGLE,
        'first_name': user.displayName?.split(' ').first ?? '',
        'last_name': user.displayName?.split(' ').last ?? '',
        'username':
            user.email?.split('@').first.replaceAll('.', '').toLowerCase(),
        'user_type': 'user',
        'display_name': user.displayName,
        'uid': user.uid,
        'social_image': user.photoURL,
      };

      try {
        var loginResponse = await loginUser(request, isSocialLogin: true);
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        // Use onLoginSuccessRedirection instead of direct navigation
        onLoginSuccessRedirection();
      } catch (e) {
        if (e.toString().contains('User not found')) {
          var signupResponse = await createUser(request);
          await saveUserData(signupResponse.userData!);
          await appStore.setLoginType(LOGIN_TYPE_GOOGLE);
          onLoginSuccessRedirection();
        } else {
          throw e;
        }
      }
    } catch (e) {
      appStore.setLoading(false);
      _isGoogleSignInProgress = false;
      toast(e.toString());
    } finally {
      // Make sure we always reset the flags
      _isGoogleSignInProgress = false;
    }
  }

  void appleSign() async {
    appStore.setLoading(true);

    await authService.appleSignIn().then((req) async {
      await loginUser(req, isSocialLogin: true).then((value) async {
        await saveUserData(value.userData!);
        appStore.setLoginType(LOGIN_TYPE_APPLE);

        appStore.setLoading(false);
        authService.verifyFirebaseUser();

        onLoginSuccessRedirection();
      }).catchError((e) {
        appStore.setLoading(false);
        log(e.toString());
        throw e;
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void otpSignIn() async {
    hideKeyboard(context);

    SimplePhoneLoginScreen().launch(context);
  }

  void onLoginSuccessRedirection() {
    afterBuildCreated(() {
      appStore.setLoading(false);
      if (widget.isFromServiceBooking.validate() ||
          widget.isFromDashboard.validate() ||
          widget.returnExpected.validate()) {
        if (widget.isFromDashboard.validate()) {
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

//endregion

//region Widgets
  Widget _buildTopWidget() {
    return Container(
      child: Column(
        children: [
          Text("${language.lblLoginTitle}!", style: boldTextStyle(size: 20))
              .center(),
          16.height,
          Text(language.lblLoginSubTitle,
                  style: primaryTextStyle(size: 14),
                  textAlign: TextAlign.center)
              .center()
              .paddingSymmetric(horizontal: 32),
          32.height,
        ],
      ),
    );
  }

  Widget _buildRememberWidget() {
    return Column(
      children: [
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RoundedCheckBox(
              borderColor: context.primaryColor,
              checkedColor: context.primaryColor,
              isChecked: isRemember,
              text: language.rememberMe,
              textStyle: secondaryTextStyle(),
              size: 20,
              onTap: (value) async {
                await setValue(IS_REMEMBERED, isRemember);
                isRemember = !isRemember;
                setState(() {});
              },
            ),
            TextButton(
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
              child: Text(
                language.forgotPassword,
                style: boldTextStyle(
                    color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
            ).flexible(),
          ],
        ),
        24.height,
        AppButton(
          text: language.signIn,
          color: primaryColor,
          textColor: Colors.white,
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            _handleLogin();
          },
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                hideKeyboard(context);
                SignUpScreen().launch(context);
              },
              child: Text(
                language.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        // TextButton(
        //   onPressed: () {
        //     if (isAndroid) {
        //       if (getStringAsync(PROVIDER_PLAY_STORE_URL).isNotEmpty) {
        //         launchUrl(Uri.parse(getStringAsync(PROVIDER_PLAY_STORE_URL)), mode: LaunchMode.externalApplication);
        //       } else {
        //         launchUrl(Uri.parse('${getSocialMediaLink(LinkProvider.PLAY_STORE)}$PROVIDER_PACKAGE_NAME'), mode: LaunchMode.externalApplication);
        //       }
        //     } else if (isIOS) {
        //       if (getStringAsync(PROVIDER_APPSTORE_URL).isNotEmpty) {
        //         commonLaunchUrl(getStringAsync(PROVIDER_APPSTORE_URL));
        //       } else {
        //         commonLaunchUrl(IOS_LINK_FOR_PARTNER);
        //       }
        //     }
        //   },
        //   child: Text(language.lblRegisterAsPartner, style: boldTextStyle(color: primaryColor)),
        // )
      ],
    );
  }

  Widget _buildSocialWidget() {
    if (appConfigurationStore.socialLoginStatus) {
      return Column(
        children: [
          20.height,
          if ((appConfigurationStore.googleLoginStatus ||
                  appConfigurationStore.otpLoginStatus) ||
              (isIOS && appConfigurationStore.appleLoginStatus))
            Row(
              children: [
                Divider(color: context.dividerColor, thickness: 2).expand(),
                16.width,
                Text(language.lblOrContinueWith, style: secondaryTextStyle()),
                16.width,
                Divider(color: context.dividerColor, thickness: 2).expand(),
              ],
            ),
          24.height,
          if (appConfigurationStore.facebookLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/ic_facebook.png',
                        height: 16, width: 16),
                  ),
                  Text(language.lblSignInWithFacebook,
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.center)
                      .expand(),
                ],
              ),
              onTap: facebookSignIn,
            ),
          if (appConfigurationStore.facebookLoginStatus) 16.height,
          if (appConfigurationStore.googleLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: GoogleLogoWidget(size: 16),
                  ),
                  Text(language.lblSignInWithGoogle,
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.center)
                      .expand(),
                ],
              ),
              onTap: googleSignIn,
            ),
          if (appConfigurationStore.googleLoginStatus) 16.height,
          if (appConfigurationStore.otpLoginStatus)
            //todo sign in with otp make ot works
            // AppButton(
            //   text: '',
            //   color: context.cardColor,
            //   padding: EdgeInsets.all(8),
            //   textStyle: boldTextStyle(),
            //   width: context.width() - context.navigationBarHeight,
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: EdgeInsets.all(8),
            //         decoration: boxDecorationWithRoundedCorners(
            //           backgroundColor:
            //               Color(0xFF25D366).withOpacity(0.1), // WhatsApp green
            //           boxShape: BoxShape.circle,
            //         ),
            //         child: Image.asset(
            //           'assets/icons/ic_whatsapp.png',
            //           height: 20,
            //           width: 20,
            //           color: Color(0xFF25D366), // WhatsApp green
            //         ),
            //       ),
            //       Text("Sign in with WhatsApp OTP",
            //               style: boldTextStyle(size: 12),
            //               textAlign: TextAlign.center)
            //           .expand(),
            //     ],
            //   ),
            //   onTap: otpSignIn,
            // ),
          if (appConfigurationStore.otpLoginStatus) 16.height,
          if (isIOS)
            if (appConfigurationStore.appleLoginStatus)
              AppButton(
                text: '',
                color: context.cardColor,
                padding: EdgeInsets.all(8),
                textStyle: boldTextStyle(),
                width: context.width() - context.navigationBarHeight,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        boxShape: BoxShape.circle,
                      ),
                      child: Icon(Icons.apple),
                    ),
                    Text(language.lblSignInWithApple,
                            style: boldTextStyle(size: 12),
                            textAlign: TextAlign.center)
                        .expand(),
                  ],
                ),
                onTap: appleSign,
              ),
        ],
      );
    } else {
      return Offstage();
    }
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                textFieldType: TextFieldType.EMAIL_ENHANCED,
                controller: emailCont,
                focus: emailFocus,
                nextFocus: passwordFocus,
                errorThisFieldRequired: language.requiredText,
                decoration:
                    inputDecoration(context, labelText: language.hintEmailTxt),
                suffix: ic_message.iconImage(size: 10).paddingAll(14),
                autoFillHints: [AutofillHints.email],
              ),
              16.height,
              AppTextField(
                textFieldType: TextFieldType.PASSWORD,
                controller: passwordCont,
                focus: passwordFocus,
                errorThisFieldRequired: language.requiredText,
                decoration: inputDecoration(context,
                    labelText: language.hintPasswordTxt),
                suffixPasswordVisibleWidget:
                    ic_show.iconImage(size: 10).paddingAll(14),
                suffixPasswordInvisibleWidget:
                    ic_hide.iconImage(size: 10).paddingAll(14),
                onFieldSubmitted: (s) {
                  _handleLogin();
                },
                autoFillHints: [AutofillHints.password],
              ),
            ],
          ),
        ),
      ],
    );
  }

//endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (widget.isFromServiceBooking.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
    } else if (widget.isFromDashboard.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor,
          statusBarIconBrightness: Brightness.light);
    }
    super.dispose();
  }

// In SignInScreen
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.scaffoldBackgroundColor,
          leading: Navigator.of(context).canPop()
              ? BackWidget(iconColor: context.iconColor)
              : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  appStore.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Stack(
          children: [
            Body(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Observer(builder: (context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        (context.height() * 0.05).toInt().height,
                        _buildTopWidget(),
                        _buildFormWidget(),
                        _buildRememberWidget(),
                        if (!getBoolAsync(HAS_IN_REVIEW)) _buildSocialWidget(),
                        30.height,
                      ],
                    );
                  }),
                ),
              ),
            ),
            // Single loader at the top level
            Observer(
              builder: (_) => appStore.isLoading
                  ? Container(
                      color: Colors.black26, child: LoaderWidget().center())
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
