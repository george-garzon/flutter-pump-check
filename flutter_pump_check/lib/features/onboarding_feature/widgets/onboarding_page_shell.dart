import 'package:flutter/material.dart';

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 180,
        ),
        child: child,
      ),
    );
  }
}
