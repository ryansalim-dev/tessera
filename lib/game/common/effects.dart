import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// Short "press in" used when a tile changes.
Effect pressEffect() => ScaleEffect.to(
  Vector2.all(0.9),
  EffectController(duration: 0.06, reverseDuration: 0.1),
);
