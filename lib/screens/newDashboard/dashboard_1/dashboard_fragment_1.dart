import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_1/shimmer/dashboard_shimmer_1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../../model/dashboard_model.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/constant.dart';
import '../../dashboard/component/category_component.dart';
import 'component/booking_confirmed_component_1.dart';
import 'component/feature_services_dashboard_component_1.dart';
import 'component/job_request_dashboard_component_1.dart';
import 'component/service_list_dashboard_component_1.dart';
import 'component/slider_dashboard_component_1.dart';

class DashboardFragment1 extends StatefulWidget {
  @override
  _DashboardFragment1State createState() => _DashboardFragment1State();
}

class _DashboardFragment1State extends State<DashboardFragment1> {
  Future<DashboardResponse>? future;

  @override
  void initState() {
    super.initState();
    init();

    setStatusBarColor(transparentColor, delayInMilliSeconds: 800);

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      init();
      appStore.setLoading(true);

      setState(() {});
    });
  }

  void init() async {
    future = userDashboard(
        isCurrentLocation: appStore.isCurrentLocation,
        lat: getDoubleAsync(LATITUDE),
        long: getDoubleAsync(LONGITUDE));

    // Debug slider data
    future!.then((response) {
      // DIAGNOSTIC: If no sliders have direction set, manually set some for testing
      bool hasUpSliders = false;
      bool hasDownSliders = false;

      // Check if any sliders have directions set
      response.slider?.forEach((slider) {
        if ((slider.direction ?? '').toLowerCase() == 'up') hasUpSliders = true;
        if ((slider.direction ?? '').toLowerCase() == 'down')
          hasDownSliders = true;
      });

      debugPrint('Has UP sliders: $hasUpSliders');
      debugPrint('Has DOWN sliders: $hasDownSliders');

      // If no directions are set, let's set some for testing
      if (!hasUpSliders &&
          !hasDownSliders &&
          response.slider != null &&
          response.slider!.length >= 2) {
        debugPrint('SETTING TEST DIRECTIONS ON SLIDERS');

        // Set first half of sliders to "up"
        for (int i = 0; i < response.slider!.length ~/ 2; i++) {
          response.slider![i].direction = 'up';
          debugPrint('Set slider ${response.slider![i].id} to direction UP');
        }

        // Set second half to "down"
        for (int i = response.slider!.length ~/ 2;
            i < response.slider!.length;
            i++) {
          response.slider![i].direction = 'down';
          debugPrint('Set slider ${response.slider![i].id} to direction DOWN');
        }

        // Force UI update
        setState(() {});
      }

      // Original debug code
      debugPrint('=============== DEBUG SLIDER DATA ===============');
      debugPrint('Total sliders: ${response.slider?.length ?? 0}');

      response.slider?.forEach((slider) {
        debugPrint('Slider ID: ${slider.id}, Title: ${slider.title}');
        debugPrint('  Direction: ${slider.direction ?? "null"}');
        debugPrint('  Media Type: ${slider.mediaType ?? "null"}');
        debugPrint('  Image URL: ${slider.sliderImage}');
        debugPrint('-------------------------------------------');
      });

      // Check top and bottom sliders
      List<SliderModel> topSliders = response.slider
              ?.where((slider) =>
                  (slider.direction ?? '').toLowerCase() == 'up' ||
                  (slider.direction ?? '').isEmpty)
              .toList() ??
          [];

      List<SliderModel> bottomSliders = response.slider
              ?.where(
                  (slider) => (slider.direction ?? '').toLowerCase() == 'down')
              .toList() ??
          [];

      debugPrint('Top sliders count: ${topSliders.length}');
      debugPrint('Bottom sliders count: ${bottomSliders.length}');
      debugPrint('===============================================');
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SnapHelperWidget<DashboardResponse>(
            initialData: cachedDashboardResponse,
            future: future,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  appStore.setLoading(true);
                  init();

                  setState(() {});
                },
              );
            },
            loadingWidget: DashboardShimmer1(),
            onSuccess: (snap) {
              return Observer(builder: (context) {
                return AnimatedScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);

                    setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    SliderDashboardComponent1(
                      sliderList: snap.slider.validate(),
                      featuredList: snap.featuredServices.validate(),
                      callback: () async {
                        appStore.setLoading(true);

                        init();
                        setState(() {});
                      },
                    ),
                    BookingConfirmedComponent1(
                        upcomingConfirmedBooking: snap.upcomingData),
                    16.height,
                    CategoryComponent(
                        categoryList: snap.category.validate(),
                        isNewDashboard: true),
                    16.height,
                    ServiceListDashboardComponent1(
                        serviceList: snap.service.validate()),
                    16.height,
                    FeatureServicesDashboardComponent1(
                        serviceList: snap.featuredServices.validate()),
                    16.height,
                    if (appConfigurationStore.jobRequestStatus)
                      NewJobRequestDashboardComponent1()
                  ],
                );
              });
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
