import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../theme/tessera_colors.dart';
import 'pebbles_game.dart';
import 'pebbles_tile_component.dart';

/// The board: one [PebblesTileComponent] per cell, with thick grout lines
/// drawn along region borders on top.
class PebblesBoardComponent extends PositionComponent
    with HasGameReference<PebblesGame> {
  PebblesBoardComponent() : super(anchor: Anchor.center);

  static const _pad = 4.0;
  static const _tileGap = 2.0;

  final List<PebblesTileComponent> _tiles = [];
  double _tile = 0;

  PebblesTileComponent tileAt(int index) => _tiles[index];

  /// Soft washes of the glazes. Region borders are drawn too, so the tint is
  /// never the only cue.
  static final _tints = [
    for (final g in TesseraColors.glazes)
      Color.lerp(TesseraColors.clayLight, g, 0.28)!,
  ];

  late final List<int> _regionColour = _colourRegions();

  Color tintAt(int cell) =>
      _tints[_regionColour[game.board.puzzle.region(cell)] % _tints.length];

  /// Greedy colouring so neighbouring regions never share a tint.
  List<int> _colourRegions() {
    final p = game.board.puzzle;
    final n = p.size;
    final touching = List.generate(n, (_) => <int>{});
    for (var i = 0; i < p.cellCount; i++) {
      for (final j in [
        if (i % n < n - 1) i + 1,
        if (i + n < p.cellCount) i + n,
      ]) {
        final a = p.regions[i], b = p.regions[j];
        if (a != b) {
          touching[a].add(b);
          touching[b].add(a);
        }
      }
    }
    final colour = List.filled(n, -1);
    for (var r = 0; r < n; r++) {
      final taken = {for (final o in touching[r]) colour[o]};
      var c = 0;
      while (taken.contains(c)) {
        c++;
      }
      colour[r] = c;
    }
    return colour;
  }

  @override
  Future<void> onLoad() async {
    final n = game.board.size;
    for (var i = 0; i < n * n; i++) {
      _tiles.add(PebblesTileComponent(i));
    }
    await addAll(_tiles);
    await add(_RegionBorders()..priority = 1);
    _layoutTiles();
  }

  @override
  set size(Vector2 value) {
    super.size = value;
    if (isLoaded) _layoutTiles();
  }

  double get pitch => _tile + _tileGap;
  double get pad => _pad;

  void _layoutTiles() {
    final n = game.board.size;
    final gaps = 2 * _pad + (n - 1) * _tileGap;
    _tile = math.max(0.0, math.min((size.x - gaps) / n, (size.y - gaps) / n));
    for (var i = 0; i < _tiles.length; i++) {
      final r = i ~/ n, c = i % n;
      _tiles[i]
        ..size = Vector2.all(_tile)
        ..position = Vector2(
          _pad + c * pitch + _tile / 2,
          _pad + r * pitch + _tile / 2,
        );
    }
  }

  static final _groutPaint = Paint()..color = TesseraColors.grout;
  static final _shadowPaint = Paint()
    ..color = TesseraColors.ink.withValues(alpha: 0.12)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect.shift(const Offset(0, 3)), _shadowPaint);
    canvas.drawRRect(rect, _groutPaint);
  }

  /// "Kiln firing": the pebbles pulse, then a ripple crosses the board.
  void fire({void Function()? onComplete}) {
    final n = game.board.size;
    final step = 0.3 / n;
    for (var i = 0; i < _tiles.length; i++) {
      final r = i ~/ n, c = i % n;
      _tiles[i].add(
        ScaleEffect.to(
          Vector2.all(1.06),
          EffectController(
            duration: 0.08,
            reverseDuration: 0.1,
            startDelay: (r + c) * step / 2,
          ),
        ),
      );
    }
    add(TimerComponent(period: 0.55, removeOnFinish: true, onTick: onComplete));
  }
}

/// Ink lines along every edge where two regions meet, and around the board.
class _RegionBorders extends Component
    with HasGameReference<PebblesGame>, ParentIsA<PebblesBoardComponent> {
  static final _paint = Paint()
    ..color = TesseraColors.ink.withValues(alpha: 0.8)
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final p = game.board.puzzle;
    final n = p.size;
    final pitch = parent.pitch;
    final pad = parent.pad;
    _paint.strokeWidth = math.max(2.5, pitch * 0.07);
    // Grid line k sits in the gap before row/column k.
    double line(int k) => pad + k * pitch - PebblesBoardComponent._tileGap / 2;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final i = r * n + c;
        if (c + 1 < n && p.regions[i] != p.regions[i + 1]) {
          canvas.drawLine(
            Offset(line(c + 1), line(r)),
            Offset(line(c + 1), line(r + 1)),
            _paint,
          );
        }
        if (r + 1 < n && p.regions[i] != p.regions[i + n]) {
          canvas.drawLine(
            Offset(line(c), line(r + 1)),
            Offset(line(c + 1), line(r + 1)),
            _paint,
          );
        }
      }
    }
  }
}
