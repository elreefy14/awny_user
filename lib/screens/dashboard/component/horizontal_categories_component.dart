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

    // Create scroll controller for categories
    final ScrollController scrollController = ScrollController();

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
              TextButton.icon(
                onPressed: () {
                  CategoryScreen().launch(context);
                },
                icon: Icon(Icons.arrow_forward, size: 16, color: primaryColor),
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

        16.height,

        // Horizontal categories list with scroll indicator
        Stack(
          alignment: Alignment.centerRight,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                return true;
              },
              child: HorizontalList(
                itemCount: categoryList.length,
                spacing: 16,
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      ViewAllServiceScreen(
                              categoryId: categoryList[index].id,
                              categoryName: categoryList[index].name,
                              isFromCategory: true)
                          .launch(context);
                    },
                    child: CategoryWidget(
                      categoryData: categoryList[index],
                      width: context.width() / 4 -
                          16, // Better size for horizontal list
                      isFromCategory: true,
                    ),
                  );
                },
              ),
            ),

            // Right scroll indicator (subtle arrow)
            if (categoryList.length > 3)
              Positioned(
                right: 0,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        context.scaffoldBackgroundColor,
                        context.scaffoldBackgroundColor.withOpacity(0.0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ).onTap(() {
                  scrollController.animateTo(
                    scrollController.offset + 150,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }),
              ),
          ],
        ),

        16.height,
      ],
    );
  }
}
