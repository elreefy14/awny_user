import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/view_all_label_component.dart';
import '../../../../model/category_model.dart';
import '../../../../utils/colors.dart';
import '../../../category/category_screen.dart';
import 'category_dashboard_component_3.dart';

class CategoryListDashboardComponent3 extends StatelessWidget {
  final List<CategoryData> categoryList;
  final String listTiTle;

  CategoryListDashboardComponent3(
      {required this.categoryList, this.listTiTle = ''});

  @override
  Widget build(BuildContext context) {
    if (categoryList.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        0.height, // Keep no spacing at top
        ViewAllLabel(
          label: listTiTle,
          list: categoryList,
          trailingTextStyle: boldTextStyle(color: primaryColor, size: 12),
          onTap: () {
            CategoryScreen().launch(context).then((value) {
              setStatusBarColor(Colors.transparent);
            });
          },
        ).paddingSymmetric(horizontal: 16),
        if (categoryList.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75, // Better ratio for compact layout
                crossAxisSpacing: 20,
                mainAxisSpacing: 0, // Very minimal vertical spacing
              ),
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 100, // Reasonable height for icons and text
                  child: CategoryDashboardComponent3(
                    categoryData: categoryList[index],
                    width: context.width() / 4 - 6,
                  ),
                );
              },
            ),
          ).paddingSymmetric(horizontal: 8),
      ],
    );
  }
}
