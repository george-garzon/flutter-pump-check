import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class DashboardSettingsRow extends StatelessWidget {
  const DashboardSettingsRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.dividerColor,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final Color dividerColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: context.dimensions.values.s58,
        padding: EdgeInsets.symmetric(
          horizontal: context.dimensions.values.s22,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: context.textSizes.s18,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: context.textSizes.s18,
                  ),
                ),
              ),
            SizedBox(width: context.dimensions.values.s8),
            Icon(
              Icons.chevron_right,
              color: valueColor,
              size: context.dimensions.values.s26,
            ),
          ],
        ),
      ),
    );
  }
}
