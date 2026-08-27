import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final pagePadding = EdgeInsets.fromLTRB(
      dimensions.spacing.pageSide,
      dimensions.spacing.pageTop,
      dimensions.spacing.pageSide,
      dimensions.spacing.pageBottom,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight = constraints.maxHeight - pagePadding.vertical;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: pagePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minContentHeight < 0 ? 0 : minContentHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
