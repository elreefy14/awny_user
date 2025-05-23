import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AllServicesComponent extends StatelessWidget {
  final List<ServiceData> services;
  final String title;

  const AllServicesComponent({
    Key? key,
    required this.services,
    this.title = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: boldTextStyle(size: 18),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to view all services screen
                    // ViewAllServiceScreen().launch(context);
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

        // Services Grid
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: services.length > 6
                ? 6
                : services.length, // Show max 6 services
            itemBuilder: (context, index) {
              ServiceData service = services[index];
              return ServiceGridCard(service: service);
            },
          ),
        ),

        // Show more button if there are more than 6 services
        if (services.length > 6)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AppButton(
              text:
                  '${language.lblViewAll} (${services.length - 6}+ ${language.allServices})',
              textStyle: boldTextStyle(color: Colors.white),
              color: primaryColor,
              onTap: () {
                // Navigate to view all services screen
                // ViewAllServiceScreen().launch(context);
              },
            ),
          ),
      ],
    );
  }
}

class ServiceGridCard extends StatelessWidget {
  final ServiceData service;

  const ServiceGridCard({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  CachedImageWidget(
                    url: service.attachments.validate().isNotEmpty
                        ? service.attachments!.first
                        : '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    radius: 12,
                  ),
                  // Discount Badge
                  if (service.discount.validate() > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: radius(6),
                        ),
                        child: Text(
                          '${service.discount.validate().toInt()}% ${language.lblOff}',
                          style: boldTextStyle(
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  // Featured Badge
                  if (service.isFeatured.validate() == 1)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: radius(6),
                        ),
                        child: Text(
                          language.lblFeatured,
                          style: boldTextStyle(
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                ],
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
                    // Price and Rating
                    Row(
                      children: [
                        Expanded(
                          child: PriceWidget(
                            price: service.price.validate(),
                            hourlyTextColor: Colors.white,
                            size: 12,
                          ),
                        ),
                        if (service.totalRating.validate() > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              2.width,
                              Text(
                                service.totalRating
                                    .validate()
                                    .toStringAsFixed(1),
                                style: boldTextStyle(size: 12),
                              ),
                            ],
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
