import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0–1.0
  final double size;
  final Color? color;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: ringColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              );
            },
          ),
          // Inner avatar
          const CircleAvatar(radius: 22),
        ],
      ),
    );
  }
}
