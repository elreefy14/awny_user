import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/model/device_model.dart';
import 'package:booking_system_flutter/services/device_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';

class DeviceTelemetryScreen extends StatefulWidget {
  final String deviceId;

  const DeviceTelemetryScreen({Key? key, required this.deviceId})
      : super(key: key);

  @override
  _DeviceTelemetryScreenState createState() => _DeviceTelemetryScreenState();
}

class _DeviceTelemetryScreenState extends State<DeviceTelemetryScreen>
    with TickerProviderStateMixin {
  DeviceModel? _deviceData;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _deviceSubscription;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    print(
        '🚀 DeviceTelemetryScreen initialized for device: ${widget.deviceId}');

    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadDeviceData();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadDeviceData() {
    print('🔄 Loading device data for: ${widget.deviceId}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _deviceSubscription?.cancel();
    _deviceSubscription = DeviceService.getDeviceStream(widget.deviceId).listen(
      (deviceData) {
        print('📱 Device data received: ${deviceData?.deviceId}');
        setState(() {
          _deviceData = deviceData;
          _isLoading = false;
          _error = null;
        });

        // Start animations when data is loaded
        _fadeController.forward();
        _slideController.forward();
      },
      onError: (error) {
        print('❌ Error loading device data: $error');
        setState(() {
          _error = 'حدث خطأ في تحميل بيانات الجهاز: $error';
          _isLoading = false;
        });
      },
    );
  }

  Widget _buildModernSensorCard(
      String title, dynamic value, String unit, IconData icon, Color color,
      {bool isStatus = false}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: modernCardShadowColor,
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with animated background
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                16.height,

                // Title with improved contrast
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        Colors.white, // Changed to white for better visibility
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                8.height,

                // Value with animated appearance
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isStatus
                                ? (value ?? 'N/A')
                                : (value?.toString() ?? 'N/A'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // Changed to white for better visibility
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!isStatus && unit.isNotEmpty) ...[
                            4.width,
                            Text(
                              unit,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    color.withOpacity(0.9), // Made more visible
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatusBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            statusConnectedColor.withOpacity(0.15),
            statusConnectedColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusConnectedColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusConnectedColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated status indicator with pulse effect
          TweenAnimationBuilder<double>(
            duration: Duration(seconds: 2),
            tween: Tween(begin: 0.8, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusConnectedColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusConnectedColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          16.width,
          Expanded(
            child: Text(
              'متصل - البيانات محدثة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Changed to white for better visibility
                letterSpacing: 0.5,
              ),
            ),
          ),
          Icon(
            Icons.wifi,
            color: statusConnectedColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          12.width,
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed to white for better visibility
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Add a subtle icon
          Icon(
            Icons.sensors,
            color: primaryColor.withOpacity(0.8), // Made more visible
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    if (_deviceData?.settings == null) return SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    12.width,
                    Text(
                      'إعدادات الجهاز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .white, // Changed to white for better visibility
                      ),
                    ),
                  ],
                ),
                20.height,
                _buildSettingRow('الحد الأقصى للجهد',
                    '${_deviceData!.settings.highVolt} V', Icons.flash_on),
                _buildSettingRow('الحد الأدنى للجهد',
                    '${_deviceData!.settings.lowVolt} V', Icons.flash_off),
                _buildSettingRow(
                    'الحد الأقصى للتيار',
                    '${_deviceData!.settings.maxCurrent} A',
                    Icons.electric_bolt),
                _buildSettingRow(
                    'وقت فتح الباب',
                    '${_deviceData!.settings.doorOpenTime} ثانية',
                    Icons.door_front_door),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor.withOpacity(0.7),
                    size: 16,
                  ),
                ),
                12.width,
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white
                          .withOpacity(0.9), // Changed to white with opacity
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateCard() {
    if (_deviceData?.state == null) return SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusInfoColor.withOpacity(0.1),
                  statusInfoColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusInfoColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusInfoColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusInfoColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: statusInfoColor,
                        size: 20,
                      ),
                    ),
                    12.width,
                    Text(
                      'حالة الجهاز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .white, // Changed to white for better visibility
                      ),
                    ),
                  ],
                ),
                20.height,
                if (_deviceData!.state.lowT1 != null)
                  _buildStateRow(
                      'T1 الأدنى', _deviceData!.state.lowT1!, Icons.thermostat),
                if (_deviceData!.state.lowT2 != null)
                  _buildStateRow('T2 الأدنى', '${_deviceData!.state.lowT2}°C',
                      Icons.thermostat),
                if (_deviceData!.state.lowT3 != null)
                  _buildStateRow('T3 الأدنى', '${_deviceData!.state.lowT3}°C',
                      Icons.thermostat),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateRow(String label, String value, IconData icon) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusInfoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: statusInfoColor.withOpacity(0.7),
                    size: 16,
                  ),
                ),
                12.width,
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white
                          .withOpacity(0.9), // Changed to white with opacity
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusInfoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'جهاز ${widget.deviceId}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: primaryColor,
              ),
              onPressed: () {
                // Add haptic feedback
                HapticFeedback.lightImpact();
                _loadDeviceData();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 3,
                        ),
                      );
                    },
                  ),
                  16.height,
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          'جاري تحميل بيانات الجهاز...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors
                                .white, // Changed to white for better visibility
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                      16.height,
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade300, // Made more visible
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      24.height,
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 1200),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _loadDeviceData();
                              },
                              icon: Icon(Icons.refresh),
                              label: Text('إعادة المحاولة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: primaryColor.withOpacity(0.3),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : _deviceData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.device_unknown,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                          16.height,
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 1000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, opacity, child) {
                              return Opacity(
                                opacity: opacity,
                                child: Text(
                                  'لا توجد بيانات للجهاز',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // Changed to white for better visibility
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          8.height,
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 1200),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, opacity, child) {
                              return Opacity(
                                opacity: opacity,
                                child: Text(
                                  'تأكد من أن معرف الجهاز صحيح وأن الجهاز متصل',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(
                                        0.8), // Changed to white with opacity
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                          24.height,
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 1400),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, opacity, child) {
                              return Opacity(
                                opacity: opacity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _loadDeviceData();
                                  },
                                  icon: Icon(Icons.refresh),
                                  label: Text('إعادة المحاولة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Modern Status Banner
                              _buildModernStatusBanner(),
                              24.height,

                              // Sensors Section
                              _buildSectionHeader('قراءات المستشعرات'),
                              GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                                children: [
                                  _buildModernSensorCard(
                                    'التيار',
                                    _deviceData!.sensors.current
                                        .toStringAsFixed(1),
                                    'A',
                                    Icons.electric_bolt,
                                    sensorCurrentColor,
                                  ),
                                  _buildModernSensorCard(
                                    'الجهد',
                                    _deviceData!.sensors.volt
                                        .toStringAsFixed(0),
                                    'V',
                                    Icons.power,
                                    sensorVoltageColor,
                                  ),
                                  _buildModernSensorCard(
                                    'الرطوبة',
                                    _deviceData!.sensors.humidity.toString(),
                                    '%',
                                    Icons.water_drop,
                                    sensorHumidityColor,
                                  ),
                                  _buildModernSensorCard(
                                    'الباب',
                                    _deviceData!.sensors.door == 1
                                        ? 'مفتوح'
                                        : 'مغلق',
                                    '',
                                    Icons.door_front_door,
                                    _deviceData!.sensors.door == 1
                                        ? sensorDoorOpenColor
                                        : sensorDoorClosedColor,
                                    isStatus: true,
                                  ),
                                  _buildModernSensorCard(
                                    'T2',
                                    _deviceData!.sensors.t2
                                            ?.toStringAsFixed(1) ??
                                        'N/A',
                                    '°C',
                                    Icons.thermostat,
                                    sensorTemp2Color,
                                  ),
                                  _buildModernSensorCard(
                                    'T3',
                                    _deviceData!.sensors.t3
                                            ?.toStringAsFixed(1) ??
                                        'N/A',
                                    '°C',
                                    Icons.thermostat,
                                    sensorTemp3Color,
                                  ),
                                ],
                              ),
                              24.height,

                              // Settings Card
                              _buildSettingsCard(),
                              16.height,

                              // State Card
                              _buildStateCard(),
                              24.height,
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
