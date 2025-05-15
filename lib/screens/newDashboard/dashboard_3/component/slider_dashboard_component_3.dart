import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../model/dashboard_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/configs.dart';
import '../../../../utils/constant.dart';
import '../../../../main.dart';
import '../../../service/service_detail_screen.dart';

class SliderDashboardComponent3 extends StatefulWidget {
  final List<SliderModel> sliderList;

  SliderDashboardComponent3({required this.sliderList});

  @override
  _SliderDashboardComponent3State createState() =>
      _SliderDashboardComponent3State();
}

class _SliderDashboardComponent3State extends State<SliderDashboardComponent3>
    with TickerProviderStateMixin {
  // Full-width page controllers
  PageController topSliderPageController = PageController(initialPage: 0);
  PageController bottomSliderPageController = PageController(initialPage: 0);

  int _currentTopPage = 0;
  int _currentBottomPage = 0;

  Timer? _topTimer;
  Timer? _bottomTimer;
  Map<int, VideoPlayerController> videoControllers = {};

  // Animation controllers for subtle fade effects
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.repeat(reverse: true);

    // Initialize video controllers for any video sliders
    initializeVideoControllers();

    init();
  }

  // Separate method for video controller initialization for better organization
  void initializeVideoControllers() {
    for (int i = 0; i < widget.sliderList.length; i++) {
      if (widget.sliderList[i].isVideo) {
        final videoUrl = widget.sliderList[i].sliderImage.validate();
        print('Initializing video at index $i, URL: $videoUrl');

        if (videoUrl.isEmpty) {
          print('Empty video URL for slider at index $i');
          continue;
        }

        try {
          videoControllers[i] = VideoPlayerController.network(videoUrl)
            ..initialize().then((_) {
              print('Video at index $i successfully initialized');
              if (mounted) setState(() {});

              // Add a listener to handle video completion for each controller
              videoControllers[i]?.addListener(() {
                // Check if video has reached the end
                if (videoControllers[i]?.value.isInitialized == true &&
                    videoControllers[i]?.value.position ==
                        videoControllers[i]?.value.duration) {
                  print('Video at index $i completed playback');
                  // Move to next slide logic...
                  handleVideoCompletion(i);
                }
              });

              // Auto-play first video if it's the first slide
              if (mounted && i == 0) {
                List<SliderModel> topSliders = getSlidersByDirection('up');
                if (topSliders.isNotEmpty &&
                    topSliders[0] == widget.sliderList[i]) {
                  print('Auto-playing first video at index $i');
                  videoControllers[i]?.play();
                  videoControllers[i]?.setLooping(false);
                }
              }
            });
        } catch (e) {
          print('Error initializing video at index $i: $e');
        }
      }
    }
  }

  // Handle video completion event
  void handleVideoCompletion(int videoIndex) {
    // If this is the current slide, move to the next one
    List<SliderModel> topSliders = getSlidersByDirection('up');
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    int topIndex = topSliders.indexOf(widget.sliderList[videoIndex]);
    int bottomIndex = bottomSliders.indexOf(widget.sliderList[videoIndex]);

    if (topIndex == _currentTopPage && topIndex != -1) {
      // This video is in the top slider and is the current one
      if (_currentTopPage < topSliders.length - 1) {
        _currentTopPage++;
      } else {
        _currentTopPage = 0;
      }

      topSliderPageController.animateToPage(_currentTopPage,
          duration: Duration(milliseconds: 800), curve: Curves.easeOutQuint);

      _scheduleTopSliderTransition(topSliders);
    } else if (bottomIndex == _currentBottomPage && bottomIndex != -1) {
      // This video is in the bottom slider and is the current one
      if (_currentBottomPage < bottomSliders.length - 1) {
        _currentBottomPage++;
      } else {
        _currentBottomPage = 0;
      }

      bottomSliderPageController.animateToPage(_currentBottomPage,
          duration: Duration(milliseconds: 800), curve: Curves.easeOutQuint);

      _scheduleBottomSliderTransition(bottomSliders);
    }
  }

  void init() async {
    // Get top and bottom sliders
    List<SliderModel> topSliders = getSlidersByDirection('up');
    List<SliderModel> bottomSliders = getSlidersByDirection('down');

    // Auto-slide for top sliders
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        topSliders.length >= 2) {
      // Initial setup for top slider transition
      _scheduleTopSliderTransition(topSliders);

      topSliderPageController.addListener(() {
        if (topSliderPageController.page != null) {
          int newPage = topSliderPageController.page!.round();
          if (_currentTopPage != newPage) {
            _currentTopPage = newPage;

            // Handle video playback when manually sliding
            videoControllers.forEach((index, controller) {
              controller.pause();
            });

            int sliderIndex =
                widget.sliderList.indexOf(topSliders[_currentTopPage]);
            if (sliderIndex != -1 && topSliders[_currentTopPage].isVideo) {
              videoControllers[sliderIndex]?.play();
              videoControllers[sliderIndex]?.setLooping(true);

              // If a video is now playing, cancel existing timer and schedule based on video duration
              _topTimer?.cancel();
              _scheduleTopSliderTransition(topSliders);
            }
          }
        }
      });
    }

    // Auto-slide for bottom sliders
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        bottomSliders.length >= 2) {
      // Initial setup for bottom slider transition
      _scheduleBottomSliderTransition(bottomSliders);

      bottomSliderPageController.addListener(() {
        if (bottomSliderPageController.page != null) {
          int newPage = bottomSliderPageController.page!.round();
          if (_currentBottomPage != newPage) {
            _currentBottomPage = newPage;

            // Handle video playback when manually sliding
            videoControllers.forEach((index, controller) {
              controller.pause();
            });

            int sliderIndex =
                widget.sliderList.indexOf(bottomSliders[_currentBottomPage]);
            if (sliderIndex != -1 &&
                bottomSliders[_currentBottomPage].isVideo) {
              videoControllers[sliderIndex]?.play();
              videoControllers[sliderIndex]?.setLooping(true);

              // If a video is now playing, cancel existing timer and schedule based on video duration
              _bottomTimer?.cancel();
              _scheduleBottomSliderTransition(bottomSliders);
            }
          }
        }
      });
    }
  }

  // New method to schedule top slider transitions based on content
  void _scheduleTopSliderTransition(List<SliderModel> topSliders) {
    // Cancel any existing timer
    _topTimer?.cancel();

    // Get current slider content type
    bool isCurrentSlideVideo = _currentTopPage < topSliders.length &&
        topSliders[_currentTopPage].isVideo;

    int sliderIndex = widget.sliderList.indexOf(topSliders[_currentTopPage]);
    VideoPlayerController? currentVideoController =
        isCurrentSlideVideo ? videoControllers[sliderIndex] : null;

    if (isCurrentSlideVideo &&
        currentVideoController != null &&
        currentVideoController.value.isInitialized) {
      // For video slides, listen for video completion to advance
      _topTimer = Timer(currentVideoController.value.duration, () {
        if (mounted) {
          // Video finished, move to next slide
          if (_currentTopPage < topSliders.length - 1) {
            _currentTopPage++;
          } else {
            _currentTopPage = 0;
          }

          // Pause current video
          currentVideoController.pause();

          // Animate to next slide
          topSliderPageController.animateToPage(_currentTopPage,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutQuint);

          // This will trigger the listener which will schedule the next transition
        }
      });

      // Make sure the video is playing and not looping
      currentVideoController.setLooping(false);
      currentVideoController.play();
    } else {
      // For image slides, use the standard timer
      _topTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (mounted) {
          if (_currentTopPage < topSliders.length - 1) {
            _currentTopPage++;
          } else {
            _currentTopPage = 0;
          }

          // Pause any currently playing videos before sliding
          videoControllers.forEach((index, controller) {
            if (controller.value.isPlaying) {
              controller.pause();
            }
          });

          topSliderPageController.animateToPage(_currentTopPage,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutQuint);

          // Play the video at the new position if it's a video
          int sliderIndex =
              widget.sliderList.indexOf(topSliders[_currentTopPage]);
          if (sliderIndex != -1 && topSliders[_currentTopPage].isVideo) {
            videoControllers[sliderIndex]?.setLooping(false);
            videoControllers[sliderIndex]?.play();

            // Cancel the timer and wait for video to finish
            timer.cancel();
            _scheduleTopSliderTransition(topSliders);
          }
        }
      });
    }
  }

  // New method to schedule bottom slider transitions based on content
  void _scheduleBottomSliderTransition(List<SliderModel> bottomSliders) {
    // Cancel any existing timer
    _bottomTimer?.cancel();

    // Get current slider content type
    bool isCurrentSlideVideo = _currentBottomPage < bottomSliders.length &&
        bottomSliders[_currentBottomPage].isVideo;

    int sliderIndex =
        widget.sliderList.indexOf(bottomSliders[_currentBottomPage]);
    VideoPlayerController? currentVideoController =
        isCurrentSlideVideo ? videoControllers[sliderIndex] : null;

    if (isCurrentSlideVideo &&
        currentVideoController != null &&
        currentVideoController.value.isInitialized) {
      // For video slides, listen for video completion to advance
      _bottomTimer = Timer(currentVideoController.value.duration, () {
        if (mounted) {
          // Video finished, move to next slide
          if (_currentBottomPage < bottomSliders.length - 1) {
            _currentBottomPage++;
          } else {
            _currentBottomPage = 0;
          }

          // Pause current video
          currentVideoController.pause();

          // Animate to next slide
          bottomSliderPageController.animateToPage(_currentBottomPage,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutQuint);

          // This will trigger the listener which will schedule the next transition
        }
      });

      // Make sure the video is playing and not looping
      currentVideoController.setLooping(false);
      currentVideoController.play();
    } else {
      // For image slides, use the standard timer
      _bottomTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (mounted) {
          if (_currentBottomPage < bottomSliders.length - 1) {
            _currentBottomPage++;
          } else {
            _currentBottomPage = 0;
          }

          // Pause any currently playing videos before sliding
          videoControllers.forEach((index, controller) {
            if (controller.value.isPlaying) {
              controller.pause();
            }
          });

          bottomSliderPageController.animateToPage(_currentBottomPage,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutQuint);

          // Play the video at the new position if it's a video
          int sliderIndex =
              widget.sliderList.indexOf(bottomSliders[_currentBottomPage]);
          if (sliderIndex != -1 && bottomSliders[_currentBottomPage].isVideo) {
            videoControllers[sliderIndex]?.setLooping(false);
            videoControllers[sliderIndex]?.play();

            // Cancel the timer and wait for video to finish
            timer.cancel();
            _scheduleBottomSliderTransition(bottomSliders);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _topTimer?.cancel();
    _bottomTimer?.cancel();
    topSliderPageController.dispose();
    bottomSliderPageController.dispose();
    _fadeController.dispose();

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

  // Professional modern design for full-width media widget
  Widget getMediaWidget(SliderModel data, int index, {bool isTop = true}) {
    // Use full screen width
    final double width = context.width();
    // Dynamically calculate height based on screen size for better proportions
    final double height = isTop
        ? context.height() * 0.22 // 22% of screen height for top banner
        : context.height() * 0.20; // 20% of screen height for bottom banner

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media Content (Video or Image)
                if (data.isVideo)
                  _buildVideoSlider(data, index, height, width)
                else
                  _buildImageSlider(data, height, width),

                // Enhanced gradient overlay
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: [0.6, 0.75, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),

                // Removed title text with enhanced styling as requested
                /* Original title text code removed
                if (data.title.validate().isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data.description.validate().isNotEmpty)
                            Text(
                              data.description.validate(),
                              style: secondaryTextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          4.height,
                          Text(
                            data.title.validate(),
                            style: boldTextStyle(
                                color: Colors.white,
                                size: 18,
                                letterSpacing: 0.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data.serviceName.validate().isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.8),
                                borderRadius: radius(30),
                              ),
                              child: Text(
                                data.serviceName.validate(),
                                style: boldTextStyle(
                                    color: Colors.white, size: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                */
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced video slider widget
  Widget _buildVideoSlider(
      SliderModel data, int index, double height, double width) {
    VideoPlayerController? controller = videoControllers[index];

    return GestureDetector(
      onTap: () {
        if (data.type == SERVICE) {
          ServiceDetailScreen(serviceId: data.typeId.validate().toInt())
              .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
        } else if (controller != null) {
          // Toggle play/pause when tapping on video
          controller.value.isPlaying ? controller.pause() : controller.play();
          setState(() {});

          // If we're playing the video, make sure it's not set to loop
          if (controller.value.isPlaying) {
            controller.setLooping(false);
          }
        }
      },
      child: Container(
        height: height,
        width: width,
        color: Colors.black,
        child: controller != null && controller.value.isInitialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: height,
                    width: width,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  if (!controller.value.isPlaying)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  // Add video progress indicator
                  if (controller.value.isPlaying)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: controller.value.isInitialized
                            ? controller.value.position.inMilliseconds /
                                controller.value.duration.inMilliseconds
                            : 0.0,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 3,
                      ),
                    ),
                ],
              )
            : Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
      ),
    );
  }

  // Enhanced image slider widget with improved dimensions
  Widget _buildImageSlider(SliderModel data, double height, double width) {
    return GestureDetector(
      onTap: () {
        if (data.type == SERVICE) {
          ServiceDetailScreen(serviceId: data.typeId.validate().toInt())
              .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
        }
      },
      child: Container(
        height: height,
        width: width,
        child: CachedImageWidget(
          url: data.sliderImage.validate(),
          fit: BoxFit.cover,
          height: height,
          width: width,
          radius: 0,
        ),
      ),
    );
  }

  // Modern professional indicator with sleek animation
  Widget buildIndicator(int pageCount, int currentIndex) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: radius(30),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (index) {
            bool isActive = currentIndex == index;
            return AnimatedContainer(
              duration: Duration(milliseconds: 350),
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: isActive ? 8 : 6,
              width: isActive ? 24 : 6,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : Colors.white.withOpacity(0.3),
                borderRadius: radius(isActive ? 4 : 3),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 0,
                        )
                      ]
                    : null,
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          primaryColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
              ),
              child: isActive
                  ? Center(
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: 1.0,
                        child: Container(
                          height: 3,
                          width: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get top and bottom sliders
    final topSliders = getSlidersByDirection('up');
    final bottomSliders = getSlidersByDirection('down');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title for Top Banner with improved styling
        if (topSliders.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: radius(2),
                  ),
                ),
                8.width,
                Text(
                  language.allServices,
                  style: boldTextStyle(size: 18, letterSpacing: 0.3),
                ),
              ],
            ),
          ),

        // Enhanced Full-Width Top Slider Banner
        if (topSliders.isNotEmpty)
          Container(
            height: context.height() * 0.22, // 22% of screen height
            width: context.width(),
            child: Stack(
              children: [
                // Full-width page view
                PageView.builder(
                  controller: topSliderPageController,
                  itemCount: topSliders.length,
                  itemBuilder: (context, index) {
                    SliderModel data = topSliders[index];
                    return getMediaWidget(data, widget.sliderList.indexOf(data),
                        isTop: true);
                  },
                ),

                // Enhanced custom indicators (centered at bottom)
                if (topSliders.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                        child:
                            buildIndicator(topSliders.length, _currentTopPage)),
                  ),
              ],
            ),
          ),

        // Bottom Banner Section (if available) with improved styling
        if (bottomSliders.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              30.height,

              // Section Title for Bottom Banner with improved styling
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: radius(2),
                      ),
                    ),
                    8.width,
                    Text(
                      language.booking,
                      style: boldTextStyle(size: 18, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),

              12.height,

              // Enhanced Full-Width Bottom Slider Banner
              Container(
                height: context.height() * 0.20, // 20% of screen height
                width: context.width(),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: bottomSliderPageController,
                      itemCount: bottomSliders.length,
                      itemBuilder: (context, index) {
                        SliderModel data = bottomSliders[index];
                        return getMediaWidget(
                            data, widget.sliderList.indexOf(data),
                            isTop: false);
                      },
                    ),

                    // Enhanced custom indicators (centered at bottom)
                    if (bottomSliders.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: buildIndicator(
                                bottomSliders.length, _currentBottomPage)),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
