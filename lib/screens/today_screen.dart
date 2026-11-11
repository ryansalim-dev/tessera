import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../theme/tessera_colors.dart';
import 'cutouts_screen.dart';
import 'glaze_screen.dart';
import 'keystone_screen.dart';
import 'kiln_path_screen.dart';
import 'pebbles_screen.dart';
import 'seams_screen.dart';
import 'shards_screen.dart';

/// The day's tray: four puzzle tiles and the keystone.
///
/// Solved tray puzzles are remembered for this session only, which is enough
/// to unlock the keystone's clues.
///
/// TODO(M2): streak ("kiln"), persistence of the day's progress, Riverpod
/// state and go_router routes.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.today});

  final DateTime? today;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// Tray puzzles solved today, with the hints each took.
  final Map<PuzzleKind, int> _solved = {};
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
      if (!inTray || !mounted) return;
      setState(() => _solved.putIfAbsent(kind, () => hints));
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
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openKeystone(PuzzleDay day, DailyTray tray) {
    if (_keystoneDay != day) {
      _keystone = const KeystoneBuilder().forDay(day);
      _keystoneDay = day;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KeystoneScreen(
          puzzle: _keystone!,
          tray: tray.kinds,
          solved: _solved.keys.toSet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = PuzzleDay.fromLocal(widget.today ?? DateTime.now());
    final tray = DailyTray.forDay(day);
    // Playable types that are not in today's tray, so every finished puzzle
    // type can always be reached.
    final practice = [
      for (final kind in PuzzleKind.values)
        if (kind.isPlayable && !tray.kinds.contains(kind)) kind,
    ];
    final date = day.date;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              'Tessera',
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}'
              '  ·  ${_difficultyLabel(day.difficulty)}',
              style: text.titleMedium?.copyWith(color: TesseraColors.inkSoft),
            ),
            const SizedBox(height: 24),
            Text("Today's tray", style: text.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final (i, kind) in tray.kinds.indexed)
                  _TrayTile(
                    kind: kind,
                    accent: TesseraColors.glazes[i],
                    solved: _solved.containsKey(kind),
                    onTap: kind.isPlayable
                        ? () => _open(kind, day, inTray: true)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _KeystoneTile(
              collected: tray.kinds.where(_solved.containsKey).length,
              total: tray.kinds.length,
              onTap: () => _openKeystone(day, tray),
            ),
            if (practice.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Practice', style: text.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final kind in practice)
                    _TrayTile(
                      kind: kind,
                      accent: TesseraColors.celadon,
                      onTap: () => _open(kind, day, inTray: false),
                    ),
                ],
              ),
            ],
          ],
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
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      label:
          '${kind.title}${enabled ? '' : ', coming soon'}'
          '${solved ? ', fired' : ''}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: solved
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: accent.computeLuminance() > 0.35
                                ? TesseraColors.ink
                                : TesseraColors.clayLight,
                          )
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    kind.title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    enabled ? kind.tagline : 'In the kiln, coming soon',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: TesseraColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeystoneTile extends StatelessWidget {
  const _KeystoneTile({
    required this.collected,
    required this.total,
    required this.onTap,
  });

  final int collected;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = collected == total;
    return Card(
      margin: EdgeInsets.zero,
      color: TesseraColors.ink,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                all ? Icons.lock_open : Icons.lock_outline,
                color: TesseraColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keystone',
                      style: text.titleMedium?.copyWith(
                        color: TesseraColors.clayLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      all
                          ? 'Every clue collected. Set the keystone for gold.'
                          : '$collected of $total clues collected. '
                                'Start now and the keystone lends you tiles.',
                      style: text.bodySmall?.copyWith(
                        color: TesseraColors.grout,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TesseraColors.grout),
            ],
          ),
        ),
      ),
    );
  }
}
