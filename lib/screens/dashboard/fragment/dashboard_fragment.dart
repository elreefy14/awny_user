import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/horizontal_categories_component.dart';
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
                    30.height,

                    // Horizontal Categories
                    HorizontalCategoriesComponent(
                        categoryList: snap.category.validate()),

                    16.height,

                    // Pending Booking Section
                    PendingBookingComponent(
                        upcomingConfirmedBooking: snap.upcomingData),

                    16.height,

                    // All Services section
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
                            // Right scroll indicator (subtle arrow)
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

                    16.height,

                    // Categories with their services section
                    CategoryServiceListComponent(
                      categoryList: snap.category.validate(),
                      serviceList: snap.service.validate(),
                    ),

                    16.height,

                    // Featured Services Section
                    if (snap.featuredServices.validate().isNotEmpty)
                      FeaturedServiceListComponent(
                          serviceList: snap.featuredServices.validate()),

                    24.height,

                    // Bottom Banner Slider
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
                            Container(
                              height: 200, // Reduced height for bottom banner
                              child: SliderWidget(
                                sliderList: bottomSliders,
                                autoPlay: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                    16.height,

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
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: radius(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius(10),
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
                          fit: BoxFit.cover, // Cover for full screen
                          width: context.width(),
                          height: double.infinity,
                        ),
                        // Optional caption overlay
                        if (data.title.validate().isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
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
                                style: boldTextStyle(color: Colors.white),
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
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.sliderList.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 16 : 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index ? primaryColor : Colors.white,
                        borderRadius: radius(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
