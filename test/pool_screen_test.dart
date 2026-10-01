import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/pool/pool_screen.dart';

class _PoolAdapter implements HttpClientAdapter {
  _PoolAdapter({this.fail = false, this.empty = false});
  bool fail;
  int requests = 0;
  final bool empty;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    requests++;
    return ResponseBody.fromString(
        jsonEncode({
          'data': empty
              ? []
              : [
                  {
                    '_id': 'pool-1',
                    'namaWadah': 'Tangki utama',
                    'serial': 'AIR-001',
                    'isActive': true,
                    'kedalaman': 120,
                    'keranTutup': 100,
                    'keranNormal': 80,
                    'keranBuka': 30
                  },
                  {
                    '_id': 'pool-2',
                    'namaWadah': 'Tangki cadangan',
                    'serial': 'AIR-002',
                    'isActive': false
                  },
                ]
        }),
        fail ? 500 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> scrollTo(WidgetTester tester, Finder finder, double delta) async {
  for (var i = 0; i < 120; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(find.byType(CustomScrollView), Offset(0, -delta.sign * 40));
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsWidgets);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));
  testWidgets('Search filters by serial and monitor passes the pool ID',
      (tester) async {
    final dio = Dio()..httpClientAdapter = _PoolAdapter();
    Object? routeArgument;
    await tester.pumpWidget(MaterialApp(home: PoolScreen(client: dio), routes: {
      '/detail-pool': (context) {
        routeArgument = ModalRoute.of(context)!.settings.arguments;
        return const Scaffold(body: Text('Detail destination'));
      },
    }));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'AIR-001');
    await tester.pumpAndSettle();
    final searchPosition = tester.getTopLeft(find.byType(TextField));
    final headerPosition = tester.getTopLeft(find.text('Daftar wadah'));
    final summaryPosition = tester.getTopLeft(find.text('Wadah air Anda'));
    await scrollTo(tester, find.text('Monitor wadah'), 300);
    expect(tester.getTopLeft(find.byType(TextField)), searchPosition);
    expect(tester.getTopLeft(find.text('Daftar wadah')), headerPosition);
    expect(tester.getTopLeft(find.text('Wadah air Anda')), summaryPosition);
    expect(find.text('Tangki utama'), findsOneWidget);
    expect(find.text('Tangki cadangan'), findsNothing);
    await tester.tap(find.text('Monitor wadah'));
    await tester.pumpAndSettle();
    expect(routeArgument, 'pool-1');
    expect(find.text('Detail destination'), findsOneWidget);
  });
  testWidgets('Refresh button updates the list and keeps the search',
      (tester) async {
    final adapter = _PoolAdapter();
    await tester.pumpWidget(MaterialApp(
        home: PoolScreen(client: Dio()..httpClientAdapter = adapter)));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);
    await tester.enterText(find.byType(TextField), 'AIR-001');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byTooltip('Perbarui daftar wadah'), -200);
    await tester.tap(find.byTooltip('Perbarui daftar wadah'));
    await tester.pumpAndSettle();
    expect(adapter.requests, 2);
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'AIR-001');
  });
  testWidgets('Failed request shows retry and recovers', (tester) async {
    final adapter = _PoolAdapter(fail: true);
    await tester.pumpWidget(MaterialApp(
        home: PoolScreen(client: Dio()..httpClientAdapter = adapter)));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Coba lagi'), 300);
    adapter.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Tangki utama'), -200);
    expect(find.text('Tangki utama'), findsOneWidget);
  });
  testWidgets('Missing session stops loading and empty state can create a pool',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PoolScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await scrollTo(tester,
        find.text('Silakan masuk kembali untuk melihat wadah Anda.'), 300);
    expect(find.text('Silakan masuk kembali untuk melihat wadah Anda.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    await tester.pumpWidget(MaterialApp(
        home: PoolScreen(
            client: Dio()..httpClientAdapter = _PoolAdapter(empty: true)),
        routes: {
          '/create-pool': (_) =>
              const Scaffold(body: Text('Create destination')),
        }));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Mulai dengan wadah pertama'), 300);
    expect(find.text('Mulai dengan wadah pertama'), findsOneWidget);
    await scrollTo(tester, find.byTooltip('Tambah wadah'), -200);
    await tester.tap(find.byTooltip('Tambah wadah'));
    await tester.pumpAndSettle();
    expect(find.text('Create destination'), findsOneWidget);
  });
  testWidgets('Pool content fits phone, landscape, tablet and large text',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(375, 812),
      const Size(812, 375),
      const Size(768, 1024)
    ]) {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: child!),
            home: PoolScreen(client: Dio()..httpClientAdapter = _PoolAdapter()),
          ));
          await tester.pumpAndSettle();
          await scrollTo(tester, find.text('Monitor wadah'), 200);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}
