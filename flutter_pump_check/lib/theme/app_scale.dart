import 'package:flutter/material.dart';

class AppScale extends StatelessWidget {
  static const double factor = 0.85;

  final Widget child;

  const AppScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final virtualSize = Size(
      mediaQuery.size.width / factor,
      mediaQuery.size.height / factor,
    );

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: virtualSize.width,
        maxWidth: virtualSize.width,
        minHeight: virtualSize.height,
        maxHeight: virtualSize.height,
        child: Transform.scale(
          scale: factor,
          alignment: Alignment.topCenter,
          child: MediaQuery(
            data: mediaQuery.copyWith(size: virtualSize),
            child: SizedBox.fromSize(size: virtualSize, child: child),
          ),
        ),
      ),
    );
  }
}
