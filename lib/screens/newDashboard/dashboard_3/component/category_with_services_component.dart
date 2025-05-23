import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class CategoryWithServicesComponent extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryWithServicesComponent({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort categories by priority (ascending order - lower numbers first)
    List<CategoryData> sortedCategories = List.from(categories);
    sortedCategories.sort((a, b) {
      int priorityA = a.priority ?? 999;
      int priorityB = b.priority ?? 999;
      return priorityA.compareTo(priorityB);
    });

    // Filter categories that have services
    List<CategoryData> categoriesWithServices = sortedCategories
        .where((category) =>
            category.totalServices != null &&
            category.totalServices!.isNotEmpty)
        .toList();

    if (categoriesWithServices.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoriesWithServices.map((category) {
        return Container(
          margin: EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Category Image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: radius(8),
                        color: context.cardColor,
                      ),
                      child: CachedImageWidget(
                        url: category.categoryImage.validate(),
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                        radius: 8,
                      ),
                    ),
                    12.width,
                    // Category Name and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name.validate(),
                            style: boldTextStyle(size: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category.description != null)
                            Text(
                              category.description.validate(),
                              style: secondaryTextStyle(size: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // View All Button
                    TextButton(
                      onPressed: () {
                        // Navigate to category services screen
                        // You can implement this navigation based on your app structure
                      },
                      child: Text(
                        language.lblViewAll,
                        style: boldTextStyle(
                          color: primaryColor,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              16.height,
              // Services Horizontal List
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: category.totalServices!.length,
                  itemBuilder: (context, index) {
                    ServiceData service = category.totalServices![index];
                    return ServiceCard(service: service);
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceData service;

  const ServiceCard({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: radius(12),
        onTap: () {
          ServiceDetailScreen(serviceId: service.id.validate()).launch(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: CachedImageWidget(
                url: service.attachments.validate().isNotEmpty
                    ? service.attachments!.first
                    : '',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                radius: 12,
              ),
            ),
            // Service Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    Text(
                      service.name.validate(),
                      style: boldTextStyle(size: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.height,
                    // Provider Name
                    Text(
                      service.providerName.validate(),
                      style: secondaryTextStyle(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    // Price and Discount
                    Row(
                      children: [
                        Expanded(
                          child: PriceWidget(
                            price: service.price.validate(),
                            hourlyTextColor: Colors.white,
                            size: 14,
                          ),
                        ),
                        if (service.discount.validate() > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: radius(4),
                            ),
                            child: Text(
                              '${service.discount.validate().toInt()}% ${language.lblOff}',
                              style: boldTextStyle(
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
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
