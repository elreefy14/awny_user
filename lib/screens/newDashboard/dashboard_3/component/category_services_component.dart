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
    // Filter categories that have services
    final categoriesWithServices = widget.categories.where((category) {
      return widget.services
          .any((service) => service.categoryId == category.id);
    }).toList();

    if (categoriesWithServices.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoriesWithServices.map((category) {
        // Get services for this category
        final categoryServices = widget.services
            .where((service) => service.categoryId == category.id)
            .toList();

        if (categoryServices.isEmpty) return SizedBox();

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
            HorizontalList(
              itemCount: categoryServices.length.clamp(0, 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
