import 'dart:math' as math;
import 'dart:ui';

import '../../theme/tessera_colors.dart';

/// Shared painters that make board pieces read as fired ceramic: a raised
/// tile with a darker lip, a glaze gradient and a gloss highlight, sitting on
/// a dark kiln-shelf slab.
abstract final class Ceramic {
  static final _paint = Paint();
  static final _stroke = Paint()..style = PaintingStyle.stroke;
  static final _shadow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  static Color shade(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF000000), amount)!;
  static Color tint(Color c, double amount) =>
      Color.lerp(c, const Color(0xFFFFFFFF), amount)!;

  /// A raised glazed tile filling [rect]. [depth] is the lip height as a
  /// fraction of the tile; [gloss] scales the highlight (0 for matte bisque).
  static void tile(
    Canvas canvas,
    Rect rect,
    Color color, {
    double radius = 0.18,
    double depth = 0.08,
    double gloss = 1,
    bool pressed = false,
  }) {
    final side = math.min(rect.width, rect.height);
    final r = Radius.circular(side * radius);
    final lip = pressed ? side * depth * 0.35 : side * depth;
    final top = Rect.fromLTRB(
      rect.left,
      rect.top + (pressed ? lip * 1.6 : 0),
      rect.right,
      rect.bottom - lip,
    );
    // Lip: the tile's fired edge, darker below the face.
    _paint
      ..shader = null
      ..color = shade(color, 0.38);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rect.left, top.top + lip, rect.right, rect.bottom),
        r,
      ),
      _paint,
    );
    // Face: glaze pools darker toward the bottom.
    final face = RRect.fromRectAndRadius(top, r);
    _paint.shader = Gradient.linear(top.topCenter, top.bottomCenter, [
      tint(color, 0.14),
      shade(color, 0.06),
    ]);
    canvas.drawRRect(face, _paint);
    _paint.shader = null;
    if (gloss > 0) {
      // Gloss: a soft window reflection in the top-left.
      _paint.color = Color.fromRGBO(255, 255, 255, 0.28 * gloss);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            top.left + top.width * 0.1,
            top.top + top.height * 0.07,
            top.width * 0.5,
            top.height * 0.16,
          ),
          Radius.circular(side * 0.1),
        ),
        _paint,
      );
      _paint.color = Color.fromRGBO(255, 255, 255, 0.35 * gloss);
      canvas.drawCircle(
        Offset(top.left + top.width * 0.72, top.top + top.height * 0.15),
        side * 0.035,
        _paint,
      );
    }
    // Rim light on the top edge.
    _stroke
      ..color = Color.fromRGBO(255, 255, 255, 0.22)
      ..strokeWidth = math.max(1, side * 0.02);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(top.left, top.top, top.right, top.top + top.height * 0.4),
    );
    canvas.drawRRect(face.deflate(_stroke.strokeWidth / 2), _stroke);
    canvas.restore();
  }

  /// The top face of a [tile] (where content such as digits sits).
  static Rect faceOf(Rect rect, {double depth = 0.08, bool pressed = false}) {
    final side = math.min(rect.width, rect.height);
    final lip = pressed ? side * depth * 0.35 : side * depth;
    return Rect.fromLTRB(
      rect.left,
      rect.top + (pressed ? lip * 1.6 : 0),
      rect.right,
      rect.bottom - lip,
    );
  }

  /// A sunken well: an empty socket in the shelf where a tile can go.
  static void well(Canvas canvas, Rect rect, {double radius = 0.18}) {
    final side = math.min(rect.width, rect.height);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(side * radius));
    _paint
      ..shader = null
      ..color = TesseraColors.shelfDark;
    canvas.drawRRect(rr, _paint);
    _stroke
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    canvas.drawRRect(rr.deflate(0.5), _stroke);
  }

  /// The kiln shelf slab under a board, with a warm glow cast below it.
  static void plate(Canvas canvas, Rect rect, {double radius = 16}) {
    final r = Radius.circular(radius);
    _shadow.color = const Color(0x99000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 8)), r),
      _shadow,
    );
    // Thick slab edge.
    _paint
      ..shader = null
      ..color = TesseraColors.shelfDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 5)), r),
      _paint,
    );
    final rr = RRect.fromRectAndRadius(rect, r);
    _paint.shader = Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [TesseraColors.shelfLight, TesseraColors.shelf, TesseraColors.shelfDark],
      const [0, 0.55, 1],
    );
    canvas.drawRRect(rr, _paint);
    _paint.shader = null;
    // Speckles in the fired clay, fixed so they never flicker.
    final rnd = math.Random(rect.width.round());
    _paint.color = const Color(0x18FFFFFF);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(
          rect.left + rnd.nextDouble() * rect.width,
          rect.top + rnd.nextDouble() * rect.height,
        ),
        0.6 + rnd.nextDouble() * 1.1,
        _paint,
      );
    }
    _stroke
      ..color = const Color(0x30FFFFFF)
      ..strokeWidth = 1.5;
    canvas.drawRRect(rr.deflate(0.75), _stroke);
  }
}
