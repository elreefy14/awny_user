import 'dart:async';

import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../model/dashboard_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/configs.dart';
import '../../../../utils/constant.dart';
import '../../../service/service_detail_screen.dart';

class SliderDashboardComponent4 extends StatefulWidget {
  final List<SliderModel> sliderList;

  SliderDashboardComponent4({required this.sliderList});

  @override
  _SliderDashboardComponent4State createState() =>
      _SliderDashboardComponent4State();
}

class _SliderDashboardComponent4State extends State<SliderDashboardComponent4> {
  PageController topSliderPageController = PageController(initialPage: 0);
  PageController bottomSliderPageController = PageController(initialPage: 0);
  int _currentTopPage = 0;
  int _currentBottomPage = 0;

  Timer? _topTimer;
  Timer? _bottomTimer;
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();
    init();

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
  }

  void init() async {
    // Get top and bottom sliders
    List<SliderModel> topSliders = getSlidersByDirection('up');
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    // Auto-slide for top sliders
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        topSliders.length >= 2) {
      _topTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (_currentTopPage < topSliders.length - 1) {
          _currentTopPage++;
        } else {
          _currentTopPage = 0;
        }
        topSliderPageController.animateToPage(_currentTopPage,
            duration: Duration(milliseconds: 950), curve: Curves.easeOutQuart);
      });

      topSliderPageController.addListener(() {
        _currentTopPage = topSliderPageController.page!.toInt();
      });
    }

    // Auto-slide for bottom sliders
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        bottomSliders.length >= 2) {
      _bottomTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (_currentBottomPage < bottomSliders.length - 1) {
          _currentBottomPage++;
        } else {
          _currentBottomPage = 0;
        }
        bottomSliderPageController.animateToPage(_currentBottomPage,
            duration: Duration(milliseconds: 950), curve: Curves.easeOutQuart);
      });

      bottomSliderPageController.addListener(() {
        _currentBottomPage = bottomSliderPageController.page!.toInt();
      });
    }
  }

  @override
  void dispose() {
    _topTimer?.cancel();
    _bottomTimer?.cancel();
    topSliderPageController.dispose();
    bottomSliderPageController.dispose();

    // Dispose video controllers
    videoControllers.forEach((key, controller) {
      controller.dispose();
    });

    super.dispose();
  }

  // Get sliders for a specific direction
  List<SliderModel> getSlidersByDirection(String direction) {
    return widget.sliderList
        .where((slider) =>
                (slider.direction ?? '').toLowerCase() ==
                    direction.toLowerCase() ||
                (direction == 'up' &&
                    (slider.direction ?? '')
                        .isEmpty) // Default to top if no direction
            )
        .toList();
  }

  // Widget to render either image or video based on media_type
  Widget getMediaWidget(SliderModel data, int index) {
    if (data.isVideo) {
      VideoPlayerController? controller = videoControllers[index];

      if (controller != null && controller.value.isInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
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
                .launch(
              context,
              pageRouteAnimation: PageRouteAnimation.Fade,
            );
          }
        });
      } else {
        return Center(child: CircularProgressIndicator());
      }
    } else {
      // Regular image slider
      return CachedImageWidget(
        url: data.sliderImage.validate(),
        height: 190,
        width: context.width() - 32,
        fit: BoxFit.cover,
      ).onTap(() {
        if (data.type == SERVICE) {
          ServiceDetailScreen(serviceId: data.typeId.validate().toInt()).launch(
            context,
            pageRouteAnimation: PageRouteAnimation.Fade,
          );
        }
      });
    }
  }

  Widget getSliderWidget(
      List<SliderModel> sliders, PageController controller, int currentPage) {
    return SizedBox(
      height: 190,
      width: context.width(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          sliders.isNotEmpty
              ? PageView(
                  controller: controller,
                  physics: ClampingScrollPhysics(),
                  children: List.generate(
                    sliders.length,
                    (index) {
                      SliderModel data = sliders[index];
                      return getMediaWidget(
                          data, widget.sliderList.indexOf(data));
                    },
                  ),
                )
              : CachedImageWidget(url: '', height: 175, width: context.width()),
          if (sliders.length.validate() > 1)
            Positioned(
              bottom: -25,
              left: 0,
              right: 0,
              child: DotIndicator(
                pageController: controller,
                pages: sliders,
                indicatorColor: primaryColor,
                unselectedIndicatorColor:
                    appStore.isDarkMode ? context.cardColor : Colors.white,
                currentBoxShape: BoxShape.rectangle,
                boxShape: BoxShape.rectangle,
                borderRadius: radius(2),
                currentBorderRadius: radius(3),
                currentDotSize: 18,
                currentDotWidth: 6,
                dotSize: 6,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get top and bottom sliders
    final topSliders = getSlidersByDirection('up');
    final bottomSliders = getSlidersByDirection('down');

    return Column(
      children: [
        // Top Sliders (default or explicitly marked as 'up')
        getSliderWidget(topSliders, topSliderPageController, _currentTopPage),

        // Bottom Sliders (if any with direction=down)
        if (bottomSliders.isNotEmpty)
          Column(
            children: [
              30.height,
              getSliderWidget(bottomSliders, bottomSliderPageController,
                  _currentBottomPage),
            ],
          ),
      ],
    );
  }
}
