import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../auth/sign_in_screen.dart';
import '../../jobRequest/my_post_request_list_screen.dart';

class NewJobRequestComponent extends StatelessWidget {
  const NewJobRequestComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12), // Reduced from 16 to 12
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.primaryColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultRadius),
            topRight: Radius.circular(defaultRadius)),
      ),
      width: context.width(),
      child: Column(
        children: [
          12.height, // Reduced from 16 to 12
          Text(language.jobRequestSubtitle,
              style: primaryTextStyle(color: white, size: 15),
              textAlign: TextAlign.center), // Reduced from 16 to 15
          16.height, // Reduced from 20 to 16
          AppButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add,
                    color: appStore.isDarkMode
                        ? Colors.white
                        : context.primaryColor),
                3.width, // Reduced from 4 to 3
                Text(language.newPostJobRequest,
                    style: boldTextStyle(
                        color: appStore.isDarkMode
                            ? Colors.white
                            : context.primaryColor)),
              ],
            ),
            textStyle: primaryTextStyle(
                color: appStore.isDarkMode
                    ? textPrimaryColorGlobal
                    : context.primaryColor),
            onTap: () async {
              if (appStore.isLoggedIn) {
                MyPostRequestListScreen().launch(context);
              } else {
                setStatusBarColor(Colors.white,
                    statusBarIconBrightness: Brightness.dark);
                bool? res =
                    await SignInScreen(isFromDashboard: true).launch(context);

                if (res ?? false) {
                  MyPostRequestListScreen().launch(context);
                }
              }
            },
          ),
          12.height, // Reduced from 16 to 12
        ],
      ),
    );
  }
}
