import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../main.dart';
import '../../../service/view_all_service_screen.dart';

class CategoryDashboardComponent4 extends StatelessWidget {
  final CategoryData categoryData;
  final double? width;

  CategoryDashboardComponent4({required this.categoryData, this.width});

  @override
  Widget build(BuildContext context) {
    // Vibrant orange color for background
    final orangeColor = Color(0xFFFF7F00);

    // Always use grid item sizing now for consistency
    final bool isGridItem = true;

    // Much larger image sizes for better visibility
    final double imageSize = 75;
    // Smaller background rectangle
    final double rectangleHeight = 44;
    final double rectangleWidth = width ?? 80;

    return GestureDetector(
      onTap: () {
        ViewAllServiceScreen(
                categoryId: categoryData.id.validate(),
                categoryName: categoryData.name.validate(),
                isFromCategory: true)
            .launch(context);
      },
      child: Container(
        width: width,
        height: 120, // Increased height to accommodate larger image
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stack to position image partially above the rectangle
            Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Orange rectangle positioned below with more of the image showing above it
                Padding(
                  padding: EdgeInsets.only(top: imageSize * 0.35),
                  child: Container(
                    width: rectangleWidth,
                    height: rectangleHeight,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: orangeColor,
                      borderRadius: radius(14),
                      boxShadow: [
                        BoxShadow(
                          color: orangeColor.withOpacity(0.25),
                          blurRadius: 6,
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

            // Compact text for grid items
            Container(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '${categoryData.name.validate()}',
                style: boldTextStyle(size: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
