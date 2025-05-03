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

    // Check if widget is used in horizontal list (smaller) or regular size
    final bool isSmallSize = width != null && width! < 150;

    // Image dimensions - adjust based on usage context
    final double imageSize = isSmallSize
        ? (categoryData.categoryImage.validate().endsWith('.svg') ? 60 : 70)
        : (categoryData.categoryImage.validate().endsWith('.svg') ? 80 : 90);

    final double rectangleHeight =
        isSmallSize ? 50 : 65; // Smaller height for horizontal list
    final double rectangleWidth = isSmallSize
        ? (width! - 12) // Slightly narrower for horizontal list
        : (context.width() / 2 - 28); // Regular width for grid

    return SizedBox(
      width: width ?? context.width() / 2 - 24,
      child: Column(
        children: [
          // Stack to position image partially above the rectangle
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Orange rectangle positioned below
              Padding(
                padding: EdgeInsets.only(
                    top: imageSize * 0.3), // Push down to let image protrude
                child: Container(
                  width: rectangleWidth,
                  height: rectangleHeight,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: radius(14), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: orangeColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Image positioned to overlap the rectangle
              Positioned(
                top: 0,
                child: categoryData.categoryImage.validate().endsWith('.svg')
                    ? SvgPicture.network(
                        categoryData.categoryImage.validate(),
                        height: imageSize,
                        width: imageSize,
                        fit: BoxFit.contain,
                        color: Colors
                            .white, // Make SVG white for better visibility
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

          // Text below the orange rectangle with proper spacing
          Container(
            width: isSmallSize ? width! - 8 : (context.width() / 2 - 40),
            padding: EdgeInsets.only(top: isSmallSize ? 12 : 14),
            child: Text(
              '${categoryData.name.validate()}',
              style: boldTextStyle(size: isSmallSize ? 12 : 15),
              textAlign: TextAlign.center,
              maxLines:
                  1, // Only one line for horizontal list to avoid overflow
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
