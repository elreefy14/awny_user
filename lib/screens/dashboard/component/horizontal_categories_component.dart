import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_widget.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class HorizontalCategoriesComponent extends StatelessWidget {
  final List<CategoryData> categoryList;

  HorizontalCategoriesComponent({required this.categoryList});

  @override
  Widget build(BuildContext context) {
    if (categoryList.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category section header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Text(
                  language.category,
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
              if (categoryList.length > 8)
                TextButton.icon(
                  onPressed: () {
                    CategoryScreen().launch(context);
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

        12.height,

        // Grid layout for categories - fixed item size approach
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.56, // Further adjusted for even larger icons
              crossAxisSpacing: 4, // Maintain small spacing
              mainAxisSpacing: 6, // Slightly increase vertical spacing
            ),
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  ViewAllServiceScreen(
                    categoryId: categoryList[index].id,
                    categoryName: categoryList[index].name,
                    isFromCategory: true,
                  ).launch(context);
                },
                child: Container(
                  height: 130, // Increased container height for larger images
                  child: CategoryWidget(
                    categoryData: categoryList[index],
                    width: context.width() / 4 - 6,
                    isFromCategory: true,
                  ),
                ),
              );
            },
          ),
        ),

        16.height,
      ],
    );
  }
}
