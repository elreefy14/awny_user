import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/cached_image_widget.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../service/view_all_service_screen.dart';

class FeaturedServiceListComponent extends StatelessWidget {
  final List<ServiceData> serviceList;

  FeaturedServiceListComponent({required this.serviceList});

  @override
  Widget build(BuildContext context) {
    if (serviceList.isEmpty) return Offstage();

    // Create scroll controller for featured section
    final ScrollController scrollController = ScrollController();

    return Container(
      padding: EdgeInsets.only(bottom: 24),
      width: context.width(),
      decoration: BoxDecoration(
        color: appStore.isDarkMode
            ? context.cardColor
            : context.primaryColor.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.height,

          // Featured header with bold title and view all button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Text(
                    language.lblFeatured,
                    style: boldTextStyle(size: 18, letterSpacing: 0.5),
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
                TextButton.icon(
                  onPressed: () {
                    ViewAllServiceScreen(isFeatured: "1").launch(context);
                  },
                  icon:
                      Icon(Icons.arrow_forward, size: 16, color: primaryColor),
                  label: Text(
                    "View All",
                    style: boldTextStyle(color: primaryColor, size: 14),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: Size(10, 30),
                  ),
                ),
              ],
            ),
          ),

          16.height,

          if (serviceList.isNotEmpty)
            Container(
              height: 200, // Reduced height to match modern component
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: serviceList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140, // Reduced width to match modern component
                        margin: EdgeInsets.only(right: 12),
                        child: CompactServiceCard(
                          service: serviceList[index],
                        ),
                      );
                    },
                  ),

                  // Right scroll indicator (subtle arrow)
                  if (serviceList.length > 1)
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
                              appStore.isDarkMode
                                  ? context.cardColor
                                  : context.primaryColor.withOpacity(0.1),
                              appStore.isDarkMode
                                  ? context.cardColor.withOpacity(0.0)
                                  : context.primaryColor.withOpacity(0.0),
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
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: NoDataWidget(
                title: language.lblNoServicesFound,
                imageWidget: EmptyStateWidget(),
              ),
            ).center(),
        ],
      ),
    );
  }
}

// Compact Service Card Widget for Featured Services
class CompactServiceCard extends StatelessWidget {
  final ServiceData service;

  const CompactServiceCard({Key? key, required this.service}) : super(key: key);

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
                  // Price Tag
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
                      child: Text(
                        '${service.price.validate()} ج.م',
                        style: boldTextStyle(
                          size: 10, // Reduced from 12
                          color: Colors.white,
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
