import 'package:flutter/material.dart';

import 'screens/today_screen.dart';
import 'theme/tessera_theme.dart';

class TesseraApp extends StatelessWidget {
  const TesseraApp({super.key, this.today});

  /// Overrides the current date, for tests and previews.
  final DateTime? today;

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
      home: TodayScreen(today: today),
    );
  }
}
