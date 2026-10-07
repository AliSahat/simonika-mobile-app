import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simonika_mobile_app/screens/auth/login_screen.dart';
import 'package:simonika_mobile_app/services/google_auth_service.dart';

class _GoogleAuthService extends Fake implements GoogleAuthService {
  late final result = Completer<bool>();
  int calls = 0;

  @override
  Future<bool> signIn() {
    calls++;
    return result.future;
  }
}

void main() {
  late _GoogleAuthService service;

  setUp(() => service = _GoogleAuthService());

  Future<void> openLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(googleAuthService: service),
      routes: {
        '/bnav': (_) => const Scaffold(body: Text('Beranda pengujian')),
      },
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lanjutkan dengan Google'));
  }

  testWidgets(
      'Google login ignores password fields and prevents duplicate taps',
      (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();
    expect(service.calls, 1);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull);
    service.result.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Beranda pengujian'), findsOneWidget);
  });

  testWidgets('cancel restores the button without navigation or an error',
      (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Lanjutkan dengan Google'));
    service.result.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull);
  });

  testWidgets('shows a useful error and allows retry', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Lanjutkan dengan Google'));
    service.result.completeError(
        const GoogleLoginException('Layanan login Google belum tersedia.'));
    await tester.pumpAndSettle();
    expect(find.text('Layanan login Google belum tersedia.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull);
  });

  testWidgets('a pending login may finish safely after leaving the screen',
      (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    service.result.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
