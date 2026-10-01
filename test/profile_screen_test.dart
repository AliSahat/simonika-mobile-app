import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/profile/profile_screen.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.fail = false});
  bool fail;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      ResponseBody.fromString(
          jsonEncode({
            'user': {
              'name': 'Budi Santoso Pengelola Tangki Utama',
              'username': 'budi.santoso'
            }
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
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsWidgets);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets(
      'Profile loads identity, logout cancellation keeps token and confirmation removes it',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(client: Dio()..httpClientAdapter = _Adapter()),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login destination'))
        }));
    await tester.pumpAndSettle();
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('@budi.santoso'), findsOneWidget);
    await scrollTo(tester, find.text('Keluar dari akun'));
    await tester.tap(find.text('Keluar dari akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getString('token'),
        'test-token');
    await tester.tap(find.text('Keluar dari akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getString('token'), isNull);
    expect(find.text('Login destination'), findsOneWidget);
  });
  testWidgets('Profile retry recovers and about dialog uses SIMONIKA',
      (tester) async {
    final adapter = _Adapter(fail: true);
    await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(client: Dio()..httpClientAdapter = adapter)));
    await tester.pumpAndSettle();
    adapter.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('BS'), findsOneWidget);
    await scrollTo(tester, find.text('Tentang aplikasi'));
    await tester.tap(find.text('Tentang aplikasi'));
    await tester.pumpAndSettle();
    expect(find.text('SIMONIKA'), findsOneWidget);
  });
  testWidgets(
      'Profile supports long names, large text and landscape in both themes',
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
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!),
          home: ProfileScreen(client: Dio()..httpClientAdapter = _Adapter()),
        ));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Keluar dari akun'));
        expect(tester.takeException(), isNull);
      }
    }
  });
}
