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
        // Grid layout for categories - fixed item size approach
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.56, // Further adjusted for even larger icons
              crossAxisSpacing: 2, // Reduced spacing between columns
              mainAxisSpacing: 3, // Reduced spacing between rows
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
