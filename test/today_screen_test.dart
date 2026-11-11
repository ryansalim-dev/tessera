import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/app.dart';

void main() {
  setUp(() {
    // An iPhone-sized surface so the whole tray is laid out.
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1170, 2532);
    view.devicePixelRatio = 3;
  });

  testWidgets('shows the day\'s tray and the keystone', (tester) async {
    final today = DateTime(2026, 11, 11);
    await tester.pumpWidget(TesseraApp(today: today));

    expect(find.text('Tessera'), findsOneWidget);
    expect(find.textContaining('Wednesday, November 11'), findsOneWidget);
    for (final kind in DailyTray.forDay(PuzzleDay.fromLocal(today)).kinds) {
      expect(find.text(kind.title), findsWidgets);
    }
    expect(find.text('Keystone'), findsOneWidget);
  });

  testWidgets('Glaze is always reachable from the home screen', (tester) async {
    for (var d = 1; d <= 7; d++) {
      await tester.pumpWidget(TesseraApp(today: DateTime(2026, 11, d)));
      expect(find.text('Glaze'), findsOneWidget, reason: 'Nov $d');
    }
  });

  testWidgets('every playable type is reachable from the home screen', (
    tester,
  ) async {
    for (var d = 1; d <= 7; d++) {
      await tester.pumpWidget(TesseraApp(today: DateTime(2026, 11, d)));
      for (final kind in PuzzleKind.values.where((k) => k.isPlayable)) {
        expect(find.text(kind.title), findsOneWidget, reason: 'Nov $d');
        expect(find.text(kind.tagline), findsOneWidget, reason: 'Nov $d');
      }
    }
  });

  testWidgets('opens Kiln Path from the home screen', (tester) async {
    await tester.pumpWidget(TesseraApp(today: DateTime(2026, 11, 11)));
    await tester.tap(find.text('Kiln Path'));
    // The Flame loop never settles, so pump past the route transition.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Undo'), findsOneWidget);
    expect(find.textContaining('/ 36 tiles'), findsOneWidget);
  });
}
