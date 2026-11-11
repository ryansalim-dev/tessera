import 'package:flutter/material.dart';

import 'progress/progress_store.dart';
import 'screens/today_screen.dart';
import 'theme/tessera_theme.dart';

class TesseraApp extends StatefulWidget {
  const TesseraApp({super.key, this.today, this.progress});

  /// Overrides the current date, for tests and previews.
  final DateTime? today;

  /// Saved solves and streaks. Defaults to an unsaved in-memory store.
  final ProgressStore? progress;

  @override
  State<TesseraApp> createState() => _TesseraAppState();
}

class _TesseraAppState extends State<TesseraApp> {
  late final ProgressStore _progress =
      widget.progress ?? ProgressStore.memory();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tessera',
      debugShowCheckedModeBanner: false,
      theme: TesseraTheme.studio(),
      // Keep a phone-shaped column on tablets and wide browser windows.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFF0E0908),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        ),
      ),
      home: TodayScreen(today: widget.today, progress: _progress),
    );
  }
}
