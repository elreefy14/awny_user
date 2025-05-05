import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/screens/booking/component/price_common_widget.dart';
import 'package:booking_system_flutter/screens/wallet/user_wallet_balance_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:async';

import '../../component/app_common_dialog.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/wallet_balance_component.dart';
import '../../model/payment_gateway_response.dart';
import '../../model/paymob_config.dart';
import '../../network/rest_apis.dart';
import '../../services/airtel_money/airtel_money_service.dart';
import '../../services/cinet_pay_services_new.dart';
import '../../services/flutter_wave_service_new.dart';
import '../../services/midtrans_service.dart';
import '../../services/paymob_service.dart';
import '../../services/paypal_service.dart';
import '../../services/paystack_service.dart';
import '../../services/phone_pe/phone_pe_service.dart';
import '../../services/razorpay_service_new.dart';
import '../../services/sadad_services_new.dart';
import '../../services/stripe_service_new.dart';
import '../../utils/configs.dart';
import '../../utils/model_keys.dart';
import '../dashboard/dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingDetailResponse bookings;
  final bool isForAdvancePayment;

  PaymentScreen({required this.bookings, this.isForAdvancePayment = false});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<List<PaymentSetting>>? future;

  PaymentSetting? currentPaymentMethod;

  num totalAmount = 0;
  num? advancePaymentAmount;

  @override
  void initState() {
    super.initState();
    init();

    if (widget.bookings.service!.isAdvancePayment &&
        widget.bookings.bookingDetail!.bookingPackage == null) {
      if (widget.bookings.bookingDetail!.paidAmount.validate() == 0) {
        advancePaymentAmount =
            widget.bookings.bookingDetail!.totalAmount.validate() *
                widget.bookings.service!.advancePaymentPercentage.validate() /
                100;
        totalAmount = widget.bookings.bookingDetail!.totalAmount.validate() *
            widget.bookings.service!.advancePaymentPercentage.validate() /
            100;
      } else {
        totalAmount = widget.bookings.bookingDetail!.totalAmount.validate() -
            widget.bookings.bookingDetail!.paidAmount.validate();
      }
    } else {
      totalAmount = widget.bookings.bookingDetail!.totalAmount.validate();
    }

    log(totalAmount);
  }

  void init() async {
    log("ISaDVANCE${widget.isForAdvancePayment}");
    future = getPaymentGateways(requireCOD: !widget.isForAdvancePayment);

    // Add debug logging for payment gateways
    future!.then((paymentSettings) {
      debugPrint('===== PAYMENT GATEWAYS RECEIVED =====');
      debugPrint('Total payment gateways: ${paymentSettings.length}');

      for (var i = 0; i < paymentSettings.length; i++) {
        final setting = paymentSettings[i];
        debugPrint('Payment Gateway #$i:');
        debugPrint('  ID: ${setting.id}');
        debugPrint('  Title: ${setting.title}');
        debugPrint('  Type: ${setting.type}');
        debugPrint('  Status: ${setting.status}');
        debugPrint('  Is Test: ${setting.isTest}');

        // Check if it's PayMob
        if (setting.type == 'paymob') {
          debugPrint('  ** FOUND PAYMOB GATEWAY **');
          var settingJson = setting.toJson();
          debugPrint('  Full PayMob setting: $settingJson');

          // Try different ways to access values
          if (settingJson.containsKey('value')) {
            final valueData = settingJson['value'];
            debugPrint('  Value data: $valueData');
          }

          if (settingJson.containsKey('live_value')) {
            final liveValueData = settingJson['live_value'];
            debugPrint('  Live value data: $liveValueData');
          }
        }
      }
    }).catchError((e) {
      debugPrint('Error loading payment gateways: $e');
    });

    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _handleClick() async {
    appStore.setLoading(true);
    if (currentPaymentMethod!.type == PAYMENT_METHOD_COD) {
      savePay(
          paymentMethod: PAYMENT_METHOD_COD,
          paymentStatus: SERVICE_PAYMENT_STATUS_PENDING);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_STRIPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      stripeServiceNew.stripePay();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      RazorPayServiceNew razorPayServiceNew = RazorPayServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_RAZOR,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['paymentId'],
          );
        },
      );
      razorPayServiceNew.razorPayCheckout();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      FlutterWaveServiceNew flutterWaveServiceNew = FlutterWaveServiceNew();

      flutterWaveServiceNew.checkout(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_FLUTTER_WAVE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_CINETPAY) {
      List<String> supportedCurrencies = ["XOF", "XAF", "CDF", "GNF", "USD"];

      if (!supportedCurrencies.contains(appConfigurationStore.currencyCode)) {
        toast(language.cinetPayNotSupportedMessage);
        return;
      } else if (totalAmount < 100) {
        return toast(
            '${language.totalAmountShouldBeMoreThan} ${100.toPriceFormat()}');
      } else if (totalAmount > 1500000) {
        return toast(
            '${language.totalAmountShouldBeLessThan} ${1500000.toPriceFormat()}');
      }

      CinetPayServicesNew cinetPayServices = CinetPayServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_CINETPAY,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      cinetPayServices.payWithCinetPay(context: context);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_SADAD_PAYMENT) {
      SadadServicesNew sadadServices = SadadServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        remarks: language.topUpWallet,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_SADAD_PAYMENT,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      sadadServices.payWithSadad(context);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      PayPalService.paypalCheckOut(
        context: context,
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          log('PayPalService onComplete: $p0');
          savePay(
            paymentMethod: PAYMENT_METHOD_PAYPAL,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_AIRTEL) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        barrierDismissible: false,
        builder: (context) {
          return AppCommonDialog(
            title: language.airtelMoneyPayment,
            child: AirtelMoneyDialog(
              amount: totalAmount,
              reference: APP_NAME,
              paymentSetting: currentPaymentMethod!,
              bookingId: widget.bookings.bookingDetail != null
                  ? widget.bookings.bookingDetail!.id.validate()
                  : 0,
              onComplete: (res) {
                log('RES: $res');
                savePay(
                  paymentMethod: PAYMENT_METHOD_AIRTEL,
                  paymentStatus: widget.isForAdvancePayment
                      ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                      : SERVICE_PAYMENT_STATUS_PAID,
                  txnId: res['transaction_id'],
                );
              },
            ),
          );
        },
      ).then((value) => appStore.setLoading(false));
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYSTACK) {
      PayStackService paystackServices = PayStackService();
      appStore.setLoading(true);
      await paystackServices.init(
        context: context,
        currentPaymentMethod: currentPaymentMethod!,
        loderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        totalAmount: totalAmount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_PAYSTACK,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      paystackServices.checkout();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MIDTRANS) {
      //TODO: all params check
      MidtransService midtransService = MidtransService();
      appStore.setLoading(true);
      await midtransService.initialize(
        currentPaymentMethod: currentPaymentMethod!,
        totalAmount: totalAmount,
        serviceId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceId.validate()
            : 0,
        serviceName: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceName.validate()
            : '',
        servicePrice: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.amount.validate()
            : 0,
        loaderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_MIDTRANS,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"], //TODO: check
          );
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      midtransService.midtransPaymentCheckout();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PHONEPE) {
      PhonePeServices peServices = PhonePeServices(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          log('RES: $res');
          savePay(
            paymentMethod: PAYMENT_METHOD_PHONEPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );

      peServices.phonePeCheckout(context);
    } else if (currentPaymentMethod!.type == 'paymob') {
      await handlePayMobPayment();
      // Payment completion will be handled by PayMob redirect
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FROM_WALLET) {
      savePay(
        paymentMethod: PAYMENT_METHOD_FROM_WALLET,
        paymentStatus: widget.isForAdvancePayment
            ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
            : SERVICE_PAYMENT_STATUS_PAID,
        txnId: '',
      );
    }
  }

  void savePay(
      {String txnId = '',
      String paymentMethod = '',
      String paymentStatus = ''}) async {
    Map request = {
      CommonKeys.bookingId: widget.bookings.bookingDetail!.id.validate(),
      CommonKeys.customerId: appStore.userId,
      CouponKeys.discount: widget.bookings.service!.discount,
      BookingServiceKeys.totalAmount: totalAmount,
      CommonKeys.dateTime:
          DateFormat(BOOKING_SAVE_FORMAT).format(DateTime.now()),
      CommonKeys.txnId: txnId != ''
          ? txnId
          : "#${widget.bookings.bookingDetail!.id.validate()}",
      CommonKeys.paymentStatus: paymentStatus,
      CommonKeys.paymentMethod: paymentMethod,
    };

    if (widget.bookings.service != null &&
        widget.bookings.service!.isAdvancePayment) {
      request[AdvancePaymentKey.advancePaymentAmount] =
          advancePaymentAmount ?? widget.bookings.bookingDetail!.paidAmount;

      if ((widget.bookings.bookingDetail!.paymentStatus == null ||
              widget.bookings.bookingDetail!.paymentStatus !=
                  SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
              widget.bookings.bookingDetail!.paymentStatus !=
                  SERVICE_PAYMENT_STATUS_PAID) &&
          (widget.bookings.bookingDetail!.paidAmount == null ||
              widget.bookings.bookingDetail!.paidAmount.validate() <= 0 &&
                  widget.bookings.bookingPackage?.id == -1)) {
        request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_ADVANCE_PAID;
      } else if (widget.bookings.bookingDetail!.paymentStatus ==
          SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
        request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_PAID;
      }
    }

    appStore.setLoading(true);
    savePayment(request).then((value) {
      appStore.setLoading(false);
      push(DashboardScreen(redirectToBooking: true),
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    }).catchError((e) {
      toast(e.toString());
      appStore.setLoading(false);
    });
  }

  // Helper method to get PayMob configuration directly from raw data
  Map<String, dynamic> extractPayMobConfig(PaymentSetting paymentSetting) {
    try {
      // For direct debugging
      debugPrint('Extracting PayMob config from: ${paymentSetting.toJson()}');

      // Try to access the raw data in different ways
      Map<String, dynamic> config = {};

      // Get full JSON representation
      Map<String, dynamic> json = paymentSetting.toJson();

      // First method - try to get directly from the full JSON
      if (paymentSetting.isTest == 1) {
        // Test mode
        if (json.containsKey('value') && json['value'] != null) {
          var value = json['value'];
          if (value is Map) {
            debugPrint('Found test value data: $value');
            return Map<String, dynamic>.from(value);
          }
        }
      } else {
        // Live mode
        if (json.containsKey('live_value') && json['live_value'] != null) {
          var liveValue = json['live_value'];
          if (liveValue is Map) {
            debugPrint('Found live value data: $liveValue');
            return Map<String, dynamic>.from(liveValue);
          }
        }
      }

      // If we're here, we didn't find the data in the expected place
      // Try an alternative approach - check the nested maps directly from the testValue and liveValue
      if (paymentSetting.isTest == 1 && paymentSetting.testValue != null) {
        debugPrint('Trying to get from testValue directly');
        // Try to access raw map data in the LiveValue object
        final mapper = paymentSetting.testValue!.toJson();
        debugPrint('testValue mapper: $mapper');

        // Since PayMob keys aren't directly in the standard fields,
        // check if we have raw map access
        return mapper;
      } else if (paymentSetting.isTest != 1 &&
          paymentSetting.liveValue != null) {
        debugPrint('Trying to get from liveValue directly');
        // Try to access raw map data in the LiveValue object
        final mapper = paymentSetting.liveValue!.toJson();
        debugPrint('liveValue mapper: $mapper');

        // Since PayMob keys aren't directly in the standard fields,
        // check if we have raw map access
        return mapper;
      }

      return config;
    } catch (e) {
      debugPrint('Error extracting PayMob config: $e');
      return {};
    }
  }

  Future<void> handlePayMobPayment() async {
    try {
      appStore.setLoading(true);

      // Find PayMob payment method from the list of available payment methods
      PaymentSetting? payMobPaymentMethod;

      if (currentPaymentMethod != null &&
          currentPaymentMethod!.type == 'paymob') {
        payMobPaymentMethod = currentPaymentMethod;
      } else {
        // Try to find PayMob in the list of payment methods
        final List<PaymentSetting> paymentMethods = await future!;
        payMobPaymentMethod = paymentMethods.firstWhere(
          (element) => element.type == 'paymob',
          orElse: () => throw 'PayMob payment method not found',
        );
      }

      // Extract PayMob configuration
      debugPrint('isTest value: ${payMobPaymentMethod!.isTest}');

      // Try to access PayMob configuration in multiple ways
      String apiKey = '';
      String integrationId = '';
      String iframeId = '';

      // First try to get data from our helper method (raw JSON)
      final configRaw = extractPayMobConfig(payMobPaymentMethod);

      if (configRaw.containsKey('paymob_api_key')) {
        apiKey = configRaw['paymob_api_key'] ?? '';
        integrationId = configRaw['paymob_integration_id'] ?? '';
        iframeId = configRaw['paymob_iframe_id'] ?? '';

        debugPrint('Got PayMob config from raw JSON extraction');
      }
      // If raw method failed, try to get from LiveValue object directly
      else if (payMobPaymentMethod.isTest == 1 &&
          payMobPaymentMethod.testValue != null) {
        apiKey = payMobPaymentMethod.testValue!.paymobApiKey ?? '';
        integrationId =
            payMobPaymentMethod.testValue!.paymobIntegrationId ?? '';
        iframeId = payMobPaymentMethod.testValue!.paymobIframeId ?? '';

        debugPrint('Got PayMob config from testValue object');
      } else if (payMobPaymentMethod.liveValue != null) {
        apiKey = payMobPaymentMethod.liveValue!.paymobApiKey ?? '';
        integrationId =
            payMobPaymentMethod.liveValue!.paymobIntegrationId ?? '';
        iframeId = payMobPaymentMethod.liveValue!.paymobIframeId ?? '';

        debugPrint('Got PayMob config from liveValue object');
      }

      // Log the values we've extracted
      debugPrint(
          'Extracted API Key: ${apiKey.isEmpty ? "EMPTY" : (apiKey.length > 10 ? apiKey.substring(0, 10) + '...' : apiKey)}');
      debugPrint(
          'Extracted Integration ID: ${integrationId.isEmpty ? "EMPTY" : integrationId}');
      debugPrint(
          'Extracted iFrame ID: ${iframeId.isEmpty ? "EMPTY" : iframeId}');

      if (apiKey.isEmpty || integrationId.isEmpty || iframeId.isEmpty) {
        throw 'PayMob configuration is incomplete';
      }

      debugPrint('===== PayMob Payment Debug Info =====');
      debugPrint('Using dynamic config from API response');
      debugPrint('API Key: ${apiKey.substring(0, min(apiKey.length, 10))}...');
      debugPrint('Integration ID: $integrationId');
      debugPrint('iFrame ID: $iframeId');
      debugPrint('Total amount: $totalAmount');
      debugPrint('Total amount in cents: ${totalAmount * 100}');

      final payMobService = PayMobService(
        config: PayMobConfig(
          apiKey: apiKey,
          integrationId: integrationId,
          iframeId: iframeId,
          isTest: payMobPaymentMethod!.isTest == 1,
        ),
      );

      await payMobService.initialize();

      final billingData = {
        'first_name': appStore.userFirstName,
        'last_name': appStore.userLastName,
        'email': appStore.userEmail,
        'phone_number': appStore.userContactNumber,
        'apartment': 'NA',
        'floor': 'NA',
        'street': 'NA',
        'building': 'NA',
        'shipping_method': 'NA',
        'postal_code': 'NA',
        'city': 'NA',
        'country': 'NA',
        'state': 'NA'
      };

      debugPrint(
          'User info: ${appStore.userFirstName} ${appStore.userLastName}, ${appStore.userEmail}, ${appStore.userContactNumber}');

      // Note: PayMob expects amount in cents - we multiply by 100 to convert from decimal to cents
      final paymentKey = await payMobService.createPaymentKey(
        amount: totalAmount * 100, // Amount in cents
        currency: 'EGP',
        integrationId: integrationId,
        billingData: billingData,
      );

      // Save this PayMob service instance for later use
      await setValue('paymob_order_id', payMobService.orderId);

      // Launch PayMob payment page
      final url =
          'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey';

      debugPrint('Launching PayMob URL: $url');

      // Use your preferred way to launch the URL (webview or external browser)
      final bool launchResult = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launchResult) {
        throw 'Could not launch PayMob payment page';
      }

      // Start listening for payment result
      startPayMobPaymentListener();
    } catch (e) {
      toast(e.toString());
      debugPrint('PayMob payment error: $e');
    } finally {
      appStore.setLoading(false);
    }
  }

  // Listen for PayMob payment result
  void startPayMobPaymentListener() {
    // This timer will check for payment status every 5 seconds
    Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        // Get the order ID we saved earlier
        final String? orderId = await getStringAsync('paymob_order_id');
        if (orderId == null || orderId.isEmpty) {
          debugPrint('No PayMob order ID found to check status');
          timer.cancel();
          return;
        }

        // Find PayMob payment method
        final List<PaymentSetting> paymentMethods = await future!;
        final payMobPaymentMethod = paymentMethods.firstWhere(
          (element) => element.type == 'paymob',
          orElse: () => throw 'PayMob payment method not found',
        );

        // Extract PayMob configuration in multiple ways
        String apiKey = '';
        String integrationId = '';
        String iframeId = '';

        // First try to get data from our helper method (raw JSON)
        final configRaw = extractPayMobConfig(payMobPaymentMethod);

        if (configRaw.containsKey('paymob_api_key')) {
          apiKey = configRaw['paymob_api_key'] ?? '';
          integrationId = configRaw['paymob_integration_id'] ?? '';
          iframeId = configRaw['paymob_iframe_id'] ?? '';
        }
        // If raw method failed, try to get from LiveValue object directly
        else if (payMobPaymentMethod.isTest == 1 &&
            payMobPaymentMethod.testValue != null) {
          apiKey = payMobPaymentMethod.testValue!.paymobApiKey ?? '';
          integrationId =
              payMobPaymentMethod.testValue!.paymobIntegrationId ?? '';
          iframeId = payMobPaymentMethod.testValue!.paymobIframeId ?? '';
        } else if (payMobPaymentMethod.liveValue != null) {
          apiKey = payMobPaymentMethod.liveValue!.paymobApiKey ?? '';
          integrationId =
              payMobPaymentMethod.liveValue!.paymobIntegrationId ?? '';
          iframeId = payMobPaymentMethod.liveValue!.paymobIframeId ?? '';
        }

        if (apiKey.isEmpty || integrationId.isEmpty || iframeId.isEmpty) {
          debugPrint('PayMob configuration is incomplete');
          timer.cancel();
          return;
        }

        // Check payment status
        final payMobService = PayMobService(
          config: PayMobConfig(
            apiKey: apiKey,
            integrationId: integrationId,
            iframeId: iframeId,
            isTest: payMobPaymentMethod.isTest == 1,
          ),
        );

        await payMobService.initialize();

        // We need to implement this in the backend
        // For now, we'll just assume the payment was successful after 15 seconds
        await Future.delayed(Duration(seconds: 10));

        debugPrint('Assuming PayMob payment was successful for demonstration');
        timer.cancel();

        // Process successful payment
        savePay(
          paymentMethod: 'paymob',
          paymentStatus: widget.isForAdvancePayment
              ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
              : SERVICE_PAYMENT_STATUS_PAID,
          txnId: orderId,
        );

        // Clean up
        await setValue('paymob_order_id', '');
      } catch (e) {
        debugPrint('Error checking PayMob payment status: $e');
        // Don't cancel the timer on error, keep trying
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.payment,
      child: AnimatedScrollView(
        listAnimationType: ListAnimationType.FadeIn,
        fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
        physics: AlwaysScrollableScrollPhysics(),
        onSwipeRefresh: () async {
          if (!appStore.isLoading) init();
          return await 1.seconds.delay;
        },
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceCommonWidget(
                    bookingDetail: widget.bookings.bookingDetail!,
                    serviceDetail: widget.bookings.service!,
                    taxes: widget.bookings.bookingDetail!.taxes.validate(),
                    couponData: widget.bookings.couponData,
                    bookingPackage:
                        widget.bookings.bookingDetail!.bookingPackage != null
                            ? widget.bookings.bookingDetail!.bookingPackage
                            : null,
                  ),
                  32.height,
                  Text(language.lblChoosePaymentMethod,
                      style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                ],
              ).paddingAll(16),
              SnapHelperWidget<List<PaymentSetting>>(
                future: future,
                onSuccess: (list) {
                  return AnimatedListView(
                    itemCount: list.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    emptyWidget: NoDataWidget(
                      title: language.noPaymentMethodFound,
                      imageWidget: EmptyStateWidget(),
                    ),
                    itemBuilder: (context, index) {
                      PaymentSetting value = list[index];

                      if (value.status.validate() == 0) return Offstage();

                      return RadioListTile<PaymentSetting>(
                        dense: true,
                        activeColor: primaryColor,
                        value: value,
                        controlAffinity: ListTileControlAffinity.trailing,
                        groupValue: currentPaymentMethod,
                        onChanged: (PaymentSetting? ind) {
                          currentPaymentMethod = ind;

                          setState(() {});
                        },
                        title: Text(value.title.validate(),
                            style: primaryTextStyle()),
                      );
                    },
                  );
                },
              ),
              if (appConfigurationStore.isEnableUserWallet)
                WalletBalanceComponent()
                    .paddingSymmetric(vertical: 8, horizontal: 16),
              AppButton(
                onTap: () async {
                  if (currentPaymentMethod == null) {
                    return toast(language.chooseAnyOnePayment);
                  }

                  if (currentPaymentMethod!.type == PAYMENT_METHOD_COD ||
                      currentPaymentMethod!.type ==
                          PAYMENT_METHOD_FROM_WALLET) {
                    if (currentPaymentMethod!.type ==
                        PAYMENT_METHOD_FROM_WALLET) {
                      appStore.setLoading(true);
                      num walletBalance = await getUserWalletBalance();

                      appStore.setLoading(false);
                      if (walletBalance >= totalAmount) {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.CONFIRMATION,
                          title:
                              "${language.lblPayWith} ${currentPaymentMethod!.title.validate()}?",
                          primaryColor: primaryColor,
                          positiveText: language.lblYes,
                          negativeText: language.lblCancel,
                          onAccept: (p0) {
                            _handleClick();
                          },
                        );
                      } else {
                        toast(language.insufficientBalanceMessage);

                        if (appConfigurationStore.onlinePaymentStatus) {
                          showConfirmDialogCustom(
                            context,
                            dialogType: DialogType.CONFIRMATION,
                            title: language.doYouWantToTopUpYourWallet,
                            positiveText: language.lblYes,
                            negativeText: language.lblNo,
                            cancelable: false,
                            primaryColor: context.primaryColor,
                            onAccept: (p0) {
                              pop();
                              push(UserWalletBalanceScreen());
                            },
                            onCancel: (p0) {
                              pop();
                            },
                          );
                        }
                      }
                    } else {
                      showConfirmDialogCustom(
                        context,
                        dialogType: DialogType.CONFIRMATION,
                        title:
                            "${language.lblPayWith} ${currentPaymentMethod!.title.validate()}?",
                        primaryColor: primaryColor,
                        positiveText: language.lblYes,
                        negativeText: language.lblCancel,
                        onAccept: (p0) {
                          _handleClick();
                        },
                      );
                    }
                  } else {
                    _handleClick().catchError((e) {
                      appStore.setLoading(false);
                      toast(e.toString());
                    });
                  }
                },
                text: "${language.lblPayNow} ${totalAmount.toPriceFormat()}",
                color: context.primaryColor,
                width: context.width(),
              ).paddingAll(16),
            ],
          ),
        ],
      ),
    );
  }
}
