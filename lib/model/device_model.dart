class DeviceModel {
  final String deviceId;
  final DeviceSensors sensors;
  final DeviceSettings settings;
  final DeviceState state;

  DeviceModel({
    required this.deviceId,
    required this.sensors,
    required this.settings,
    required this.state,
  });

  factory DeviceModel.fromJson(String deviceId, Map<String, dynamic> json) {
    try {
      print('🔧 Parsing DeviceModel for device: $deviceId');
      print('🔧 JSON keys: ${json.keys.toList()}');

      final sensors = DeviceSensors.fromJson(json['Sensors'] ?? {});
      print('✅ Sensors parsed successfully');

      final settings = DeviceSettings.fromJson(json['Setting'] ?? {});
      print('✅ Settings parsed successfully');

      final state = DeviceState.fromJson(json['State'] ?? {});
      print('✅ State parsed successfully');

      return DeviceModel(
        deviceId: deviceId,
        sensors: sensors,
        settings: settings,
        state: state,
      );
    } catch (e) {
      print('❌ Error in DeviceModel.fromJson: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'Sensors': sensors.toJson(),
      'Setting': settings.toJson(),
      'State': state.toJson(),
    };
  }
}

class DeviceSensors {
  final double current;
  final int door;
  final int humidity;
  final int mainRelay;
  final String? t1;
  final double? t2;
  final double? t3;
  final String? t4;
  final String? t5;
  final double volt;

  DeviceSensors({
    required this.current,
    required this.door,
    required this.humidity,
    required this.mainRelay,
    this.t1,
    this.t2,
    this.t3,
    this.t4,
    this.t5,
    required this.volt,
  });

  factory DeviceSensors.fromJson(Map<String, dynamic> json) {
    try {
      print('🔧 Parsing DeviceSensors');
      print('🔧 Sensors JSON keys: ${json.keys.toList()}');

      final current = (json['Current'] ?? 0.0).toDouble();
      print('✅ Current: $current');

      final door = json['Door'] ?? 0;
      print('✅ Door: $door');

      final humidity = json['Humidity'] ?? 0;
      print('✅ Humidity: $humidity');

      final mainRelay = json['Main Realy'] ?? 0;
      print('✅ MainRelay: $mainRelay');

      final t1 = _parseNullableString(json['T1']);
      print('✅ T1: $t1');

      final t2 = _parseNullableDouble(json['T2']);
      print('✅ T2: $t2');

      final t3 = _parseNullableDouble(json['T3']);
      print('✅ T3: $t3');

      final t4 = _parseNullableString(json['T4']);
      print('✅ T4: $t4');

      final t5 = _parseNullableString(json['T5']);
      print('✅ T5: $t5');

      final volt = (json['Volt'] ?? 0.0).toDouble();
      print('✅ Volt: $volt');

      return DeviceSensors(
        current: current,
        door: door,
        humidity: humidity,
        mainRelay: mainRelay,
        t1: t1,
        t2: t2,
        t3: t3,
        t4: t4,
        t5: t5,
        volt: volt,
      );
    } catch (e) {
      print('❌ Error in DeviceSensors.fromJson: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Helper method to parse nullable string values
  static String? _parseNullableString(dynamic value) {
    if (value == null || value == "Null" || value == "null") {
      return null;
    }
    return value.toString();
  }

  // Helper method to parse nullable double values
  static double? _parseNullableDouble(dynamic value) {
    if (value == null || value == "Null" || value == "null") {
      return null;
    }
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'Current': current,
      'Door': door,
      'Humidity': humidity,
      'Main Realy': mainRelay,
      'T1': t1,
      'T2': t2,
      'T3': t3,
      'T4': t4,
      'T5': t5,
      'Volt': volt,
    };
  }
}

class DeviceSettings {
  final int delay;
  final int doorOpenTime;
  final int highVolt;
  final int lowVolt;
  final int maxCurrent;
  final int setpointTime;
  final int t1Max;
  final int t2Max;

  DeviceSettings({
    required this.delay,
    required this.doorOpenTime,
    required this.highVolt,
    required this.lowVolt,
    required this.maxCurrent,
    required this.setpointTime,
    required this.t1Max,
    required this.t2Max,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      delay: json['Delay'] ?? 10,
      doorOpenTime: json['Door open Time'] ?? 5,
      highVolt: json['High Volt'] ?? 240,
      lowVolt: json['LOW Volt'] ?? 190,
      maxCurrent: json['Max Current'] ?? 20,
      setpointTime: json['Setpoint Time'] ?? 50,
      t1Max: json['T1 Max'] ?? 70,
      t2Max: json['T2 Max'] ?? 80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Delay': delay,
      'Door open Time': doorOpenTime,
      'High Volt': highVolt,
      'LOW Volt': lowVolt,
      'Max Current': maxCurrent,
      'Setpoint Time': setpointTime,
      'T1 Max': t1Max,
      'T2 Max': t2Max,
    };
  }
}

class DeviceState {
  final String? lowT1;
  final double? lowT2;
  final double? lowT3;
  final String? lowT4;
  final String? lowT5;

  DeviceState({
    this.lowT1,
    this.lowT2,
    this.lowT3,
    this.lowT4,
    this.lowT5,
  });

  factory DeviceState.fromJson(Map<String, dynamic> json) {
    return DeviceState(
      lowT1: DeviceSensors._parseNullableString(json['LOW T1']),
      lowT2: DeviceSensors._parseNullableDouble(json['LOW T2']),
      lowT3: DeviceSensors._parseNullableDouble(json['LOW T3']),
      lowT4: DeviceSensors._parseNullableString(json['LOW T4']),
      lowT5: DeviceSensors._parseNullableString(json['LOW T5']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LOW T1': lowT1,
      'LOW T2': lowT2,
      'LOW T3': lowT3,
      'LOW T4': lowT4,
      'LOW T5': lowT5,
    };
  }
}
