import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onAdd,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.theme.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colors.gray
          ),
        ),
        Row(
          children: [
            if (onAdd != null)
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                      color: colors.gray4,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}