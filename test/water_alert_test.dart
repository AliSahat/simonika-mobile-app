import 'package:flutter_test/flutter_test.dart';
import 'package:simonika_mobile_app/models/water_alert.dart';

void main() {
  final now = DateTime.utc(2026, 10, 10, 12);
  final pool = <String, dynamic>{
    '_id': 'pool-1',
    'namaWadah': 'Tangki utama',
    'isActive': true,
    'kedalaman': 100,
    'batasIsiMulai': 20,
    'batasBuangMulai': 90,
    'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
  };
  Map<String, dynamic> reading(double level, {DateTime? time}) => {
        'waterLevel': level,
        'createdAt': (time ?? now).toIso8601String(),
      };

  test('Alerts at thresholds; noise does not rearm, recovery does', () {
    final detector = WaterAlertDetector();
    expect(detector.evaluate(pool, reading(20), now).single.kind,
        WaterAlertKind.low);
    expect(detector.evaluate(pool, reading(20), now), isEmpty);
    expect(detector.evaluate(pool, reading(21), now), isEmpty);
    expect(detector.evaluate(pool, reading(19), now), isEmpty);
    expect(detector.evaluate(pool, reading(30), now), isEmpty);
    expect(detector.evaluate(pool, reading(19), now).single.kind,
        WaterAlertKind.low);
    expect(detector.evaluate(pool, reading(90), now).single.kind,
        WaterAlertKind.high);
    expect(detector.evaluate(pool, reading(89), now), isEmpty);
    expect(detector.evaluate(pool, reading(91), now), isEmpty);
    expect(detector.evaluate(pool, reading(80), now), isEmpty);
    expect(detector.evaluate(pool, reading(90), now).single.kind,
        WaterAlertKind.high);
  });

  test('Stale data never also creates a water level warning', () {
    final detector = WaterAlertDetector();
    final old = reading(10, time: now.subtract(const Duration(minutes: 5)));
    expect(detector.evaluate(pool, old, now).single.kind, WaterAlertKind.stale);
    expect(detector.evaluate(pool, old, now), isEmpty);
    expect(detector.evaluate(pool, reading(10), now).single.kind,
        WaterAlertKind.low);
    expect(
        detector
            .evaluate(pool, reading(10), now.add(const Duration(minutes: 5)))
            .single
            .kind,
        WaterAlertKind.stale);
  });

  test('Empty sensor stream has a grace period and respects active state', () {
    final detector = WaterAlertDetector();
    expect(
        detector
            .evaluate({...pool, 'createdAt': now.toIso8601String()}, null, now),
        isEmpty);
    expect(
        detector.evaluate(pool, null, now).single.kind, WaterAlertKind.stale);
    expect(detector.evaluate({...pool, 'isActive': false}, reading(10), now),
        isEmpty);
  });

  test('Rejects invalid readings, future timestamps and incomplete thresholds',
      () {
    final detector = WaterAlertDetector();
    for (final level in [double.nan, double.infinity, -1.0]) {
      expect(detector.evaluate(pool, reading(level), now), isEmpty);
    }
    expect(
        detector.evaluate(
            pool, reading(10, time: now.add(const Duration(hours: 1))), now),
        isEmpty);
    expect(
        detector.evaluate({...pool, 'batasIsiMulai': null}, reading(10), now),
        isEmpty);
    expect(detector.evaluate(pool, {'waterLevel': 10}, now), isEmpty);
  });

  test('Older readings cannot reset the previous condition', () {
    final detector = WaterAlertDetector();
    detector.evaluate(pool, reading(10), now);
    expect(
        detector.evaluate(pool,
            reading(50, time: now.subtract(const Duration(seconds: 10))), now),
        isEmpty);
    expect(detector.evaluate(pool, reading(10), now), isEmpty);
  });
}
