import 'dart:async';

import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
<<<<<<< Updated upstream
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/all_services_grid_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_services_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/enhanced_category_services_component.dart';
=======
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_list_dashboard_component_3.dart';
>>>>>>> Stashed changes
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/job_request_dahboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/service_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/slider_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/shimmer/dashboard_shimmer_3.dart';
<<<<<<< Updated upstream
=======
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
>>>>>>> Stashed changes
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
                    // Top Banner Slider with video control - like fragment 1
                    Column(
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

<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes
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
                                      Text(
                                        appStore.isCurrentLocation
                                            ? getStringAsync(CURRENT_ADDRESS)
                                            : language.lblLocationOff,
                                        style: secondaryTextStyle(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ).expand(),
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

                        0.height,

                        // TOP BANNER - Featured Sliders with video control
                        if (topSliders.isNotEmpty)
                          SliderDashboardComponent3(
                            key: _topSliderKey,
                            sliderList: topSliders,
                          ),
                      ],
                    ),

                    0.height, // Same spacing as fragment 1

<<<<<<< Updated upstream
                    // TOP BANNER - Featured Sliders
                    if (topSliders.isNotEmpty)
                      SliderDashboardComponent3(sliderList: topSliders),
=======
                    // Horizontal Categories - like fragment 1
                    if (sortedCategories.isNotEmpty)
                      CategoryListDashboardComponent3(
                        categoryList: sortedCategories.take(8).toList(),
                      ),
>>>>>>> Stashed changes

                    8.height, // Reduced spacing after categories

                    // Upcoming Bookings Section - like fragment 1
                    UpcomingBookingDashboardComponent3(
                        upcomingBookingData: snap.upcomingData),

                    0.height, // Slightly reduced spacing

<<<<<<< Updated upstream
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
=======
                    // Same spacing as fragment 1

                    // Categories with their services - exactly like fragment 1
                    SimpleCategoriesWithServicesComponent(
                      categories: sortedCategories,
                      services: snap.service.validate(),
                    ),

                    16.height, // Same spacing as fragment 1

                    // Featured Services Section - exactly like fragment 1
                    if (snap.featuredServices.validate().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Text(
                                    language.featuredServices,
                                    style: boldTextStyle(
                                        size: 18, letterSpacing: 0.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: primaryColor.withOpacity(0.5),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  padding: EdgeInsets.only(bottom: 4),
                                ),
                                if (snap.featuredServices.validate().length > 3)
                                  TextButton.icon(
                                    onPressed: () {
                                      ViewAllServiceScreen(isFeatured: '1')
                                          .launch(context);
                                    },
                                    icon: Icon(Icons.arrow_forward,
                                        size: 16, color: primaryColor),
                                    label: Text(
                                      "View All",
                                      style: boldTextStyle(
                                          color: primaryColor, size: 14),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 0),
                                      minimumSize: Size(10, 30),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          12.height,
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              HorizontalList(
                                itemCount:
                                    snap.featuredServices.validate().length,
                                spacing: 16,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  return ServiceComponent(
                                    serviceData: snap.featuredServices![index],
                                    width: context.width() / 2 - 26,
                                  );
                                },
                              ),
                              // Right scroll indicator
                              if (snap.featuredServices.validate().length > 2)
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        colors: [
                                          context.scaffoldBackgroundColor,
                                          context.scaffoldBackgroundColor
                                              .withOpacity(0.0),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
>>>>>>> Stashed changes

                    24.height,
                    // All Services section - exactly like fragment 1
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Text(
                                  language.allServices,
                                  style: boldTextStyle(
                                      size: 18, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor.withOpacity(0.5),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                padding: EdgeInsets.only(bottom: 4),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  ViewAllServiceScreen(isFeatured: '')
                                      .launch(context);
                                },
                                icon: Icon(Icons.arrow_forward,
                                    size: 16, color: primaryColor),
                                label: Text(
                                  "View All",
                                  style: boldTextStyle(
                                      color: primaryColor, size: 14),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                  minimumSize: Size(10, 30),
                                ),
                              ),
                            ],
                          ),
                        ),
                        12.height,
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            HorizontalList(
                              itemCount: snap.service.validate().length,
                              spacing: 16,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                return ServiceComponent(
                                  serviceData: snap.service![index],
                                  width: context.width() / 2 - 26,
                                );
                              },
                            ),
                            // Right scroll indicator - exactly like fragment 1
                            if (snap.service.validate().length > 2)
                              Positioned(
                                right: 0,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        context.scaffoldBackgroundColor,
                                        context.scaffoldBackgroundColor
                                            .withOpacity(0.0),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

<<<<<<< Updated upstream
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
=======
                    16.height, // Same spacing as fragment 1

                    // Bottom Banner Slider - exactly like fragment 1
                    if (bottomSliders.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Container(
                                child: Text(
                                  "Promotions",
                                  style: boldTextStyle(
                                      size: 18, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor.withOpacity(0.5),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                padding: EdgeInsets.only(bottom: 4),
                              ),
                            ),
                            16.height,
                            SliderDashboardComponent3(
                              key: _bottomSliderKey,
                              sliderList: bottomSliders,
                            ),
                          ],
                        ),
                      ),

                    16.height, // Same spacing as fragment 1

                    // Job Request Section - exactly like fragment 1
>>>>>>> Stashed changes
                    if (appConfigurationStore.jobRequestStatus)
                      JobRequestDashboardComponent3(),
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
<<<<<<< Updated upstream
=======

// Simplified component to match CategoryServiceListComponent from fragment 1
class SimpleCategoriesWithServicesComponent extends StatelessWidget {
  final List<CategoryData> categories;
  final List<ServiceData> services;

  SimpleCategoriesWithServicesComponent({
    required this.categories,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.category,
          style: boldTextStyle(size: 22),
        ).paddingSymmetric(horizontal: 16),
        12.height, // Reduced from 16

        // Categories with minimal spacing - exactly like fragment 1
        ...categories.asMap().entries.map((entry) {
          CategoryData category = entry.value;

          // Get services for this category (including from totalServices if available)
          List<ServiceData> categoryServices = [];

          // First, get services from the main services list
          categoryServices.addAll(services
              .where((service) => service.categoryId == category.id)
              .toList());

          // Then, add services from category's totalServices if available
          if (category.totalServices != null &&
              category.totalServices!.isNotEmpty) {
            for (var service in category.totalServices!) {
              // Avoid duplicates
              if (!categoryServices.any((s) => s.id == service.id)) {
                categoryServices.add(service);
              }
            }
          }

          // Skip if no services found for this category
          if (categoryServices.isEmpty) return SizedBox();

          return Container(
            margin:
                EdgeInsets.only(bottom: 16), // Reduced spacing from 20 to 16
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header - exactly like fragment 1
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          category.name.validate(),
                          style: boldTextStyle(size: 18, letterSpacing: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: primaryColor.withOpacity(0.5),
                              width: 2.0,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(bottom: 4),
                      ).expand(),
                      if (categoryServices.length > 3)
                        TextButton.icon(
                          onPressed: () {
                            ViewAllServiceScreen(
                                    categoryId: category.id.validate(),
                                    categoryName: category.name,
                                    isFromCategory: true)
                                .launch(context);
                          },
                          icon: Icon(Icons.arrow_forward,
                              size: 16, color: primaryColor),
                          label: Text(
                            "View All",
                            style: boldTextStyle(color: primaryColor, size: 14),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            minimumSize: Size(10, 30),
                          ),
                        ),
                    ],
                  ),
                ),
                12.height, // Same spacing as fragment 1

                // Horizontal Services List - exactly like fragment 1
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    HorizontalList(
                      itemCount: categoryServices.length,
                      spacing: 16,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return ServiceComponent(
                          serviceData: categoryServices[index],
                          width: context.width() / 2 - 26,
                        );
                      },
                    ),
                    // Right scroll indicator - exactly like fragment 1
                    if (categoryServices.length > 2)
                      Positioned(
                        right: 0,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                context.scaffoldBackgroundColor,
                                context.scaffoldBackgroundColor
                                    .withOpacity(0.0),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
>>>>>>> Stashed changes
