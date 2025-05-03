import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';

class CategoryServiceListComponent extends StatefulWidget {
  final List<CategoryData> categoryList;
  final List<ServiceData> serviceList;

  CategoryServiceListComponent(
      {required this.categoryList, required this.serviceList});

  @override
  _CategoryServiceListComponentState createState() =>
      _CategoryServiceListComponentState();
}

class _CategoryServiceListComponentState
    extends State<CategoryServiceListComponent> {
  Map<int, List<ServiceData>> categoryServiceMap = {};

  @override
  void initState() {
    super.initState();

    // Group services by category
    groupServicesByCategory();
  }

  void groupServicesByCategory() {
    categoryServiceMap.clear();

    // First, add all categories to the map
    widget.categoryList.forEach((category) {
      categoryServiceMap[category.id!] = [];
    });

    // Then, add services to their categories
    widget.serviceList.forEach((service) {
      if (service.categoryId != null &&
          categoryServiceMap.containsKey(service.categoryId)) {
        categoryServiceMap[service.categoryId]!.add(service);
      }
    });

    log('CategoryServiceList: Total categories: ${widget.categoryList.length}');
    log('CategoryServiceList: Total services: ${widget.serviceList.length}');

    // Log categories and their service counts
    widget.categoryList.forEach((category) {
      int serviceCount = categoryServiceMap[category.id]?.length ?? 0;
      log('Category: ${category.name} (ID: ${category.id}) - Services: $serviceCount');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryList.isEmpty || widget.serviceList.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text(
          language.category,
          style: boldTextStyle(size: 22),
        ).paddingSymmetric(horizontal: 16),
        16.height,
        ...widget.categoryList
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
                            child: Text(
                              category.name.validate(),
                              style:
                                  boldTextStyle(size: 18, letterSpacing: 0.5),
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
                    12.height, // More space between header and content

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

                        // Right scroll indicator (subtle arrow)
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
                            ).onTap(() {
                              scrollController.animateTo(
                                scrollController.offset + 150,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }),
                          ),
                      ],
                    ),

                    16.height, // Increased space before divider
                    Divider(
                            height: 1,
                            thickness: 1,
                            color: context.dividerColor.withOpacity(0.3))
                        .paddingSymmetric(horizontal: 16),
                  ],
                ),
              );
            })
            .where((widget) => widget is! SizedBox)
            .toList(),
      ],
    );
  }
}
