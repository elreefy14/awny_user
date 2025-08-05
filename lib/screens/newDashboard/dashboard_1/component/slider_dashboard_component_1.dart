import 'dart:async';

import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../main.dart';
import '../../../../model/dashboard_model.dart';
import '../../../../model/service_data_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/common.dart';
import '../../../../utils/configs.dart';
import '../../../../utils/constant.dart';
import '../../../../utils/images.dart';
import '../../../notification/notification_screen.dart';
import '../../../service/search_service_screen.dart';
import '../../../service/service_detail_screen.dart';

class SliderDashboardComponent1 extends StatefulWidget {
  final List<SliderModel> sliderList;
  final List<ServiceData>? featuredList;
  final VoidCallback? callback;

  SliderDashboardComponent1(
      {required this.sliderList, this.callback, this.featuredList});

  @override
  _SliderDashboardComponent1State createState() =>
      _SliderDashboardComponent1State();
}

class _SliderDashboardComponent1State extends State<SliderDashboardComponent1> {
  PageController sliderPageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();

    // Debug log for sliders
    debugPrint('========== SLIDER COMPONENT 1 DEBUG ==========');
    debugPrint('Total sliders received: ${widget.sliderList.length}');

    // Print all sliders and their directions
    widget.sliderList.forEach((slider) {
      debugPrint(
          'Slider ID: ${slider.id}, Direction: ${slider.direction ?? "null"}');
    });

    // Check top and bottom sliders
    List<SliderModel> topSliders = getSlidersByDirection('up');
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    debugPrint('Top sliders count: ${topSliders.length}');
    debugPrint('Bottom sliders count: ${bottomSliders.length}');

    if (topSliders.isEmpty && bottomSliders.isNotEmpty) {
      debugPrint(
          'WARNING: No top sliders found, but found ${bottomSliders.length} bottom sliders');
    }

    debugPrint('===========================================');

    // Initialize video controllers for any video sliders
    for (int i = 0; i < widget.sliderList.length; i++) {
      if (widget.sliderList[i].isVideo) {
        videoControllers[i] = VideoPlayerController.network(
            widget.sliderList[i].sliderImage.validate())
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
      }
    }

    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        widget.sliderList.length >= 2) {
      _timer = Timer.periodic(Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND),
          (Timer timer) {
        if (_currentPage < widget.sliderList.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        // Pause current video if any
        if (videoControllers.containsKey(_currentPage) &&
            videoControllers[_currentPage]!.value.isPlaying) {
          videoControllers[_currentPage]!.pause();
        }

        sliderPageController.animateToPage(_currentPage,
            duration: Duration(milliseconds: 950), curve: Curves.easeOutQuart);
      });

      sliderPageController.addListener(() {
        int newPage = sliderPageController.page!.toInt();
        if (_currentPage != newPage) {
          // Pause previous video if playing
          if (videoControllers.containsKey(_currentPage) &&
              videoControllers[_currentPage]!.value.isPlaying) {
            videoControllers[_currentPage]!.pause();
          }

          // Play new video if available
          if (videoControllers.containsKey(newPage) &&
              !videoControllers[newPage]!.value.isPlaying) {
            videoControllers[newPage]!.play();
          }

          _currentPage = newPage;
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    sliderPageController.dispose();

    // Dispose all video controllers
    videoControllers.forEach((key, controller) {
      controller.dispose();
    });
  }

  // Widget to render either image or video based on media_type
  Widget getMediaWidget(SliderModel data) {
    if (data.isVideo) {
      int index = widget.sliderList.indexOf(data);
      VideoPlayerController? controller = videoControllers[index];

      if (controller != null && controller.value.isInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: context.width(),
              height: 320, // Increased height for better display
              child: VideoPlayer(controller),
            ),
            if (!controller.value.isPlaying)
              IconButton(
                icon: Icon(Icons.play_circle_outline,
                    size: 50, color: Colors.white),
                onPressed: () {
                  controller.play();
                  setState(() {});
                },
              ),
          ],
        ).onTap(() {
          if (data.type == SERVICE) {
            ServiceDetailScreen(serviceId: data.typeId.validate().toInt())
                .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          }
        });
      } else {
        return Center(child: CircularProgressIndicator());
      }
    } else {
      // Regular image slider with proper aspect ratio and no cropping
      return Container(
        width: context.width(),
        height: 320, // Increased height for better display
        child: CachedImageWidget(
          url: data.sliderImage.validate(),
          height: 320,
          width: context.width(),
          fit: BoxFit.cover, // Changed back to cover for better appearance
        ),
      ).onTap(() {
        if (data.type == SERVICE) {
          ServiceDetailScreen(serviceId: data.typeId.validate().toInt())
              .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
        }
      });
    }
  }

  // Get sliders for a specific direction - returns sliders filtered by direction
  List<SliderModel> getSlidersByDirection(String direction) {
    return widget.sliderList
        .where((slider) =>
                (slider.direction ?? '').toLowerCase() ==
                    direction.toLowerCase() ||
                (direction == 'up' &&
                    (slider.direction ?? '')
                        .isEmpty) // Only include empty directions for "up"
            )
        .toList();
  }

  Widget getSliderWidget() {
    // Get sliders that should be displayed at the top (default position)
    List<SliderModel> topSliders = getSlidersByDirection('up');
    if (topSliders.isEmpty)
      topSliders =
          widget.sliderList; // If no direction specified, show all at top

    return Container(
      height: 320, // Fixed height to match media widget
      width: context.width(),
      child: Stack(
        children: [
          topSliders.isNotEmpty
              ? PageView(
                  controller: sliderPageController,
                  children: List.generate(
                    topSliders.length,
                    (index) {
                      SliderModel data = topSliders[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: radius(12),
                        ),
                        child: ClipRRect(
                          borderRadius: radius(12),
                          child: getMediaWidget(data),
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: radius(12),
                  ),
                  child: Center(
                    child: Text('No banners available',
                        style: secondaryTextStyle()),
                  ),
                ),
          if (topSliders.length > 1)
            Positioned(
              bottom: 16,
              left: 16,
              child: DotIndicator(
                pageController: sliderPageController,
                pages: topSliders,
                indicatorColor: primaryColor,
                unselectedIndicatorColor: white,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(16),
                currentBorderRadius: radius(16),
                currentDotSize: 70,
                currentDotWidth: 20,
                dotSize: 40,
              ).scale(scale: 0.4),
            ),
          if (appStore.isLoggedIn)
            Positioned(
              top: context.statusBarHeight + 16,
              right: 16,
              child: Container(
                decoration: boxDecorationDefault(
                    color: context.cardColor, shape: BoxShape.circle),
                height: 36,
                padding: EdgeInsets.all(8),
                width: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ic_notification
                        .iconImage(size: 24, color: primaryColor)
                        .center(),
                    Observer(builder: (context) {
                      return Positioned(
                        top: -20,
                        right: -10,
                        child: appStore.unreadCount.validate() > 0
                            ? Container(
                                padding: EdgeInsets.all(4),
                                child: FittedBox(
                                  child: Text(appStore.unreadCount.toString(),
                                      style: primaryTextStyle(
                                          size: 12, color: Colors.white)),
                                ),
                                decoration: boxDecorationDefault(
                                    color: Colors.red, shape: BoxShape.circle),
                              )
                            : Offstage(),
                      );
                    })
                  ],
                ),
              ).onTap(() {
                NotificationScreen().launch(context);
              }),
            )
        ],
      ),
    );
  }

  // Get bottom sliders widget if there are any with direction=down
  Widget? getBottomSlidersWidget() {
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    if (bottomSliders.isEmpty) return null;

    PageController bottomSliderController = PageController(initialPage: 0);

    return Container(
      height: 200, // Consistent height for bottom sliders
      width: context.width(),
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius(12),
            child: PageView(
              controller: bottomSliderController,
              children: List.generate(
                bottomSliders.length,
                (index) {
                  SliderModel data = bottomSliders[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: radius(12),
                    ),
                    child: CachedImageWidget(
                      url: data.sliderImage.validate(),
                      height: 200,
                      width: context.width(),
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
          ),
          if (bottomSliders.length > 1)
            Positioned(
              bottom: 16,
              left: 16,
              child: DotIndicator(
                pageController: bottomSliderController,
                pages: bottomSliders,
                indicatorColor: primaryColor,
                unselectedIndicatorColor: white,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(16),
                currentBorderRadius: radius(16),
                currentDotSize: 70,
                currentDotWidth: 20,
                dotSize: 40,
              ).scale(scale: 0.4),
            ),
        ],
      ),
    );
  }

  Decoration get commonDecoration {
    return boxDecorationDefault(
      color: context.cardColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom sliders widget if any
    Widget? bottomSlidersWidget = getBottomSlidersWidget();

    return Column(
      children: [
        getSliderWidget(),
        Row(
          children: [
            Observer(
              builder: (context) {
                return AppButton(
                  padding: EdgeInsets.all(0),
                  width: context.width(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: commonDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ic_location.iconImage(
                            color: appStore.isDarkMode
                                ? Colors.white
                                : Colors.black),
                        8.width,
                        Text(
                          appStore.isCurrentLocation
                              ? getStringAsync(CURRENT_ADDRESS)
                              : language.lblLocationOff,
                          style: secondaryTextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).expand(),
                        8.width,
                        ic_active_location.iconImage(
                            size: 24,
                            color: appStore.isCurrentLocation
                                ? primaryColor
                                : grey),
                      ],
                    ),
                  ),
                  onTap: () async {
                    locationWiseService(context, () {
                      widget.callback?.call();
                    });
                  },
                );
              },
            ).expand(),
            16.width,
            GestureDetector(
              onTap: () {
                SearchServiceScreen(featuredList: widget.featuredList)
                    .launch(context);
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: commonDecoration,
                child: ic_search.iconImage(color: primaryColor),
              ),
            ),
          ],
        ).paddingAll(16),

        // Add bottom sliders if any
        if (bottomSlidersWidget != null) bottomSlidersWidget,
      ],
    );
  }
}
