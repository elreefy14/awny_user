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
import 'dart:convert';

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

    // Add comprehensive debug logging for payment gateways
    future!.then((paymentSettings) {
      debugPrint('');
      debugPrint(
          '═══════════════════════════════════════════════════════════════');
      debugPrint(
          '                    PAYMENT GATEWAYS DEBUG                     ');
      debugPrint(
          '═══════════════════════════════════════════════════════════════');
      debugPrint('Total payment gateways received: ${paymentSettings.length}');
      debugPrint('');

      for (var i = 0; i < paymentSettings.length; i++) {
        final setting = paymentSettings[i];
        debugPrint(
            '┌─────────────────────────────────────────────────────────────');
        debugPrint('│ Payment Gateway #${i + 1}');
        debugPrint(
            '├─────────────────────────────────────────────────────────────');
        debugPrint('│ ID: ${setting.id}');
        debugPrint('│ Title: ${setting.title}');
        debugPrint('│ Type: ${setting.type}');
        debugPrint('│ Status: ${setting.status}');
        debugPrint('│ Is Test: ${setting.isTest}');
        debugPrint(
            '└─────────────────────────────────────────────────────────────');

        // Special handling for PayMob gateway
        if (setting.type == 'paymob') {
          debugPrint('');
          debugPrint('🔥🔥🔥 PAYMOB GATEWAY FOUND - DETAILED ANALYSIS 🔥🔥🔥');
          debugPrint('');

          // Full JSON representation
          var settingJson = setting.toJson();
          debugPrint('📋 FULL PAYMOB SETTING JSON:');
          debugPrint('${jsonEncode(settingJson)}');
          debugPrint('');

          // Test Value Analysis
          if (setting.testValue != null) {
            debugPrint('🧪 TEST VALUE ANALYSIS:');
            debugPrint('  testValue exists: ✅');
            var testJson = setting.testValue!.toJson();
            debugPrint('  Full testValue JSON: ${jsonEncode(testJson)}');
            debugPrint(
                '  PayMob API Key: ${setting.testValue!.paymobApiKey ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Integration ID: ${setting.testValue!.paymobIntegrationId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob iFrame ID: ${setting.testValue!.paymobIframeId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Wallet Integration ID: ${setting.testValue!.paymobWalletIntegrationId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Wallet iFrame ID: ${setting.testValue!.paymobWalletIframeId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob HMAC: ${setting.testValue!.paymobHmac ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Callback URL: ${setting.testValue!.paymobCallbackUrl ?? "❌ NULL"}');
          } else {
            debugPrint('🧪 TEST VALUE: ❌ NULL');
          }
          debugPrint('');

          // Live Value Analysis
          if (setting.liveValue != null) {
            debugPrint('🚀 LIVE VALUE ANALYSIS:');
            debugPrint('  liveValue exists: ✅');
            var liveJson = setting.liveValue!.toJson();
            debugPrint('  Full liveValue JSON: ${jsonEncode(liveJson)}');
            debugPrint(
                '  PayMob API Key: ${setting.liveValue!.paymobApiKey ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Integration ID: ${setting.liveValue!.paymobIntegrationId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob iFrame ID: ${setting.liveValue!.paymobIframeId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Wallet Integration ID: ${setting.liveValue!.paymobWalletIntegrationId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Wallet iFrame ID: ${setting.liveValue!.paymobWalletIframeId ?? "❌ NULL"}');
            debugPrint(
                '  PayMob HMAC: ${setting.liveValue!.paymobHmac ?? "❌ NULL"}');
            debugPrint(
                '  PayMob Callback URL: ${setting.liveValue!.paymobCallbackUrl ?? "❌ NULL"}');
          } else {
            debugPrint('🚀 LIVE VALUE: ❌ NULL');
          }
          debugPrint('');

          // Raw JSON Value Analysis
          if (settingJson.containsKey('value')) {
            debugPrint('📦 RAW VALUE FIELD ANALYSIS:');
            final valueData = settingJson['value'];
            debugPrint('  Raw value type: ${valueData.runtimeType}');
            debugPrint('  Raw value content: ${jsonEncode(valueData)}');

            if (valueData is Map) {
              final valueMap = Map<String, dynamic>.from(valueData);
              debugPrint('  PayMob fields in raw value:');
              valueMap.forEach((key, value) {
                if (key.toLowerCase().contains('paymob')) {
                  debugPrint('    $key: $value');
                }
              });
            }
          } else {
            debugPrint('📦 RAW VALUE FIELD: ❌ NOT FOUND');
          }
          debugPrint('');

          // Raw Live Value Analysis
          if (settingJson.containsKey('live_value')) {
            debugPrint('📦 RAW LIVE_VALUE FIELD ANALYSIS:');
            final liveValueData = settingJson['live_value'];
            debugPrint('  Raw live_value type: ${liveValueData.runtimeType}');
            debugPrint(
                '  Raw live_value content: ${jsonEncode(liveValueData)}');

            if (liveValueData is Map) {
              final liveValueMap = Map<String, dynamic>.from(liveValueData);
              debugPrint('  PayMob fields in raw live_value:');
              liveValueMap.forEach((key, value) {
                if (key.toLowerCase().contains('paymob')) {
                  debugPrint('    $key: $value');
                }
              });
            }
          } else {
            debugPrint('📦 RAW LIVE_VALUE FIELD: ❌ NOT FOUND');
          }
          debugPrint('');

          // Configuration Extraction Test
          debugPrint('🔧 CONFIGURATION EXTRACTION TEST:');
          final extractedConfig = extractPayMobConfig(setting);
          debugPrint('  Extracted config: ${jsonEncode(extractedConfig)}');
          debugPrint('  Config keys found: ${extractedConfig.keys.toList()}');
          debugPrint(
              '  Has paymob_api_key: ${extractedConfig.containsKey('paymob_api_key') ? "✅" : "❌"}');
          debugPrint(
              '  Has paymob_integration_id: ${extractedConfig.containsKey('paymob_integration_id') ? "✅" : "❌"}');
          debugPrint(
              '  Has paymob_iframe_id: ${extractedConfig.containsKey('paymob_iframe_id') ? "✅" : "❌"}');
          debugPrint(
              '  Has paymob_wallet_integration_id: ${extractedConfig.containsKey('paymob_wallet_integration_id') ? "✅" : "❌"}');
          debugPrint(
              '  Has paymob_wallet_iframe_id: ${extractedConfig.containsKey('paymob_wallet_iframe_id') ? "✅" : "❌"}');

          debugPrint('');
          debugPrint('🔥🔥🔥 END PAYMOB ANALYSIS 🔥🔥🔥');
          debugPrint('');
        }
        debugPrint('');
      }

      debugPrint(
          '═══════════════════════════════════════════════════════════════');
      debugPrint(
          '                   END PAYMENT GATEWAYS DEBUG                  ');
      debugPrint(
          '═══════════════════════════════════════════════════════════════');
      debugPrint('');
    }).catchError((e) {
      debugPrint('❌ ERROR LOADING PAYMENT GATEWAYS: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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
      debugPrint('=== EXTRACTING PAYMOB CONFIG ===');
      debugPrint('PaymentSetting ID: ${paymentSetting.id}');
      debugPrint('PaymentSetting Title: ${paymentSetting.title}');
      debugPrint('PaymentSetting Type: ${paymentSetting.type}');
      debugPrint('PaymentSetting Status: ${paymentSetting.status}');
      debugPrint('PaymentSetting isTest: ${paymentSetting.isTest}');
      debugPrint('Full PaymentSetting JSON: ${paymentSetting.toJson()}');

      // Try to access the raw data in different ways
      Map<String, dynamic> config = {};

      // Get full JSON representation
      Map<String, dynamic> json = paymentSetting.toJson();

      // First method - try to get directly from the full JSON
      if (paymentSetting.isTest == 1) {
        // Test mode
        debugPrint('Using TEST mode configuration');
        if (json.containsKey('value') && json['value'] != null) {
          var value = json['value'];
          if (value is Map) {
            debugPrint('Found test value data: $value');
            return Map<String, dynamic>.from(value);
          }
        }
      } else {
        // Live mode
        debugPrint('Using LIVE mode configuration');
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
        debugPrint('Trying to get from testValue object directly');
        // Try to access raw map data in the LiveValue object
        final mapper = paymentSetting.testValue!.toJson();
        debugPrint('testValue mapper: $mapper');

        // Since PayMob keys aren't directly in the standard fields,
        // check if we have raw map access
        return mapper;
      } else if (paymentSetting.isTest != 1 &&
          paymentSetting.liveValue != null) {
        debugPrint('Trying to get from liveValue object directly');
        // Try to access raw map data in the LiveValue object
        final mapper = paymentSetting.liveValue!.toJson();
        debugPrint('liveValue mapper: $mapper');

        // Since PayMob keys aren't directly in the standard fields,
        // check if we have raw map access
        return mapper;
      }

      debugPrint('No PayMob configuration found in any expected location');
      return config;
    } catch (e) {
      debugPrint('Error extracting PayMob config: $e');
      return {};
    }
  }

  Future<void> handlePayMobPayment() async {
    try {
      appStore.setLoading(true);

      debugPrint('');
      debugPrint('🚀🚀🚀 STARTING PAYMOB PAYMENT PROCESS 🚀🚀🚀');
      debugPrint('');

      // Find PayMob payment method from the list of available payment methods
      PaymentSetting? payMobPaymentMethod;

      if (currentPaymentMethod != null &&
          currentPaymentMethod!.type == 'paymob') {
        payMobPaymentMethod = currentPaymentMethod;
        debugPrint('✅ Using current selected PayMob payment method');
      } else {
        // Try to find PayMob in the list of payment methods
        final List<PaymentSetting> paymentMethods = await future!;
        payMobPaymentMethod = paymentMethods.firstWhere(
          (element) => element.type == 'paymob',
          orElse: () => throw 'PayMob payment method not found',
        );
        debugPrint('✅ Found PayMob payment method from list');
      }

      debugPrint('');
      debugPrint('📊 PAYMOB PAYMENT METHOD DETAILS:');
      debugPrint('  ID: ${payMobPaymentMethod!.id}');
      debugPrint('  Title: ${payMobPaymentMethod.title}');
      debugPrint('  Type: ${payMobPaymentMethod.type}');
      debugPrint('  Status: ${payMobPaymentMethod.status}');
      debugPrint('  Is Test: ${payMobPaymentMethod.isTest}');
      debugPrint('');

      // Extract PayMob configuration
      debugPrint('🔧 EXTRACTING PAYMOB CONFIGURATION...');
      debugPrint('  Test mode check: isTest = ${payMobPaymentMethod.isTest}');

      // Try to access PayMob configuration in multiple ways
      String apiKey = '';
      List<String> integrationIds = [];
      String iframeId = '';

      debugPrint('');
      debugPrint('🔍 METHOD 1: EXTRACTING FROM RAW JSON...');
      // First try to get data from our helper method (raw JSON)
      final configRaw = extractPayMobConfig(payMobPaymentMethod);
      debugPrint('  Raw config extracted: ${jsonEncode(configRaw)}');
      debugPrint('  Raw config keys: ${configRaw.keys.toList()}');

      if (configRaw.containsKey('paymob_api_key')) {
        apiKey = configRaw['paymob_api_key'] ?? '';
        debugPrint(
            '  ✅ API Key found in raw config: ${apiKey.isNotEmpty ? "${apiKey.substring(0, min(10, apiKey.length))}..." : "EMPTY"}');

        // Handle integration_id - it's an array containing both card and wallet IDs
        var integrationIdRaw = configRaw['paymob_integration_id'];
        debugPrint(
            '  🔍 Integration ID raw value: $integrationIdRaw (type: ${integrationIdRaw.runtimeType})');

        // Parse the integration IDs array
        integrationIds = _parseIntegrationIds(integrationIdRaw);
        debugPrint('  ✅ Parsed Integration IDs: $integrationIds');

        iframeId = configRaw['paymob_iframe_id'] ?? '';
        debugPrint(
            '  ✅ iFrame ID: ${iframeId.isNotEmpty ? iframeId : "EMPTY"}');
        debugPrint('  ✅ Got PayMob config from raw JSON extraction');
      }
      // If raw method failed, try to get from LiveValue object directly
      else if (payMobPaymentMethod.isTest == 1 &&
          payMobPaymentMethod.testValue != null) {
        debugPrint('');
        debugPrint('🔍 METHOD 2: EXTRACTING FROM TEST VALUE OBJECT...');

        apiKey = payMobPaymentMethod.testValue!.paymobApiKey ?? '';
        debugPrint(
            '  ✅ API Key from testValue: ${apiKey.isNotEmpty ? "${apiKey.substring(0, min(10, apiKey.length))}..." : "EMPTY"}');

        // Handle integration_id array from testValue
        var integrationIdRaw =
            payMobPaymentMethod.testValue!.paymobIntegrationId;
        debugPrint('  🔍 Integration ID raw from testValue: $integrationIdRaw');

        // Parse the integration IDs array
        integrationIds = _parseIntegrationIds(integrationIdRaw);
        debugPrint(
            '  ✅ Parsed Integration IDs from testValue: $integrationIds');

        iframeId = payMobPaymentMethod.testValue!.paymobIframeId ?? '';
        debugPrint(
            '  ✅ iFrame ID from testValue: ${iframeId.isNotEmpty ? iframeId : "EMPTY"}');
        debugPrint('  ✅ Got PayMob config from testValue object');
      } else if (payMobPaymentMethod.liveValue != null) {
        debugPrint('');
        debugPrint('🔍 METHOD 3: EXTRACTING FROM LIVE VALUE OBJECT...');

        apiKey = payMobPaymentMethod.liveValue!.paymobApiKey ?? '';
        debugPrint(
            '  ✅ API Key from liveValue: ${apiKey.isNotEmpty ? "${apiKey.substring(0, min(10, apiKey.length))}..." : "EMPTY"}');

        // Handle integration_id array from liveValue
        var integrationIdRaw =
            payMobPaymentMethod.liveValue!.paymobIntegrationId;
        debugPrint('  🔍 Integration ID raw from liveValue: $integrationIdRaw');

        // Parse the integration IDs array
        integrationIds = _parseIntegrationIds(integrationIdRaw);
        debugPrint(
            '  ✅ Parsed Integration IDs from liveValue: $integrationIds');

        iframeId = payMobPaymentMethod.liveValue!.paymobIframeId ?? '';
        debugPrint(
            '  ✅ iFrame ID from liveValue: ${iframeId.isNotEmpty ? iframeId : "EMPTY"}');
        debugPrint('  ✅ Got PayMob config from liveValue object');
      }

      debugPrint('');
      debugPrint('📋 FINAL EXTRACTED CONFIGURATION SUMMARY:');
      debugPrint(
          '  API Key: ${apiKey.isEmpty ? "❌ EMPTY" : "✅ ${apiKey.substring(0, min(10, apiKey.length))}..."}');
      debugPrint(
          '  Integration IDs Array: ${integrationIds.isEmpty ? "❌ EMPTY" : "✅ $integrationIds"}');
      debugPrint('  Total Integration IDs: ${integrationIds.length}');
      debugPrint(
          '  iFrame ID: ${iframeId.isEmpty ? "❌ EMPTY" : "✅ $iframeId"}');
      debugPrint('');

      if (apiKey.isEmpty || integrationIds.isEmpty || iframeId.isEmpty) {
        debugPrint('❌ CONFIGURATION VALIDATION FAILED:');
        debugPrint('  API Key empty: ${apiKey.isEmpty}');
        debugPrint('  Integration IDs empty: ${integrationIds.isEmpty}');
        debugPrint('  iFrame ID empty: ${iframeId.isEmpty}');
        throw 'PayMob configuration is incomplete';
      }

      debugPrint('✅ CONFIGURATION VALIDATION PASSED');
      debugPrint('');

      // Validate integration IDs are valid integers
      debugPrint('🔢 VALIDATING INTEGRATION IDS AS INTEGERS...');
      List<String> validIntegrationIds = [];

      for (String id in integrationIds) {
        final int? integrationIdInt = int.tryParse(id.trim());
        if (integrationIdInt != null) {
          validIntegrationIds.add(id.trim());
          debugPrint('  ✅ Integration ID "$id" -> Valid: $integrationIdInt');
        } else {
          debugPrint('  ❌ Integration ID "$id" -> Invalid (not a number)');
        }
      }

      if (validIntegrationIds.isEmpty) {
        debugPrint('❌ VALIDATION FAILED: No valid integration IDs found');
        throw 'No valid integration IDs found in: $integrationIds';
      }

      debugPrint('✅ INTEGER VALIDATION PASSED');
      debugPrint('  Valid Integration IDs: $validIntegrationIds');
      debugPrint('');

      // Log the values we've extracted
      debugPrint('💰 PAYMENT DETAILS:');
      debugPrint('  Total amount: $totalAmount');
      debugPrint('  Amount in cents: ${totalAmount * 100}');
      debugPrint('  Currency: EGP');
      debugPrint('  Test mode: ${payMobPaymentMethod.isTest == 1}');
      debugPrint('');

      debugPrint('👤 USER BILLING INFO:');
      debugPrint('  First Name: ${appStore.userFirstName}');
      debugPrint('  Last Name: ${appStore.userLastName}');
      debugPrint('  Email: ${appStore.userEmail}');
      debugPrint('  Phone: ${appStore.userContactNumber}');
      debugPrint('');

      final payMobService = PayMobService(
        config: PayMobConfig(
          apiKey: apiKey,
          integrationId: validIntegrationIds.first, // Use first ID as primary
          iframeId: iframeId,
          allIntegrationIds: validIntegrationIds, // Pass the full array
          isTest: payMobPaymentMethod.isTest == 1,
        ),
      );

      debugPrint('🔧 INITIALIZING PAYMOB SERVICE...');
      await payMobService.initialize();
      debugPrint('✅ PayMob service initialized successfully');
      debugPrint('');

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

      debugPrint('📦 BILLING DATA PREPARED:');
      debugPrint('  ${jsonEncode(billingData)}');
      debugPrint('');

      // Create payment URL with all integration IDs (cards + wallets)
      debugPrint(
          '🏦 CREATING PAYMENT WITH ALL INTEGRATION IDS (CARDS + WALLETS)...');
      debugPrint('  Integration IDs array: $validIntegrationIds');
      debugPrint('  Primary iFrame ID: $iframeId');

      // Use the wallet-enabled method with all integration IDs
      final paymentUrl = await payMobService.createPaymentUrlWithWallets(
        amount: totalAmount * 100, // Amount in cents
        currency: 'EGP',
        billingData: billingData,
        primaryIframeId: iframeId,
      );

      debugPrint('✅ PayMob payment URL with all payment methods created');

      // Save this PayMob service instance for later use
      await setValue('paymob_order_id', payMobService.orderId);
      debugPrint('💾 Saved PayMob order ID: ${payMobService.orderId}');
      debugPrint('');

      debugPrint('🌐 LAUNCHING PAYMOB PAYMENT PAGE...');
      debugPrint('  Payment URL: $paymentUrl');
      debugPrint('');

      // Use your preferred way to launch the URL (webview or external browser)
      final bool launchResult = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launchResult) {
        debugPrint('❌ FAILED TO LAUNCH PAYMOB PAYMENT PAGE');
        throw 'Could not launch PayMob payment page';
      }

      debugPrint('✅ PayMob payment page launched successfully');
      debugPrint('🎯 Starting payment status listener...');

      // Start listening for payment result
      startPayMobPaymentListener();

      debugPrint('');
      debugPrint('🚀🚀🚀 PAYMOB PAYMENT PROCESS COMPLETED 🚀🚀🚀');
      debugPrint('');
    } catch (e) {
      debugPrint('');
      debugPrint('❌❌❌ PAYMOB PAYMENT ERROR ❌❌❌');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('');
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  // Helper method to parse integration IDs from various formats
  List<String> _parseIntegrationIds(dynamic integrationIdRaw) {
    debugPrint(
        '🔍 Parsing integration IDs from: $integrationIdRaw (type: ${integrationIdRaw.runtimeType})');

    List<String> integrationIds = [];

    if (integrationIdRaw == null) {
      debugPrint('  ⚠️ Integration ID is null');
      return integrationIds;
    }

    if (integrationIdRaw is List) {
      // If it's already a list, convert each item to string
      for (var item in integrationIdRaw) {
        String id = item.toString().trim();
        if (id.isNotEmpty) {
          integrationIds.add(id);
        }
      }
      debugPrint('  ✅ Parsed from List: $integrationIds');
    } else if (integrationIdRaw is String) {
      String rawString = integrationIdRaw.trim();

      // Check if it's a JSON array format like "[5005804 , 5005899 , 5005900]"
      if (rawString.startsWith('[') && rawString.endsWith(']')) {
        // Remove brackets and split by comma
        String cleanString = rawString.substring(1, rawString.length - 1);
        List<String> parts = cleanString.split(',');

        for (String part in parts) {
          String id = part.trim();
          if (id.isNotEmpty) {
            integrationIds.add(id);
          }
        }
        debugPrint('  ✅ Parsed from JSON array string: $integrationIds');
      } else if (rawString.contains(',')) {
        // If it contains commas but no brackets, split by comma
        List<String> parts = rawString.split(',');
        for (String part in parts) {
          String id = part.trim();
          if (id.isNotEmpty) {
            integrationIds.add(id);
          }
        }
        debugPrint('  ✅ Parsed from comma-separated string: $integrationIds');
      } else {
        // Single ID
        if (rawString.isNotEmpty) {
          integrationIds.add(rawString);
        }
        debugPrint('  ✅ Parsed as single ID: $integrationIds');
      }
    } else {
      // Try to convert to string and parse
      String stringValue = integrationIdRaw.toString();
      if (stringValue.isNotEmpty && stringValue != 'null') {
        integrationIds = _parseIntegrationIds(stringValue);
        debugPrint('  ✅ Converted to string and parsed: $integrationIds');
      }
    }

    debugPrint('  📋 Final parsed integration IDs: $integrationIds');
    return integrationIds;
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
        List<String> integrationIds = [];
        String iframeId = '';

        // First try to get data from our helper method (raw JSON)
        final configRaw = extractPayMobConfig(payMobPaymentMethod);

        if (configRaw.containsKey('paymob_api_key')) {
          apiKey = configRaw['paymob_api_key'] ?? '';
          integrationIds =
              _parseIntegrationIds(configRaw['paymob_integration_id']);
          iframeId = configRaw['paymob_iframe_id'] ?? '';
        }
        // If raw method failed, try to get from LiveValue object directly
        else if (payMobPaymentMethod.isTest == 1 &&
            payMobPaymentMethod.testValue != null) {
          apiKey = payMobPaymentMethod.testValue!.paymobApiKey ?? '';

          // Handle integration_id array from testValue
          var integrationIdRaw =
              payMobPaymentMethod.testValue!.paymobIntegrationId;
          integrationIds = _parseIntegrationIds(integrationIdRaw);

          iframeId = payMobPaymentMethod.testValue!.paymobIframeId ?? '';
          debugPrint('Got PayMob config from testValue object');
        } else if (payMobPaymentMethod.liveValue != null) {
          apiKey = payMobPaymentMethod.liveValue!.paymobApiKey ?? '';

          // Handle integration_id array from liveValue
          var integrationIdRaw =
              payMobPaymentMethod.liveValue!.paymobIntegrationId;
          integrationIds = _parseIntegrationIds(integrationIdRaw);

          iframeId = payMobPaymentMethod.liveValue!.paymobIframeId ?? '';
          debugPrint('Got PayMob config from liveValue object');
        }

        if (apiKey.isEmpty || integrationIds.isEmpty || iframeId.isEmpty) {
          debugPrint('PayMob configuration is incomplete');
          timer.cancel();
          return;
        }

        // Check payment status
        final payMobService = PayMobService(
          config: PayMobConfig(
            apiKey: apiKey,
            integrationId: integrationIds.first, // Use first ID as primary
            iframeId: iframeId,
            allIntegrationIds: integrationIds, // Pass the full array
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
