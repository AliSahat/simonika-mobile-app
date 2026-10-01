import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/pool/detail_pool_screen.dart';
import 'package:simonika_mobile_app/screens/pool/widgets/animated_water_tank.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.empty = false, this.advancing = false});
  final bool advancing;
  int readings = 0;
  final bool empty;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.path.endsWith('/api/water/level')) readings++;
    final data = options.path.endsWith('/api/water/level')
        ? (empty
            ? []
            : [
                {
                  'waterLevel': advancing ? 75 + readings : 75,
                  'distance': 100,
                  'createdAt': advancing
                      ? DateTime.utc(2026, 10, 1, 12)
                          .add(Duration(seconds: readings * 5))
                          .toIso8601String()
                      : '2026-10-01T12:00:00Z'
                }
              ])
        : {
            'namaWadah': 'Tangki utama',
            'serial': 'AIR-001',
            'isActive': true,
            'kedalaman': 120,
            'keranTutup': 100,
            'keranNormal': 70,
            'keranBuka': 30
          };
    return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> openDetail(WidgetTester tester,
    {bool empty = false,
    bool advancing = false,
    double scale = 1,
    Brightness brightness = Brightness.light}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: brightness),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(scale)),
        child: child!),
    home: const Scaffold(),
    onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => DetailPoolScreen(
            client: Dio()
              ..httpClientAdapter =
                  _Adapter(empty: empty, advancing: advancing))),
  ));
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushNamed('/detail', arguments: 'pool-1');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Trend appears after distinct sensor timestamps arrive',
      (tester) async {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    await openDetail(tester, advancing: true);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tren level air'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets('Monitoring shows readings and automatic valve status',
      (tester) async {
    await openDetail(tester);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Tinggi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Status otomatis'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Tertutup'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('No readings are presented as unknown instead of zero',
      (tester) async {
    await openDetail(tester, empty: true);
    expect(find.text('0%'), findsNothing);
    expect(find.text('Menunggu pembacaan sensor'), findsOneWidget);
    expect(find.text('Belum ada data'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Monitoring fits small screens, landscape and large text in both themes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(375, 812),
      const Size(812, 375),
      const Size(768, 1024)
    ]) {
      for (final brightness in Brightness.values) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await openDetail(tester, scale: 2, brightness: brightness);
        await tester.scrollUntilVisible(find.text('Status otomatis'), 160,
            scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
  testWidgets('Tank animates level changes and handles empty and full readings',
      (tester) async {
    final colors = ColorScheme.fromSeed(seedColor: Colors.blue);
    for (final level in [0.0, 75.0, 100.0, -5.0, 120.0]) {
      await tester.pumpWidget(MaterialApp(
          home:
              Center(child: AnimatedWaterTank(level: level, colors: colors))));
      await tester.pump(const Duration(milliseconds: 850));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
