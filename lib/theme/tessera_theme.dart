import 'package:flutter/material.dart';

import 'tessera_colors.dart';

/// Type families bundled in `assets/fonts` (SIL OFL 1.1).
abstract final class TesseraFonts {
  /// Soft, wonky serif for titles and big moments.
  static const display = 'Fraunces';

  /// Rounded sans for everything else, including digits on tiles.
  static const body = 'Nunito';
}

abstract final class TesseraTheme {
  static ThemeData studio() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TesseraColors.terracotta,
          brightness: Brightness.dark,
          surface: TesseraColors.nightHigh,
        ).copyWith(
          primary: TesseraColors.ember,
          onPrimary: TesseraColors.night,
          secondary: TesseraColors.cobalt,
          tertiary: TesseraColors.gold,
          onSurface: TesseraColors.chalk,
        );
    final base = Typography.whiteCupertino.apply(
      fontFamily: TesseraFonts.body,
      bodyColor: TesseraColors.chalk,
      displayColor: TesseraColors.chalk,
    );
    TextStyle? serif(TextStyle? s) => s?.copyWith(
      fontFamily: TesseraFonts.display,
      fontWeight: FontWeight.w800,
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: TesseraFonts.body,
      scaffoldBackgroundColor: TesseraColors.night,
      textTheme: base.copyWith(
        displayLarge: serif(base.displayLarge),
        displayMedium: serif(base.displayMedium),
        displaySmall: serif(base.displaySmall),
        headlineLarge: serif(base.headlineLarge),
        headlineMedium: serif(base.headlineMedium),
        headlineSmall: serif(base.headlineSmall),
        titleLarge: serif(base.titleLarge),
      ),
      splashFactory: NoSplash.splashFactory,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: TesseraColors.shelfDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: TesseraFonts.body,
          color: TesseraColors.chalk,
        ),
      ),
    );
  }
}
