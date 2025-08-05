import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';

import '../../../../component/cached_image_widget.dart';
import '../../../../component/empty_error_state_widget.dart';

class ModernCategoryServicesComponent extends StatefulWidget {
  final List<CategoryData> categoryList;
  final List<ServiceData> serviceList;

  ModernCategoryServicesComponent({
    required this.categoryList,
    required this.serviceList,
  });

  @override
  _ModernCategoryServicesComponentState createState() =>
      _ModernCategoryServicesComponentState();
}

class _ModernCategoryServicesComponentState
    extends State<ModernCategoryServicesComponent>
    with TickerProviderStateMixin {
  Map<int, List<ServiceData>> categoryServiceMap = {};
  Map<int, ScrollController> scrollControllers = {};
  Map<int, bool> showScrollIndicators = {};

  @override
  void initState() {
    super.initState();
    groupServicesByCategory();
    initializeScrollControllers();
  }

  void groupServicesByCategory() {
    categoryServiceMap.clear();

    // Use total_services from each category instead of searching in serviceList
    widget.categoryList.forEach((category) {
      List<ServiceData> services = [];

      // Check if category has total_services
      if (category.totalServices != null &&
          category.totalServices!.isNotEmpty) {
        services = category.totalServices!;
        log('Category "${category.name}" (ID: ${category.id}) has ${services.length} services from total_services');
      } else {
        // Fallback: search in serviceList for this category
        services = widget.serviceList
            .where((service) => service.categoryId == category.id)
            .toList();
        log('Category "${category.name}" (ID: ${category.id}) has ${services.length} services from serviceList fallback');
      }

      categoryServiceMap[category.id!] = services;
    });

    log('ModernCategoryServices: Total categories: ${widget.categoryList.length}');
    log('ModernCategoryServices: Total services: ${widget.serviceList.length}');
  }

  void initializeScrollControllers() {
    widget.categoryList.forEach((category) {
      scrollControllers[category.id!] = ScrollController();
      showScrollIndicators[category.id!] = false;
    });
  }

  @override
  void dispose() {
    scrollControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryList.isEmpty || widget.serviceList.isEmpty) {
      return SizedBox();
    }

    // Filter categories that have services
    List<CategoryData> categoriesWithServices = widget.categoryList
        .where(
            (category) => categoryServiceMap[category.id]?.isNotEmpty == true)
        .toList();

    if (categoriesWithServices.isEmpty) {
      return SizedBox();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Title
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                12.width,
                Text(
                  language.category,
                  style: boldTextStyle(size: 20, color: context.primaryColor),
                ),
              ],
            ),
          ),

          // Display all categories with their services
          ...categoriesWithServices.map((category) {
            List<ServiceData> services = categoryServiceMap[category.id] ?? [];
            if (services.isEmpty) return SizedBox();

            return Container(
              margin: EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Category Icon
                              if (category.categoryImage != null)
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: EdgeInsets.only(right: 12),
                                  child: CachedImageWidget(
                                    url: category.categoryImage!,
                                    fit: BoxFit.cover,
                                    radius: 16,
                                    height: 32,
                                  ),
                                ),

                              // Category Name and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name.validate(),
                                      style: boldTextStyle(size: 18),
                                    ),
                                    if (category.description != null &&
                                        category.description!.isNotEmpty)
                                      Text(
                                        category.description!,
                                        style: secondaryTextStyle(size: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Service Count Badge
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${services.length}',
                            style: secondaryTextStyle(
                              size: 12,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        // View All Button
                        if (services.length > 3) ...[
                          12.width,
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
                              "View All",
                              style:
                                  boldTextStyle(color: primaryColor, size: 14),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Services Horizontal List
                  Container(
                    height: 280,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollUpdateNotification) {
                          setState(() {
                            showScrollIndicators[category.id!] =
                                scrollNotification.metrics.pixels <
                                    scrollNotification.metrics.maxScrollExtent;
                          });
                        }
                        return true;
                      },
                      child: Stack(
                        children: [
                          // Services List
                          ListView.builder(
                            controller: scrollControllers[category.id],
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.only(
                                right: showScrollIndicators[category.id] == true
                                    ? 40
                                    : 0),
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 16),
                                child: ServiceComponent(
                                  serviceData: services[index],
                                  width: 200,
                                ),
                              );
                            },
                          ),

                          // Scroll Indicator
                          if (showScrollIndicators[category.id] == true)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
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
                                ),
                                child: Center(
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ).onTap(() {
                                    scrollControllers[category.id]?.animateTo(
                                      scrollControllers[category.id]!.offset +
                                          200,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
