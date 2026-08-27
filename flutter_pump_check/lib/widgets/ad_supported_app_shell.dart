import 'package:flutter/material.dart';
import 'package:flutter_pump_check/services/pro_entitlement_service.dart';
import 'package:flutter_pump_check/widgets/mobile_ad_banner.dart';

class AdSupportedAppShell extends StatelessWidget {
  final Widget child;

  const AdSupportedAppShell({super.key, required this.child});

  static final adsHidden = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adsHidden,
      builder: (context, hideAds, _) {
        return StreamBuilder<bool>(
          stream: ProEntitlementService.watchIsPro(),
          builder: (context, snapshot) {
            final isPro = snapshot.data ?? false;
            final showAd = !hideAds && !isPro;
            final adHeight = showAd ? MobileAdBanner.solidHeight(context) : 0.0;

            return AdSupportedAppInsets(
              bottomAdHeight: 0,
              child: Column(
                children: [
                  Expanded(child: child),
                  if (showAd)
                    SizedBox(height: adHeight, child: const MobileAdBanner()),
                ],
              ),
            );
          },
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
