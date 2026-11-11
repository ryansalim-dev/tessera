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
      theme: TesseraTheme.light(),
      home: TodayScreen(today: today),
    );
  }
}
