import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/horizontal_categories_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/modern_category_services_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/slider_and_location_component.dart';
import 'package:booking_system_flutter/screens/dashboard/shimmer/dashboard_shimmer.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../component/booking_confirmed_component.dart';
import '../component/new_job_request_component.dart';

class DashboardFragment extends StatefulWidget {
  @override
  _DashboardFragmentState createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment> {
  Future<DashboardResponse>? future;

  @override
  void initState() {
    super.initState();
    init();

    setStatusBarColor(transparentColor, delayInMilliSeconds: 800);

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
        long: getDoubleAsync(LONGITUDE));
  }

  // Method to order categories by priority and add all services at the end
  List<CategoryData> _getOrderedCategories(List<CategoryData> categories) {
    List<CategoryData> orderedCategories = List.from(categories);

    // Sort categories by priority (lower number = higher priority)
    orderedCategories.sort((a, b) {
      int priorityA = a.priority ?? 999;
      int priorityB = b.priority ?? 999;
      return priorityA.compareTo(priorityB);
    });

    // Create a special "All Services" category at the end
    CategoryData allServicesCategory = CategoryData(
      id: -1, // Special ID for all services
      name: language.allServices,
      description: "جميع الخدمات المتاحة",
      categoryImage: null,
      priority: 999, // Lowest priority to appear at the end
      totalServices: [], // Will be populated with all services
    );

    // Add all services to the "All Services" category
    List<ServiceData> allServices = [];
    categories.forEach((category) {
      if (category.totalServices != null &&
          category.totalServices!.isNotEmpty) {
        allServices.addAll(category.totalServices!);
      }
    });
    allServicesCategory.totalServices = allServices;

    // Add the "All Services" category at the end
    orderedCategories.add(allServicesCategory);

    return orderedCategories;
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
      resizeToAvoidBottomInset: false, // منع إعادة الحجم عند ظهور لوحة المفاتيح
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
            loadingWidget: DashboardShimmer(),
            onSuccess: (snap) {
              // Split the sliders into two groups if there are enough of them
              List<SliderModel> topSliders = [];
              List<SliderModel> bottomSliders = [];

              if (snap.slider != null && snap.slider!.isNotEmpty) {
                if (snap.slider!.length > 1) {
                  // If we have multiple sliders, split them between top and bottom
                  int midPoint = (snap.slider!.length / 2).ceil();
                  topSliders = snap.slider!.sublist(0, midPoint);
                  bottomSliders = snap.slider!.sublist(midPoint);
                } else {
                  // If we have only one slider, put it at the top
                  topSliders = snap.slider!;
                }
              }

              return Observer(builder: (context) {
                return AnimatedScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  padding: EdgeInsets.zero, // إزالة جميع الهوامش
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);

                    setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    // Top Banner Slider
                    SliderLocationComponent(
                      sliderList: topSliders,
                      featuredList: snap.featuredServices.validate(),
                      callback: () async {
                        appStore.setLoading(true);
                        init();
                        setState(() {});
                      },
                    ),
                    20.height, // Reduced from 30 to 20

                    // Horizontal Categories
                    HorizontalCategoriesComponent(
                        categoryList: snap.category.validate()),

                    12.height, // Reduced from 16 to 12

                    // Pending Booking Section
                    PendingBookingComponent(
                        upcomingConfirmedBooking: snap.upcomingData),

                    12.height, // Reduced from 16 to 12

                    // Categories with their services section
                    ModernCategoryServicesComponent(
                      categoryList:
                          _getOrderedCategories(snap.category.validate()),
                      serviceList: snap.service.validate(),
                    ),

                    16.height, // Reduced from 24 to 16

                    // Featured Services Section
                    if (snap.featuredServices.validate().isNotEmpty)
                      FeaturedServiceListComponent(
                          serviceList: snap.featuredServices.validate()),

                    16.height, // Reduced from 24 to 16

                    // Bottom Banner Slider
                    if (bottomSliders.isNotEmpty)
                      Container(
                        margin: EdgeInsets.zero, // إزالة جميع الهوامش
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6), // Reduced from 8 to 6
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
                            12.height, // Reduced from 16 to 12
                            Container(
                              height: context.height() *
                                  0.22, // Reduced from 0.25 to 0.22
                              margin: EdgeInsets.zero, // إزالة الهوامش
                              child: SliderWidget(
                                sliderList: bottomSliders,
                                autoPlay: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                    12.height, // Reduced from 16 to 12

                    // Job Request Section
                    if (appConfigurationStore.jobRequestStatus)
                      NewJobRequestComponent(),
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

// Custom Slider Widget to address the video display issues
class SliderWidget extends StatefulWidget {
  final List<SliderModel> sliderList;
  final bool autoPlay;

  SliderWidget({required this.sliderList, this.autoPlay = true});

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  PageController sliderPageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.sliderList.length > 1) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        if (_currentPage < widget.sliderList.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (sliderPageController.hasClients) {
          sliderPageController.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 950),
            curve: Curves.easeOutQuart,
          );
        }
      });

      sliderPageController.addListener(() {
        if (sliderPageController.page != null) {
          _currentPage = sliderPageController.page!.round();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    sliderPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero, // إزالة جميع الهوامش
      decoration: BoxDecoration(
        color: context.cardColor,
      ),
      child: Stack(
        children: [
          // Page View for Slides
          PageView.builder(
            controller: sliderPageController,
            itemCount: widget.sliderList.length,
            itemBuilder: (context, index) {
              SliderModel data = widget.sliderList[index];
              return GestureDetector(
                onTap: () {
                  if (data.type == SERVICE) {
                    ServiceDetailScreen(
                            serviceId: data.typeId.validate().toInt())
                        .launch(context,
                            pageRouteAnimation: PageRouteAnimation.Fade);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                  ),
                  child: Stack(
                    children: [
                      // Image with specific display settings
                      CachedImageWidget(
                        url: data.sliderImage.validate(),
                        fit: BoxFit
                            .cover, // استخدام BoxFit.cover لضمان ظهور الصورة كاملة
                        width: context.width(),
                        height: double.infinity,
                      ),
                      // إضافة تأثير التدرج اللوني
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      // Optional caption overlay
                      if (data.title.validate().isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 16), // Reduced from 8 to 6
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              data.title.validate(),
                              style: boldTextStyle(
                                  color: Colors.white,
                                  size: 14), // Reduced from default to 14
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Slide Indicators
          if (widget.sliderList.length > 1)
            Positioned(
              bottom: 6, // Reduced from 8 to 6
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.sliderList.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: 3), // Reduced from 4 to 3
                    height: 6, // Reduced from 8 to 6
                    width: _currentPage == index
                        ? 12
                        : 6, // Reduced from 16:8 to 12:6
                    decoration: BoxDecoration(
                      color:
                          _currentPage == index ? primaryColor : Colors.white,
                      borderRadius: radius(3), // Reduced from 4 to 3
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Compact Service Card Widget for Dashboard Fragment
class CompactServiceCard extends StatelessWidget {
  final ServiceData service;

  const CompactServiceCard({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get image URL
    String imageUrl = service.attachments.validate().isNotEmpty
        ? service.attachments!.first.validate()
        : '';

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        ServiceDetailScreen(
          serviceId: service.id.validate(),
        ).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
        });
      },
      child: Container(
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(8), // Reduced from default
          backgroundColor: context.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section
            Container(
              height: 85, // Reduced from 100 to 85
              width: double.infinity,
              child: Stack(
                children: [
                  // Service Image
                  Container(
                    height: 85, // Reduced from 100 to 85
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedImageWidget(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            height: 85, // Reduced from 100 to 85
                            width: double.infinity,
                            circle: false,
                          ).cornerRadiusWithClipRRectOnly(
                            topRight: 8, topLeft: 8)
                        : Container(
                            height: 85, // Reduced from 100 to 85
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 25, // Reduced from 30 to 25
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  // Price Tag
                  Positioned(
                    bottom: 3, // Reduced from 4 to 3
                    right: 3, // Reduced from 4 to 3
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1), // Reduced padding
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius:
                            BorderRadius.circular(10), // Reduced from 12 to 10
                      ),
                      child: Text(
                        '${service.price.validate()} ج.م',
                        style: boldTextStyle(
                          size: 9, // Reduced from 10 to 9
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4), // Reduced from 6 to 4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 10,
                            color: Colors.amber), // Reduced from 12 to 10
                        1.width, // Reduced from 2 to 1
                        Text(
                          service.totalRating.validate().toString(),
                          style: secondaryTextStyle(
                              size: 9), // Reduced from 10 to 9
                        ),
                      ],
                    ),
                    2.height, // Reduced from 4 to 2
                    // Service Name
                    Expanded(
                      child: Text(
                        service.name.validate().length > 20
                            ? service.name.validate().substring(0, 20) + '...'
                            : service.name.validate(),
                        style: boldTextStyle(size: 10), // Reduced from 11 to 10
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
