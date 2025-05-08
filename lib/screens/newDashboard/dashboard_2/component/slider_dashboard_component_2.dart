import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../model/dashboard_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/constant.dart';
import '../../../service/service_detail_screen.dart';

class SliderDashboardComponent2 extends StatefulWidget {
  final List<SliderModel> sliderList;

  SliderDashboardComponent2({required this.sliderList});

  @override
  _SliderDashboardComponent2State createState() =>
      _SliderDashboardComponent2State();
}

class _SliderDashboardComponent2State extends State<SliderDashboardComponent2> {
  int _currentPage = 0;
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
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
            (slider.direction ?? '').toLowerCase() == direction.toLowerCase() ||
            (slider.direction ?? '').isEmpty)
        .toList();
  }

  // Widget to render either image or video based on media_type
  Widget getMediaWidget(SliderModel data, int index) {
    if (data.isVideo) {
      VideoPlayerController? controller = videoControllers[index];

      if (controller != null && controller.value.isInitialized) {
        // Auto-play when this slide is active
        if (_currentPage == index && !controller.value.isPlaying) {
          controller.play();
        } else if (_currentPage != index && controller.value.isPlaying) {
          controller.pause();
        }

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
        height: 200,
        width: context.width(),
        radius: 8,
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

  @override
  Widget build(BuildContext context) {
    // Get sliders for top and bottom
    List<SliderModel> topSliders = getSlidersByDirection('up');
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    // If no direction specified, show all at top
    if (topSliders.isEmpty && bottomSliders.isEmpty) {
      topSliders = widget.sliderList;
    }

    return Column(
      children: [
        // Top Sliders
        if (topSliders.isNotEmpty)
          Column(
            children: [
              CarouselSlider(
                items: List.generate(topSliders.length, (index) {
                  SliderModel data = topSliders[index];
                  return getMediaWidget(data, widget.sliderList.indexOf(data));
                }),
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  autoPlay: !topSliders.any((slider) =>
                      slider.isVideo), // Don't auto-play if there are videos
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                ),
              ),
              if (topSliders.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    topSliders.length,
                    (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 0),
                      height: 4,
                      width: 30,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? primaryColor
                            : context.cardColor,
                        borderRadius: index == 0
                            ? BorderRadius.only(
                                topLeft: Radius.circular(5),
                                bottomLeft: Radius.circular(5),
                                topRight: Radius.circular(
                                    _currentPage == index ? 5 : 0),
                                bottomRight: Radius.circular(
                                    _currentPage == index ? 5 : 0),
                              )
                            : topSliders.length - 1 == index
                                ? BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(
                                        _currentPage == index ? 5 : 0),
                                    topLeft: Radius.circular(
                                        _currentPage == index ? 5 : 0),
                                  )
                                : BorderRadius.circular(
                                    _currentPage == index ? 5 : 0),
                      ),
                    ),
                  ),
                ).paddingTop(16),
            ],
          )
        else
          CachedImageWidget(url: '', height: 200, width: context.width()),

        // Bottom Sliders (if any with direction=down)
        if (bottomSliders.isNotEmpty)
          Column(
            children: [
              16.height,
              CarouselSlider(
                items: List.generate(bottomSliders.length, (index) {
                  SliderModel data = bottomSliders[index];
                  return getMediaWidget(data, widget.sliderList.indexOf(data));
                }),
                options: CarouselOptions(
                  height: 180, // Slightly smaller for bottom sliders
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  autoPlay: !bottomSliders.any((slider) => slider.isVideo),
                  onPageChanged: (index, reason) {
                    // This will not interfere with top slider index
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
