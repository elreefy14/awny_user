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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Full-width page controllers
  PageController topSliderPageController = PageController(initialPage: 0);
  PageController bottomSliderPageController = PageController(initialPage: 0);

  int _currentTopPage = 0;
  int _currentBottomPage = 0;

  Timer? _topTimer;
  Timer? _bottomTimer;
  Map<int, VideoPlayerController> videoControllers = {};
  // Track if a video is being interacted with to prevent auto-slide
  bool _isVideoInteracting = false;

  // Animation controllers for subtle fade effects
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Add a new field to track completions
  Map<int, bool> completedVideos = {};

  @override
  void initState() {
    super.initState();
    // Register to app lifecycle changes to pause videos when app is in background
    WidgetsBinding.instance.addObserver(this);

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

    // Listen for events to pause videos
    LiveStream().on('PAUSE_ALL_VIDEOS', (_) {
      pauseAllVideos();
    });

    init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause all videos when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseAllVideos();
    }
  }

  // Pause all active videos - call when navigating away
  void pauseAllVideos() {
    videoControllers.forEach((key, controller) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    });
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
                final controller = videoControllers[i];
                if (controller == null) return;

                // Check if video has reached the end (with a small threshold)
                if (controller.value.isInitialized &&
                    controller.value.position >=
                        controller.value.duration -
                            Duration(milliseconds: 300)) {
                  print('Video at index $i completed playback');

                  // تغيير هنا: نسجل أن الفيديو قد اكتمل ولكن نتيح إعادة مشاهدته
                  completedVideos[i] = true;
                  _isVideoInteracting = false;

                  // لا ننتقل للشريحة التالية مباشرة، بل نظهر زر إعادة التشغيل
                  controller.pause();
                  controller.seekTo(Duration.zero);
                  setState(() {});

                  // إذا كان التبديل التلقائي مفعلا، ننتقل للشريحة التالية بعد فترة
                  if (_isAutoSlideEnabled() && !_isVideoInteracting) {
                    Future.delayed(Duration(seconds: 3), () {
                      if (mounted && !_isVideoInteracting) {
                        handleVideoCompletion(i);
                      }
                    });
                  }
                }
              });

              // Volume settings
              videoControllers[i]?.setVolume(1.0);

              // Don't autoplay videos initially - let user tap to play
              videoControllers[i]?.pause();
            });
        } catch (e) {
          print('Error initializing video at index $i: $e');
        }
      }
    }
  }

  // Add helper to check if auto-slide is enabled
  bool _isAutoSlideEnabled() {
    return getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true);
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
      // تعديل: لا نضع مؤقت للفيديو - سننتظر الاستماع للحدث في الـ listener
      // Just ensure video is playing if supposed to be
      if (_isAutoSlideEnabled() && !_isVideoInteracting) {
        // Make sure the video is playing and not looping
        currentVideoController.setLooping(false);
        if (!currentVideoController.value.isPlaying) {
          currentVideoController.play();
        }
      }
    } else if (_isAutoSlideEnabled()) {
      // For image slides, use the standard timer
      _topTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (mounted) {
          // ننتقل فقط للشريحة التالية إذا لم نكن في وضع تفاعل مع الفيديو
          if (!_isVideoInteracting) {
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

              // Cancel the timer - we'll let the video completion listener handle the next transition
              timer.cancel();
              _scheduleTopSliderTransition(topSliders);
            }
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
      // تعديل: لا نضع مؤقت للفيديو - سننتظر الاستماع للحدث في الـ listener
      // Just ensure video is playing if supposed to be
      if (_isAutoSlideEnabled() && !_isVideoInteracting) {
        // Make sure the video is playing and not looping
        currentVideoController.setLooping(false);
        if (!currentVideoController.value.isPlaying) {
          currentVideoController.play();
        }
      }
    } else if (_isAutoSlideEnabled()) {
      // For image slides, use the standard timer
      _bottomTimer = Timer.periodic(
          Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND), (Timer timer) {
        if (mounted) {
          // ننتقل فقط للشريحة التالية إذا لم نكن في وضع تفاعل مع الفيديو
          if (!_isVideoInteracting) {
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
            if (sliderIndex != -1 &&
                bottomSliders[_currentBottomPage].isVideo) {
              videoControllers[sliderIndex]?.setLooping(false);
              videoControllers[sliderIndex]?.play();

              // Cancel the timer - we'll let the video completion listener handle the next transition
              timer.cancel();
              _scheduleBottomSliderTransition(bottomSliders);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Remove LiveStream listener
    LiveStream().dispose('PAUSE_ALL_VIDEOS');

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

  // Enhanced video slider widget with YouTube-like controls
  Widget _buildVideoSlider(
      SliderModel data, int index, double height, double width) {
    VideoPlayerController? controller = videoControllers[index];

    if (controller == null) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    // رمز الفيديو المشاهد سابقاً
    bool isVideoCompleted = completedVideos[index] ?? false;

    return GestureDetector(
      onTap: () {
        if (controller.value.isInitialized) {
          setState(() {
            _isVideoInteracting = true;
          });

          // Toggle play/pause when tapping on video
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            // إعادة تشغيل الفيديو من البداية إذا كان قد انتهى
            if (controller.value.position >=
                controller.value.duration - Duration(milliseconds: 300)) {
              controller.seekTo(Duration.zero);
            }

            // Pause any other playing videos first
            videoControllers.forEach((key, videoController) {
              if (key != index && videoController.value.isPlaying) {
                videoController.pause();
              }
            });
            controller.play();

            // إعادة ضبط متغير الاكتمال عند إعادة التشغيل
            completedVideos[index] = false;
          }
          setState(() {});
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            height: height,
            width: width,
            color: Colors.black,
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
          ),

          // Professional video controls overlay - تحسين الظهور
          AnimatedOpacity(
            opacity: controller.value.isPlaying ? 0.0 : 1.0,
            duration: Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    isVideoCompleted && !controller.value.isPlaying
                        ? Icons.replay_rounded
                        : controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Video progress indicator at bottom مع تحسين العرض
          if (controller.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // إضافة شريط تحكم محسن
                  if (!controller.value.isPlaying)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: radius(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر التحكم في الصوت
                          GestureDetector(
                            onTap: () {
                              final isMuted = controller.value.volume == 0;
                              controller.setVolume(isMuted ? 1.0 : 0.0);
                              setState(() {});
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: controller.value.volume > 0
                                    ? primaryColor
                                    : Colors.grey.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.value.volume > 0
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          // مؤشر الوقت
                          Text(
                            '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // مؤشر إذا كان الفيديو قد شوهد
                          if (isVideoCompleted)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.8),
                                borderRadius: radius(8),
                              ),
                              child: Text(
                                "تمت المشاهدة",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Container(
                    height: 5,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: primaryColor,
                        bufferedColor: Colors.white.withOpacity(0.5),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

          // Add play/pause control buttons with overlay
          if (controller.value.isInitialized && controller.value.isPlaying)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVideoInteracting = true;
                });
                controller.pause();
                setState(() {});
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  // Helper to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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

  // Modern simplified indicator with minimal design
  Widget buildIndicator(int pageCount, int currentIndex) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: radius(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simplified dots
          ...List.generate(
            pageCount,
            (index) {
              bool isActive = currentIndex == index;
              bool isVideo = false;

              if (pageCount == widget.sliderList.length) {
                isVideo = widget.sliderList[index].isVideo;
              } else {
                List<SliderModel> sliders =
                    pageCount == topSliderPageController.page!.round() + 1
                        ? getSlidersByDirection('up')
                        : getSlidersByDirection('down');
                if (index < sliders.length) {
                  isVideo = sliders[index].isVideo;
                }
              }

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 16 : 6,
                decoration: BoxDecoration(
                  color:
                      isActive ? primaryColor : Colors.white.withOpacity(0.6),
                  borderRadius: radius(8),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                          )
                        ]
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pause videos when this widget is removed from the widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        pauseAllVideos();
      }
    });

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

  // Add route observer to detect when the user navigates away
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Add route observer to pause videos when route changes
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      pauseAllVideos();
      return true;
    });
  }
}
