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

  Widget buildNewDesignComponent(BuildContext context) {
    // Vibrant orange color for background
    final orangeColor = Color(0xFFFF7F00);

    // Check if widget is used in grid
    final bool isGridItem =
        isFromCategory == true || (width != null && width! < 100);

    // Much larger image sizes for better visibility
    final double imageSize = isGridItem
        ? (categoryData.categoryImage.validate().endsWith('.svg') ? 75 : 78)
        : (categoryData.categoryImage.validate().endsWith('.svg') ? 130 : 140);

    // Smaller background rectangle
    final double rectangleHeight = isGridItem ? 44 : 80;
    final double rectangleWidth =
        isGridItem ? (width ?? 80) : (context.width() / 2 - 30);

    return Container(
      width: width,
      height: isGridItem ? 120 : null, // Increased height for grid items
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Stack to position image partially above the rectangle
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Orange rectangle positioned below with more of the image showing above it
              Padding(
                padding: EdgeInsets.only(
                    top: imageSize * (isGridItem ? 0.35 : 0.38)),
                child: Container(
                  width: rectangleWidth,
                  height: rectangleHeight,
                  margin: EdgeInsets.symmetric(horizontal: isGridItem ? 2 : 4),
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: radius(isGridItem ? 14 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: orangeColor.withOpacity(0.25),
                        blurRadius: isGridItem ? 6 : 12,
                        offset: Offset(0, 3),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Image positioned to overlap the rectangle more prominently
              Positioned(
                top: 0,
                child: categoryData.categoryImage.validate().endsWith('.svg')
                    ? SvgPicture.network(
                        categoryData.categoryImage.validate(),
                        height: imageSize,
                        width: imageSize,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        placeholderBuilder: (context) => PlaceHolderWidget(
                          height: imageSize,
                          width: imageSize,
                          color: transparentColor,
                        ),
                      )
                    : CachedImageWidget(
                        url: categoryData.categoryImage.validate(),
                        fit: BoxFit.contain,
                        width: imageSize,
                        height: imageSize,
                        radius: 0,
                        placeHolderImage: '',
                      ),
              ),
            ],
          ),

          // Text below the orange rectangle
          Container(
            width: isGridItem
                ? width ?? context.width() / 4 - 4
                : (context.width() / 2 - 40),
            padding: EdgeInsets.only(top: isGridItem ? 6 : 12),
            child: Text(
              '${categoryData.name.validate()}',
              style: boldTextStyle(size: isGridItem ? 12 : 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always return the new design component regardless of dashboardType
    return buildNewDesignComponent(context);
  }
}
