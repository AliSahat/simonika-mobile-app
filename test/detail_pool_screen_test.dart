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
  final List<Map<String, dynamic>> waterQueries = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.path.endsWith('/api/water/level')) {
      readings++;
      waterQueries.add(Map<String, dynamic>.from(options.queryParameters));
    }
    final data = options.path.endsWith('/api/water/level')
        ? (empty
            ? []
            : [
                {
                  'waterLevel': advancing ? 75 + readings : 75,
                  'distance': 100,
                  'controlState': 'FILLING',
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
            'jarakSensorDasar': 135,
            'batasIsiMulai': 20,
            'batasBuangBerhenti': 40,
            'batasIsiBerhenti': 80,
            'batasBuangMulai': 100,
            'modeAuto': true
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

Future<_Adapter> openDetail(WidgetTester tester,
    {bool empty = false,
    bool advancing = false,
    double scale = 1,
    Brightness brightness = Brightness.light}) async {
  final adapter = _Adapter(empty: empty, advancing: advancing);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: brightness),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(scale)),
        child: child!),
    home: const Scaffold(),
    onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            DetailPoolScreen(client: Dio()..httpClientAdapter = adapter)),
  ));
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushNamed('/detail', arguments: 'pool-1');
  await tester.pumpAndSettle();
  return adapter;
}

Finder _slideScrollable(int index) => find.descendant(
    of: find.byKey(PageStorageKey('pool-slide-$index')),
    matching: find.byType(Scrollable));

void main() {
  testWidgets('Slides swipe while the pool name stays fixed', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openDetail(tester);
    final headerPosition = tester.getTopLeft(find.text('Tangki utama'));
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Tren level air'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Tangki utama')), headerPosition);

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Berhenti buang'), 180,
        scrollable: _slideScrollable(2));
    expect(tester.getTopLeft(find.text('Tangki utama')), headerPosition);
    await tester.tap(find.text('Monitoring'));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Trend appears after distinct sensor timestamps arrive',
      (tester) async {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    await openDetail(tester, advancing: true);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tren'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets('Monitoring shows telemetry state without deriving valve status',
      (tester) async {
    final adapter = await openDetail(tester);
    expect(find.text('75%'), findsOneWidget);
    expect(adapter.waterQueries.single, {'poolId': 'pool-1', 'limit': 30});
    await tester.scrollUntilVisible(find.text('Status otomatis'), 200,
        scrollable: _slideScrollable(0));
    expect(find.text('FILLING'), findsOneWidget);
    expect(find.text('Belum diketahui'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('No readings are presented as unknown instead of zero',
      (tester) async {
    await openDetail(tester, empty: true);
    expect(find.text('0%'), findsNothing);
    expect(find.text('Menunggu pembacaan sensor'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Status otomatis'), 200,
        scrollable: _slideScrollable(0));
    expect(find.text('Belum diketahui'), findsWidgets);
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
            scrollable: _slideScrollable(0));
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
