import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/screens/maintenance_mode_screen.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:country_picker/country_picker.dart';

import '../component/loader_widget.dart';
import '../network/rest_apis.dart';
import 'walk_through_screen.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/screens/maintenance_mode_screen.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:country_picker/country_picker.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool appNotSynced = false;
  final String LANGUAGE_SELECTED_KEY = 'language_selected';
  final String USER_LANGUAGE_CODE_KEY = 'user_language_code';
  final String COUNTRY_SELECTED_KEY = 'country_selected';
  final String USER_COUNTRY_CODE_KEY = 'user_country_code';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Country? selectedCountry;
  List<Country> allowedCountries = [];

  void showCustomCountryPicker(BuildContext parentContext, StateSetter parentSetState) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.selectCountry,
                      style: boldTextStyle(size: 20, color: context.primaryColor),
                    ),
                    16.height,
                    ...allowedCountries.map((country) {
                      bool isSelected = selectedCountry?.countryCode == country.countryCode;
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? context.primaryColor : Colors.grey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected ? context.primaryColor.withOpacity(0.1) : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // Update the state in parent dialog and main screen
                              selectedCountry = country;

                              // Update all states
                              setDialogState(() {});
                              parentSetState(() {});
                              setState(() {});

                              // Save to preferences
                              await setValue(USER_COUNTRY_CODE_KEY, country.countryCode);
                              await setValue(COUNTRY_SELECTED_KEY, true);

                              // Close dialog after a short delay
                              await Future.delayed(Duration(milliseconds: 200));
                              Navigator.pop(dialogContext);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.displayName,
                                        style: boldTextStyle(
                                          color: isSelected ? context.primaryColor : null,
                                        ),
                                      ),
                                      4.height,
                                      Text(
                                        '+${country.phoneCode}',
                                        style: secondaryTextStyle(
                                          color: isSelected ? context.primaryColor : null,
                                        ),
                                      ),
                                    ],
                                  ).expand(),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: context.primaryColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
    initializeAllowedCountries();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    afterBuildCreated(() {
      setStatusBarColor(Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark);
      init();
    });
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

  void initializeAllowedCountries() {
    allowedCountries = [getEgyptCountry(), getSaudiArabiaCountry()];

    // Set initial country from saved preferences
    String savedCountryCode = getStringAsync(USER_COUNTRY_CODE_KEY);
    if (savedCountryCode.isNotEmpty) {
      selectedCountry = allowedCountries.firstWhere(
            (country) => country.countryCode == savedCountryCode,
        orElse: () => getEgyptCountry(),
      );
    }
  }



  Future<void> showLanguageCountryDialog() async {
    await initializeDefaultSettings();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.selectPreferences,
                        style: boldTextStyle(size: 24, color: context.primaryColor),
                      ),
                      24.height,

                      // Language Section
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.language,
                              style: boldTextStyle(color: context.primaryColor),
                            ),
                            16.height,
                            LanguageListWidget(
                              widgetType: WidgetType.LIST,
                              onLanguageChange: (v) async {
                                await setValue(USER_LANGUAGE_CODE_KEY, v.languageCode);
                                await appStore.setLanguage(v.languageCode!);
                                await setValue(LANGUAGE_SELECTED_KEY, true);
                                dialogSetState(() {});
                                setState(() {}); // Update parent state too
                              },
                            ),
                          ],
                        ),
                      ),
                      24.height,

                      // Country Section
                      StatefulBuilder(
                        builder: (context, countrySetState) {
                          return Container(
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language.selectCountry,
                                  style: boldTextStyle(color: context.primaryColor),
                                ),
                                16.height,
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        showCustomCountryPicker(context, (value) {
                                          dialogSetState(() {});
                                          countrySetState(() {});
                                          setState(() {});
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Text(
                                              selectedCountry?.displayName ?? language.selectCountry,
                                              style: primaryTextStyle(),
                                            ).expand(),
                                            Icon(Icons.arrow_drop_down, color: context.iconColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      24.height,

                      // Confirm Button
                      Container(
                        width: context.width(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [context.primaryColor, context.primaryColor.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => finish(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            language.confirm,
                            style: boldTextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
        fit: StackFit.expand,
        children: [
        // Animated background
        FadeTransition(
        opacity: _fadeAnimation,
        child: Image.asset(
        appStore.isDarkMode ? splash_background : splash_light_background,
        height: context.height(),
    width: context.width(),
    fit: BoxFit.cover,
    ),
    ),

    // Content
    FadeTransition(
    opacity: _fadeAnimation,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Container(
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
    BoxShadow(
    color: context.primaryColor.withOpacity(0.2),
    blurRadius: 20,
      //blurRadius: 20,
      spreadRadius: 5,
      offset: Offset(0, 5),
    ),
    ],
    ),
      child: Image.asset(
        appStore.isDarkMode ? lightLogo : darkLogo,
        height: 120,
        width: 120,
      ),
    ),
      32.height,
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          APP_NAME,
          style: boldTextStyle(
            size: 26,
            color: appStore.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      16.height,
      if (appNotSynced)
        Observer(
          builder: (_) => appStore.isLoading
              ? Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: LoaderWidget(),
          )
              : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton.icon(
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                language.reload,
                style: boldTextStyle(color: Colors.white),
              ),
              onPressed: () {
                appStore.setLoading(true);
                init();
              },
            ).paddingSymmetric(horizontal: 8, vertical: 4),
          ),
        ),
    ],
    ),
    ),
        ],
        ),
    );
  }

  Future<void> initializeDefaultSettings() async {
    // Check if language is already set, if not set Arabic as default
    if (!getBoolAsync(LANGUAGE_SELECTED_KEY)) {
      await setValue(SELECTED_LANGUAGE_CODE, 'ar');
      await setValue(USER_LANGUAGE_CODE_KEY, 'ar');
      await appStore.setLanguage('ar');
      await setValue(LANGUAGE_SELECTED_KEY, true);
    }

    // Check if country is already set, if not set Egypt as default
    if (!getBoolAsync(COUNTRY_SELECTED_KEY)) {
      selectedCountry = getEgyptCountry();
      await setValue(USER_COUNTRY_CODE_KEY, 'EG');
      await setValue(COUNTRY_SELECTED_KEY, true);
    } else {
      String savedCountryCode = getStringAsync(USER_COUNTRY_CODE_KEY);
      selectedCountry = allowedCountries.firstWhere(
            (country) => country.countryCode == savedCountryCode,
        orElse: () => getEgyptCountry(),
      );
      setState(() {}); // Ensure UI updates with selected country
    }
  }

  Future<void> init() async {
    String cachedLanguageCode = getStringAsync(USER_LANGUAGE_CODE_KEY, defaultValue: 'ar');
    await appStore.setLanguage(cachedLanguageCode);

    try {
      await getAppConfigurations();

      appStore.setLoading(false);
      if (!getBoolAsync(IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)) {
        appNotSynced = true;
        setState(() {});
      } else {
        int themeModeIndex = getIntAsync(THEME_MODE_INDEX, defaultValue: THEME_MODE_SYSTEM);
        if (themeModeIndex == THEME_MODE_SYSTEM) {
          appStore.setDarkMode(MediaQuery.of(context).platformBrightness == Brightness.dark);
        }

        if (appConfigurationStore.maintenanceModeStatus) {
          MaintenanceModeScreen().launch(context,
              isNewTask: true,
              pageRouteAnimation: PageRouteAnimation.Fade
          );
        } else {
          if (!getBoolAsync(LANGUAGE_SELECTED_KEY) || !getBoolAsync(COUNTRY_SELECTED_KEY)) {
            await showLanguageCountryDialog();
          }

          if (getBoolAsync(IS_FIRST_TIME, defaultValue: true)) {
            WalkThroughScreen().launch(context,
                isNewTask: true,
                pageRouteAnimation: PageRouteAnimation.Fade
            );
          } else {
            DashboardScreen().launch(context,
                isNewTask: true,
                pageRouteAnimation: PageRouteAnimation.Fade
            );
          }
        }
      }
    } catch (e) {
      if (!await isNetworkAvailable()) {
        toast(errorInternetNotAvailable);
      }
      log(e.toString());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

