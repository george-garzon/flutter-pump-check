import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class DashboardWeekdayLabel extends StatelessWidget {
  const DashboardWeekdayLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLight
              ? ClaudePalette.lightMutedText
              : ClaudePalette.mutedText,
          fontSize: context.textSizes.s13,
        ),
      ),
    );
  }
}
