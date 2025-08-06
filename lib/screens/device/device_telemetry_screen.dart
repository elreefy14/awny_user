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

  // Modern color scheme
  final Color primaryOrange = Color(0xFFFF6B35);
  final Color lightOrange = Color(0xFFFF8A65);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final Color cardBackground = Colors.white;
  final Color textPrimary = Color(0xFF2C3E50);
  final Color textSecondary = Color(0xFF7F8C8D);
  final Color accentBlue = Color(0xFF3498DB);

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
      String title, dynamic value, String unit, IconData icon,
      {bool isStatus = false}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with modern styling
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryOrange, lightOrange],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          16.height,

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          8.height,

          // Value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isStatus ? (value ?? 'N/A') : (value?.toString() ?? 'N/A'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isStatus && unit.isNotEmpty) ...[
                4.width,
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryOrange, lightOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          16.width,
          Expanded(
            child: Text(
              'متصل - البيانات محدثة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Icon(
            Icons.wifi,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryOrange, lightOrange],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          12.width,
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    if (_deviceData?.settings == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings,
                  color: primaryOrange,
                  size: 20,
                ),
              ),
              12.width,
              Text(
                'إعدادات الجهاز',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          20.height,
          _buildSettingRow('الحد الأقصى للجهد',
              '${_deviceData!.settings.highVolt} V', Icons.flash_on),
          _buildSettingRow('الحد الأدنى للجهد',
              '${_deviceData!.settings.lowVolt} V', Icons.flash_off),
          _buildSettingRow('الحد الأقصى للتيار',
              '${_deviceData!.settings.maxCurrent} A', Icons.electric_bolt),
          _buildSettingRow(
              'وقت فتح الباب',
              '${_deviceData!.settings.doorOpenTime} ثانية',
              Icons.door_front_door),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: primaryOrange,
              size: 16,
            ),
          ),
          12.width,
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard() {
    if (_deviceData?.state == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: accentBlue,
                  size: 20,
                ),
              ),
              12.width,
              Text(
                'حالة الجهاز',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          20.height,
          if (_deviceData!.state.lowT1 != null)
            _buildStateRow(
                'T1 الأدنى', _deviceData!.state.lowT1!, Icons.thermostat),
          if (_deviceData!.state.lowT2 != null)
            _buildStateRow(
                'T2 الأدنى', '${_deviceData!.state.lowT2}°C', Icons.thermostat),
          if (_deviceData!.state.lowT3 != null)
            _buildStateRow(
                'T3 الأدنى', '${_deviceData!.state.lowT3}°C', Icons.thermostat),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: accentBlue,
              size: 16,
            ),
          ),
          12.width,
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'جهاز ${widget.deviceId}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: primaryOrange,
              ),
              onPressed: () {
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
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                    strokeWidth: 3,
                  ),
                  16.height,
                  Text(
                    'جاري تحميل بيانات الجهاز...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
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
                      16.height,
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      24.height,
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _loadDeviceData();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                )
              : _deviceData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: textSecondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.device_unknown,
                              size: 64,
                              color: textSecondary,
                            ),
                          ),
                          16.height,
                          Text(
                            'لا توجد بيانات للجهاز',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          8.height,
                          Text(
                            'تأكد من أن معرف الجهاز صحيح وأن الجهاز متصل',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          24.height,
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _loadDeviceData();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
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
                              // Status Card
                              _buildStatusCard(),
                              24.height,

                              // Sensors Section
                              _buildSectionHeader(
                                  'قراءات المستشعرات', Icons.sensors),
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
                                  ),
                                  _buildModernSensorCard(
                                    'الجهد',
                                    _deviceData!.sensors.volt
                                        .toStringAsFixed(0),
                                    'V',
                                    Icons.power,
                                  ),
                                  _buildModernSensorCard(
                                    'الرطوبة',
                                    _deviceData!.sensors.humidity.toString(),
                                    '%',
                                    Icons.water_drop,
                                  ),
                                  _buildModernSensorCard(
                                    'الباب',
                                    _deviceData!.sensors.door == 1
                                        ? 'مفتوح'
                                        : 'مغلق',
                                    '',
                                    Icons.door_front_door,
                                    isStatus: true,
                                  ),
                                  _buildModernSensorCard(
                                    'T2',
                                    _deviceData!.sensors.t2
                                            ?.toStringAsFixed(1) ??
                                        'N/A',
                                    '°C',
                                    Icons.thermostat,
                                  ),
                                  _buildModernSensorCard(
                                    'T3',
                                    _deviceData!.sensors.t3
                                            ?.toStringAsFixed(1) ??
                                        'N/A',
                                    '°C',
                                    Icons.thermostat,
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
