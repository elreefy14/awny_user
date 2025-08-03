import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/services/device_service.dart';
import 'package:booking_system_flutter/screens/device/device_telemetry_screen.dart';
import 'package:nb_utils/nb_utils.dart';

class LinkDeviceScreen extends StatefulWidget {
  @override
  _LinkDeviceScreenState createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _deviceIdController = TextEditingController();
  bool _isLoading = false;
  bool _showScanner = false;
  MobileScannerController? _scannerController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();

    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _scannerController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _linkDevice(String deviceId) async {
    if (deviceId.trim().isEmpty) {
      toast('يرجى إدخال معرف الجهاز');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Checking if device exists: ${deviceId.trim()}');
      final exists = await DeviceService.deviceExists(deviceId.trim());
      print('📊 Device exists: $exists');

      if (exists) {
        print('✅ Device found, navigating to telemetry screen');
        // Navigate to device telemetry screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DeviceTelemetryScreen(deviceId: deviceId.trim()),
          ),
        );
      } else {
        print('❌ Device not found');
        toast('الجهاز غير موجود أو معرف الجهاز غير صحيح');
      }
    } catch (e) {
      print('❌ Error linking device: $e');
      toast('حدث خطأ أثناء الاتصال بالجهاز: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _deviceIdController.text = code;
        _linkDevice(code);
        setState(() {
          _showScanner = false;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLightColor, // خلفية دافئة بدلاً من الداكنة
      appBar: AppBar(
        title: Text(
          'ربط الجهاز',
          style: TextStyle(
            color: appTextPrimaryColor, // لون النص بني داكن
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cardColor, // خلفية دافئة للـ AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: appTextPrimaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Header Section - ألوان عونني
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        awnyBrandOrange, // البرتقالي الأساسي
                        awnyBrandLightOrange, // البيج الفاتح
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: awnyBrandOrange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.device_hub_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      20.height,
                      Text(
                        'ربط جهاز جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      8.height,
                      Text(
                        'امسح رمز QR أو أدخل معرف الجهاز يدويًا',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                30.height,

                // QR Scanner Section
                if (_showScanner) ...[
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: awnyBrandTeal.withOpacity(0.5),
                          width: 2), // تركوازي عونني
                      boxShadow: [
                        BoxShadow(
                          color: awnyBrandTeal.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController!,
                            onDetect: _onQRCodeDetected,
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: awnyBrandBrown
                                    .withOpacity(0.9), // بني داكن عونني
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.white, size: 24),
                                onPressed: () {
                                  setState(() {
                                    _showScanner = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  20.height,
                ],

                // Manual Entry Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor, // لون كارت دافئ
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor), // حدود بيج فاتح
                    boxShadow: [
                      BoxShadow(
                        color: awnyBrandOrange.withOpacity(0.08),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: awnyBrandOrange, // البرتقالي الأساسي
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.keyboard_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          12.width,
                          Text(
                            'إدخال معرف الجهاز يدويًا',
                            style: TextStyle(
                              color: appTextPrimaryColor, // بني داكن
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      20.height,
                      Container(
                        decoration: BoxDecoration(
                          color: awnyNeutralColor, // لون محايد دافئ
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _deviceIdController,
                          style: TextStyle(
                              color: appTextPrimaryColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'معرف الجهاز',
                            hintStyle: TextStyle(
                                color: appTextSecondaryColor.withOpacity(0.7)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            prefixIcon: Icon(
                              Icons.device_hub_rounded,
                              color: awnyBrandOrange,
                            ),
                          ),
                          onSubmitted: (value) => _linkDevice(value),
                        ),
                      ),
                      20.height,
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              awnyBrandOrange, // البرتقالي الأساسي
                              awnyBrandOrange.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: awnyBrandOrange.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: _isLoading
                                ? null
                                : () => _linkDevice(_deviceIdController.text),
                            child: Center(
                              child: _isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        12.width,
                                        Text(
                                          'جاري التحقق...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'ربط الجهاز',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                20.height,

                // QR Scanner Button
                if (!_showScanner) ...[
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor, // لون كارت دافئ
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: awnyBrandTeal.withOpacity(0.08),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: awnyBrandTeal, // التركوازي
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            12.width,
                            Text(
                              'مسح رمز QR',
                              style: TextStyle(
                                color: appTextPrimaryColor, // بني داكن
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        20.height,
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                awnyBrandTeal, // التركوازي
                                awnyBrandTeal.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: awnyBrandTeal.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                setState(() {
                                  _showScanner = true;
                                });
                              },
                              child: Center(
                                child: Text(
                                  'فتح الماسح الضوئي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Help Section
                30.height,
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        awnyBrandLightOrange.withOpacity(0.2), // بيج فاتح شفاف
                        awnyBrandTeal.withOpacity(0.1), // تركوازي شفاف
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: awnyBrandLightOrange.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: awnyBrandOrange, // البرتقالي الأساسي
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          12.width,
                          Text(
                            'كيفية الربط',
                            style: TextStyle(
                              color: appTextPrimaryColor, // بني داكن
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      16.height,
                      _buildHelpItem('امسح رمز QR الموجود على الجهاز',
                          Icons.qr_code_rounded),
                      12.height,
                      _buildHelpItem('أو أدخل معرف الجهاز المكون من 8 أرقام',
                          Icons.keyboard_rounded),
                      12.height,
                      _buildHelpItem('تأكد من أن الجهاز متصل بالإنترنت',
                          Icons.wifi_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: awnyBrandOrange, // البرتقالي الأساسي
          size: 18,
        ),
        12.width,
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: appTextSecondaryColor, // بني ذهبي
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
