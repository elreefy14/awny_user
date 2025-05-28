import 'dart:async';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_services_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/job_request_dahboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/service_list_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/slider_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/shimmer/dashboard_shimmer_3.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
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

class _DashboardFragment3State extends State<DashboardFragment3>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  Future<DashboardResponse>? future;

  // Keys to access slider components for video control
  final GlobalKey<SliderDashboardComponent3State> _topSliderKey =
      GlobalKey<SliderDashboardComponent3State>();
  final GlobalKey<SliderDashboardComponent3State> _bottomSliderKey =
      GlobalKey<SliderDashboardComponent3State>();

  @override
  bool get wantKeepAlive => true; // Keep state alive for better performance

  @override
  void initState() {
    super.initState();
    init();

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is going to background or being closed
        _pauseAllVideos();
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        // Videos will auto-resume based on their current slide position
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        _pauseAllVideos();
        break;
    }
  }

  @override
  void deactivate() {
    // Called when the widget is removed from the tree temporarily
    _pauseAllVideos();
    super.deactivate();
  }

  /// Pause all videos in both top and bottom sliders
  void _pauseAllVideos() {
    try {
      // Pause videos in top slider
      _topSliderKey.currentState?.pauseAllVideos();

      // Pause videos in bottom slider
      _bottomSliderKey.currentState?.pauseAllVideos();

      print(
          'Dashboard Fragment 3: All videos paused due to navigation/lifecycle change');
    } catch (e) {
      print('Error pausing videos: $e');
    }
  }

  /// Resume videos that should be playing based on current slide
  void _resumeCurrentVideos() {
    try {
      // Resume current video in top slider
      _topSliderKey.currentState?.resumeCurrentVideo();

      // Resume current video in bottom slider
      _bottomSliderKey.currentState?.resumeCurrentVideo();

      print('Dashboard Fragment 3: Current videos resumed');
    } catch (e) {
      print('Error resuming videos: $e');
    }
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
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Pause all videos before disposing
    _pauseAllVideos();

    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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

                    // TOP BANNER - Featured Sliders with video control
                    if (topSliders.isNotEmpty)
                      SliderDashboardComponent3(
                        key: _topSliderKey,
                        sliderList: topSliders,
                      ),

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

                    // BOTTOM BANNER - Promotional Sliders with video control
                    if (bottomSliders.isNotEmpty)
                      SliderDashboardComponent3(
                        key: _bottomSliderKey,
                        sliderList: bottomSliders,
                      ),

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
        // Section Title with enhanced styling
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.15),
                primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: radius(25),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              12.width,
              Text(
                language.category + " & " + language.services,
                style: boldTextStyle(size: 18, color: primaryColor),
              ),
            ],
          ),
        ),
        24.height,

        // Categories with their services and modern dividers
        ...categories.asMap().entries.map((entry) {
          int index = entry.key;
          CategoryData category = entry.value;
          bool isLast = index == categories.length - 1;

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
              // Category Section with enhanced design
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: radius(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Category Header with enhanced styling
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.12),
                            primaryColor.withOpacity(0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: primaryColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Category Image with enhanced styling
                          if (category.categoryImage != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: radius(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: radius(12),
                                child: CachedImageWidget(
                                  url: category.categoryImage!,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          16.width,

                          // Category Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      category.name.validate(),
                                      style: boldTextStyle(size: 18),
                                    ).expand(),
                                  ],
                                ),
                                if (category.description != null) ...[
                                  6.height,
                                  Text(
                                    category.description!,
                                    style: secondaryTextStyle(size: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Services count with enhanced design
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: radius(25),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.design_services,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                6.width,
                                Text(
                                  '${categoryServices.length}',
                                  style: boldTextStyle(
                                      color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Horizontal Services List with padding
                    Container(
                      height: 200, // Further reduced from 220 to 200
                      padding: EdgeInsets.symmetric(
                          vertical: 8), // Further reduced padding
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categoryServices.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: (context.width() - 64) /
                                2, // Calculate width to fit 2 services with margins
                            margin: EdgeInsets.only(right: 12),
                            child: CompactServiceItemWidget(
                                serviceData: categoryServices[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Modern Professional Divider (only if not the last category)
              if (!isLast) ...[
                32.height,
                _buildModernDivider(context),
                32.height,
              ] else ...[
                24.height,
              ],
            ],
          );
        }).toList(),
      ],
    );
  }

  // Modern divider widget with professional design
  Widget _buildModernDivider(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Main divider line with gradient
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.6),
                  primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
          ),

          // Center decorative element
          Transform.translate(
            offset: Offset(0, -8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: radius(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  8.width,
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  8.width,
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact Service Item Widget for better space utilization
class CompactServiceItemWidget extends StatelessWidget {
  final ServiceData serviceData;

  CompactServiceItemWidget({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ServiceDetailScreen(serviceId: serviceData.id.validate())
            .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
      },
      child: Container(
        height: 184, // Fixed height to prevent overflow
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Service Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: radiusOnly(
                    topLeft: 12,
                    topRight: 12,
                  ),
                  child: Container(
                    height: 80, // Further reduced from 100 to 80
                    width: double.infinity,
                    child: CachedImageWidget(
                      url: serviceData.attachments.validate().isNotEmpty
                          ? serviceData.attachments!.first.validate()
                          : serviceData.attachmentsArray.validate().isNotEmpty
                              ? serviceData.attachmentsArray!.first.url
                                  .validate()
                              : '',
                      fit: BoxFit.cover,
                      height: 80,
                      width: double.infinity,
                    ),
                  ),
                ),

                // Compact discount badge
                if (serviceData.discount != 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: radius(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.25),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '${serviceData.discount.validate()}%',
                        style: boldTextStyle(color: Colors.white, size: 9),
                      ),
                    ),
                  ),

                // Featured badge (compact version)
                if (serviceData.isFeatured != null &&
                    serviceData.isFeatured == 1)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.9), primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: radius(10),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 8),
                          1.width,
                          Text(
                            'Featured',
                            style: boldTextStyle(color: Colors.white, size: 7),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Compact Service Details - Fixed height container
            Container(
              height: 104, // Fixed height for content area
              padding: EdgeInsets.all(8), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Service name - Fixed height
                  Container(
                    height: 32, // Fixed height for title
                    child: Text(
                      serviceData.name.validate(),
                      style:
                          boldTextStyle(size: 12), // Further reduced font size
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Price section - Compact layout
                  Container(
                    height: 36, // Fixed height for price section
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Current price
                        Text(
                          _formatPrice(serviceData),
                          style: boldTextStyle(color: primaryColor, size: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Original price if discounted
                        if (serviceData.discount.validate() != 0) ...[
                          2.height,
                          Text(
                            appConfigurationStore.currencySymbol +
                                serviceData.price.toString(),
                            style: secondaryTextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              size: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Provider info - Compact and fixed height
                  Container(
                    height: 20, // Fixed height for provider section
                    child: Row(
                      children: [
                        Container(
                          height: 16, // Further reduced size
                          width: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 2,
                                spreadRadius: 0,
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(
                                  serviceData.providerImage.validate()),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        4.width, // Reduced spacing
                        Expanded(
                          child: Text(
                            serviceData.providerName.validate(),
                            style: secondaryTextStyle(
                                size: 10), // Further reduced font size
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(ServiceData serviceData) {
    double finalPrice = serviceData.price.validate().toDouble();
    if (serviceData.discount.validate() != 0) {
      finalPrice =
          finalPrice - (finalPrice * serviceData.discount.validate()) / 100;
    }

    String priceText = appConfigurationStore.currencySymbol +
        finalPrice.toStringAsFixed(appConfigurationStore.priceDecimalPoint);

    if (serviceData.type.validate() == SERVICE_TYPE_HOURLY) {
      priceText += '/hr';
    }

    return priceText;
  }
}
