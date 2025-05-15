import 'dart:io';

import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/chat/chat_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/profile_fragment.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/loader_widget.dart';
import '../../component/voice_search_component.dart';
import '../../model/availability_response.dart';
import '../../model/base_response_model.dart';
import '../../network/network_utils.dart';
import '../../network/rest_apis.dart';
import '../../utils/app_configuration.dart';
import '../../utils/firebase_messaging_utils.dart';
import '../newDashboard/dashboard_1/dashboard_fragment_1.dart';
import '../newDashboard/dashboard_2/dashboard_fragment_2.dart';
import '../newDashboard/dashboard_3/dashboard_fragment_3.dart';
import '../newDashboard/dashboard_4/dashboard_fragment_4.dart';
import 'dart:io';

import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/chat/chat_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/profile_fragment.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

import '../../component/loader_widget.dart';
import '../../component/voice_search_component.dart';
import '../../model/availability_response.dart';
import '../../network/rest_apis.dart';
import '../../utils/app_configuration.dart';
import '../../utils/firebase_messaging_utils.dart';
import '../newDashboard/dashboard_1/dashboard_fragment_1.dart';
import '../newDashboard/dashboard_2/dashboard_fragment_2.dart';
import '../newDashboard/dashboard_3/dashboard_fragment_3.dart';
import '../newDashboard/dashboard_4/dashboard_fragment_4.dart';

class DashboardScreen extends StatefulWidget {
  final bool? redirectToBooking;

  DashboardScreen({this.redirectToBooking});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;
  bool _isLocationCheckCompleted = false;
  bool _isLocationDialogShownThisSession = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.redirectToBooking == true ? 1 : 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request location automatically on app start
      requestLocationAccess();
      initializeThemeMode();
      initializeFirebase();
    });

    LiveStream().on(LIVESTREAM_FIREBASE, (value) {
      if (value == 3) {
        currentIndex = 3;
        setState(() {});
      }
    });

    init();
  }

  // Method to open maps and handle location selection
  Future<void> openMapForLocationSelection() async {
    try {
      // First show instructions dialog
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('تغيير الموقع', style: boldTextStyle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 48, color: context.primaryColor),
              16.height,
              Text(
                'سيتم فتح تطبيق الخرائط. قم بالبحث عن الموقع المطلوب أو تحريك الخريطة واختيار الموقع الذي تريده.',
                style: primaryTextStyle(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('فهمت',
                  style: boldTextStyle(color: context.primaryColor)),
            ),
          ],
        ),
      );

      // Get the last known position to use as starting point
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      double latitude = lastPosition?.latitude ??
          30.0444; // Default to Cairo coordinates if no position
      double longitude = lastPosition?.longitude ?? 31.2357;

      // Create a URL that will allow users to search for places
      // The 'q=' parameter is for search query - we'll leave it empty to let user search
      final url = Platform.isIOS
          ? 'https://maps.apple.com/?ll=$latitude,$longitude&q='
          : 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      // Open the map in the device's map app
      final canLaunch =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      if (!canLaunch) {
        // Try with just coordinates as fallback
        final fallbackUrl = 'geo:$latitude,$longitude?q=';
        await launchUrl(Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication);
      }

      // After user returns from the map app, ask if they've selected a new location
      if (mounted) {
        // Give user some time to return from the maps app
        bool dialogShown = false;

        // Set a timeout to ensure we don't wait forever if user doesn't return to app
        Future.delayed(Duration(seconds: 15)).then((_) {
          if (!dialogShown && mounted) {
            // If dialog hasn't been shown after timeout, assume user didn't return
            toast('لم يتم اختيار موقع جديد. يرجى المحاولة مرة أخرى.');
          }
        });

        // Wait for a reasonable time for the user to interact with maps and return
        await Future.delayed(Duration(seconds: 3));

        // Show dialog only if still mounted (user returned to app)
        if (mounted) {
          dialogShown = true;

          bool? shouldCheckNewLocation = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: radius(16)),
              title: Text('تأكيد الموقع الجديد', style: boldTextStyle()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 56, color: Colors.green),
                  16.height,
                  Text(
                    'هل قمت بتحديد موقع جديد وترغب في التحقق من توفر الخدمة في هذا الموقع؟',
                    style: primaryTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('لا', style: boldTextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: radius(8)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('نعم، تحقق الآن',
                      style: boldTextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (shouldCheckNewLocation == true) {
            // User selected a new location, try to get it and verify service availability
            toast('جاري التحقق من الموقع الجديد...');
            appStore.setLoading(true); // Show loading indicator
            requestLocationAccess();
          }
        }
      }
    } catch (e) {
      log('Error opening map: $e');
      toast('لا يمكن فتح الخريطة. يرجى المحاولة مرة أخرى.');
    }
  }

  // Function to check location availability once per session
  Future<void> checkLocationAndShowDialogOnce(
      BuildContext context, Position position) async {
    // Skip showing dialog if already shown this session
    if (_isLocationDialogShownThisSession) return;

    // Mark as shown for this session
    _isLocationDialogShownThisSession = true;

    // You can add your location availability check logic here if needed
    // For now, we're just skipping the dialog
  }

  Future<void> requestLocationAccess() async {
    try {
      // Check if we already have location saved (for subsequent app opens)
      double savedLat = getDoubleAsync(LATITUDE);
      double savedLong = getDoubleAsync(LONGITUDE);

      // If we already have the location and it's not the first run, use saved location
      if (savedLat != 0 && savedLong != 0 && !isFirstTime()) {
        appStore.setCurrentLocation(true);
        _isLocationCheckCompleted = true;

        // Still update in background without showing dialog
        getLocationInBackground();

        setState(() {});
        return;
      }

      appStore.setLoading(true);

      // Check if location services are enabled at the system level
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog to enable location services
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => EnableLocationServiceDialog(),
          );
        }
        appStore.setLoading(false);
        _isLocationCheckCompleted = true;
        setState(() {});
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => RequestLocationPermissionDialog(),
            );
          }
          appStore.setLoading(false);
          _isLocationCheckCompleted = true;
          setState(() {});
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OpenSettingsDialog(),
          );
        }
        appStore.setLoading(false);
        _isLocationCheckCompleted = true;
        setState(() {});
        return;
      }

      // Get the location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      // Store location in preferences
      await setValue(LATITUDE, position.latitude);
      await setValue(LONGITUDE, position.longitude);

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          // localeIdentifier: 'ar'
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address = '';

          if (place.locality != null && place.locality!.isNotEmpty) {
            address += place.locality!;
          } else if (place.subLocality != null &&
              place.subLocality!.isNotEmpty) {
            address += place.subLocality!;
          }

          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            if (address.isNotEmpty) address += ", ";
            address += place.administrativeArea!;
          }

          if (address.isEmpty &&
              place.country != null &&
              place.country!.isNotEmpty) {
            address = place.country!;
          }

          await setValue(CURRENT_ADDRESS, address);
          appStore.setCurrentLocation(true);
        }
      } catch (e) {
        log('Error getting address: $e');
        // If geocoding fails, at least save coordinates
        await setValue(CURRENT_ADDRESS,
            'Lat: ${position.latitude}, Long: ${position.longitude}');
        appStore.setCurrentLocation(true);
      }

      // Mark first time as false after successful location capture
      await setValue(IS_FIRST_TIME, false);

      // Check if service is available at this location using our helper function
      await checkLocationAndShowDialogOnce(context, position);

      appStore.setLoading(false);
      _isLocationCheckCompleted = true;
      setState(() {});

      // Trigger dashboard data refresh with location
      LiveStream().emit(LIVESTREAM_UPDATE_DASHBOARD);
    } catch (e) {
      log('Error in requestLocationAccess: $e');
      appStore.setLoading(false);
      _isLocationCheckCompleted = true;
      setState(() {});
    }
  }

  // Get location in background without UI interference
  Future<void> getLocationInBackground() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Get the location with a shorter timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ).catchError((e) {
        // Just log error and continue - don't interrupt user
        log('Background location error: $e');
        return Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });

      // Only update if we got a valid location
      if (position.latitude != 0 && position.longitude != 0) {
        await setValue(LATITUDE, position.latitude);
        await setValue(LONGITUDE, position.longitude);
        appStore.setCurrentLocation(true);

        // Quietly update the dashboard
        LiveStream().emit(LIVESTREAM_UPDATE_DASHBOARD);
      }
    } catch (e) {
      // Silently log error
      log('Background location error: $e');
    }
  }

  // Helper to check if it's first time opening the app
  bool isFirstTime() {
    return getBoolAsync(IS_FIRST_TIME, defaultValue: true);
  }

  void initializeThemeMode() {
    if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
      appStore.setDarkMode(context.platformBrightness() == Brightness.dark);
    }

    View.of(context).platformDispatcher.onPlatformBrightnessChanged = () async {
      if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(
            MediaQuery.of(context).platformBrightness == Brightness.light);
      }
    };
  }

  void initializeFirebase() {
    Firebase.initializeApp().then((value) {
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        handleNotificationClick(message);
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          handleNotificationClick(message);
        }
      });
    }).catchError(onError);
  }

  void init() async {
    if (isMobile && appStore.isLoggedIn) {
      // Handle Notification click and redirect
    }

    await 3.seconds.delay;
    if (getIntAsync(FORCE_UPDATE_USER_APP).getBoolInt()) {
      showForceUpdateDialog(context);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_FIREBASE);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      message: language.lblBackPressMsg,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            AnimatedOpacity(
              opacity: _isLocationCheckCompleted ? 1.0 : 0.5,
              duration: Duration(milliseconds: 300),
              child: [
                Observer(builder: (context) {
                  if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
                    return DashboardFragment1();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_2) {
                    return DashboardFragment2();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_3) {
                    return DashboardFragment3();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_4) {
                    return DashboardFragment4();
                  } else {
                    return DashboardFragment();
                  }
                }),
                Observer(
                    builder: (context) => appStore.isLoggedIn
                        ? BookingFragment()
                        : SignInScreen(isFromDashboard: true)),
                CategoryScreen(),
                Observer(
                    builder: (context) => appStore.isLoggedIn
                        ? ChatListScreen()
                        : SignInScreen(isFromDashboard: true)),
                ProfileFragment(),
              ][currentIndex],
            ),

            // Loading indicator
            Observer(
              builder: (_) => appStore.isLoading
                  ? Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: LoaderWidget(),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
        bottomNavigationBar: Blur(
          blur: 30,
          borderRadius: radius(0),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: primaryColor,
              indicatorColor: Colors.white.withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.all(
                  primaryTextStyle(size: 12, color: Colors.white)),
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              destinations: [
                NavigationDestination(
                  icon: ic_home.iconImage(color: Colors.white70),
                  selectedIcon: ic_home.iconImage(color: Colors.white),
                  label: language.home,
                ),
                NavigationDestination(
                  icon: ic_ticket.iconImage(color: Colors.white70),
                  selectedIcon: ic_ticket.iconImage(color: Colors.white),
                  label: language.booking,
                ),
                NavigationDestination(
                  icon: ic_category.iconImage(color: Colors.white70),
                  selectedIcon: ic_category.iconImage(color: Colors.white),
                  label: language.category,
                ),
                NavigationDestination(
                  icon: ic_chat.iconImage(color: Colors.white70),
                  selectedIcon: ic_chat.iconImage(color: Colors.white),
                  label: language.lblChat,
                ),
                Observer(builder: (context) {
                  return NavigationDestination(
                    icon: (appStore.isLoggedIn &&
                            appStore.userProfileImage.isNotEmpty)
                        ? IgnorePointer(
                            ignoring: true,
                            child: ImageBorder(
                                src: appStore.userProfileImage, height: 26))
                        : ic_profile2.iconImage(color: Colors.white70),
                    selectedIcon: (appStore.isLoggedIn &&
                            appStore.userProfileImage.isNotEmpty)
                        ? IgnorePointer(
                            ignoring: true,
                            child: ImageBorder(
                                src: appStore.userProfileImage, height: 26))
                        : ic_profile2.iconImage(color: Colors.white),
                    label: language.profile,
                  );
                }),
              ],
              onDestinationSelected: (index) {
                currentIndex = index;
                setState(() {});
              },
            ),
          ),
        ),
        bottomSheet: Observer(builder: (context) {
          return VoiceSearchComponent().visible(appStore.isSpeechActivated);
        }),
      ),
    );
  }
}

class EnableLocationServiceDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: radius()),
      child: Container(
        width: context.width() * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 56),
            16.height,
            Text(
              'خدمة الموقع معطلة',
              style: boldTextStyle(size: 20),
              textAlign: TextAlign.center,
            ),
            16.height,
            Text(
              'يرجى تفعيل خدمة الموقع لاستخدام التطبيق',
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: 'إلغاء',
                  textStyle: boldTextStyle(color: Colors.grey),
                  color: Colors.grey.withOpacity(0.2),
                  onTap: () => finish(context),
                ),
                16.width,
                AppButton(
                  text: 'فتح الإعدادات',
                  textStyle: boldTextStyle(color: Colors.white),
                  color: context.primaryColor,
                  onTap: () async {
                    await Geolocator.openLocationSettings();
                    if (context.mounted) finish(context);
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

class RequestLocationPermissionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: radius()),
      child: Container(
        width: context.width() * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_disabled, color: Colors.orange, size: 56),
            16.height,
            Text(
              'مطلوب إذن الموقع',
              style: boldTextStyle(size: 20),
              textAlign: TextAlign.center,
            ),
            16.height,
            Text(
              'يرجى السماح بالوصول إلى موقعك لاستخدام التطبيق',
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: 'إلغاء',
                  textStyle: boldTextStyle(color: Colors.grey),
                  color: Colors.grey.withOpacity(0.2),
                  onTap: () => finish(context),
                ),
                16.width,
                AppButton(
                  text: 'السماح',
                  textStyle: boldTextStyle(color: Colors.white),
                  color: context.primaryColor,
                  onTap: () async {
                    await Permission.location.request();
                    if (context.mounted) finish(context);
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

class OpenSettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: radius()),
      child: Container(
        width: context.width() * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, color: Colors.orange, size: 56),
            16.height,
            Text(
              'تم رفض إذن الموقع',
              style: boldTextStyle(size: 20),
              textAlign: TextAlign.center,
            ),
            16.height,
            Text(
              'يرجى فتح إعدادات التطبيق والسماح بإذن الموقع',
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  text: 'إلغاء',
                  textStyle: boldTextStyle(color: Colors.grey),
                  color: Colors.grey.withOpacity(0.2),
                  onTap: () => finish(context),
                ),
                16.width,
                AppButton(
                  text: 'فتح الإعدادات',
                  textStyle: boldTextStyle(color: Colors.white),
                  color: context.primaryColor,
                  onTap: () async {
                    await openAppSettings();
                    if (context.mounted) finish(context);
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

class UnsupportedAreaDialog extends StatelessWidget {
  const UnsupportedAreaDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: radius(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: redColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: redColor,
                size: 48,
              ),
            ),
            24.height,
            Text(
              'الخدمة غير متوفرة في موقعك',
              style: boldTextStyle(size: 20),
              textAlign: TextAlign.center,
            ),
            16.height,
            Text(
              'نعتذر، خدماتنا غير متوفرة حاليًا في الموقع الذي تم تحديده. يمكنك المحاولة مرة أخرى لاحقًا.',
              style: secondaryTextStyle(size: 14),
              textAlign: TextAlign.center,
            ),
            30.height,
            // Only showing the close button, change location button is commented out
            AppButton(
              text: 'إغلاق',
              textStyle: boldTextStyle(color: textPrimaryColorGlobal),
              elevation: 0,
              width: context.width() - 80, // Full width button
              color: context.scaffoldBackgroundColor,
              shapeBorder: RoundedRectangleBorder(
                  borderRadius: radius(10),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2))),
              onTap: () {
                finish(context);
              },
            ),
            /* Commenting out the Change Location button
            Row(
              children: [
                AppButton(
                  text: 'إغلاق',
                  textStyle: boldTextStyle(color: textPrimaryColorGlobal),
                  elevation: 0,
                  color: context.scaffoldBackgroundColor,
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius: radius(10),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  onTap: () {
                    finish(context);
                  },
                ).expand(),
                16.width,
                AppButton(
                  text: 'تغيير الموقع',
                  textStyle: boldTextStyle(color: Colors.white),
                  elevation: 0,
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: radius(10),
                  ),
                  color: context.primaryColor,
                  onTap: () {
                    finish(context);

                    // Use our new method to open maps for location selection
                    if (context is _DashboardScreenState) {
                      (context as _DashboardScreenState)
                          .openMapForLocationSelection();
                    }
                  },
                ).expand(),
              ],
            ),
            */
          ],
        ),
      ),
    );
  }
}

class LocationService {
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => EnableLocationServiceDialog(),
          );
        }
        return null;
      }

      // Then check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => RequestLocationPermissionDialog(),
            );
          }
          return null;
        }
      }

      // Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OpenSettingsDialog(),
          );
        }
        return null;
      }

      // Get actual position with shorter timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }
}
