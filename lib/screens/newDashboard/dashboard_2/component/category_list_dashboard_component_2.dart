import 'package:booking_system_flutter/screens/newDashboard/dashboard_2/component/category_dashboard_component_2.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/view_all_label_component.dart';
import '../../../../main.dart';
import '../../../../model/category_model.dart';
import '../../../../utils/colors.dart';
import '../../../category/category_screen.dart';
import '../../../service/view_all_service_screen.dart';

class CategoryListDashboardComponent2 extends StatefulWidget {
  final List<CategoryData>? categoryList;

  CategoryListDashboardComponent2({this.categoryList});

  @override
  _CategoryListDashboardComponent2State createState() =>
      _CategoryListDashboardComponent2State();
}

class _CategoryListDashboardComponent2State
    extends State<CategoryListDashboardComponent2> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryList.validate().isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.category,
          list: widget.categoryList!,
          trailingTextStyle: boldTextStyle(color: primaryColor, size: 12),
          onTap: () {
            CategoryScreen().launch(context).then((value) {
              setStatusBarColor(Colors.transparent);
            });
          },
        ).paddingSymmetric(horizontal: 16),
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
            itemCount: widget.categoryList.validate().length,
            itemBuilder: (context, i) {
              CategoryData data = widget.categoryList![i];

              return GestureDetector(
                onTap: () {
                  setState(() => currentIndex = i);
                  ViewAllServiceScreen(
                          categoryId: data.id.validate(),
                          categoryName: data.name,
                          isFromCategory: true)
                      .launch(context);
                },
                child: Container(
                  height: 130, // Increased container height for larger images
                  child: CategoryDashboardComponent2(
                    categoryData: data,
                    isSelected: currentIndex == i,
                  ),
                ),
              );
            },
          ),
        ).paddingSymmetric(horizontal: 8),
      ],
    );
  }
}
