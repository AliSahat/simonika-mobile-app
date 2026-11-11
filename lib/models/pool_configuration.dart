import 'package:flutter/material.dart';

class ContainerConfig {
  const ContainerConfig({
    this.id,
    this.namaWadah,
    this.serial,
    this.kedalaman,
    this.jarakSensorDasar,
    this.batasIsiMulai,
    this.batasBuangBerhenti,
    this.batasIsiBerhenti,
    this.batasBuangMulai,
    this.modeAuto,
    this.isActive,
    this.mqttConnected,
    this.lastStatus,
    this.createdAt,
  });

  final String? id;
  final String? namaWadah;
  final String? serial;
  final double? kedalaman;
  final double? jarakSensorDasar;
  final double? batasIsiMulai;
  final double? batasBuangBerhenti;
  final double? batasIsiBerhenti;
  final double? batasBuangMulai;
  final bool? modeAuto;
  final bool? isActive;
  final bool? mqttConnected;
  final Map<String, dynamic>? lastStatus;
  final String? createdAt;

  double? get maxDepth => kedalaman;
  double? get sensorToBottom => jarakSensorDasar;
  double? get fillStart => batasIsiMulai;
  double? get drainStop => batasBuangBerhenti;
  double? get fillStop => batasIsiBerhenti;
  double? get drainStart => batasBuangMulai;

  factory ContainerConfig.fromJson(Map<String, dynamic> raw) {
    final normalized = normalizePoolMap(raw);
    return ContainerConfig(
      id: normalized['_id']?.toString(),
      namaWadah: normalized['namaWadah']?.toString(),
      serial: normalized['serial']?.toString(),
      kedalaman: _toDouble(normalized['kedalaman']),
      jarakSensorDasar: _toDouble(normalized['jarakSensorDasar']),
      batasIsiMulai: _toDouble(normalized['batasIsiMulai']),
      batasBuangBerhenti: _toDouble(normalized['batasBuangBerhenti']),
      batasIsiBerhenti: _toDouble(normalized['batasIsiBerhenti']),
      batasBuangMulai: _toDouble(normalized['batasBuangMulai']),
      modeAuto: normalized['modeAuto'] is bool
          ? normalized['modeAuto'] as bool
          : null,
      isActive: normalized['isActive'] is bool
          ? normalized['isActive'] as bool
          : null,
      mqttConnected: normalized['mqtt_connected'] is bool
          ? normalized['mqtt_connected'] as bool
          : null,
      lastStatus: normalized['last_status'] is Map
          ? Map<String, dynamic>.from(normalized['last_status'] as Map)
          : null,
      createdAt: normalized['createdAt']?.toString(),
    );
  }

  static Map<String, dynamic> normalizePoolMap(Map<String, dynamic> raw) {
    final base = raw['config'] is Map
        ? <String, dynamic>{
            ...raw,
            ...Map<String, dynamic>.from(raw['config'] as Map),
          }
        : Map<String, dynamic>.from(raw);

    final kedalaman = base['kedalaman'] ?? base['max_depth'];
    final jarakSensorDasar =
        base['jarakSensorDasar'] ?? base['sensor_to_bottom'];
    final batasIsiMulai = base['batasIsiMulai'] ?? base['fill_start'];
    final batasBuangBerhenti =
        base['batasBuangBerhenti'] ?? base['drain_stop'];
    final batasIsiBerhenti = base['batasIsiBerhenti'] ?? base['fill_stop'];
    final batasBuangMulai = base['batasBuangMulai'] ?? base['drain_start'];
    final modeAuto = _toBool(base['modeAuto'] ?? base['mode_auto']);
    final isActive = _toBool(base['isActive'] ?? base['is_active']);
    final serial =
        base['serial'] ?? base['deviceId'] ?? base['device_id'];
    final namaWadah =
        base['namaWadah'] ?? base['nama_wadah'] ?? base['name'];
    final id = base['_id'] ?? base['id'] ?? serial;
    final mqttConnected =
        _toBool(base['mqtt_connected'] ?? base['mqttConnected']);
    final rawLastStatus = base['last_status'] ?? base['lastStatus'];

    if (id != null) base['_id'] = id;
    if (namaWadah != null) base['namaWadah'] = namaWadah;
    if (serial != null) base['serial'] = serial;
    if (kedalaman != null) {
      base['kedalaman'] = kedalaman;
      base['max_depth'] = kedalaman;
    }
    if (jarakSensorDasar != null) {
      base['jarakSensorDasar'] = jarakSensorDasar;
      base['sensor_to_bottom'] = jarakSensorDasar;
    }
    if (batasIsiMulai != null) {
      base['batasIsiMulai'] = batasIsiMulai;
      base['fill_start'] = batasIsiMulai;
    }
    if (batasBuangBerhenti != null) {
      base['batasBuangBerhenti'] = batasBuangBerhenti;
      base['drain_stop'] = batasBuangBerhenti;
    }
    if (batasIsiBerhenti != null) {
      base['batasIsiBerhenti'] = batasIsiBerhenti;
      base['fill_stop'] = batasIsiBerhenti;
    }
    if (batasBuangMulai != null) {
      base['batasBuangMulai'] = batasBuangMulai;
      base['drain_start'] = batasBuangMulai;
    }
    if (modeAuto != null) {
      base['modeAuto'] = modeAuto;
      base['mode_auto'] = modeAuto;
    }
    if (isActive != null) {
      base['isActive'] = isActive;
      base['is_active'] = isActive;
    }
    if (mqttConnected != null) {
      base['mqtt_connected'] = mqttConnected;
      base['mqttConnected'] = mqttConnected;
    }
    if (rawLastStatus is Map) {
      final normalizedStatus = TelemetryLog.normalizeTelemetryMap(
          Map<String, dynamic>.from(rawLastStatus));
      base['last_status'] = normalizedStatus;
      base['lastStatus'] = normalizedStatus;
    }
    return base;
  }

  static double? _toDouble(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed?.isFinite == true ? parsed : null;
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }
}

class TelemetryLog {
  const TelemetryLog({
    this.id,
    this.serial,
    this.waterLevel,
    this.distance,
    this.fillValveOpen,
    this.drainValveOpen,
    this.controlState,
    this.sensorValid,
    this.createdAt,
  });

  final String? id;
  final String? serial;
  final double? waterLevel;
  final double? distance;
  final bool? fillValveOpen;
  final bool? drainValveOpen;
  final String? controlState;
  final bool? sensorValid;
  final String? createdAt;

  double? get sensorDistance => distance;
  bool? get inletValve => fillValveOpen;
  bool? get outletValve => drainValveOpen;
  String? get systemState => controlState;

  factory TelemetryLog.fromJson(Map<String, dynamic> raw) {
    final normalized = normalizeTelemetryMap(raw);
    return TelemetryLog(
      id: normalized['_id']?.toString(),
      serial: normalized['serial']?.toString(),
      waterLevel: ContainerConfig._toDouble(normalized['waterLevel']),
      distance: ContainerConfig._toDouble(normalized['distance']),
      fillValveOpen: normalized['fillValveOpen'] is bool
          ? normalized['fillValveOpen'] as bool
          : null,
      drainValveOpen: normalized['drainValveOpen'] is bool
          ? normalized['drainValveOpen'] as bool
          : null,
      controlState: normalized['controlState']?.toString(),
      sensorValid: normalized['sensorValid'] is bool
          ? normalized['sensorValid'] as bool
          : null,
      createdAt: normalized['createdAt']?.toString(),
    );
  }

  static Map<String, dynamic> normalizeTelemetryMap(Map<String, dynamic> raw) {
    final base = Map<String, dynamic>.from(raw);
    final waterLevel = base['waterLevel'] ?? base['water_level'];
    final distance = base['distance'] ?? base['sensor_distance'];
    final fillValveOpen =
        ContainerConfig._toBool(base['fillValveOpen'] ?? base['inlet_valve']);
    final drainValveOpen =
        ContainerConfig._toBool(base['drainValveOpen'] ?? base['outlet_valve']);
    final controlState = base['controlState'] ?? base['system_state'];
    final sensorValid =
        ContainerConfig._toBool(base['sensorValid'] ?? base['sensor_valid']);
    final serial =
        base['serial'] ?? base['deviceId'] ?? base['device_id'];
    final createdAt =
        base['createdAt'] ?? base['created_at'] ?? base['timestamp'] ?? base['updatedAt'] ?? base['updated_at'];

    if (waterLevel != null) {
      base['waterLevel'] = waterLevel;
      base['water_level'] = waterLevel;
    }
    if (distance != null) {
      base['distance'] = distance;
      base['sensor_distance'] = distance;
    }
    if (fillValveOpen != null) {
      base['fillValveOpen'] = fillValveOpen;
      base['inlet_valve'] = fillValveOpen;
    }
    if (drainValveOpen != null) {
      base['drainValveOpen'] = drainValveOpen;
      base['outlet_valve'] = drainValveOpen;
    }
    if (controlState != null) {
      base['controlState'] = controlState;
      base['system_state'] = controlState;
    }
    if (sensorValid != null) {
      base['sensorValid'] = sensorValid;
      base['sensor_valid'] = sensorValid;
    }
    if (serial != null) {
      base['serial'] = serial;
    }
    if (createdAt != null) {
      base['createdAt'] = createdAt;
    }
    return base;
  }

  static List<Map<String, dynamic>> extractTelemetryList(dynamic responseData) {
    if (responseData is! Map) return [];
    final rawData = responseData['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map>()
          .map((item) =>
              normalizeTelemetryMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (rawData is Map) {
      final list = rawData['telemetry'] ??
          rawData['readings'] ??
          rawData['logs'] ??
          rawData['history'] ??
          rawData['items'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) =>
                normalizeTelemetryMap(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (rawData['last_status'] is Map) {
        return [
          normalizeTelemetryMap(
              Map<String, dynamic>.from(rawData['last_status'] as Map))
        ];
      }
      if (rawData.containsKey('waterLevel') ||
          rawData.containsKey('water_level') ||
          rawData.containsKey('system_state') ||
          rawData.containsKey('controlState')) {
        return [normalizeTelemetryMap(Map<String, dynamic>.from(rawData))];
      }
    }
    return [];
  }
}

String? extractBackendErrorMessage(Object error) {
  try {
    final dynamic dyn = error;
    final dynamic response = dyn.response;
    final dynamic data = response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  } catch (_) {}
  return null;
}

class PoolConfigurationControllers {
  final namaWadah = TextEditingController();
  final serial = TextEditingController();
  final kedalaman = TextEditingController();
  final jarakSensorDasar = TextEditingController();
  final batasIsiMulai = TextEditingController();
  final batasIsiBerhenti = TextEditingController();
  final batasBuangMulai = TextEditingController();
  final batasBuangBerhenti = TextEditingController();

  List<TextEditingController> get all => [
        namaWadah,
        serial,
        kedalaman,
        jarakSensorDasar,
        batasIsiMulai,
        batasIsiBerhenti,
        batasBuangMulai,
        batasBuangBerhenti,
      ];

  void load(Map<String, dynamic> data) {
    final normalized = ContainerConfig.normalizePoolMap(data);
    namaWadah.text = _text(normalized['namaWadah']);
    serial.text = _text(normalized['serial']);
    kedalaman.text = _text(normalized['kedalaman']);
    jarakSensorDasar.text = _text(normalized['jarakSensorDasar']);
    batasIsiMulai.text = _text(normalized['batasIsiMulai']);
    batasIsiBerhenti.text = _text(normalized['batasIsiBerhenti']);
    batasBuangMulai.text = _text(normalized['batasBuangMulai']);
    batasBuangBerhenti.text = _text(normalized['batasBuangBerhenti']);
  }

  Map<String, dynamic> payload({required bool modeAuto, bool? isActive}) {
    final result = <String, dynamic>{
      'namaWadah': namaWadah.text.trim(),
      'serial': serial.text.trim(),
      'kedalaman': _jsonNumber(kedalaman.text),
      'jarakSensorDasar': _jsonNumber(jarakSensorDasar.text),
      'batasIsiMulai': _jsonNumber(batasIsiMulai.text),
      'batasIsiBerhenti': _jsonNumber(batasIsiBerhenti.text),
      'batasBuangMulai': _jsonNumber(batasBuangMulai.text),
      'batasBuangBerhenti': _jsonNumber(batasBuangBerhenti.text),
      'modeAuto': modeAuto,
    };
    if (isActive != null) result['isActive'] = isActive;
    return result;
  }

  bool get isComplete => all.every((controller) => controller.text.isNotEmpty);

  void dispose() {
    for (final controller in all) {
      controller.dispose();
    }
  }

  static String _text(dynamic value) => value == null ? '' : '$value';

  static num _jsonNumber(String value) {
    final number = double.parse(value.trim());
    return number == number.roundToDouble() ? number.toInt() : number;
  }
}

class PoolConfigurationValidator {
  const PoolConfigurationValidator(this.fields);

  final PoolConfigurationControllers fields;

  double? _number(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    return value?.isFinite == true ? value : null;
  }

  String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  // Retained as a small helper so every numeric field rejects empty/non-finite
  // values without ever converting them to zero.
  String? number(String? value, String label, {bool positive = false}) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite) return 'Masukkan angka yang valid';
    if (positive && parsed <= 0) return '$label harus lebih dari 0 cm';
    return null;
  }

  String? kedalaman(String? value) {
    final basic = number(value, 'Kedalaman wadah', positive: true);
    if (basic != null) return basic;
    final buangMulai = _number(fields.batasBuangMulai);
    final depth = _number(fields.kedalaman)!;
    final sensorDistance = _number(fields.jarakSensorDasar);
    if (buangMulai != null && buangMulai >= depth) {
      return 'Kedalaman harus > mulai buang';
    }
    if (sensorDistance != null && depth > sensorDistance) {
      return 'Kedalaman harus ≤ jarak sensor ke dasar';
    }
    return null;
  }

  String? jarakSensor(String? value) {
    final basic = number(value, 'Jarak sensor ke dasar', positive: true);
    if (basic != null) return basic;
    final sensorDistance = _number(fields.jarakSensorDasar)!;
    final depth = _number(fields.kedalaman);
    if (depth != null && sensorDistance < depth) {
      return 'Jarak sensor ke dasar harus ≥ kedalaman wadah';
    }
    return null;
  }

  String? isiMulai(String? value) {
    final basic = number(value, 'Mulai isi', positive: true);
    if (basic != null) return basic;
    final current = _number(fields.batasIsiMulai)!;
    final next = _number(fields.batasBuangBerhenti);
    if (next != null && current >= next) return 'Harus < berhenti buang';
    return null;
  }

  String? buangBerhenti(String? value) {
    final basic = number(value, 'Berhenti buang', positive: true);
    if (basic != null) return basic;
    final current = _number(fields.batasBuangBerhenti)!;
    final previous = _number(fields.batasIsiMulai);
    final next = _number(fields.batasIsiBerhenti);
    if (previous != null && current <= previous) return 'Harus > mulai isi';
    if (next != null && current >= next) return 'Harus < berhenti isi';
    return null;
  }

  String? isiBerhenti(String? value) {
    final basic = number(value, 'Berhenti isi', positive: true);
    if (basic != null) return basic;
    final current = _number(fields.batasIsiBerhenti)!;
    final previous = _number(fields.batasBuangBerhenti);
    final next = _number(fields.batasBuangMulai);
    if (previous != null && current <= previous)
      return 'Harus > berhenti buang';
    if (next != null && current >= next) return 'Harus < mulai buang';
    return null;
  }

  String? buangMulai(String? value) {
    final basic = number(value, 'Mulai buang', positive: true);
    if (basic != null) return basic;
    final current = _number(fields.batasBuangMulai)!;
    final previous = _number(fields.batasIsiBerhenti);
    final depth = _number(fields.kedalaman);
    if (previous != null && current <= previous) return 'Harus > berhenti isi';
    if (depth != null && current >= depth)
      return 'Harus < kedalaman wadah';
    return null;
  }
}
