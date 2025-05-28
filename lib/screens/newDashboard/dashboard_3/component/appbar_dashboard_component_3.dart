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
      decoration: BoxDecoration(
        color:
            appStore.isDarkMode ? bottomNavBarDarkBgColor : orangePrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: appStore.isDarkMode
                ? Colors.black.withOpacity(0.2)
                : orangePrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (appStore.isLoggedIn)
            CachedImageWidget(
              url: appStore.userProfileImage.validate(),
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            ).cornerRadiusWithClipRRect(100).paddingRight(16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
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
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.asset(ic_hi, height: 24, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          8.width,
          Container(
            constraints: BoxConstraints(
              maxWidth: context.width() * 0.25,
              minWidth: 80,
            ),
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: appStore.unreadCount > 0 ? 10 : 8),
            decoration: boxDecorationDefault(
              color: Colors.white.withOpacity(0.2),
              borderRadius: radius(28),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ic_search.iconImage(size: 22, color: Colors.white).onTap(() {
                  SearchServiceScreen(featuredList: widget.featuredList)
                      .launch(context);
                }),
                if (appStore.isLoggedIn) ...[
                  SizedBox(width: 16),
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
                                    color: Colors.red, shape: BoxShape.circle),
                              ),
                            );
                          })
                      ],
                    ),
                  ).onTap(() {
                    NotificationScreen().launch(context);
                  }),
                ],
              ],
            ),
          )
        ],
      ).paddingSymmetric(horizontal: 16, vertical: 24),
    );
  }
}
