import 'package:flutter/material.dart';

/// Editable fields for the water-control configuration documented by the API.
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
    namaWadah.text = _text(data['namaWadah']);
    serial.text = _text(data['serial']);
    kedalaman.text = _text(data['kedalaman']);
    jarakSensorDasar.text = _text(data['jarakSensorDasar']);
    batasIsiMulai.text = _text(data['batasIsiMulai']);
    batasIsiBerhenti.text = _text(data['batasIsiBerhenti']);
    batasBuangMulai.text = _text(data['batasBuangMulai']);
    batasBuangBerhenti.text = _text(data['batasBuangBerhenti']);
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
    if (buangMulai != null && buangMulai > depth) {
      return 'Kedalaman harus ≥ mulai buang';
    }
    return null;
  }

  String? jarakSensor(String? value) =>
      number(value, 'Jarak sensor ke dasar', positive: true);

  String? isiMulai(String? value) {
    final basic = number(value, 'Mulai isi');
    if (basic != null) return basic;
    final current = _number(fields.batasIsiMulai)!;
    if (current < 0) return 'Mulai isi tidak boleh negatif';
    final next = _number(fields.batasBuangBerhenti);
    if (next != null && current >= next) return 'Harus < berhenti buang';
    return null;
  }

  String? buangBerhenti(String? value) {
    final basic = number(value, 'Berhenti buang');
    if (basic != null) return basic;
    final current = _number(fields.batasBuangBerhenti)!;
    final previous = _number(fields.batasIsiMulai);
    final next = _number(fields.batasIsiBerhenti);
    if (previous != null && current <= previous) return 'Harus > mulai isi';
    if (next != null && current >= next) return 'Harus < berhenti isi';
    return null;
  }

  String? isiBerhenti(String? value) {
    final basic = number(value, 'Berhenti isi');
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
    final basic = number(value, 'Mulai buang');
    if (basic != null) return basic;
    final current = _number(fields.batasBuangMulai)!;
    final previous = _number(fields.batasIsiBerhenti);
    final depth = _number(fields.kedalaman);
    if (previous != null && current <= previous) return 'Harus > berhenti isi';
    if (depth != null && current > depth)
      return 'Tidak boleh melebihi kedalaman';
    return null;
  }
}
