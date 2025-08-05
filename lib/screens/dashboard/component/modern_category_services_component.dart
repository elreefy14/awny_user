import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
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

    // Use total_services from each category
    widget.categoryList.forEach((category) {
      List<ServiceData> services = [];

      // Check if category has total_services
      if (category.totalServices != null &&
          category.totalServices!.isNotEmpty) {
        services = category.totalServices!;
        log('✅ Category "${category.name}" (ID: ${category.id}) has ${services.length} services from total_services');

        // Debug: Check if services have images
        services.forEach((service) {
          if (service.attachments != null && service.attachments!.isNotEmpty) {
            log('  ✅ Service "${service.name}" has image: ${service.attachments!.first}');
          } else {
            log('  ❌ Service "${service.name}" has no images');
          }
        });
      }

      // Add services to map (even if empty)
      categoryServiceMap[category.id!] = services;
      log('📋 Added ${services.length} services for category "${category.name}" (Priority: ${category.priority})');
    });

    log('📊 ModernCategoryServices Summary:');
    log('  - Total categories: ${widget.categoryList.length}');
    log('  - Categories with services: ${categoryServiceMap.length}');
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
          // Display all categories with their services
          ...categoriesWithServices.map((category) {
            List<ServiceData> services = categoryServiceMap[category.id] ?? [];
            if (services.isEmpty) return SizedBox();

            return Container(
              margin: EdgeInsets.only(bottom: 16), // Reduced from 24 to 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header - More Compact
                  Container(
                    margin: EdgeInsets.only(bottom: 8), // Reduced from 12 to 8
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Category Icon
                              if (category.categoryImage != null)
                                Container(
                                  width: 24, // Reduced from 28 to 24
                                  height: 24, // Reduced from 28 to 24
                                  margin: EdgeInsets.only(
                                      right: 8), // Reduced from 10 to 8
                                  child: CachedImageWidget(
                                    url: category.categoryImage!,
                                    fit: BoxFit.cover,
                                    radius: 12, // Reduced from 14 to 12
                                    height: 24, // Reduced from 28 to 24
                                  ),
                                ),

                              // Category Name and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name.validate().length > 20
                                          ? category.name
                                                  .validate()
                                                  .substring(0, 20) +
                                              '...'
                                          : category.name.validate(),
                                      style: boldTextStyle(
                                          size: 14), // Reduced from 15 to 14
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (category.description != null &&
                                        category.description!.isNotEmpty)
                                      Text(
                                        category.description!.length > 40
                                            ? category.description!
                                                    .substring(0, 40) +
                                                '...'
                                            : category.description!,
                                        style: secondaryTextStyle(
                                            size: 9), // Reduced from 10 to 9
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1), // Reduced padding
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                8), // Reduced from 10 to 8
                          ),
                          child: Text(
                            '${services.length}',
                            style: secondaryTextStyle(
                              size: 9, // Reduced from 10 to 9
                              color: primaryColor,
                            ),
                          ),
                        ),

                        // View All Button
                        if (services.length > 3) ...[
                          6.width, // Reduced from 8 to 6
                          TextButton.icon(
                            onPressed: () {
                              ViewAllServiceScreen(
                                categoryId: category.id,
                                categoryName: category.name,
                                isFromCategory: true,
                              ).launch(context);
                            },
                            icon: Icon(Icons.arrow_forward,
                                size: 14,
                                color: primaryColor), // Reduced from 16
                            label: Text(
                              "View All",
                              style: boldTextStyle(
                                  color: primaryColor,
                                  size: 12), // Reduced from 14
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4), // Reduced padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    16), // Reduced from 20
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Services Horizontal List - Redesigned
                  Container(
                    height: 180, // Reduced from 200 to 180
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
                              ServiceData service = services[index];

                              // Debug log for this specific service
                              log('🔄 Building service card for: ${service.name}');
                              if (service.attachments != null &&
                                  service.attachments!.isNotEmpty) {
                                log('  📷 Service image URL: ${service.attachments!.first}');
                              } else {
                                log('  ❌ No image found for service: ${service.name}');
                              }

                              return Container(
                                width: 130, // Reduced from 140 to 130
                                margin: EdgeInsets.only(
                                    right: 10), // Reduced from 12 to 10
                                child: CompactServiceCard(
                                    service: service), // New compact card
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
                                    width: 28, // Reduced from 32
                                    height: 28, // Reduced from 32
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 6, // Reduced from 8
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14, // Reduced from 16
                                      color: Colors.white,
                                    ),
                                  ).onTap(() {
                                    scrollControllers[category.id]?.animateTo(
                                      scrollControllers[category.id]!.offset +
                                          180, // Reduced from 200
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

// New Compact Service Card Widget
class CompactServiceCard extends StatelessWidget {
  final ServiceData service;

  const CompactServiceCard({Key? key, required this.service}) : super(key: key);

  // Calculate price after discount
  num getPriceAfterDiscount() {
    num originalPrice = service.price.validate();
    num discountPercentage = service.discount.validate();

    if (discountPercentage > 0) {
      num discountAmount = (originalPrice * discountPercentage) / 100;
      return originalPrice - discountAmount;
    }

    return originalPrice;
  }

  // Check if service has discount
  bool get hasDiscount => service.discount.validate() > 0;

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
              height: 100, // Reduced height
              width: double.infinity,
              child: Stack(
                children: [
                  // Service Image
                  Container(
                    height: 100,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedImageWidget(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            height: 100,
                            width: double.infinity,
                            circle: false,
                          ).cornerRadiusWithClipRRectOnly(
                            topRight: 8, topLeft: 8)
                        : Container(
                            height: 100,
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
                              size: 30, // Reduced from 40
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  // Price Tag with Discount Support
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2), // Reduced padding
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show discounted price if available
                          if (hasDiscount) ...[
                            Text(
                              '${getPriceAfterDiscount().toStringAsFixed(0)} ج.م',
                              style: boldTextStyle(
                                size: 10, // Reduced from 12
                                color: Colors.white,
                              ),
                            ),
                            // Show original price with strikethrough
                            Text(
                              '${service.price.validate()} ج.م',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ] else ...[
                            // Show original price only
                            Text(
                              '${service.price.validate()} ج.م',
                              style: boldTextStyle(
                                size: 10, // Reduced from 12
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${service.discount.validate()}%',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                padding: EdgeInsets.all(6), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 12, color: Colors.amber), // Reduced from 14
                        2.width,
                        Text(
                          service.totalRating.validate().toString(),
                          style:
                              secondaryTextStyle(size: 10), // Reduced from 11
                        ),
                      ],
                    ),
                    4.height, // Reduced spacing
                    // Service Name
                    Expanded(
                      child: Text(
                        service.name.validate().length > 25
                            ? service.name.validate().substring(0, 25) + '...'
                            : service.name.validate(),
                        style: boldTextStyle(size: 11), // Reduced from 12
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
