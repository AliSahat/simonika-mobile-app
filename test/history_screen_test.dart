import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/history/history_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.empty = false, this.fail = false});
  final bool empty;
  bool fail;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': empty
                ? []
                : [
                    {
                      'serial': 'AIR-001',
                      'waterLevel': '45.5',
                      'distance': 160,
                      'createdAt': '2026-10-01T12:00:00Z'
                    },
                    {
                      'serial': 'AIR-001',
                      'waterLevel': 75,
                      'distance': 120,
                      'createdAt': '2026-10-01T12:10:00Z'
                    },
                    {
                      'serial': 'AIR-002',
                      'waterLevel': 20,
                      'distance': 90,
                      'createdAt': '2026-10-01T11:00:00Z'
                    },
                    {
                      'serial': 'AIR-001',
                      'waterLevel': null,
                      'distance': null,
                      'createdAt': 'bad-date'
                    },
                  ]
          }),
          fail ? 500 : 200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
  @override
  void close({bool force = false}) {}
}

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 60; i++) {
    if (target.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsWidgets);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets(
      'Charts sort readings, separate devices, and fit distances above 100 cm',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: HistoryScreen(client: Dio()..httpClientAdapter = _Adapter())));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Jarak sensor'));
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(
        chart.data.lineBarsData.single.spots.map((spot) => spot.y), [45.5, 75]);
    await tester.tap(find.text('Jarak sensor'));
    await tester.pumpAndSettle();
    final distances = tester.widget<LineChart>(find.byType(LineChart));
    expect(distances.data.maxY, greaterThan(160));
    expect(distances.data.lineBarsData.single.spots.map((spot) => spot.y),
        [160, 120]);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AIR-002').last);
    await tester.pumpAndSettle();
    await scrollTo(
        tester, find.text('Menunggu dua pembacaan dengan waktu berbeda.'));
    expect(find.byType(LineChart), findsNothing);
  });
  testWidgets('Error can retry and empty readings show an empty state',
      (tester) async {
    final adapter = _Adapter(empty: true, fail: true);
    await tester.pumpWidget(MaterialApp(
        home: HistoryScreen(client: Dio()..httpClientAdapter = adapter)));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    adapter.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat'), findsOneWidget);
  });
  testWidgets('History supports landscape, large text and both themes',
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
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2), disableAnimations: true),
              child: child!),
          home: HistoryScreen(client: Dio()..httpClientAdapter = _Adapter()),
        ));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Catatan pengukuran'));
        expect(tester.takeException(), isNull);
      }
    }
  });
}
