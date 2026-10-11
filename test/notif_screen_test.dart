import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/models/water_alert.dart';
import 'package:simonika_mobile_app/screens/notif/notif_screen.dart';
import 'package:simonika_mobile_app/services/notification_service.dart';
import 'package:simonika_mobile_app/widgets/notification_button.dart';
import 'notification_service_test.dart' show AlertAdapter;

void main() {
  late NotificationService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    final adapter = AlertAdapter();
    service = NotificationService(
        client: Dio()..httpClientAdapter = adapter, clock: () => adapter.now);
  });
  tearDown(() => service.dispose());

  testWidgets('Bell opens inbox, alert opens its pool, back returns to inbox',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NotificationButton(service: service)),
      routes: {
        '/notif': (_) => NotifScreen(service: service),
        '/detail-pool': (context) => Scaffold(
            appBar: AppBar(),
            body: Text('Detail ${ModalRoute.of(context)!.settings.arguments}')),
      },
    ));
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Level air rendah'), findsOneWidget);
    expect(service.unreadCount, 1);
    await tester.ensureVisible(find.text('Level air rendah'));
    await tester.tap(find.text('Level air rendah'));
    await tester.pumpAndSettle();
    expect(find.text('Detail pool-user-a'), findsOneWidget);
    expect(service.unreadCount, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NotifScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifikasi'), findsOneWidget);
  });

  testWidgets('Read filter and preference switches work', (tester) async {
    await tester.pumpWidget(MaterialApp(home: NotifScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belum dibaca (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Semua sudah dibaca'), findsOneWidget);
    await tester.tap(find.byTooltip('Pengaturan notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(service.enabled(WaterAlertKind.low), isFalse);
  });

  testWidgets(
      'Inbox and preferences fit small screens, large text and dark mode',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      for (final brightness in Brightness.values) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(2), disableAnimations: true),
              child: child!),
          home: NotifScreen(service: service),
        ));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Pengaturan notifikasi'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
