import 'dart:async';

import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/job_request_dahboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/modern_category_services_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/service_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/slider_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/shimmer/dashboard_shimmer_3.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

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
        throw e; // Re-throw the error to maintain the Future's error state
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

    if (apiServices != null) {
      for (var service in apiServices) {
        if (service.country != null && service.country!.contains(country)) {
          allServices.add(service);
        }
      }
    }

    return allServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Observer(
        builder: (context) {
          return FutureBuilder<DashboardResponse>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DashboardResponse data = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    init();
                    setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // App Bar
                        AppbarDashboardComponent3(
                          featuredList: data.featuredServices.validate(),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                onTap: () {
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

                        // Slider Component
                        SliderDashboardComponent3(
                          sliderList: data.slider.validate(),
                        ),

                        16.height,

                        // Modern Category Services Component (replaces separate category and service components)
                        ModernCategoryServicesComponent(
                          categoryList: data.category.validate(),
                          serviceList: data.service.validate(),
                        ),

                        16.height,

                        // Job Request Component
                        JobRequestDashboardComponent3(),

                        16.height,

                        // Upcoming Booking Component
                        UpcomingBookingDashboardComponent3(
                          upcomingBookingData: data.upcomingData,
                        ),

                        16.height,
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return NoDataWidget(
                  title: language.noDataFoundInFilter,
                  subTitle: language.noDataFoundInFilter,
                  onRetry: () {
                    init();
                    setState(() {});
                  },
                );
              }

              return DashboardShimmer3();
            },
          );
        },
      ),
    );
  }
}
