import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/main/bnav_container_screen.dart';
import 'package:simonika_mobile_app/screens/history/history_screen.dart';
import 'package:simonika_mobile_app/screens/profile/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Tabs load lazily and retain their state after switching',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BnavContainerScreen()));
    await tester.pump();
    expect(find.byType(HistoryScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
    await tester.tap(find.byTooltip('Riwayat'));
    await tester.pump(const Duration(milliseconds: 250));
    final historyState = tester.state(find.byType(HistoryScreen));
    await tester.tap(find.byTooltip('Wadah'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byTooltip('Riwayat'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.state(find.byType(HistoryScreen)), same(historyState));
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
    final semantics = tester.getSemantics(find.byTooltip('Riwayat'));
    expect(
        semantics,
        matchesSemantics(
            label: 'Riwayat',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true));
  });

  testWidgets('Navigation fits small screens, landscape and large text',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BnavContainerScreen()));
    await tester.pump();
    final navigation = tester
        .widget<Scaffold>(find.byType(Scaffold).first)
        .bottomNavigationBar!;
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
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
                padding: const EdgeInsets.only(bottom: 34)),
            child: child!,
          ),
          home: Scaffold(
              body: const SizedBox.expand(), bottomNavigationBar: navigation),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final label in ['Wadah', 'Riwayat', 'Profil']) {
          final rect = tester.getRect(find.byTooltip(label));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 34));
        }
      }
    }
  });
}
