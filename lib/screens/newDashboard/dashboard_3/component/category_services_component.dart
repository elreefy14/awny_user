import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../component/view_all_label_component.dart';
import '../../../../main.dart';
import '../../../../model/category_model.dart';
import '../../../../model/service_data_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/constant.dart';
import '../../../category/category_screen.dart';
import '../../../service/service_detail_screen.dart';
import '../../../service/view_all_service_screen.dart';

class CategoryServicesComponent extends StatefulWidget {
  final List<CategoryData> categories;
  final List<ServiceData> services;

  CategoryServicesComponent({required this.categories, required this.services});

  @override
  _CategoryServicesComponentState createState() =>
      _CategoryServicesComponentState();
}

class _CategoryServicesComponentState extends State<CategoryServicesComponent> {
  @override
  Widget build(BuildContext context) {
    // DEBUG: Print all categories received from API
    print('\n==== ALL CATEGORIES FROM API (in component) ====');
    widget.categories.forEach((category) {
      print('Category: ${category.name} (ID: ${category.id})');
    });

    // DEBUG: Print all services to check category associations
    print('\n==== ALL SERVICES FROM API (in component) ====');
    widget.services.forEach((service) {
      print(
          'Service: ${service.name} (ID: ${service.id}, Category ID: ${service.categoryId})');
    });

    // IMPORTANT: Make a copy of categories to work with
    final List<CategoryData> allCategories = List.from(widget.categories);

    // DEBUG: Check country parameter being used
    String countryCode =
        getStringAsync(USER_COUNTRY_CODE_KEY, defaultValue: 'EG');
    String country = countryCode == 'EG' ? 'egypt' : 'saudi arabia';
    print('\n==== COUNTRY SETTINGS ====');
    print('Country Code: $countryCode');
    print('Country Parameter: $country');

    // IMPROVED: Enhanced category-service matching with better type handling and null checking
    Map<String, List<ServiceData>> categoryServicesMap = {};

    // First initialize the map with empty lists for all categories
    for (var category in allCategories) {
      if (category.id != null) {
        categoryServicesMap[category.id.toString()] = [];
      }
    }

    // Then populate the map with services with robust type checking
    for (var service in widget.services) {
      if (service.categoryId == null) {
        print(
            'WARNING: Service "${service.name}" (ID: ${service.id}) has null categoryId');
        continue;
      }

      String catId = service.categoryId.toString();

      // Check if this service should be included based on country filter
      bool shouldIncludeService = true;

      // If service has country restrictions, check if the current country is included
      if (service.country != null && service.country!.isNotEmpty) {
        shouldIncludeService = service.country!
            .any((c) => c.toString().toLowerCase() == country.toLowerCase());

        if (!shouldIncludeService) {
          print(
              'Service "${service.name}" filtered out due to country restrictions. Service countries: ${service.country}, User country: $country');
        }
      }

      if (shouldIncludeService && categoryServicesMap.containsKey(catId)) {
        categoryServicesMap[catId]!.add(service);
        print('Matched service "${service.name}" to category ID $catId');
      } else if (shouldIncludeService) {
        // If service has a valid category ID but it's not in our categories list
        print(
            'WARNING: Service "${service.name}" has category ID $catId which is not in available categories');

        // Try to find if there's a category with numeric ID matching
        var numericCatId = int.tryParse(catId);
        if (numericCatId != null) {
          var matchingCategory = allCategories.firstWhere(
              (category) => category.id.toString() == numericCatId.toString(),
              orElse: () => CategoryData());

          if (matchingCategory.id != null) {
            print(
                'RECOVERY: Found matching category by numeric ID: ${matchingCategory.name}');
            categoryServicesMap[matchingCategory.id.toString()]!.add(service);
          }
        }
      }
    }

    // Print the count of services for each category
    allCategories.forEach((category) {
      String catId = category.id.toString();
      List<ServiceData> matchingServices = categoryServicesMap[catId] ?? [];
      print(
          'Category: ${category.name} (ID: ${category.id}) - Service count: ${matchingServices.length}');

      // For debugging, show all services that match this category
      if (matchingServices.isNotEmpty) {
        print(
            '  Matching services: ${matchingServices.map((s) => "${s.name} (ID: ${s.id})").join(", ")}');
      } else {
        print('  No matching services found');
      }
    });

    // Sort categories with priority order
    allCategories.sort((a, b) {
      // Arabic names for air conditioning and refrigeration - expanded list
      final airConditioningNames = [
        'تكييف',
        'تكييفات',
        'مكيف',
        'مكيفات',
        'Air Conditioning',
        'AC',
        'air condition',
        'A/C',
        'air',
        'conditioning'
      ];
      final refrigerationNames = [
        'تبريد',
        'ثلاجات',
        'ثلاجة',
        'Refrigeration',
        'Cooling',
        'fridge',
        'refrigerator',
        'freezer'
      ];

      // Check if category a is air conditioning - more flexible matching
      bool aIsAC = airConditioningNames.any((name) {
        bool matches =
            a.name.validate().toLowerCase().contains(name.toLowerCase());
        if (matches) print('Category "${a.name}" matches AC keyword: $name');
        return matches;
      });

      // Check if category b is air conditioning
      bool bIsAC = airConditioningNames.any((name) {
        bool matches =
            b.name.validate().toLowerCase().contains(name.toLowerCase());
        if (matches) print('Category "${b.name}" matches AC keyword: $name');
        return matches;
      });

      // Check if category a is refrigeration
      bool aIsRefrigeration = refrigerationNames.any((name) {
        bool matches =
            a.name.validate().toLowerCase().contains(name.toLowerCase());
        if (matches)
          print('Category "${a.name}" matches refrigeration keyword: $name');
        return matches;
      });

      // Check if category b is refrigeration
      bool bIsRefrigeration = refrigerationNames.any((name) {
        bool matches =
            b.name.validate().toLowerCase().contains(name.toLowerCase());
        if (matches)
          print('Category "${b.name}" matches refrigeration keyword: $name');
        return matches;
      });

      // Sort logic:
      // 1. Air conditioning first
      // 2. Refrigeration second
      // 3. Everything else by name
      if (aIsAC) return -1; // a comes first
      if (bIsAC) return 1; // b comes first
      if (aIsRefrigeration) return -1; // a comes second
      if (bIsRefrigeration) return 1; // b comes second

      // Sort alphabetically by name for the rest
      return a.name.validate().compareTo(b.name.validate());
    });

    // Print categories to help debug
    print('\n==== SORTED CATEGORIES ====');
    allCategories.forEach((category) {
      String catId = category.id.toString();
      final count = categoryServicesMap[catId]?.length ?? 0;
      print(
          'Category: ${category.name} (ID: ${category.id}) - Services count: $count');
    });

    // Filter out categories with no services if needed
    // Uncomment this line if you want to hide empty categories
    // allCategories.removeWhere((category) => (categoryServicesMap[category.id.toString()] ?? []).isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Categories',
          style: boldTextStyle(size: 18),
        ).paddingSymmetric(horizontal: 16),
        8.height,
        ...allCategories.map((category) {
          // FIXED: Get services for this category using string-based key
          final categoryServices =
              categoryServicesMap[category.id.toString()] ?? [];

          // Print services for debugging
          print(
              'Rendering category ${category.name} with ${categoryServices.length} services');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              ViewAllLabel(
                label: category.name.validate(),
                list: categoryServices,
                trailingTextStyle: boldTextStyle(color: primaryColor, size: 12),
                onTap: () {
                  ViewAllServiceScreen(
                    categoryId: category.id,
                    categoryName: category.name,
                    isFromCategory: true,
                  ).launch(context);
                },
              ).paddingSymmetric(horizontal: 16),
              8.height,
              categoryServices.isEmpty
                  ? Text(
                      'Click "View All" to see services in this category',
                      style: secondaryTextStyle(),
                    ).paddingSymmetric(horizontal: 16)
                  : HorizontalList(
                      itemCount: categoryServices.length.clamp(0, 10),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      spacing: 12,
                      runSpacing: 16,
                      itemBuilder: (context, index) {
                        final service = categoryServices[index];
                        return ServiceItemWidget(serviceData: service);
                      },
                    ),
            ],
          );
        }).toList(),
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
          children: [
            // Service Image with improved display
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

                // Modern discount tag
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

                // Featured badge if applicable
                if (serviceData.isFeatured != null &&
                    serviceData.isFeatured == 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

            // Service Details with improved styling
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceData.name.validate(),
                    style: boldTextStyle(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  8.height,

                  // Price with discount if applicable
                  Row(
                    children: [
                      PriceWidget(
                        price: serviceData.price.validate(),
                        isHourlyService:
                            serviceData.type.validate() == SERVICE_TYPE_HOURLY,
                        discount: serviceData.discount.validate(),
                        color: primaryColor,
                        size: 16,
                      ),
                      8.width,
                      if (serviceData.discount.validate() != 0)
                        Text(
                          appConfigurationStore.currencySymbol +
                              serviceData.price.toString(),
                          style: secondaryTextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  12.height,

                  // Provider Info with improved styling
                  Row(
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
                              blurRadius: 5,
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
                      8.width,
                      Text(
                        serviceData.providerName.validate(),
                        style: secondaryTextStyle(size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).expand(),
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

class PriceWidget extends StatelessWidget {
  final num price;
  final bool isHourlyService;
  final num discount;
  final Color? color;
  final int? size;

  PriceWidget(
      {required this.price,
      required this.isHourlyService,
      this.discount = 0,
      this.color,
      this.size});

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
        ),
        if (isHourlyService)
          Text('/${language.lblHr}',
              style: secondaryTextStyle(
                  color: color ?? textSecondaryColorGlobal,
                  size: size != null ? size! - 2 : null)),
      ],
    );
  }
}
