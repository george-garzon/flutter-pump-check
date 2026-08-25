import 'package:flutter/material.dart';

import 'claude_palette.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget child;
  final bool blocksRouteBehind;

  const AppGradientBackground({
    super.key,
    required this.child,
    this.blocksRouteBehind = true,
  });

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

    final background = DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -150,
            left: -45,
            right: -105,
            height: 460,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.27, -0.34),
                    radius: 0.72,
                    colors: [topCore, topHalo, Colors.transparent],
                    stops: const [0, 0.36, 1],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (!blocksRouteBehind) return background;

    return ColoredBox(color: base, child: background);
  }
}
