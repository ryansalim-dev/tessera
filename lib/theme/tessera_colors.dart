import 'dart:ui';

/// Studio palette from the design doc.
abstract final class TesseraColors {
  static const clay = Color(0xFFF3EDE4);
  static const clayLight = Color(0xFFFBF8F3);
  static const grout = Color(0xFFD8CDBE);
  static const groutDark = Color(0xFFB9AB98);
  static const terracotta = Color(0xFFC8643B);
  static const celadon = Color(0xFF9DB8A0);
  static const cobalt = Color(0xFF2F4E8C);
  static const gold = Color(0xFFC9A24B);
  static const ink = Color(0xFF2E2A26);
  static const inkSoft = Color(0xFF6E655C);

  /// One glaze per digit. Digits are always drawn too, so color is never the
  /// only cue (accessibility twin).
  static const glazes = <Color>[
    celadon,
    cobalt,
    terracotta,
    gold,
    Color(0xFF7A4E6E), // plum
    Color(0xFF3F7F7A), // teal
    Color(0xFF8A6A4F), // umber
    Color(0xFFD49A8F), // rose
    Color(0xFF4A4A57), // slate
  ];

  static Color glaze(int value) => glazes[(value - 1) % glazes.length];

  /// Text color that reads on top of [glaze(value)].
  static Color onGlaze(int value) =>
      glaze(value).computeLuminance() > 0.35 ? ink : clayLight;
}
