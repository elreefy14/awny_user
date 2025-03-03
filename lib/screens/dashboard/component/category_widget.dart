import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../newDashboard/dashboard_3/component/category_dashboard_component_3.dart';
import '../../newDashboard/dashboard_4/component/category_dashboard_component_4.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryData categoryData;
  final double? width;
  final bool? isFromCategory;

  CategoryWidget({required this.categoryData, this.width, this.isFromCategory});

  Widget buildDefaultComponent(BuildContext context) {
    return SizedBox(
      width: width ?? context.width() / 4 - 20,
      child: Column(
        children: [
          Container(
            width: CATEGORY_ICON_SIZE + 16,
            height: CATEGORY_ICON_SIZE + 16,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  categoryData.color.validate(value: '000').toColor().withOpacity(0.1),
                ],
              ),
            ),
            child: categoryData.categoryImage.validate().endsWith('.svg')
                ? Container(
                    padding: EdgeInsets.all(12),
                    child: SvgPicture.network(
                      categoryData.categoryImage.validate(),
                      height: CATEGORY_ICON_SIZE - 10,
                      width: CATEGORY_ICON_SIZE - 10,
                      fit: BoxFit.contain,
                      color: appStore.isDarkMode ? Colors.white : categoryData.color.validate(value: '000').toColor(),
                      placeholderBuilder: (context) => PlaceHolderWidget(
                        height: CATEGORY_ICON_SIZE - 10,
                        width: CATEGORY_ICON_SIZE - 10,
                        color: transparentColor,
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(8),
                    child: CachedImageWidget(
                      url: categoryData.categoryImage.validate(),
                      fit: BoxFit.contain,
                      width: CATEGORY_ICON_SIZE,
                      height: CATEGORY_ICON_SIZE,
                      circle: true,
                      placeHolderImage: '',
                    ),
                  ),
          ),
          8.height,
          Container(
            width: (width ?? context.width() / 4 - 20),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0.5,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${categoryData.name.validate()}',
              style: primaryTextStyle(size: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget categoryComponent() {
      return Observer(builder: (context) {
        if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
          return buildDefaultComponent(context);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_2) {
          return buildDefaultComponent(context);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_3) {
          return CategoryDashboardComponent3(categoryData: categoryData);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_4) {
          return CategoryDashboardComponent4(categoryData: categoryData);
        } else {
          return buildDefaultComponent(context);
        }
      });
    }

    return categoryComponent();
  }
}
