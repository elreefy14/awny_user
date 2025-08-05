import 'dart:async';

import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/screens/notification/notification_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:geolocator/geolocator.dart';

import '../../../model/service_data_model.dart';
import '../../../utils/common.dart';
import '../../service/search_service_screen.dart';

class SliderLocationComponent extends StatefulWidget {
  final List<SliderModel> sliderList;
  final List<ServiceData>? featuredList;
  final VoidCallback? callback;

  SliderLocationComponent(
      {required this.sliderList, this.callback, this.featuredList});

  @override
  State<SliderLocationComponent> createState() =>
      _SliderLocationComponentState();
}

class _SliderLocationComponentState extends State<SliderLocationComponent> {
  PageController sliderPageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;
  bool isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        widget.sliderList.length >= 2) {
      _timer = Timer.periodic(Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND),
          (Timer timer) {
        if (_currentPage < widget.sliderList.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        sliderPageController.animateToPage(_currentPage,
            duration: Duration(milliseconds: 950), curve: Curves.easeOutQuart);
      });

      sliderPageController.addListener(() {
        _currentPage = sliderPageController.page!.toInt();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    sliderPageController.dispose();
  }

  Widget getSliderWidget() {
    return Container(
      height: context.height() * 0.35, // Reduced from 0.4 to 0.35
      width: context.width(),
      margin: EdgeInsets.zero, // إزالة جميع الهوامش
      child: Stack(
        children: [
          widget.sliderList.isNotEmpty
              ? PageView(
                  controller: sliderPageController,
                  children: List.generate(
                    widget.sliderList.length,
                    (index) {
                      SliderModel data = widget.sliderList[index];
                      return Container(
                        height:
                            context.height() * 0.35, // Reduced from 0.4 to 0.35
                        width: context.width(),
                        margin: EdgeInsets.zero, // إزالة الهوامش
                        decoration: BoxDecoration(
                          color: context.cardColor,
                        ),
                        child: Stack(
                          children: [
                            CachedImageWidget(
                              url: data.sliderImage.validate(),
                              height: context.height() *
                                  0.35, // Reduced from 0.4 to 0.35
                              width: context.width(),
                              fit: BoxFit
                                  .cover, // استخدام BoxFit.cover لضمان ظهور الصورة كاملة
                            ),
                            // إضافة تأثير التدرج اللوني
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ).onTap(() {
                          if (data.type == SERVICE) {
                            ServiceDetailScreen(
                                    serviceId: data.typeId.validate().toInt())
                                .launch(context,
                                    pageRouteAnimation:
                                        PageRouteAnimation.Fade);
                          }
                        }),
                      );
                    },
                  ),
                )
              : CachedImageWidget(
                  url: '',
                  height: context.height() * 0.35, // Reduced from 0.4 to 0.35
                  width: context.width(),
                  fit: BoxFit.cover),
          if (widget.sliderList.length.validate() > 1)
            Positioned(
              bottom: 28, // Reduced from 34 to 28
              left: 0,
              right: 0,
              child: DotIndicator(
                pageController: sliderPageController,
                pages: widget.sliderList,
                indicatorColor: white,
                unselectedIndicatorColor: white,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(2),
                currentBorderRadius: radius(3),
                currentDotSize: 16, // Reduced from 18 to 16
                currentDotWidth: 5, // Reduced from 6 to 5
                dotSize: 5, // Reduced from 6 to 5
              ),
            ),
          if (appStore.isLoggedIn)
            Positioned(
              top: context.statusBarHeight + 12, // Reduced from 16 to 12
              right: 12, // Reduced from 16 to 12
              child: Container(
                decoration: boxDecorationDefault(
                    color: context.cardColor, shape: BoxShape.circle),
                height: 32, // Reduced from 36 to 32
                padding: EdgeInsets.all(6), // Reduced from 8 to 6
                width: 32, // Reduced from 36 to 32
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ic_notification
                        .iconImage(size: 20, color: primaryColor) // Reduced from 24 to 20
                        .center(),
                    Observer(builder: (context) {
                      return Positioned(
                        top: -18, // Reduced from -20 to -18
                        right: -8, // Reduced from -10 to -8
                        child: appStore.unreadCount.validate() > 0
                            ? Container(
                                padding: EdgeInsets.all(3), // Reduced from 4 to 3
                                child: FittedBox(
                                  child: Text(appStore.unreadCount.toString(),
                                      style: primaryTextStyle(
                                          size: 10, color: Colors.white)), // Reduced from 12 to 10
                                ),
                                decoration: boxDecorationDefault(
                                    color: Colors.red, shape: BoxShape.circle),
                              )
                            : Offstage(),
                      );
                    })
                  ],
                ),
              ).onTap(() {
                NotificationScreen().launch(context);
              }),
            )
        ],
      ),
    );
  }

  Decoration get commonDecoration {
    return boxDecorationDefault(
      color: context.cardColor,
      boxShadow: [
        BoxShadow(color: shadowColorGlobal, offset: Offset(1, 0)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(0, 1)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(-1, 0)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        getSliderWidget(),
        Positioned(
          bottom: -20, // Reduced from -24 to -20
          right: 12, // Reduced from 16 to 12
          left: 12, // Reduced from 16 to 12
          child: Row(
            children: [
              Observer(
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.all(12), // Reduced from 16 to 12
                    decoration: commonDecoration,
                    width: context.width() - 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ic_location.iconImage(
                            color: appStore.isDarkMode
                                ? Colors.white
                                : Colors.black),
                        6.width, // Reduced from 8 to 6
                        Text(
                          appStore.isCurrentLocation
                              ? getStringAsync(CURRENT_ADDRESS)
                              : language.lblLocationOff,
                          style: secondaryTextStyle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).expand(),
                        6.width, // Reduced from 8 to 6
                        ic_active_location.iconImage(
                            size: 20, // Reduced from 24 to 20
                            color: appStore.isCurrentLocation
                                ? primaryColor
                                : grey),
                      ],
                    ),
                  ).expand();
                },
              ),
              12.width, // Reduced from 16 to 12
              GestureDetector(
                onTap: () {
                  SearchServiceScreen(featuredList: widget.featuredList)
                      .launch(context);
                },
                child: Container(
                  padding: EdgeInsets.all(12), // Reduced from 16 to 12
                  decoration: commonDecoration,
                  child: ic_search.iconImage(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
