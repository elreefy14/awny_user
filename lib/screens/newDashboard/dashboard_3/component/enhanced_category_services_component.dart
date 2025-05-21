import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../component/view_all_label_component.dart';
import '../../../../main.dart';
import '../../../../model/category_model.dart';
import '../../../../model/service_data_model.dart';
import '../../../../network/rest_apis.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/constant.dart';
import '../../../service/service_detail_screen.dart';
import '../../../service/view_all_service_screen.dart';

class EnhancedCategoryServicesComponent extends StatefulWidget {
  final List<CategoryData> categories;
  final List<ServiceData>?
      initialServices; // Initial services from dashboard API
  final bool
      fetchMissingServices; // Whether to fetch services for categories with no services

  EnhancedCategoryServicesComponent({
    required this.categories,
    this.initialServices,
    this.fetchMissingServices = true,
  });

  @override
  _EnhancedCategoryServicesComponentState createState() =>
      _EnhancedCategoryServicesComponentState();
}

class _EnhancedCategoryServicesComponentState
    extends State<EnhancedCategoryServicesComponent> {
  // Map to store services by category ID
  Map<String, List<ServiceData>> categoryServicesMap = {};

  // Track categories being loaded
  Map<int, bool> loadingCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialize the category-service map
    initCategoryServiceMap();
  }

  void initCategoryServiceMap() {
    // First, initialize map with empty lists for all categories
    for (var category in widget.categories) {
      if (category.id != null) {
        categoryServicesMap[category.id.toString()] = [];
      }
    }

    // Then, populate with initial services if available
    if (widget.initialServices != null) {
      String countryCode =
          getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
      String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';

      for (var service in widget.initialServices!) {
        if (service.categoryId == null) continue;

        // Apply country filter
        bool shouldIncludeService = true;
        if (service.country != null && service.country!.isNotEmpty) {
          shouldIncludeService = service.country!
              .any((c) => c.toString().toLowerCase() == country.toLowerCase());

          if (!shouldIncludeService) continue;
        }

        String catId = service.categoryId.toString();

        if (categoryServicesMap.containsKey(catId)) {
          categoryServicesMap[catId]!.add(service);
        } else {
          // Try to match by numeric comparison if keys don't match directly
          var matchingCategory = widget.categories.firstWhere(
            (category) =>
                category.id.toString() == service.categoryId.toString(),
            orElse: () => CategoryData(),
          );

          if (matchingCategory.id != null) {
            String matchingCatId = matchingCategory.id.toString();
            categoryServicesMap[matchingCatId]!.add(service);
          }
        }
      }
    }

    // Check for categories with no services and fetch them if needed
    if (widget.fetchMissingServices) {
      for (var category in widget.categories) {
        if (category.id != null) {
          String catId = category.id.toString();
          if (categoryServicesMap[catId]!.isEmpty) {
            fetchServicesForCategory(category.id!);
          }
        }
      }
    }
  }

  Future<void> fetchServicesForCategory(int categoryId) async {
    if (!mounted) return;

    // Mark this category as loading
    setState(() {
      loadingCategories[categoryId] = true;
    });

    try {
      print('Fetching services for category ID: $categoryId');

      // Get services for this category
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
              'Retrieved ${categoryServices.length} services for category $categoryId');
        },
      );

      if (categoryServices.isNotEmpty) {
        print(
            'SUCCESS: Found ${categoryServices.length} services for category $categoryId');

        // Apply country filter
        String countryCode =
            getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
        String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';

        List<ServiceData> filteredServices = categoryServices.where((service) {
          if (service.country == null || service.country!.isEmpty) return true;

          return service.country!
              .any((c) => c.toString().toLowerCase() == country.toLowerCase());
        }).toList();

        print(
            'After country filtering: ${filteredServices.length} services remaining');

        // Update the map with the new services
        if (mounted) {
          setState(() {
            categoryServicesMap[categoryId.toString()] = filteredServices;
          });
        }
      } else {
        print('No services found for category $categoryId');
      }
    } catch (e) {
      print('Error fetching services for category $categoryId: $e');
    } finally {
      if (mounted) {
        setState(() {
          loadingCategories[categoryId] = false;
        });
      }
    }
  }

  // Check if a category has services or is still loading
  bool shouldShowCategory(CategoryData category) {
    if (category.id == null) return false;

    final categoryId = category.id.toString();
    final isLoading = loadingCategories[category.id] ?? false;
    final hasServices = (categoryServicesMap[categoryId]?.isNotEmpty) ?? false;

    // Show if it has services or is still loading
    return hasServices || isLoading;
  }

  @override
  Widget build(BuildContext context) {
    // First, filter categories to only those with services or still loading
    final categoriesToDisplay =
        widget.categories.where(shouldShowCategory).toList();

    // If there are no categories with services, don't display anything
    if (categoriesToDisplay.isEmpty) {
      return SizedBox();
    }

    // Sort categories with the specified rules:
    // 1. "الشاشات" (Screens/TVs) always at the end
    // 2. Air Conditioning and Refrigeration at the top
    // 3. Everything else alphabetically
    categoriesToDisplay.sort((a, b) {
      // Check if either category is "الشاشات" (Screens/TVs)
      bool aIsScreens = a.name.validate().contains('الشاشات');
      bool bIsScreens = b.name.validate().contains('الشاشات');

      // If a is "الشاشات", it should come last
      if (aIsScreens) return 1;
      // If b is "الشاشات", it should come last
      if (bIsScreens) return -1;

      // For the rest, follow the previous priority logic
      final airConditioningNames = [
        'تكييف',
        'تكييفات',
        'مكيف',
        'Air Conditioning',
        'AC'
      ];
      final refrigerationNames = [
        'تبريد',
        'ثلاجات',
        'Refrigeration',
        'Cooling'
      ];

      bool aIsAC = airConditioningNames.any((name) =>
          a.name.validate().toLowerCase().contains(name.toLowerCase()));
      bool bIsAC = airConditioningNames.any((name) =>
          b.name.validate().toLowerCase().contains(name.toLowerCase()));

      bool aIsRefrig = refrigerationNames.any((name) =>
          a.name.validate().toLowerCase().contains(name.toLowerCase()));
      bool bIsRefrig = refrigerationNames.any((name) =>
          b.name.validate().toLowerCase().contains(name.toLowerCase()));

      if (aIsAC) return -1;
      if (bIsAC) return 1;
      if (aIsRefrig) return -1;
      if (bIsRefrig) return 1;

      return a.name.validate().compareTo(b.name.validate());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Available Categories',
          style: boldTextStyle(size: 18),
        ).paddingSymmetric(horizontal: 16),
        8.height,
        ...categoriesToDisplay
            .map((category) {
              // Get services for this category
              final categoryId = category.id.toString();
              final categoryServices = categoryServicesMap[categoryId] ?? [];
              final isLoading = loadingCategories[category.id] ?? false;

              // Skip categories with no services and not loading
              if (categoryServices.isEmpty && !isLoading) {
                return SizedBox(); // Will be filtered out later
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  16.height,
                  // Category header with View All
                  ViewAllLabel(
                    label: category.name.validate(),
                    list: categoryServices,
                    trailingTextStyle:
                        boldTextStyle(color: primaryColor, size: 12),
                    onTap: () {
                      // Navigate to category detail screen
                      ViewAllServiceScreen(
                        categoryId: category.id,
                        categoryName: category.name,
                        isFromCategory: true,
                      ).launch(context);
                    },
                  ).paddingSymmetric(horizontal: 16),
                  8.height,

                  // Show loading indicator if loading
                  if (isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  // Show horizontal list of services if there are any
                  else if (categoryServices.isNotEmpty)
                    Container(
                      height: 280, // Fixed height to prevent layout issues
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categoryServices.length.clamp(0, 10),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final service = categoryServices[index];
                          return ServiceItemWidget(serviceData: service)
                              .paddingRight(12);
                        },
                      ),
                    ),
                ],
              );
            })
            .where((widget) => widget is! SizedBox)
            .toList(), // Remove any empty widgets
        16.height,
      ],
    );
  }
}

class ServiceItemWidget extends StatelessWidget {
  final ServiceData serviceData;

  ServiceItemWidget({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ServiceDetailScreen(serviceId: serviceData.id.validate())
            .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Service Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: radiusOnly(
                    topLeft: 16,
                    topRight: 16,
                  ),
                  child: Container(
                    height: 140,
                    width: 180,
                    child: CachedImageWidget(
                      url: serviceData.attachments.validate().isNotEmpty
                          ? serviceData.attachments!.first.validate()
                          : '',
                      fit: BoxFit.cover,
                      height: 140,
                      width: 180,
                    ),
                  ),
                ),

                // Discount tag
                if (serviceData.discount != 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: radius(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_outlined,
                              color: Colors.white, size: 12),
                          4.width,
                          Text(
                            '${serviceData.discount.validate()}%',
                            style: boldTextStyle(color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Featured badge
                if (serviceData.isFeatured != null &&
                    serviceData.isFeatured == 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.8), primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            language.lblFeatured,
                            style: boldTextStyle(color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Service Details
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    serviceData.name.validate(),
                    style: boldTextStyle(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  8.height,

                  // Price with discount
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: PriceWidget(
                          price: serviceData.price.validate(),
                          isHourlyService: serviceData.type.validate() ==
                              SERVICE_TYPE_HOURLY,
                          discount: serviceData.discount.validate(),
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                      8.width,
                      if (serviceData.discount.validate() != 0)
                        Flexible(
                          child: Text(
                            appConfigurationStore.currencySymbol +
                                serviceData.price.toString(),
                            style: secondaryTextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              size: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  12.height,

                  // Provider info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CachedImageWidget(
                            url: serviceData.providerImage.validate(),
                            fit: BoxFit.cover,
                            height: 24,
                            width: 24,
                          ),
                        ),
                      ),
                      8.width,
                      Flexible(
                        child: Text(
                          serviceData.providerName.validate(),
                          style: secondaryTextStyle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Price widget for displaying the service price
class PriceWidget extends StatelessWidget {
  final num price;
  final bool isHourlyService;
  final num discount;
  final Color? color;
  final int? size;

  PriceWidget({
    required this.price,
    required this.isHourlyService,
    this.discount = 0,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          appConfigurationStore.currencySymbol +
              (discount != 0
                  ? (price - (price * discount) / 100)
                      .toStringAsFixed(appConfigurationStore.priceDecimalPoint)
                  : price.toStringAsFixed(
                      appConfigurationStore.priceDecimalPoint)),
          style:
              boldTextStyle(color: color ?? textPrimaryColorGlobal, size: size),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (isHourlyService) 4.width,
        if (isHourlyService)
          Text('/${language.lblHr}',
              style: secondaryTextStyle(
                  color: color ?? textSecondaryColorGlobal,
                  size: size != null ? size! - 2 : null),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
