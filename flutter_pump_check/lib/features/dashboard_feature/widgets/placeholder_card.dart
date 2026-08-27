import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class PlaceholderCard extends StatelessWidget {
  final String text;

  const PlaceholderCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dimensions.values.s16),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s24),
        child: Center(child: Text(text, style: theme.textTheme.bodySmall)),
      ),
    );
  }
}
