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
        // Manual layout for categories to reduce vertical spacing
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: _buildCategoryRows(context),
          ),
        ),
        8.height, // Reduced from 16 to 8
      ],
    );
  }

  List<Widget> _buildCategoryRows(BuildContext context) {
    List<Widget> rows = [];
    int itemsPerRow = 4;

    for (int i = 0; i < categoryList.length; i += itemsPerRow) {
      List<CategoryData> rowItems =
          categoryList.skip(i).take(itemsPerRow).toList();

      rows.add(
        Row(
          children: rowItems.map((category) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal: 2, vertical: 2), // Minimal margins
                child: GestureDetector(
                  onTap: () {
                    ViewAllServiceScreen(
                      categoryId: category.id,
                      categoryName: category.name,
                      isFromCategory: true,
                    ).launch(context);
                  },
                  child: CategoryWidget(
                    categoryData: category,
                    width: (context.width() - 32) / 4, // Account for padding
                    isFromCategory: true,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

      // Add minimal spacing between rows (only if not the last row)
      if (i + itemsPerRow < categoryList.length) {
        rows.add(SizedBox(height: 4)); // Minimal spacing between rows
      }
    }

    return rows;
  }
}
