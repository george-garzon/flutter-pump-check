import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        dimensions.spacing.pageSide,
        dimensions.spacing.pageTop,
        dimensions.spacing.pageSide,
        dimensions.spacing.pageBottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.sizeOf(context).height -
              dimensions.components.pageMinHeightOffset,
        ),
        child: child,
      ),
    );
  }
}
