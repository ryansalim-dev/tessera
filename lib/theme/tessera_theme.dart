import 'package:flutter/material.dart';

import 'tessera_colors.dart';

abstract final class TesseraTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TesseraColors.terracotta,
          surface: TesseraColors.clay,
        ).copyWith(
          primary: TesseraColors.terracotta,
          secondary: TesseraColors.cobalt,
          tertiary: TesseraColors.gold,
          onSurface: TesseraColors.ink,
        );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: TesseraColors.clay,
      appBarTheme: const AppBarTheme(
        backgroundColor: TesseraColors.clay,
        foregroundColor: TesseraColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: TesseraColors.clayLight,
        elevation: 1.5,
        shadowColor: TesseraColors.ink.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: Typography.blackCupertino.apply(
        bodyColor: TesseraColors.ink,
        displayColor: TesseraColors.ink,
      ),
    );
  }
}
