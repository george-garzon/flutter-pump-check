import 'package:flutter/material.dart';

/// Centralized responsive dimensions for layout, icons, radii, and component
/// sizes. Base token values match the current design; scaling is applied only
/// through the BuildContext-backed APIs.
class AppDimensions {
  AppDimensions._(double scale)
    : spacing = AppSpacing._(scale),
      radii = AppRadii._(scale),
      icons = AppIconSizes._(scale),
      components = AppComponentSizes._(scale),
      values = AppDimensionValues._(scale);

  final AppSpacing spacing;
  final AppRadii radii;
  final AppIconSizes icons;
  final AppComponentSizes components;
  final AppDimensionValues values;

  static AppDimensions of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    final scale = switch (shortestSide) {
      < 600 => 0.80,
      < 900 => 1.08,
      _ => 1.14,
    };

    return AppDimensions._(scale);
  }
}

/// Base layout tokens for contexts where a BuildContext is not available,
/// including static ThemeData construction.
class AppDimensionTokens {
  const AppDimensionTokens._();

  static const double radius12 = 12;
}

/// Generic responsive dimension values for migrating existing fixed layout
/// sizes without changing proportions. Prefer semantic buckets above for new
/// code; use these when preserving an existing one-off dimension.
class AppDimensionValues {
  AppDimensionValues._(this._scale);

  final double _scale;

  double value(double baseSize) => baseSize * _scale;

  double get s0 => 0;
  double get s1 => value(1);
  double get s3 => value(3);
  double get s4 => value(4);
  double get s5 => value(5);
  double get s6 => value(6);
  double get s7 => value(7);
  double get s8 => value(8);
  double get s10 => value(10);
  double get s11 => value(11);
  double get s12 => value(12);
  double get s13 => value(13);
  double get s14 => value(14);
  double get s15 => value(15);
  double get s16 => value(16);
  double get s18 => value(18);
  double get s19 => value(19);
  double get s20 => value(20);
  double get s22 => value(22);
  double get s23 => value(23);
  double get s24 => value(24);
  double get s26 => value(26);
  double get s27 => value(27);
  double get s28 => value(28);
  double get s30 => value(30);
  double get s32 => value(32);
  double get s34 => value(34);
  double get s36 => value(36);
  double get s38 => value(38);
  double get s42 => value(42);
  double get s44 => value(44);
  double get s45 => value(45);
  double get s46 => value(46);
  double get s48 => value(48);
  double get s50 => value(50);
  double get s52 => value(52);
  double get s54 => value(54);
  double get s56 => value(56);
  double get s58 => value(58);
  double get s64 => value(64);
  double get s70 => value(70);
  double get s74 => value(74);
  double get s76 => value(76);
  double get s78 => value(78);
  double get s86 => value(86);
  double get s90 => value(90);
  double get s120 => value(120);
  double get s160 => value(160);
  double get s180 => value(180);
  double get s250 => value(250);
  double get s280 => value(280);
  double get s400 => value(400);
  double get s460 => value(460);
  double get pill => 999;
}

class AppSpacing {
  AppSpacing._(this._scale);

  final double _scale;

  double value(double baseSize) => baseSize * _scale;

  double get xxs => value(4);
  double get xs => value(5);
  double get sm => value(8);
  double get md => value(10);
  double get lg => value(12);
  double get xl => value(14);
  double get xxl => value(16);
  double get xxxl => value(18);
  double get pageSide => value(24);
  double get pageTop => value(10);
  double get pageBottom => value(8);
  double get sectionSmall => value(20);
  double get sectionMedium => value(22);
  double get sectionLarge => value(24);
  double get sectionXLarge => value(26);
  double get sectionXXLarge => value(28);
  double get pageLarge => value(42);
}

class AppRadii {
  AppRadii._(this._scale);

  final double _scale;

  double value(double baseSize) => baseSize * _scale;

  double get sm => value(8);
  double get md => value(10);
  double get lg => value(18);
  double get xl => value(20);
  double get xxl => value(22);
  double get card => value(24);
  double get cardLarge => value(26);
  double get cardXLarge => value(28);
  double get pill => 999;
}

class AppIconSizes {
  AppIconSizes._(this._scale);

  final double _scale;

  double value(double baseSize) => baseSize * _scale;

  double get sm => value(22);
  double get md => value(28);
  double get lg => value(30);
  double get xl => value(34);
  double get xxl => value(42);
}

class AppComponentSizes {
  AppComponentSizes._(this._scale);

  final double _scale;

  double value(double baseSize) => baseSize * _scale;

  double get buttonHeight => value(54);
  double get iconBadge => value(72);
  double get trackingAvatarRadius => value(24);
  double get trustAvatar => value(54);
  double get trustAvatarLarge => value(62);
  double get trustAvatarOverlap => value(42);
  double get timelineLabelWidth => value(72);
  double get topBarProgressHeight => value(6);
  double get pageMinHeightOffset => value(180);
  double starGapFor(double starSize) => starSize * 0.12;
}

extension AppDimensionsContext on BuildContext {
  AppDimensions get dimensions => AppDimensions.of(this);
}
