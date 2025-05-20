import 'dart:async';
import 'dart:convert';

import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/appbar_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/all_services_grid_component.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/category_list_dashboard_component_3.dart';
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
import '../../../utils/app_configuration.dart';
import 'component/upcoming_booking_dashboard_component_3.dart';

class DashboardFragment3 extends StatefulWidget {
  @override
  _DashboardFragment3State createState() => _DashboardFragment3State();
}

class _DashboardFragment3State extends State<DashboardFragment3>
    with AutomaticKeepAliveClientMixin, RouteAware {
  Future<DashboardResponse>? future;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  // Add map to store services by category
  Map<int, List<ServiceData>> categoryServiceMap = {};
  bool isLoadingCategories = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  void init() async {
    // Get country code for debugging
    String countryCode =
        getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
    String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';

    print('\n==== DASHBOARD FRAGMENT 3 - INIT ====');
    print('Making API call with:');
    print('- Country code: $countryCode');
    print('- Country parameter: $country');
    print('- Current location: ${appStore.isCurrentLocation}');
    print('- Latitude: ${getDoubleAsync(LATITUDE)}');
    print('- Longitude: ${getDoubleAsync(LONGITUDE)}');

    future = userDashboard(
        isCurrentLocation: appStore.isCurrentLocation,
        lat: getDoubleAsync(LATITUDE),
        long: getDoubleAsync(LONGITUDE))
      ..then((value) {
        // Print received data for debugging
        print('\n==== DASHBOARD API RESPONSE SUMMARY ====');
        print('Categories received: ${value.category?.length ?? 0}');
        print('Services received: ${value.service?.length ?? 0}');
        print('Featured Services: ${value.featuredServices?.length ?? 0}');

        // DETAILED DEBUGGING: Print each category with ID
        print('\n==== CATEGORIES FROM API ====');
        value.category?.forEach((category) {
          print('Category: ${category.name} (ID: ${category.id})');
        });

        // DETAILED DEBUGGING: Print each service with its category ID
        print('\n==== SERVICES FROM API ====');
        value.service?.forEach((service) {
          print(
              'Service: ${service.name} (ID: ${service.id}, Category ID: ${service.categoryId})');
        });

        // DETAILED DEBUGGING: Check for service-category relationships
        print('\n==== SERVICE-CATEGORY MATCHING ====');
        categoryServiceMap.clear();

        // Group services by category
        value.category?.forEach((category) {
          categoryServiceMap[category.id!] = [];
        });

        value.service?.forEach((service) {
          int? catId = service.categoryId;
          if (catId != null && categoryServiceMap.containsKey(catId)) {
            categoryServiceMap[catId]!.add(service);
          } else if (catId != null) {
            print(
                'WARNING: Service ${service.name} (ID: ${service.id}) has category ID $catId not in categories list');

            // Try to find category by numeric ID if types don't match
            value.category?.forEach((category) {
              if (category.id.toString() == catId.toString()) {
                if (!categoryServiceMap.containsKey(category.id)) {
                  categoryServiceMap[category.id!] = [];
                }
                categoryServiceMap[category.id!]!.add(service);
                print(
                    'MATCHED by string comparison: ${service.name} to ${category.name}');
              }
            });
          } else {
            print(
                'WARNING: Service ${service.name} (ID: ${service.id}) has null categoryId');
          }
        });

        // Print service counts for each category
        value.category?.forEach((category) {
          int serviceCount = categoryServiceMap[category.id]?.length ?? 0;
          print(
              'Category ${category.name} (ID: ${category.id}) has $serviceCount services');

          // For categories with no services, check if the ID exists in any service
          if (serviceCount == 0) {
            print(
                '  Looking for any service with category ID ${category.id}...');
            bool foundAny = false;
            value.service?.forEach((service) {
              if (service.categoryId.toString() == category.id.toString()) {
                foundAny = true;
                print(
                    '  FOUND: Service ${service.name} (ID: ${service.id}) matches category ID ${category.id}');
              }
            });
            if (!foundAny) {
              print(
                  '  NO MATCHING SERVICES: Check why this category has no services');

              // Fetch services specifically for this category
              fetchServicesForCategory(category.id!);
            }
          }
        });

        // FINAL DEBUG: Print JSON representation of a few services for inspection
        if (value.service != null && value.service!.isNotEmpty) {
          print('\n==== SAMPLE SERVICE JSON ====');
          if (value.service!.length > 0) {
            try {
              // Convert service to map to see all fields
              var serviceMap = value.service![0].toJson();
              print(JsonEncoder.withIndent('  ').convert(serviceMap));
            } catch (e) {
              print('Error encoding service to JSON: $e');
            }
          }
        }

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

  // Add method to fetch services for a specific category
  Future<void> fetchServicesForCategory(int categoryId) async {
    if (mounted) {
      setState(() {
        isLoadingCategories = true;
      });
    }

    try {
      print('Fetching services specifically for category ID: $categoryId');

      // Country code for filtering
      String countryCode =
          getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
      String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';

      List<ServiceData> categoryServices = [];
      await searchServiceAPI(
          page: 1,
          list: categoryServices,
          categoryId: categoryId.toString(),
          latitude: appStore.isCurrentLocation
              ? getDoubleAsync(LATITUDE).toString()
              : "",
          longitude: appStore.isCurrentLocation
              ? getDoubleAsync(LONGITUDE).toString()
              : "",
          lastPageCallBack: (isLastPage) {
            print(
                'Fetched ${categoryServices.length} services for category $categoryId (isLastPage: $isLastPage)');
          });

      // Update the category service map with the fetched services
      if (categoryServices.isNotEmpty) {
        print(
            'SUCCESS: Found ${categoryServices.length} services for category $categoryId');
        categoryServices.forEach((service) {
          print('Service: ${service.name} (ID: ${service.id})');
        });

        if (categoryServiceMap.containsKey(categoryId)) {
          categoryServiceMap[categoryId]!.addAll(categoryServices);
        } else {
          categoryServiceMap[categoryId] = categoryServices;
        }

        if (mounted) setState(() {});
      } else {
        print('No services found for category $categoryId in direct fetch');
      }
    } catch (e) {
      print('Error fetching services for category $categoryId: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  // Called when route is pushed on top (user navigates away)
  @override
  void didPushNext() {
    // Notify banners to pause videos
    LiveStream().emit('PAUSE_ALL_VIDEOS');
    super.didPushNext();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

              // DEBUGGING - Print what we're passing to the CategoryServicesComponent
              print('\n==== DATA GOING TO CATEGORYSERVICESCOMPONENT ====');
              print('Categories count: ${snap.category?.length ?? 0}');
              print('Services count: ${snap.service?.length ?? 0}');

              // Combine all services for the all services section
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

                    // Enhanced Services by Category - using the new component
                    if (isLoadingCategories)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Services by Category - Enhanced Component with pre-populated data
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
                    AllServicesGridComponent(
                      serviceList: allServices,
                      title:
                          language.allServices.validate(value: 'All Services'),
                      showViewAll: allServices.length > 8,
                    ),

                    24.height, //height

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

  // Helper to combine services from API and those fetched directly
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

    // Add any services from our direct category fetches that aren't already included
    categoryServiceMap.forEach((categoryId, services) {
      services.forEach((service) {
        if (!allServices.any((s) => s.id == service.id)) {
          allServices.add(service);
        }
      });
    });

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

    print(
        'Combined ${allServices.length} services for display in All Services section');
    return allServices;
  }
}
