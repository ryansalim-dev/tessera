import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curve;

import '../../theme/tessera_colors.dart';

/// Short squash-and-pop used when a tile changes.
Effect pressEffect() => SequenceEffect([
  ScaleEffect.to(Vector2(1.12, 0.86), EffectController(duration: 0.05)),
  ScaleEffect.to(
    Vector2.all(1),
    EffectController(duration: 0.22, curve: _Spring()),
  ),
]);

/// Wobble for a wrong move.
Effect shakeEffect() => SequenceEffect([
  for (final dx in [-6.0, 10.0, -8.0, 4.0])
    MoveByEffect(Vector2(dx, 0), EffectController(duration: 0.045)),
]);

class _Spring extends Curve {
  @override
  double transformInternal(double t) =>
      1 - math.pow(math.e, -6 * t) * math.cos(t * 12);
}

final _rnd = math.Random();

/// A puff of glaze chips and sparks, for a placement.
Component chipPuff(Vector2 at, Color color, {double size = 40}) {
  return ParticleSystemComponent(
    position: at,
    priority: 50,
    particle: Particle.generate(
      count: 8,
      lifespan: 0.45,
      generator: (i) {
        final a = i / 8 * math.pi * 2 + _rnd.nextDouble() * 0.4;
        final speed = size * (2.2 + _rnd.nextDouble() * 1.5);
        return AcceleratedParticle(
          speed: Vector2(math.cos(a), math.sin(a)) * speed,
          acceleration: Vector2(0, size * 6),
          child: _ChipParticle(color, size * 0.09),
        );
      },
    ),
  );
}

/// The firing burst on solve: glazed shards fly out of the board and fall,
/// with a ring of gold sparks.
Component solveBurst(Vector2 centre, double radius) {
  return ParticleSystemComponent(
    position: centre,
    priority: 100,
    particle: Particle.generate(
      count: 70,
      lifespan: 1.6,
      generator: (i) {
        final gold = i % 3 == 0;
        final a = _rnd.nextDouble() * math.pi * 2;
        final speed = radius * (0.9 + _rnd.nextDouble() * 1.6);
        final colour = gold
            ? TesseraColors.gold
            : TesseraColors.glazes[_rnd.nextInt(TesseraColors.glazes.length)];
        return AcceleratedParticle(
          position: Vector2(math.cos(a), math.sin(a)) * radius * 0.15,
          speed: Vector2(math.cos(a), math.sin(a) - 0.8) * speed,
          acceleration: Vector2(0, radius * 2.6),
          child: _ChipParticle(
            colour,
            radius * (gold ? 0.025 : 0.045 + _rnd.nextDouble() * 0.03),
            spark: gold,
          ),
        );
      },
    ),
  );
}

/// A tumbling ceramic chip (or a twinkling spark) that fades out.
class _ChipParticle extends Particle {
  _ChipParticle(this.color, this.size, {this.spark = false})
    : _spin = (_rnd.nextDouble() - 0.5) * 14,
      _shape = _rnd.nextInt(3);

  final Color color;
  final double size;
  final bool spark;
  final double _spin;
  final int _shape;
  static final _paint = Paint();

  @override
  void render(Canvas canvas) {
    final fade = (1 - progress).clamp(0.0, 1.0);
    _paint.color = color.withValues(alpha: fade);
    if (spark) {
      final r = size * (1 + math.sin(progress * 30) * 0.4);
      canvas.drawCircle(Offset.zero, r, _paint);
      _paint.color = const Color(0xFFFFF4D6).withValues(alpha: fade);
      canvas.drawCircle(Offset.zero, r * 0.45, _paint);
      return;
    }
    canvas.save();
    canvas.rotate(progress * _spin);
    switch (_shape) {
      case 0:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size * 2,
            height: size * 1.4,
          ),
          _paint,
        );
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(0, -size)
            ..lineTo(size, size * 0.8)
            ..lineTo(-size, size * 0.6)
            ..close(),
          _paint,
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(-size, -size * 0.5)
            ..lineTo(size * 0.4, -size)
            ..lineTo(size, size * 0.3)
            ..lineTo(-size * 0.3, size)
            ..close(),
          _paint,
        );
    }
    _paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * fade);
    canvas.drawCircle(Offset(-size * 0.3, -size * 0.3), size * 0.25, _paint);
    canvas.restore();
  }
}

/// A ring of light that sweeps outward from the board's centre on solve.
class FiringGlow extends PositionComponent {
  FiringGlow({required Vector2 centre, required this.radius})
    : super(position: centre, anchor: Anchor.center, priority: 90);

  final double radius;
  double _t = 0;
  static const _duration = 0.9;
  static final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _duration).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - p, 3).toDouble();
    _paint
      ..strokeWidth = radius * 0.25 * (1 - p) + 2
      ..color = TesseraColors.emberGlow.withValues(alpha: 0.75 * (1 - p));
    canvas.drawCircle(Offset.zero, radius * 1.5 * eased, _paint);
  }
}

/// Adds the full solve celebration (glow ring plus shard burst) to [parent]
/// around [centre].
void celebrate(Component parent, Vector2 centre, double radius) {
  parent.add(FiringGlow(centre: centre, radius: radius));
  parent.add(solveBurst(centre, radius));
}
