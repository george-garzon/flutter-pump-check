import 'package:flutter/material.dart';
import 'package:flutter_pump_check/services/pro_entitlement_service.dart';
import 'package:flutter_pump_check/widgets/mobile_ad_banner.dart';

class AdSupportedAppShell extends StatelessWidget {
  final Widget child;

  const AdSupportedAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ProEntitlementService.watchIsPro(),
      builder: (context, snapshot) {
        final isPro = snapshot.data ?? false;

        return AdSupportedAppInsets(
          bottomAdHeight: 0,
          child: Column(
            children: [
              Expanded(child: child),
              if (!isPro)
                SizedBox(
                  height: MobileAdBanner.solidHeight(context),
                  child: MobileAdBanner(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AdSupportedAppInsets extends InheritedWidget {
  final double bottomAdHeight;

  const AdSupportedAppInsets({
    super.key,
    required this.bottomAdHeight,
    required super.child,
  });

  static double bottomAdHeightOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AdSupportedAppInsets>()
            ?.bottomAdHeight ??
        0;
  }

  @override
  bool updateShouldNotify(AdSupportedAppInsets oldWidget) {
    return bottomAdHeight != oldWidget.bottomAdHeight;
  }
}
