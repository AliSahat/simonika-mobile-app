import 'package:flutter_test/flutter_test.dart';
import 'package:simonika_mobile_app/models/pool_configuration.dart';

void main() {
  late PoolConfigurationControllers fields;
  late PoolConfigurationValidator validator;

  setUp(() {
    fields = PoolConfigurationControllers();
    validator = PoolConfigurationValidator(fields);
    fields.namaWadah.text = 'Tangki utama';
    fields.serial.text = 'AIR-001';
    fields.kedalaman.text = '120';
    fields.jarakSensorDasar.text = '135';
    fields.batasIsiMulai.text = '20';
    fields.batasBuangBerhenti.text = '40';
    fields.batasIsiBerhenti.text = '80';
    fields.batasBuangMulai.text = '100';
  });

  tearDown(() => fields.dispose());

  test('accepts ordered thresholds and sensor distance above depth', () {
    expect(validator.kedalaman(fields.kedalaman.text), isNull);
    expect(validator.jarakSensor(fields.jarakSensorDasar.text), isNull);
    expect(validator.isiMulai(fields.batasIsiMulai.text), isNull);
    expect(validator.buangBerhenti(fields.batasBuangBerhenti.text), isNull);
    expect(validator.isiBerhenti(fields.batasIsiBerhenti.text), isNull);
    expect(validator.buangMulai(fields.batasBuangMulai.text), isNull);
  });

  test('rejects invalid threshold ordering and values above depth', () {
    fields.batasIsiMulai.text = '0';
    expect(validator.isiMulai(fields.batasIsiMulai.text), isNotNull);
    fields.batasIsiMulai.text = '20';

    fields.batasBuangBerhenti.text = '20';
    expect(validator.isiMulai(fields.batasIsiMulai.text), isNotNull);
    expect(validator.buangBerhenti(fields.batasBuangBerhenti.text), isNotNull);

    fields.batasBuangBerhenti.text = '40';
    fields.batasBuangMulai.text = '120';
    expect(validator.kedalaman(fields.kedalaman.text), isNotNull);
    expect(validator.buangMulai(fields.batasBuangMulai.text), isNotNull);

    fields.batasBuangMulai.text = '100';
    fields.jarakSensorDasar.text = '119';
    expect(validator.kedalaman(fields.kedalaman.text), isNotNull);
    expect(validator.jarakSensor(fields.jarakSensorDasar.text), isNotNull);
  });

  test('supports dual-mapping snake_case and camelCase fields', () {
    fields.load({
      'namaWadah': 'Tangki snake',
      'serial': 'DEV-01',
      'max_depth': 150,
      'sensor_to_bottom': 160,
      'fill_start': 25,
      'drain_stop': 45,
      'fill_stop': 85,
      'drain_start': 110,
      'mode_auto': true,
    });
    expect(fields.kedalaman.text, '150');
    expect(fields.jarakSensorDasar.text, '160');
    expect(fields.batasIsiMulai.text, '25');
    expect(fields.batasBuangBerhenti.text, '45');
    expect(fields.batasIsiBerhenti.text, '85');
    expect(fields.batasBuangMulai.text, '110');

    final telemetry = TelemetryLog.fromJson({
      'water_level': 65.5,
      'sensor_distance': 54.5,
      'inlet_valve': true,
      'outlet_valve': false,
      'system_state': 'FILLING',
      'sensor_valid': true,
    });
    expect(telemetry.waterLevel, 65.5);
    expect(telemetry.distance, 54.5);
    expect(telemetry.fillValveOpen, isTrue);
    expect(telemetry.drainValveOpen, isFalse);
    expect(telemetry.controlState, 'FILLING');
    expect(telemetry.sensorValid, isTrue);
  });

  test('payload contains only API configuration fields', () {
    expect(fields.payload(modeAuto: true, isActive: false), {
      'namaWadah': 'Tangki utama',
      'serial': 'AIR-001',
      'kedalaman': 120,
      'jarakSensorDasar': 135,
      'batasIsiMulai': 20,
      'batasIsiBerhenti': 80,
      'batasBuangMulai': 100,
      'batasBuangBerhenti': 40,
      'modeAuto': true,
      'isActive': false,
    });
  });
}
