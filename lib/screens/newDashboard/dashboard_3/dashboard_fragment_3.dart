import 'dart:async';

import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_services_component.dart';
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
import '../../../component/cached_image_widget.dart';
import '../../../main.dart';
import '../../../model/dashboard_model.dart';
import '../../../model/category_model.dart';
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
      setStatusBarColor(
          appStore.isDarkMode ? bottomNavBarDarkBgColor : orangePrimaryColor,
          delayInMilliSeconds: 800,
          statusBarIconBrightness: Brightness.light);
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

              // Sort categories by priority (lower priority first, null values last)
              List<CategoryData> sortedCategories = snap.category.validate()
                ..sort((a, b) {
                  int priorityA = a.priority ?? 0;
                  int priorityB = b.priority ?? 0;
                  return priorityA.compareTo(priorityB); // Ascending order
                });

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

                    16.height,

                    // TOP BANNER - Featured Sliders
                    if (topSliders.isNotEmpty)
                      SliderDashboardComponent3(sliderList: topSliders),

                    24.height,

                    // Upcoming Bookings Section
                    UpcomingBookingDashboardComponent3(
                        upcomingBookingData: snap.upcomingData),

                    16.height,

                    // Categories Grid (Optional - for quick category access)
                    if (sortedCategories.isNotEmpty)
                      CategoryListDashboardComponent3(
                        categoryList: sortedCategories
                            .take(8)
                            .toList(), // Show first 8 categories
                      ),

                    24.height,

                    // All Categories with their Services - Sorted by Priority
                    AllCategoriesWithServicesComponent(
                      categories: sortedCategories,
                      services: snap.service.validate(),
                    ),

                    24.height,

                    // All Services Section
                    ServiceListDashboardComponent3(
                      serviceList: snap.service.validate(),
                      serviceListTitle: language.allServices,
                      isFeatured: false,
                    ),

                    20.height,

                    // Featured Services Section
                    ServiceListDashboardComponent3(
                      serviceList: snap.featuredServices.validate(),
                      serviceListTitle: language.featuredServices,
                      isFeatured: true,
                    ),

                    20.height,

                    // BOTTOM BANNER - Promotional Sliders
                    if (bottomSliders.isNotEmpty)
                      SliderDashboardComponent3(sliderList: bottomSliders),

                    16.height,

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

// New component to show all categories with their services
class AllCategoriesWithServicesComponent extends StatelessWidget {
  final List<CategoryData> categories;
  final List<ServiceData> services;

  AllCategoriesWithServicesComponent({
    required this.categories,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            language.category + " & " + language.services,
            style: boldTextStyle(size: 18),
          ),
        ),
        16.height,

        // Categories with their services
        ...categories.map((category) {
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header with priority indicator
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: radius(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Category Image
                    if (category.categoryImage != null)
                      ClipRRect(
                        borderRadius: radius(8),
                        child: CachedImageWidget(
                          url: category.categoryImage!,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    12.width,

                    // Category Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.name.validate(),
                                style: boldTextStyle(size: 16),
                              ).expand(),

                              // Priority Badge
                              // if (category.priority != null &&
                              //     category.priority! > 0)
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //       horizontal: 8, vertical: 4),
                              //   decoration: BoxDecoration(
                              //     color: primaryColor,
                              //     borderRadius: radius(12),
                              //   ),
                              //   child: Text(
                              //     'Priority ${category.priority}',
                              //     style: boldTextStyle(
                              //         color: Colors.white, size: 10),
                              //   ),
                              // ),
                            ],
                          ),
                          if (category.description != null)
                            Text(
                              category.description!,
                              style: secondaryTextStyle(size: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Services count
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: radius(20),
                      ),
                      child: Text(
                        '${categoryServices.length} ${language.services}',
                        style: boldTextStyle(color: primaryColor, size: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Services List
              Container(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryServices.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(right: 12),
                      child: ServiceItemWidget(
                          serviceData: categoryServices[index]),
                    );
                  },
                ),
              ),

              24.height,
            ],
          );
        }).toList(),
      ],
    );
  }
}
