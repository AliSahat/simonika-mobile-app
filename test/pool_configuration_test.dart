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
    fields.batasBuangBerhenti.text = '20';
    expect(validator.isiMulai(fields.batasIsiMulai.text), isNotNull);
    expect(validator.buangBerhenti(fields.batasBuangBerhenti.text), isNotNull);

    fields.batasBuangBerhenti.text = '40';
    fields.batasBuangMulai.text = '121';
    expect(validator.kedalaman(fields.kedalaman.text), isNotNull);
    expect(validator.buangMulai(fields.batasBuangMulai.text), isNotNull);
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
