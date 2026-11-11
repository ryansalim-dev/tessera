import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../juice/juice.dart';
import '../progress/progress_store.dart';
import '../theme/puzzle_style.dart';
import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_art.dart';
import '../widgets/studio_background.dart';
import '../widgets/tile_route.dart';
import 'cutouts_screen.dart';
import 'glaze_screen.dart';
import 'keystone_screen.dart';
import 'kiln_path_screen.dart';
import 'pebbles_screen.dart';
import 'seams_screen.dart';
import 'shards_screen.dart';

/// The day's tray: four puzzle tiles and the keystone.
///
/// Solved tray puzzles and the keystone are saved in [progress], which also
/// drives the streak ("kiln") and the week strip.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.today, required this.progress});

  final DateTime? today;
  final ProgressStore progress;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  KeystonePuzzle? _keystone;
  PuzzleDay? _keystoneDay;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  void _open(PuzzleKind kind, PuzzleDay day, {required bool inTray}) {
    final seed = day.seedFor(kind);
    final difficulty = day.difficulty;
    void solved(int hints) {
      if (inTray) widget.progress.recordSolve(day, kind, hints);
    }

    final Widget screen = switch (kind) {
      PuzzleKind.glaze => GlazeScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
      PuzzleKind.kilnPath => KilnPathScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
      PuzzleKind.pebbles => PebblesScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
      PuzzleKind.seams => SeamsScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
      PuzzleKind.cutouts => CutoutsScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
      PuzzleKind.shards => ShardsScreen(
        seed: seed,
        difficulty: difficulty,
        onSolved: solved,
      ),
    };
    Navigator.of(context).push(TileRoute<void>(builder: (_) => screen));
  }

  void _openKeystone(PuzzleDay day, DailyTray tray) {
    if (_keystoneDay != day) {
      _keystone = const KeystoneBuilder().forDay(day);
      _keystoneDay = day;
    }
    Navigator.of(context).push(
      TileRoute<void>(
        builder: (_) => KeystoneScreen(
          puzzle: _keystone!,
          tray: tray.kinds,
          solved: widget.progress.log.dayOf(day).solved.keys.toSet(),
          onSet: (result) => widget.progress.recordKeystone(day, result),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgress);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final day = PuzzleDay.fromLocal(widget.today ?? DateTime.now());
    final log = widget.progress.log;
    final record = log.dayOf(day);
    final solvedToday = record.solved;
    final tray = DailyTray.forDay(day);
    // Playable types that are not in today's tray, so every finished puzzle
    // type can always be reached.
    final practice = [
      for (final kind in PuzzleKind.values)
        if (kind.isPlayable && !tray.kinds.contains(kind)) kind,
    ];
    final date = day.date;
    final collected = tray.kinds.where(solvedToday.containsKey).length;

    return Scaffold(
      backgroundColor: TesseraColors.night,
      body: StudioBackground(
        child: SafeArea(
          // A plain column rather than a lazy list: the home screen is short
          // and every tile should animate in together.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _DatePill(
                        text:
                            '${_weekdays[date.weekday - 1]}, '
                            '${_months[date.month - 1]} ${date.day}'
                            '  ·  ${_difficultyLabel(day.difficulty)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClayIconButton(
                      icon: Juice.muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      tooltip: Juice.muted ? 'Sound on' : 'Sound off',
                      onPressed: () =>
                          setState(() => Juice.muted = !Juice.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _Wordmark(),
                const SizedBox(height: 18),
                _KilnStreak(
                  streak: log.currentStreak(day),
                  best: log.bestStreak(),
                  doneToday: log.counts(day),
                  week: log.week(day),
                ),
                const SizedBox(height: 22),
                _SectionLabel(
                  "Today's tray",
                  trailing: '$collected / ${tray.kinds.length} fired',
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                  children: [
                    for (final (i, kind) in tray.kinds.indexed)
                      _Entrance(
                        order: i,
                        child: _TrayTile(
                          kind: kind,
                          accent: TesseraColors.glazes[i],
                          solved: solvedToday.containsKey(kind),
                          onTap: kind.isPlayable
                              ? () => _open(kind, day, inTray: true)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _Entrance(
                  order: 4,
                  child: _KeystoneTile(
                    collected: collected,
                    result: record.keystone,
                    gems: [
                      for (final (i, k) in tray.kinds.indexed)
                        solvedToday.containsKey(k)
                            ? TesseraColors.glazes[i]
                            : null,
                    ],
                    onTap: () => _openKeystone(day, tray),
                  ),
                ),
                if (practice.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const _SectionLabel('Practice'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                    children: [
                      for (final (i, kind) in practice.indexed)
                        _Entrance(
                          order: 5 + i,
                          child: _TrayTile(
                            kind: kind,
                            accent: kind.accent,
                            onTap: () => _open(kind, day, inTray: false),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _difficultyLabel(Difficulty d) => switch (d) {
    Difficulty.gentle => 'Gentle',
    Difficulty.steady => 'Steady',
    Difficulty.tricky => 'Tricky',
    Difficulty.fierce => 'Fierce',
  };
}

/// Drops a home tile into place, one after another.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 0.08 * order;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (delay * 1000).round()),
      child: child,
      builder: (context, v, child) {
        // Hold until this tile's turn, then spring in.
        final total = 0.5 + delay;
        final t = ((v * total - delay) / 0.5).clamp(0.0, 1.0);
        final e = Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - e) * 36),
            child: child,
          ),
        );
      },
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_twilight_rounded,
            size: 16,
            color: TesseraColors.emberGlow,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: TesseraFonts.body,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: TesseraColors.chalk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The game's name with a small mosaic that drops in tile by tile and a
/// glint that passes over it now and then.
class _Wordmark extends StatefulWidget {
  const _Wordmark();

  @override
  State<_Wordmark> createState() => _WordmarkState();
}

class _WordmarkState extends State<_Wordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _MosaicPainter(_c.value)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  // A glint sweeps across the title in the first 20%.
                  final g = (_c.value / 0.2).clamp(0.0, 1.0);
                  return ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Colors.transparent,
                        Color(0x88FFFFFF),
                        Colors.transparent,
                      ],
                      stops: [
                        (g * 1.4 - 0.3).clamp(0.0, 1.0),
                        (g * 1.4 - 0.2).clamp(0.0, 1.0),
                        (g * 1.4 - 0.1).clamp(0.0, 1.0),
                      ],
                    ).createShader(r),
                    child: child,
                  );
                },
                child: const Text(
                  'Tessera',
                  style: TextStyle(
                    fontFamily: TesseraFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 46,
                    height: 1.0,
                    letterSpacing: -0.5,
                    color: TesseraColors.chalk,
                    shadows: [
                      Shadow(color: Color(0x99E8834A), blurRadius: 24),
                      Shadow(color: Color(0xAA000000), offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A daily puzzle studio',
                style: TextStyle(
                  fontFamily: TesseraFonts.body,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.4,
                  color: TesseraColors.chalkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MosaicPainter extends CustomPainter {
  _MosaicPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 3;
    final gap = size.width * 0.06;
    final cell = (size.width - (n - 1) * gap) / n;
    final colours = [
      TesseraColors.terracotta,
      TesseraColors.gold,
      TesseraColors.celadon,
      TesseraColors.cobalt,
      TesseraColors.emberGlow,
      TesseraColors.glazes[4],
      TesseraColors.glazes[5],
      TesseraColors.terracotta,
      TesseraColors.gold,
    ];
    for (var i = 0; i < 9; i++) {
      // Each tile hops in turn (a slow ripple).
      final phase = ((t * 1.6 - i * 0.06) % 1.0);
      final hop = phase < 0.12 ? -(1 - (phase / 0.06 - 1).abs()) * 4 : 0.0;
      final r = Rect.fromLTWH(
        (i % n) * (cell + gap),
        (i ~/ n) * (cell + gap) + hop,
        cell,
        cell,
      );
      final rr = RRect.fromRectAndRadius(r, Radius.circular(cell * 0.22));
      canvas.drawRRect(
        rr.shift(Offset(0, cell * 0.12)),
        Paint()..color = Color.lerp(colours[i], Colors.black, 0.45)!,
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(colours[i], Colors.white, 0.2)!, colours[i]],
          ).createShader(r),
      );
      canvas.drawCircle(
        Offset(r.left + cell * 0.3, r.top + cell * 0.28),
        cell * 0.1,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_MosaicPainter old) => old.t != t;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          flex: 3,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: TesseraFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: TesseraColors.chalk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: TesseraFonts.body,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: TesseraColors.emberGlow,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A press-to-squish wrapper with the button click.
class _Squish extends StatefulWidget {
  const _Squish({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Squish> createState() => _SquishState();
}

class _SquishState extends State<_Squish> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: enabled
          ? () {
              Juice.button();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: Duration(milliseconds: _down ? 60 : 220),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({
    required this.kind,
    required this.accent,
    this.solved = false,
    this.onTap,
  });

  final PuzzleKind kind;
  final Color accent;
  final bool solved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final lip = Color.lerp(TesseraColors.shelf, Colors.black, 0.45)!;
    return Semantics(
      button: enabled,
      label:
          '${kind.title}${enabled ? '' : ', coming soon'}'
          '${solved ? ', fired' : ''}',
      child: _Squish(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TesseraColors.shelfLight, TesseraColors.shelf],
              ),
              border: Border.all(
                color: solved
                    ? TesseraColors.gold
                    : Colors.white.withValues(alpha: 0.1),
                width: solved ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: lip, offset: const Offset(0, 6)),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 12),
                  blurRadius: 18,
                ),
                if (solved)
                  BoxShadow(
                    color: TesseraColors.gold.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: RadialGradient(
                              center: const Alignment(-0.4, -0.6),
                              radius: 1.2,
                              colors: [
                                Color.lerp(accent, Colors.white, 0.18)!,
                                accent,
                                Color.lerp(accent, Colors.black, 0.3)!,
                              ],
                              stops: const [0, 0.55, 1],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: PuzzleArt(kind: kind),
                          ),
                        ),
                      ),
                      if (solved)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: _FiredBadge(),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                  child: Text(
                    kind.title,
                    style: const TextStyle(
                      fontFamily: TesseraFonts.display,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      height: 1.05,
                      color: TesseraColors.chalk,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: Text(
                    enabled ? kind.tagline : 'In the kiln, coming soon',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: TesseraFonts.body,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.25,
                      color: TesseraColors.chalkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The stamp on a solved tray tile.
class _FiredBadge extends StatelessWidget {
  const _FiredBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 2.4, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, s, child) => Transform.scale(
        scale: s,
        child: Transform.rotate(angle: -0.2, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: TesseraColors.gold,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFF1C9), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x88000000), offset: Offset(0, 2)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: TesseraColors.ink),
            SizedBox(width: 2),
            Text(
              'FIRED',
              style: TextStyle(
                fontFamily: TesseraFonts.body,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
                color: TesseraColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The keystone: an arch with one gem socket per tray puzzle. Each solve
/// sets its glaze in a socket; with all four the arch glows gold.
class _KeystoneTile extends StatefulWidget {
  const _KeystoneTile({
    required this.collected,
    required this.result,
    required this.gems,
    required this.onTap,
  });

  final int collected;

  /// Today's keystone result, once it is set.
  final KeystoneResult? result;

  /// One entry per tray puzzle: its glaze once solved, else null.
  final List<Color?> gems;
  final VoidCallback onTap;

  @override
  State<_KeystoneTile> createState() => _KeystoneTileState();
}

class _KeystoneTileState extends State<_KeystoneTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.gems.length;
    final all = widget.collected == total;
    final result = widget.result;
    return _Squish(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(140),
              bottom: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: TesseraColors.gold.withValues(
                  alpha: (all ? 0.45 : 0.18) + _pulse.value * 0.15,
                ),
                blurRadius: 26 + _pulse.value * 10,
              ),
              const BoxShadow(color: Color(0xFF120B09), offset: Offset(0, 7)),
            ],
          ),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(140),
              bottom: Radius.circular(22),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2A20), Color(0xFF1F1511)],
            ),
            border: Border.all(
              color: TesseraColors.gold.withValues(alpha: all ? 1 : 0.55),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 54,
                height: 40,
                child: CustomPaint(painter: _KeystoneStonePainter()),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keystone',
                style: TextStyle(
                  fontFamily: TesseraFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: TesseraColors.chalk,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final g in widget.gems)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _Gem(color: g),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                switch (result) {
                  KeystoneResult(gold: true) =>
                    'Set in gold today. Well fired.',
                  KeystoneResult() when all =>
                    'Set today. Replay it without hints for gold.',
                  KeystoneResult() =>
                    'Set today. Collect every clue and replay it for gold.',
                  null when all =>
                    'Every clue collected. Set the keystone for gold.',
                  null =>
                    '${widget.collected} of $total clues collected. '
                        'Start now and the keystone lends you tiles.',
                },
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: TesseraFonts.body,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.3,
                  color: TesseraColors.chalkSoft,
                ),
              ),
              const SizedBox(height: 14),
              IgnorePointer(
                child: ClayButton(
                  onPressed: () {},
                  color: all ? TesseraColors.gold : TesseraColors.ember,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 11,
                  ),
                  child: Text(
                    result != null
                        ? 'Play again'
                        : all
                        ? 'Set it in gold'
                        : 'Start the keystone',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gem extends StatelessWidget {
  const _Gem({required this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: c == null ? Colors.black.withValues(alpha: 0.45) : null,
        gradient: c == null
            ? null
            : RadialGradient(
                center: const Alignment(-0.4, -0.5),
                colors: [Color.lerp(c, Colors.white, 0.45)!, c],
              ),
        border: Border.all(
          color: c == null
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: c == null
            ? null
            : [BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 12)],
      ),
      child: c == null
          ? const Icon(Icons.lock_rounded, size: 15, color: Color(0x55FFFFFF))
          : null,
    );
  }
}

/// A wedge-shaped gold stone: the keystone itself.
class _KeystoneStonePainter extends CustomPainter {
  const _KeystoneStonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final wedge = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * 0.78, h)
      ..lineTo(w * 0.22, h)
      ..close();
    canvas.drawPath(
      wedge.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFF6B5020),
    );
    canvas.drawPath(
      wedge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3A0), TesseraColors.gold, Color(0xFF9C7A2E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawLine(
      Offset(w * 0.12, h * 0.18),
      Offset(w * 0.5, h * 0.18),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_KeystoneStonePainter old) => false;
}

/// The kiln: how many days in a row a daily puzzle has been fired, with the
/// last seven days as a strip of small tiles.
class _KilnStreak extends StatelessWidget {
  const _KilnStreak({
    required this.streak,
    required this.best,
    required this.doneToday,
    required this.week,
  });

  final int streak;
  final int best;
  final bool doneToday;
  final List<(PuzzleDay, DayRecord)> week;

  static const _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final lit = streak > 0;
    final headline = switch (streak) {
      0 => 'Light the kiln',
      1 => '1-day kiln',
      _ => '$streak-day kiln',
    };
    final note = !doneToday
        ? (lit
              ? 'Fire a puzzle today to keep it.'
              : 'Fire a puzzle to start a streak.')
        : best > streak
        ? 'Best: $best days'
        : 'Your best run yet';
    return Semantics(
      label: '$headline. $note',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: lit
                ? TesseraColors.emberGlow.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            _Flame(lit: lit, burning: doneToday),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One line: shrink rather than wrap beside the week strip.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      headline,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: TesseraFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: TesseraColors.chalk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: TesseraFonts.body,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: TesseraColors.chalkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            for (final (i, (day, record)) in week.indexed)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: _WeekTile(
                  initial: _initials[day.date.weekday - 1],
                  record: record,
                  today: i == week.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Flame extends StatelessWidget {
  const _Flame({required this.lit, required this.burning});

  final bool lit;
  final bool burning;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.local_fire_department_rounded,
      size: 30,
      color: lit
          ? (burning ? TesseraColors.emberGlow : TesseraColors.terracotta)
          : Colors.white.withValues(alpha: 0.25),
    );
    if (!burning) return icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: TesseraColors.emberGlow.withValues(alpha: 0.45),
            blurRadius: 16,
          ),
        ],
      ),
      child: icon,
    );
  }
}

/// One day in the week strip: empty, fired, or gold when the keystone was
/// set in gold.
class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.initial,
    required this.record,
    required this.today,
  });

  final String initial;
  final DayRecord record;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final gold = record.keystone?.gold ?? false;
    final fired = record.counts;
    final fill = gold
        ? TesseraColors.gold
        : fired
        ? TesseraColors.terracotta
        : Colors.black.withValues(alpha: 0.35);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: today
                  ? TesseraColors.chalk.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: fired ? 0.4 : 0.1),
              width: today ? 1.5 : 1,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          initial,
          style: TextStyle(
            fontFamily: TesseraFonts.body,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            color: today ? TesseraColors.chalk : TesseraColors.chalkSoft,
          ),
        ),
      ],
    );
  }
}
