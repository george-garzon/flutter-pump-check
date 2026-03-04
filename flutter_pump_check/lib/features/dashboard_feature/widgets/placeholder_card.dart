import 'package:flutter/material.dart';

class PlaceholderCard extends StatelessWidget {
  final String text;

  const PlaceholderCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(text, style: theme.textTheme.bodySmall),
        ),
      ),
    );
  }
}