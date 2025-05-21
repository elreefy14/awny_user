import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../component/view_all_label_component.dart';
import '../../../../main.dart';
import '../../../../model/service_data_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/constant.dart';
import '../../../service/service_detail_screen.dart';
import '../../../service/view_all_service_screen.dart';

class AllServicesGridComponent extends StatelessWidget {
  final List<ServiceData> serviceList;
  final String title;
  final bool showViewAll;

  AllServicesGridComponent({
    required this.serviceList,
    this.title = 'All Services',
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    if (serviceList.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showViewAll)
          ViewAllLabel(
            label: title,
            list: serviceList,
            trailingTextStyle: boldTextStyle(color: primaryColor, size: 12),
            onTap: () {
              ViewAllServiceScreen().launch(context);
            },
          ).paddingSymmetric(horizontal: 16)
        else
          Text(
            title,
            style: boldTextStyle(size: 18),
          ).paddingSymmetric(horizontal: 16),
        16.height,
        Container(
          width: context.width(),
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: serviceList.length.clamp(0, 8), // Show up to 8 services
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              ServiceData service = serviceList[index];
              return ServiceGridItem(serviceData: service);
            },
          ),
        ),
        if (serviceList.length > 8)
          Container(
            width: context.width(),
            padding: EdgeInsets.symmetric(vertical: 12),
            margin: EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: primaryColor,
              borderRadius: radius(defaultRadius),
            ),
            child: Text(
              'View All ${serviceList.length} Services',
              style: boldTextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ).onTap(() {
            ViewAllServiceScreen().launch(context);
          })
      ],
    );
  }
}

class ServiceGridItem extends StatelessWidget {
  final ServiceData serviceData;

  ServiceGridItem({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ServiceDetailScreen(serviceId: serviceData.id.validate())
            .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
      },
      child: Container(
        width: context.width() / 2 - 24,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius(12),
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
            // Service Image with discount tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: radiusOnly(
                    topLeft: 12,
                    topRight: 12,
                  ),
                  child: CachedImageWidget(
                    url: serviceData.attachments.validate().isNotEmpty
                        ? serviceData.attachments!.first.validate()
                        : '',
                    fit: BoxFit.cover,
                    height: 120,
                    width: context.width() / 2 - 24,
                  ),
                ),

                // Discount tag
                if (serviceData.discount != 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: radius(30),
                      ),
                      child: Text(
                        '${serviceData.discount.validate()}% OFF',
                        style: boldTextStyle(color: Colors.white, size: 10),
                      ),
                    ),
                  ),
              ],
            ),

            // Service info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceData.name.validate(),
                    style: boldTextStyle(size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.height,
                  Text(
                    serviceData.categoryName.validate(),
                    style: secondaryTextStyle(size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  8.height,
                  Row(
                    children: [
                      PriceWidget(
                        price: serviceData.price.validate(),
                        isHourlyService:
                            serviceData.type.validate() == SERVICE_TYPE_HOURLY,
                        discount: serviceData.discount.validate(),
                        color: primaryColor,
                        size: 14,
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
