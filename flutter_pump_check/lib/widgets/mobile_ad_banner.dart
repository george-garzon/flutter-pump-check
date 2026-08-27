import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MobileAdBanner extends StatefulWidget {
  const MobileAdBanner({super.key});

  static const double topGap = 8;
  static const double standardBannerHeight = 50;

  static double solidHeight(BuildContext context) {
    return standardBannerHeight + MediaQuery.paddingOf(context).bottom;
  }

  @override
  State<MobileAdBanner> createState() => _MobileAdBannerState();
}

class _MobileAdBannerState extends State<MobileAdBanner> {
  BannerAd? _bannerAd;
  var _loaded = false;

  static String? get _testBannerAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/6300978111';
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/2934735716';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final adUnitId = _testBannerAdUnitId;
    if (kIsWeb || adUnitId == null) return;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _loaded = false;
          });
        },
      ),
    );

    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: MobileAdBanner.topGap),
        ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: ad.size.height.toDouble(),
              child: Center(
                child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
