import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/app_gradient_background.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';
import 'package:flutter_pump_check/widgets/ad_supported_app_shell.dart';

class DashboardDetailPage extends StatelessWidget {
  const DashboardDetailPage({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final foreground = isLight ? ClaudePalette.charcoal : ClaudePalette.cream;

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: foreground,
              size: context.dimensions.values.s34,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: context.textSizes.s22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            bottom: AdSupportedAppInsets.bottomAdHeightOf(context),
          ),
          child: child,
        ),
      ),
    );
  }
}
