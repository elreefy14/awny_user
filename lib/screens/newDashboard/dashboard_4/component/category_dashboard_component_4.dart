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

    // Image dimensions
    final double imageSize =
        categoryData.categoryImage.validate().endsWith('.svg') ? 80 : 90;
    final double rectangleHeight = 65; // Smaller height for modern look
    final double rectangleWidth = context.width() / 2 - 28; // Slightly wider

    return GestureDetector(
      onTap: () {
        ViewAllServiceScreen(
                categoryId: categoryData.id.validate(),
                categoryName: categoryData.name.validate(),
                isFromCategory: true)
            .launch(context);
      },
      child: SizedBox(
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
                      top: imageSize *
                          0.3), // Push down more to let image protrude further
                  child: Container(
                    width: rectangleWidth,
                    height: rectangleHeight,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: orangeColor,
                      borderRadius: radius(14), // Slightly more rounded corners
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
              width: context.width() / 2 - 40,
              padding: EdgeInsets.only(top: 14), // Slightly increased spacing
              child: Text(
                '${categoryData.name.validate()}',
                style: boldTextStyle(size: 15),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
