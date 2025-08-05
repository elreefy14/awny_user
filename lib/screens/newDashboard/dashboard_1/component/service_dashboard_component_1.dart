import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../component/image_border_component.dart';
import '../../../../component/online_service_icon_widget.dart';
import '../../../../component/price_widget.dart';
import '../../../../main.dart';
import '../../../../model/service_data_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/common.dart';
import '../../../../utils/constant.dart';
import '../../../../utils/images.dart';
import '../../../booking/provider_info_screen.dart';
import '../../../service/service_detail_screen.dart';

class ServiceDashboardComponent1 extends StatefulWidget {
  final ServiceData serviceData;
  final double? width;
  final bool? isBorderEnabled;
  final VoidCallback? onUpdate;
  final bool isFavouriteService;
  final bool isFromDashboard;

  ServiceDashboardComponent1({
    required this.serviceData,
    this.width,
    this.isBorderEnabled,
    this.isFavouriteService = false,
    this.onUpdate,
    this.isFromDashboard = false,
  });

  @override
  _ServiceDashboardComponent1State createState() =>
      _ServiceDashboardComponent1State();
}

class _ServiceDashboardComponent1State
    extends State<ServiceDashboardComponent1> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for service image
    String imageUrl = widget.isFavouriteService
        ? widget.serviceData.serviceAttachments.validate().isNotEmpty
            ? widget.serviceData.serviceAttachments.validate().first.validate()
            : ''
        : widget.serviceData.attachments.validate().isNotEmpty
            ? widget.serviceData.attachments!.first.validate()
            : '';

    log('🖼️ ServiceDashboardComponent1 - Service: ${widget.serviceData.name}');
    log('🖼️ Image URL: $imageUrl');
    log('🖼️ Has attachments: ${widget.serviceData.attachments?.isNotEmpty ?? false}');

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        ServiceDetailScreen(
          serviceId: widget.isFavouriteService
              ? widget.serviceData.serviceId.validate().toInt()
              : widget.serviceData.id.validate(),
        ).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
        });
      },
      child: Container(
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(),
          backgroundColor: context.cardColor,
          border: widget.isBorderEnabled.validate(value: false)
              ? appStore.isDarkMode
                  ? Border.all(color: context.dividerColor)
                  : null
              : null,
        ),
        width: widget.width,
        constraints: BoxConstraints(
          maxHeight: 280, // Reduced maximum height
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            SizedBox(
              height: 140, // Further reduced from 160
              width: context.width(),
              child: Stack(
                children: [
                  // Service Image with improved error handling
                  Container(
                    height: 140, // Further reduced from 160
                    width: context.width(),
                    child: imageUrl.isNotEmpty
                        ? CachedImageWidget(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            height: 140, // Further reduced from 160
                            width: context.width(),
                            circle: false,
                          ).cornerRadiusWithClipRRectOnly(
                            topRight: defaultRadius.toInt(),
                            topLeft: defaultRadius.toInt())
                        : Container(
                            height: 140, // Further reduced from 160
                            width: context.width(),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(defaultRadius),
                                topRight: Radius.circular(defaultRadius),
                              ),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40, // Reduced from 50
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8, // Reduced from 12
                    left: 8, // Reduced from 12
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      constraints: BoxConstraints(
                          maxWidth: context.width() * 0.25), // Reduced from 0.3
                      decoration: boxDecorationWithShadow(
                        backgroundColor: context.cardColor.withOpacity(0.9),
                        borderRadius: radius(20), // Reduced from 24
                      ),
                      child: Text(
                        "${widget.serviceData.subCategoryName.validate().isNotEmpty ? widget.serviceData.subCategoryName.validate() : widget.serviceData.categoryName.validate()}"
                            .toUpperCase(),
                        style: boldTextStyle(
                            color: appStore.isDarkMode ? white : Colors.black,
                            size: 8), // Reduced from 10
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).paddingSymmetric(
                          horizontal: 6, vertical: 2), // Reduced padding
                    ),
                  ),
                  // Favorite button
                  if (widget.isFavouriteService)
                    Positioned(
                      top: 8, // Reduced from 12
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6), // Reduced from 8
                        margin: EdgeInsets.only(right: 6), // Reduced from 8
                        decoration: boxDecorationWithShadow(
                            boxShape: BoxShape.circle,
                            backgroundColor: context.cardColor),
                        child: widget.serviceData.isFavourite == 1
                            ? ic_fill_heart.iconImage(
                                color: favouriteColor,
                                size: 16) // Reduced from 18
                            : ic_heart.iconImage(
                                color: unFavouriteColor,
                                size: 16), // Reduced from 18
                      ).onTap(() async {
                        if (widget.serviceData.isFavourite == 0) {
                          widget.serviceData.isFavourite = 1;
                          setState(() {});

                          await removeToWishList(
                                  serviceId: widget.serviceData.serviceId
                                      .validate()
                                      .toInt())
                              .then((value) {
                            if (!value) {
                              widget.serviceData.isFavourite = 0;
                              setState(() {});
                            }
                          });
                        } else {
                          widget.serviceData.isFavourite = 0;
                          setState(() {});

                          await addToWishList(
                                  serviceId: widget.serviceData.serviceId
                                      .validate()
                                      .toInt())
                              .then((value) {
                            if (!value) {
                              widget.serviceData.isFavourite = 1;
                              setState(() {});
                            }
                          });
                        }
                        widget.onUpdate?.call();
                      }),
                    ),
                ],
              ),
            ),
            // Content section - more compact
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2), // Reduced padding
                          decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius:
                                  BorderRadius.circular(16)), // Reduced from 24
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 20, // Reduced from 24
                                padding: EdgeInsets.all(3), // Reduced from 4
                                decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.star,
                                    color: Colors.white,
                                    size: 12), // Reduced from 14
                              ),
                              4.width, // Reduced from 6
                              Text(
                                widget.serviceData.totalRating
                                    .validate()
                                    .toString(),
                                style: boldTextStyle(
                                    size: 10, // Reduced from 11
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        if (widget.serviceData.isOnlineService)
                          OnlineServiceIconWidget()
                              .paddingLeft(6), // Reduced from 8
                      ],
                    ),
                    6.height, // Reduced from 12
                    // Service name
                    Text(
                      widget.serviceData.name.validate().length > 30
                          ? widget.serviceData.name
                                  .validate()
                                  .substring(0, 30) +
                              '...'
                          : widget.serviceData.name.validate(),
                      style: boldTextStyle(size: 12), // Reduced from 14
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    6.height, // Reduced from 12
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.serviceData.discount != 0)
                          PriceWidget(
                            price: discountedAmount,
                            isHourlyService: widget.serviceData.isHourlyService,
                            color: primaryColor,
                            hourlyTextColor: primaryColor,
                            size: 12, // Reduced from 14
                            isFreeService: widget.serviceData.type.validate() ==
                                SERVICE_TYPE_FREE,
                          ),
                        if (widget.serviceData.discount != 0)
                          4.width, // Reduced from 6
                        PriceWidget(
                          price: widget.serviceData.price.validate(),
                          isLineThroughEnabled:
                              widget.serviceData.discount != 0 ? true : false,
                          isHourlyService: widget.serviceData.isHourlyService,
                          color: widget.serviceData.discount != 0
                              ? textSecondaryColorGlobal
                              : primaryColor,
                          hourlyTextColor: widget.serviceData.discount != 0
                              ? textSecondaryColorGlobal
                              : primaryColor,
                          size: widget.serviceData.discount != 0
                              ? 10
                              : 12, // Reduced sizes
                          isFreeService: widget.serviceData.type.validate() ==
                              SERVICE_TYPE_FREE,
                        ),
                      ],
                    ),
                    Spacer(), // Push provider info to bottom
                    // Provider info
                    Row(
                      children: [
                        ImageBorder(
                            src: widget.serviceData.providerImage.validate(),
                            height: 24), // Reduced from 28
                        4.width, // Reduced from 6
                        if (widget.serviceData.providerName
                            .validate()
                            .isNotEmpty)
                          Expanded(
                            child: Text(
                              widget.serviceData.providerName.validate(),
                              style: secondaryTextStyle(
                                  size: 10, // Reduced from 11
                                  color: appStore.isDarkMode
                                      ? Colors.white
                                      : appTextSecondaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                      ],
                    ).onTap(() async {
                      if (widget.serviceData.providerId !=
                          appStore.userId.validate()) {
                        await ProviderInfoScreen(
                                providerId:
                                    widget.serviceData.providerId.validate())
                            .launch(context);
                        setStatusBarColor(Colors.transparent);
                      }
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  num get finalDiscountAmount => widget.serviceData.discount != 0
      ? ((widget.serviceData.price.validate() / 100) *
              widget.serviceData.discount.validate())
          .toStringAsFixed(appConfigurationStore.priceDecimalPoint)
          .toDouble()
      : 0;

  num get discountedAmount =>
      widget.serviceData.price.validate() - finalDiscountAmount;
}
