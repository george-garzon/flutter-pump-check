import 'package:flutter/material.dart';

import 'claude_palette.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final base = isLight ? ClaudePalette.cream : ClaudePalette.charcoal;
    final topCore = isLight
        ? ClaudePalette.accent.withValues(alpha: 0.34)
        : ClaudePalette.accent.withValues(alpha: 0.48);
    final topHalo = isLight
        ? ClaudePalette.accent.withValues(alpha: 0.18)
        : ClaudePalette.accentPressed.withValues(alpha: 0.38);
    final sideHalo = isLight
        ? ClaudePalette.goal.withValues(alpha: 0.18)
        : ClaudePalette.selectedSurface.withValues(alpha: 0.30);
    final vignette = isLight
        ? ClaudePalette.creamMuted.withValues(alpha: 0.70)
        : const Color(0xFF12110F).withValues(alpha: 0.78);

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  topHalo.withValues(alpha: isLight ? 0.10 : 0.18),
                  base,
                  vignette,
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          Positioned(
            top: -240,
            left: -120,
            right: -120,
            height: 520,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.02, -0.34),
                    radius: 0.72,
                    colors: [topCore, topHalo, Colors.transparent],
                    stops: const [0, 0.36, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -110,
            width: 380,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      sideHalo,
                      sideHalo.withValues(alpha: isLight ? 0.08 : 0.14),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -260,
            left: -180,
            width: 560,
            height: 560,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      vignette.withValues(alpha: isLight ? 0.38 : 0.54),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
