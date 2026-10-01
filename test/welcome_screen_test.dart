import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simonika_mobile_app/screens/main/welcome_screen.dart';

void main() {
  for (final action in [
    ('Mulai sekarang', '/login'),
    ('Daftar sekarang', '/register')
  ]) {
    testWidgets('Welcome opens ${action.$2}', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login destination')),
          '/register': (_) =>
              const Scaffold(body: Text('Register destination')),
        },
      ));
      await tester.ensureVisible(find.text(action.$1));
      await tester.tap(find.text(action.$1));
      await tester.pumpAndSettle();
      expect(
          find.text(action.$2 == '/login'
              ? 'Login destination'
              : 'Register destination'),
          findsOneWidget);
    });
  }
  testWidgets('Welcome adapts to phone, landscape, tablet and large text',
      (tester) async {
    for (final size in [
      const Size(375, 812),
      const Size(812, 375),
      const Size(768, 1024)
    ]) {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: child!,
            ),
            home: const WelcomeScreen(),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Mulai sekarang'), findsOneWidget);
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
