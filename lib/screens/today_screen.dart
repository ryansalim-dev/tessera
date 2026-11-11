import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../theme/tessera_colors.dart';
import 'glaze_screen.dart';
import 'kiln_path_screen.dart';

/// The day's tray: four puzzle tiles and the keystone.
///
/// TODO(M2): streak ("kiln"), keystone clues, persistence, Riverpod state and
/// go_router routes.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.today});

  final DateTime? today;

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

  void _open(BuildContext context, PuzzleKind kind, PuzzleDay day) {
    final seed = day.seedFor(kind);
    final difficulty = day.difficulty;
    final Widget? screen = switch (kind) {
      PuzzleKind.glaze => GlazeScreen(seed: seed, difficulty: difficulty),
      PuzzleKind.kilnPath => KilnPathScreen(seed: seed, difficulty: difficulty),
      _ => null,
    };
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final day = PuzzleDay.fromLocal(today ?? DateTime.now());
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
                    onTap: kind.isPlayable
                        ? () => _open(context, kind, day)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const _KeystoneTile(),
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
                      onTap: () => _open(context, kind, day),
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
  const _TrayTile({required this.kind, required this.accent, this.onTap});

  final PuzzleKind kind;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      label: '${kind.title}${enabled ? '' : ', coming soon'}',
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
  const _KeystoneTile();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: TesseraColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: TesseraColors.gold),
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
                    'Built from your answers. Solve the tray to collect its clues.',
                    style: text.bodySmall?.copyWith(color: TesseraColors.grout),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
