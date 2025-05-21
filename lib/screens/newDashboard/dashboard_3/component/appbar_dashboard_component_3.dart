import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../model/service_data_model.dart';
import '../../../notification/notification_screen.dart';
import '../../../service/search_service_screen.dart';

class AppbarDashboardComponent3 extends StatefulWidget {
  final List<ServiceData> featuredList;
  final VoidCallback? callback;

  AppbarDashboardComponent3({required this.featuredList, this.callback});

  @override
  State<AppbarDashboardComponent3> createState() =>
      _AppbarDashboardComponent3State();
}

class _AppbarDashboardComponent3State extends State<AppbarDashboardComponent3> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (appStore.isLoggedIn)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CachedImageWidget(
                    url: appStore.userProfileImage.validate(),
                    height: 46,
                    width: 46,
                    fit: BoxFit.cover,
                  ),
                ),
              ).paddingRight(16),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      appStore.isLoggedIn
                          ? appStore.userFullName
                          : language.helloGuest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: boldTextStyle(color: Colors.white, size: 18),
                    ),
                  ),
                  if (!appStore.isLoggedIn)
                    Image.asset(ic_hi, height: 24, fit: BoxFit.cover),
                ],
              ),
            ),
            16.width,
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: appStore.unreadCount > 0 ? 12 : 10),
              decoration: boxDecorationDefault(
                color: Colors.white.withOpacity(0.15),
                borderRadius: radius(28),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ic_search.iconImage(size: 22, color: Colors.white).onTap(() {
                    SearchServiceScreen(featuredList: widget.featuredList)
                        .launch(context);
                  }),
                  if (appStore.isLoggedIn)
                    Container(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ic_notification
                              .iconImage(size: 22, color: Colors.white)
                              .center(),
                          if (appStore.unreadCount.validate() > 0)
                            Observer(builder: (context) {
                              return Positioned(
                                top: -2,
                                right: 2,
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: boxDecorationDefault(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                ),
                              );
                            })
                        ],
                      ),
                    ).paddingLeft(40).onTap(() {
                      NotificationScreen().launch(context);
                    })
                ],
              ),
            )
          ],
        ).paddingSymmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
