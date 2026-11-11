import 'package:flutter/material.dart';

import '../juice/juice.dart';

/// Opening a puzzle: the new screen rises out of the tile with a quick
/// zoom and fade, and a soft whoosh.
class TileRoute<T> extends PageRouteBuilder<T> {
  TileRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondary, child) {
          final t = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final out = CurvedAnimation(parent: secondary, curve: Curves.easeIn);
          return FadeTransition(
            opacity: t,
            child: ScaleTransition(
              scale: Tween(begin: 0.86, end: 1.0).animate(t),
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.06).animate(out),
                child: child,
              ),
            ),
          );
        },
      ) {
    Juice.whoosh();
  }
}
