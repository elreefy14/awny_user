import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../utils/colors.dart';
import '../utils/constant.dart';

class AppScaffold extends StatelessWidget {
  final String? appBarTitle;
  final List<Widget>? actions;

  final Widget child;
  final Color? scaffoldBackgroundColor;
  final Widget? bottomNavigationBar;
  final bool showLoader;

  AppScaffold({
    this.appBarTitle,
    required this.child,
    this.actions,
    this.scaffoldBackgroundColor,
    this.bottomNavigationBar,
    this.showLoader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) => Scaffold(
        appBar: appBarTitle != null
            ? AppBar(
                title: Text(appBarTitle.validate(),
                    style: boldTextStyle(
                        color: Colors.white, size: APP_BAR_TEXT_SIZE)),
                elevation: 0.0,
                backgroundColor: appStore.isDarkMode
                    ? bottomNavBarDarkBgColor
                    : orangePrimaryColor,
                leading:
                    context.canPop ? BackWidget(iconColor: Colors.white) : null,
                actions: actions,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: appStore.isDarkMode
                      ? bottomNavBarDarkBgColor
                      : orangePrimaryColor,
                  statusBarIconBrightness: Brightness.light,
                ),
              )
            : null,
        backgroundColor: scaffoldBackgroundColor,
        body: Body(child: child, showLoader: showLoader),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
