import 'dart:async';

import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/all_services_grid_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_services_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/enhanced_category_services_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/job_request_dahboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/service_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/slider_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/shimmer/dashboard_shimmer_3.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../../main.dart';
import '../../../model/dashboard_model.dart';
import '../../../model/service_data_model.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/constant.dart';
import '../../../utils/images.dart';
import 'component/upcoming_booking_dashboard_component_3.dart';

class DashboardFragment3 extends StatefulWidget {
  @override
  _DashboardFragment3State createState() => _DashboardFragment3State();
}

class _DashboardFragment3State extends State<DashboardFragment3> {
  Future<DashboardResponse>? future;

  @override
  void initState() {
    super.initState();
    init();

    afterBuildCreated(() {
      setStatusBarColor(primaryColor,
          delayInMilliSeconds: 800, statusBarIconBrightness: Brightness.light);
    });

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      init();
      appStore.setLoading(true);

      setState(() {});
    });
  }

  void init() async {
    future = userDashboard(
        isCurrentLocation: appStore.isCurrentLocation,
        lat: getDoubleAsync(LATITUDE),
        long: getDoubleAsync(LONGITUDE))
      ..then((value) {
        // Turn off loading when data is loaded successfully
        appStore.setLoading(false);
        return value;
      })
      ..catchError((e) {
        // Make sure to turn off loading state on error
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  // Helper to combine all services for the all services section
  List<ServiceData> combineServices(List<ServiceData>? apiServices) {
    List<ServiceData> allServices = [];

    // Country filter
    String countryCode =
        getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
    String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';

    // Add services from API
    if (apiServices != null) {
      allServices.addAll(apiServices);
    }

    // Apply country filtering
    allServices = allServices.where((service) {
      // If no country restrictions, include the service
      if (service.country == null || service.country!.isEmpty) return true;

      // Otherwise check if user's country is in the service's allowed countries
      return service.country!
          .any((c) => c.toString().toLowerCase() == country.toLowerCase());
    }).toList();

    // Sort services alphabetically by name
    allServices.sort((a, b) => a.name.validate().compareTo(b.name.validate()));
    return allServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SnapHelperWidget<DashboardResponse>(
            initialData: cachedDashboardResponse,
            future: future,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  appStore.setLoading(true);
                  init();

                  setState(() {});
                },
              );
            },
            loadingWidget: DashboardShimmer3(),
            onSuccess: (snap) {
              // Split the sliders into two groups for top and bottom banners
              List<SliderModel> allSliders = snap.slider.validate();
              List<SliderModel> topSliders = [];
              List<SliderModel> bottomSliders = [];

              if (allSliders.isNotEmpty) {
                // First check if sliders already have direction specified
                topSliders = allSliders
                    .where((slider) =>
                        (slider.direction ?? '').isEmpty ||
                        (slider.direction ?? '').toLowerCase() == 'up')
                    .toList();

                bottomSliders = allSliders
                    .where((slider) =>
                        (slider.direction ?? '').toLowerCase() == 'down')
                    .toList();

                // If no direction specified, distribute sliders automatically
                if (bottomSliders.isEmpty && allSliders.length > 1) {
                  int midPoint = (allSliders.length / 2).ceil();
                  // Keep already assigned ones in topSliders
                  List<SliderModel> unassignedSliders = allSliders
                      .where((slider) => !topSliders.contains(slider))
                      .toList();

                  if (unassignedSliders.isNotEmpty) {
                    bottomSliders = unassignedSliders;
                  }
                }
              }

              // Combine all services for all services section
              List<ServiceData> allServices = combineServices(snap.service);

              return Observer(builder: (context) {
                return AnimatedScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);

                    setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    // App Bar with search and notification
                    AppbarDashboardComponent3(
                      featuredList: snap.featuredServices.validate(),
                      callback: () async {
                        appStore.setLoading(true);

                        init();
                        setState(() {});
                      },
                    ),

                    // Location Selection Bar
                    Observer(
                      builder: (context) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: radius(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: AppButton(
                            padding: EdgeInsets.all(0),
                            width: context.width(),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: boxDecorationDefault(
                                  color: context.cardColor),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  ic_location.iconImage(
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      size: 24),
                                  8.width,
                                  Expanded(
                                    child: Text(
                                      appStore.isCurrentLocation
                                          ? getStringAsync(CURRENT_ADDRESS)
                                          : language.lblLocationOff,
                                      style: secondaryTextStyle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  8.width,
                                  Icon(Icons.keyboard_arrow_down,
                                      size: 24,
                                      color: appStore.isCurrentLocation
                                          ? primaryColor
                                          : context.iconColor),
                                ],
                              ),
                            ),
                            onTap: () async {
                              locationWiseService(context, () {
                                appStore.setLoading(true);

                                init();
                                setState(() {});
                              });
                            },
                          ),
                        );
                      },
                    ),

                    16.height,

                    // TOP BANNER - Featured Sliders
                    if (topSliders.isNotEmpty)
                      SliderDashboardComponent3(sliderList: topSliders),

                    24.height,

                    // Upcoming Bookings Section
                    UpcomingBookingDashboardComponent3(
                        upcomingBookingData: snap.upcomingData),

                    16.height,

                    // Services by Category - Enhanced Component
                    if (snap.category != null && snap.category!.isNotEmpty)
                      EnhancedCategoryServicesComponent(
                        categories: snap.category!,
                        initialServices: snap.service,
                        fetchMissingServices: true,
                      ),

                    24.height,

                    // Featured Services Section
                    ServiceListDashboardComponent3(
                      serviceList: snap.featuredServices.validate(),
                      serviceListTitle: language.featuredServices,
                      isFeatured: true,
                    ),

                    24.height,

                    // BOTTOM BANNER - Promotional Sliders
                    if (bottomSliders.isNotEmpty)
                      SliderDashboardComponent3(sliderList: bottomSliders),

                    16.height,

                    // All Services Section
                    if (allServices.isNotEmpty)
                      SizedBox(
                        width: context.width(),
                        child: AllServicesGridComponent(
                          serviceList: allServices,
                          title: language.allServices
                              .validate(value: 'All Services'),
                          showViewAll: allServices.length > 8,
                        ),
                      ),

                    // Job Request Section (if enabled)
                    if (appConfigurationStore.jobRequestStatus)
                      JobRequestDashboardComponent3(),

                    // Extra bottom space for better scrolling experience
                    60.height,
                  ],
                );
              });
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
