import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

class OnboardingEyebrow extends StatelessWidget {
  const OnboardingEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: ClaudePalette.accent,
        fontSize: 13,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ClaudePalette.cream,
        fontSize: 36,
        height: 1.02,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class OnboardingBody extends StatelessWidget {
  const OnboardingBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: ClaudePalette.mutedText,
        fontSize: 18,
        height: 1.35,
      ),
    );
  }
}
