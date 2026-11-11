import 'package:flutter/material.dart';

import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';
import 'clay_button.dart';

/// A row of glaze pots, one per value, as chunky clay buttons.
class GlazePalette extends StatelessWidget {
  const GlazePalette({super.key, required this.count, required this.onPick});

  final int count;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var v = 1; v <= count; v++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AspectRatio(
                aspectRatio: count > 6 ? 0.82 : 1,
                child: ClayButton(
                  onPressed: () => onPick(v),
                  color: TesseraColors.glaze(v),
                  sound: false,
                  radius: 12,
                  depth: 5,
                  padding: EdgeInsets.zero,
                  semanticLabel: 'Glaze $v',
                  child: Text(
                    '$v',
                    semanticsLabel: 'Glaze $v',
                    style: TextStyle(
                      fontFamily: TesseraFonts.body,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TesseraColors.onGlaze(v),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
