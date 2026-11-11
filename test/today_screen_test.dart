import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show ValueKey;

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/app.dart';
import 'package:tessera/game/pebbles/pebbles_game.dart';
import 'package:tessera/juice/juice.dart';
import 'package:tessera/progress/progress_store.dart';

void main() {
  setUp(() {
    // No audio plugin under test.
    Juice.muted = true;
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
    // Practice sits below the keystone, so scroll to it first.
    await tester.ensureVisible(find.text('Kiln Path'));
    await tester.pump();
    await tester.tap(find.text('Kiln Path'));
    // The Flame loop never settles, so pump past the route transition.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Undo'), findsOneWidget);
    expect(find.textContaining('/ 36 tiles'), findsOneWidget);
  });

  testWidgets('opens Seams from the home screen', (tester) async {
    await tester.pumpWidget(TesseraApp(today: DateTime(2026, 11, 11)));
    await tester.ensureVisible(find.text('Seams'));
    await tester.pump();
    await tester.tap(find.text('Seams'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('seams'), findsWidgets);
  });

  testWidgets('opens every puzzle type', (tester) async {
    for (final kind in PuzzleKind.values) {
      // A fresh key per type so each starts from the home screen.
      await tester.pumpWidget(
        TesseraApp(key: ValueKey(kind), today: DateTime(2026, 11, 11)),
      );
      await tester.ensureVisible(find.text(kind.title));
      await tester.pump();
      await tester.tap(find.text(kind.title));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Hint'), findsOneWidget, reason: kind.name);
    }
  });

  testWidgets('solving a tray puzzle collects its keystone clue', (
    tester,
  ) async {
    // 2026-11-11's tray: Glaze, Pebbles, Seams, Cutouts.
    final today = DateTime(2026, 11, 11);
    await tester.pumpWidget(TesseraApp(today: today));
    expect(find.textContaining('0 of 4 clues'), findsOneWidget);

    await tester.tap(find.text('Pebbles').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final game = tester
        .widget<GameWidget<PebblesGame>>(find.byType(GameWidget<PebblesGame>))
        .game!;
    for (final cell in game.board.puzzle.solution) {
      game.tapTile(cell);
    }
    expect(game.solved.value, isTrue);
    await tester.pageBack();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('1 of 4 clues'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Pebbles.*fired')), findsOneWidget);

    await tester.ensureVisible(find.text('Keystone'));
    await tester.pump();
    await tester.tap(find.text('Keystone'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('lent'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
  });

  testWidgets('shows the streak and the week strip from saved progress', (
    tester,
  ) async {
    var log = ProgressLog();
    for (final d in [9, 10, 11]) {
      log = log.recordSolve(PuzzleDay(2026, 11, d), PuzzleKind.glaze, 0);
    }
    log = log.recordKeystone(
      PuzzleDay(2026, 11, 11),
      const KeystoneResult(gold: true, hints: 0),
    );
    await tester.pumpWidget(
      TesseraApp(
        today: DateTime(2026, 11, 11),
        progress: ProgressStore.memory(log),
      ),
    );
    expect(find.text('3-day kiln'), findsOneWidget);
    expect(find.text('Set in gold today. Well fired.'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
  });

  testWidgets('a fresh player is asked to light the kiln', (tester) async {
    await tester.pumpWidget(TesseraApp(today: DateTime(2026, 11, 11)));
    expect(find.text('Light the kiln'), findsOneWidget);
  });

  testWidgets('a tray solve marks the tile and lights the kiln', (
    tester,
  ) async {
    final today = DateTime(2026, 11, 11);
    final store = ProgressStore.memory();
    await tester.pumpWidget(TesseraApp(today: today, progress: store));
    final day = PuzzleDay.fromLocal(today);
    final kind = DailyTray.forDay(day).kinds.first;
    store.recordSolve(day, kind, 0);
    await tester.pump();
    expect(find.text('1-day kiln'), findsOneWidget);
    expect(find.text('FIRED'), findsOneWidget);
    expect(find.textContaining('1 / 4 fired'), findsOneWidget);
  });
}
