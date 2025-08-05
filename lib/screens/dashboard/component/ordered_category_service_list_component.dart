import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';

class OrderedCategoryServiceListComponent extends StatefulWidget {
  final List<CategoryData> categoryList;
  final List<ServiceData> serviceList;

  OrderedCategoryServiceListComponent(
      {required this.categoryList, required this.serviceList});

  @override
  _OrderedCategoryServiceListComponentState createState() =>
      _OrderedCategoryServiceListComponentState();
}

class _OrderedCategoryServiceListComponentState
    extends State<OrderedCategoryServiceListComponent> {
  Map<int, List<ServiceData>> categoryServiceMap = {};
  List<CategoryData> orderedCategoryList = [];

  // Define the priority order for categories
  static const Map<String, int> categoryPriority = {
    'تكييف الهواء': 1, // Air Conditioning
    'التكييف': 1, // Air Conditioning (alternative name)
    'منتجات التبريد': 2, // Refrigeration Products
    'التبريد': 2, // Refrigeration (alternative name)
    'الغسالات': 3, // Washing Machines
    'منتجات الغاز': 4, // Gas Products
    'سخانات المياه': 5, // Water Heaters
    'سخانات': 5, // Water Heaters (alternative name)
    'مبردات الهواء': 6, // Air Coolers
    'محضرات الطعام': 7, // Food Processors (Microwave and Ovens)
    'ميكرويف وافران': 7, // Microwave and Ovens
    'شفاطات': 8, // Exhaust Fans
    'الشاشات': 9, // Screens/TVs
    'شاشات': 9, // Screens/TVs (alternative name)
  };

  @override
  void initState() {
    super.initState();
    groupServicesByCategory();
    orderCategoriesByPriority();
  }

  void groupServicesByCategory() {
    categoryServiceMap.clear();

    // First, add all categories to the map
    widget.categoryList.forEach((category) {
      categoryServiceMap[category.id!] = [];
    });

    // Then, add services to their categories using both categoryId and categoryName matching
    widget.serviceList.forEach((service) {
      bool serviceAdded = false;

      // Try to match by categoryId first
      if (service.categoryId != null &&
          categoryServiceMap.containsKey(service.categoryId)) {
        categoryServiceMap[service.categoryId]!.add(service);
        serviceAdded = true;
      }

      // If not added by ID, try to match by category name (case-insensitive)
      if (!serviceAdded && service.categoryName != null) {
        for (var category in widget.categoryList) {
          if (category.name?.toLowerCase() ==
              service.categoryName?.toLowerCase()) {
            categoryServiceMap[category.id!]!.add(service);
            serviceAdded = true;
            break;
          }
        }
      }

      // If still not added, try partial name matching
      if (!serviceAdded && service.categoryName != null) {
        for (var category in widget.categoryList) {
          if (category.name != null &&
              (category.name!.contains(service.categoryName!) ||
                  service.categoryName!.contains(category.name!))) {
            categoryServiceMap[category.id!]!.add(service);
            serviceAdded = true;
            break;
          }
        }
      }
    });
  }

  void orderCategoriesByPriority() {
    // Create a copy of the category list
    orderedCategoryList = List.from(widget.categoryList);

    // Sort categories based on priority
    orderedCategoryList.sort((a, b) {
      String nameA = a.name ?? '';
      String nameB = b.name ?? '';

      int priorityA = categoryPriority[nameA] ?? 999;
      int priorityB = categoryPriority[nameB] ?? 999;

      // If priorities are the same, sort alphabetically
      if (priorityA == priorityB) {
        return nameA.compareTo(nameB);
      }

      return priorityA.compareTo(priorityB);
    });

    log('Categories ordered by priority:');
    orderedCategoryList.forEach((category) {
      String categoryName = category.name ?? '';
      int priority = categoryPriority[categoryName] ?? 999;
      int serviceCount = categoryServiceMap[category.id]?.length ?? 0;
      log('Priority $priority: $categoryName ($serviceCount services)');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryList.isEmpty || widget.serviceList.isEmpty) {
      return SizedBox();
    }

    // Check if we have any categories with services
    bool hasCategoriesWithServices = false;
    for (var category in orderedCategoryList) {
      if ((categoryServiceMap[category.id]?.length ?? 0) > 0) {
        hasCategoriesWithServices = true;
        break;
      }
    }

    if (!hasCategoriesWithServices) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "لا توجد خدمات متاحة حالياً",
                style: secondaryTextStyle(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        ...orderedCategoryList
            .map((category) {
              // Get services for this category
              List<ServiceData> categoryServices =
                  categoryServiceMap[category.id] ?? [];

              // Skip categories with no services
              if (categoryServices.isEmpty) {
                return SizedBox();
              }

              // Create scroll controller for each category to detect scroll position
              final ScrollController scrollController = ScrollController();

              return Container(
                margin: EdgeInsets.only(bottom: 32), // Increased bottom margin
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header with bold title and view all button
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category.name ?? ''),
                                  color: primaryColor,
                                  size: 20,
                                ),
                                8.width,
                                Text(
                                  category.name.validate(),
                                  style: boldTextStyle(
                                      size: 18, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                          TextButton.icon(
                            onPressed: () {
                              ViewAllServiceScreen(
                                categoryId: category.id,
                                categoryName: category.name,
                                isFromCategory: true,
                              ).launch(context);
                            },
                            icon: Icon(Icons.arrow_forward,
                                size: 16, color: primaryColor),
                            label: Text(
                              "عرض الكل (${categoryServices.length})",
                              style:
                                  boldTextStyle(color: primaryColor, size: 14),
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

                    // Horizontal scrollable list with scroll indicators
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (scrollNotification) {
                            // This can be used to update scroll indicators if needed
                            return true;
                          },
                          child: HorizontalList(
                            itemCount: categoryServices.length,
                            spacing: 16,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            controller: scrollController,
                            itemBuilder: (context, index) {
                              return ServiceComponent(
                                serviceData: categoryServices[index],
                                width: context.width() / 2 - 26,
                              );
                            },
                          ),
                        ),

                        // Right scroll indicator (subtle arrow) - only if more than 2 services
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
            })
            .where((widget) => widget is! SizedBox)
            .toList(),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'تكييف الهواء':
      case 'التكييف':
        return Icons.ac_unit;
      case 'منتجات التبريد':
      case 'التبريد':
        return Icons.kitchen;
      case 'الغسالات':
        return Icons.local_laundry_service;
      case 'منتجات الغاز':
        return Icons.gas_meter;
      case 'سخانات المياه':
      case 'سخانات':
        return Icons.hot_tub;
      case 'مبردات الهواء':
        return Icons.air;
      case 'محضرات الطعام':
      case 'ميكرويف وافران':
        return Icons.microwave;
      case 'شفاطات':
        return Icons.propane_tank;
      case 'الشاشات':
      case 'شاشات':
        return Icons.tv;
      default:
        return Icons.build;
    }
  }
}
