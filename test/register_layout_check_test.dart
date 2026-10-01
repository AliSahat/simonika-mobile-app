import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simonika_mobile_app/screens/auth/register_screen.dart';

void main() {
  testWidgets('Registration validates fields and toggles password visibility',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.ensureVisible(find.text('Buat akun'));
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();
    expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
    expect(find.text('Username tidak boleh kosong'), findsOneWidget);
    expect(find.text('Password tidak boleh kosong'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Budi');
    await tester.enterText(fields.at(1), 'budi air');
    await tester.enterText(fields.at(2), '123');
    await tester.ensureVisible(find.text('Buat akun'));
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();
    expect(find.text('Username tidak boleh mengandung spasi'), findsOneWidget);
    expect(find.text('Password minimal 6 karakter'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Tampilkan password'));
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, '123');
    expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
  });
  testWidgets('Registration adapts to phone, landscape, tablet and large text',
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
            home: const RegisterScreen(),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Buat akun'), findsOneWidget);
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
