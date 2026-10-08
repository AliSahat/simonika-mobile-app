import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/pool/create_pool_screen.dart';

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic>? payload;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    payload = Map<String, dynamic>.from(options.data);
    return ResponseBody.fromString('{"success":true}', 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);
Future<void> fill(WidgetTester tester, String label, String value) async {
  await tester.scrollUntilVisible(field(label), 120,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), value);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets('Create posts numeric settings and returns success to the list',
      (tester) async {
    final adapter = _Adapter();
    bool? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CreatePoolScreen(
                                  client: Dio()..httpClientAdapter = adapter)));
                    },
                    child: const Text('Open create'))))));
    await tester.tap(find.text('Open create'));
    await tester.pumpAndSettle();
    for (final entry in [
      ('Nama wadah', 'Tangki utama'),
      ('Serial perangkat', 'AIR-001'),
      ('Kedalaman wadah', '120'),
      ('Jarak sensor ke dasar', '135'),
      ('Mulai isi', '20'),
      ('Berhenti buang', '40'),
      ('Berhenti isi', '80'),
      ('Mulai buang', '100')
    ]) {
      await fill(tester, entry.$1, entry.$2);
    }
    await tester.tap(find.text('Simpan konfigurasi'));
    await tester.pumpAndSettle();
    expect(adapter.payload, {
      'namaWadah': 'Tangki utama',
      'serial': 'AIR-001',
      'kedalaman': 120,
      'jarakSensorDasar': 135,
      'batasIsiMulai': 20,
      'batasIsiBerhenti': 80,
      'batasBuangMulai': 100,
      'batasBuangBerhenti': 40,
      'modeAuto': true,
    });
    expect(result, true);
  });
  testWidgets('Invalid depth shows an inline error and sends no request',
      (tester) async {
    final adapter = _Adapter();
    await tester.pumpWidget(MaterialApp(
        home: CreatePoolScreen(client: Dio()..httpClientAdapter = adapter)));
    await fill(tester, 'Kedalaman wadah', 'abc');
    await tester.tap(find.text('Simpan konfigurasi'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan angka yang valid'), findsOneWidget);
    expect(adapter.payload, isNull);
  });
  testWidgets('Create form fits small phone, landscape, tablet and large text',
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
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!),
          home: const CreatePoolScreen(),
        ));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(field('Mulai buang'), 120,
            scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
        expect(find.text('Simpan konfigurasi').hitTestable(), findsOneWidget);
      }
    }
  });
}
