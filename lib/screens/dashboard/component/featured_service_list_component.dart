import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

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
            Stack(
              alignment: Alignment.centerRight,
              children: [
                HorizontalList(
                  itemCount: serviceList.length,
                  spacing: 16,
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) => ServiceComponent(
                      serviceData: serviceList[index],
                      width: 280,
                      isBorderEnabled: true),
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
