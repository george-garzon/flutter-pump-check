import 'package:flutter/material.dart';

/// Centralized responsive font sizes.
///
/// Each getter name maps to the existing base font size used throughout the
/// app. For example, `context.textSizes.s18` preserves the old 18px design
/// intent, then applies one responsive multiplier based on the current screen.
class AppTextSizes {
  AppTextSizes._(this._scale);

  final double _scale;

  static AppTextSizes of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    final scale = switch (shortestSide) {
      < 600 => 0.80,
      < 900 => 1.12,
      _ => 1.2,
    };

    return AppTextSizes._(scale);
  }

  double value(double baseSize) => baseSize * _scale;

  double get s11 => value(AppTextSizeTokens.s11);
  double get s12 => value(AppTextSizeTokens.s12);
  double get s13 => value(AppTextSizeTokens.s13);
  double get s14 => value(AppTextSizeTokens.s14);
  double get s15 => value(AppTextSizeTokens.s15);
  double get s16 => value(AppTextSizeTokens.s16);
  double get s17 => value(AppTextSizeTokens.s17);
  double get s18 => value(AppTextSizeTokens.s18);
  double get s19 => value(AppTextSizeTokens.s19);
  double get s20 => value(AppTextSizeTokens.s20);
  double get s21 => value(AppTextSizeTokens.s21);
  double get s22 => value(AppTextSizeTokens.s22);
  double get s23 => value(AppTextSizeTokens.s23);
  double get s24 => value(AppTextSizeTokens.s24);
  double get s25 => value(AppTextSizeTokens.s25);
  double get s26 => value(AppTextSizeTokens.s26);
  double get s27 => value(AppTextSizeTokens.s27);
  double get s28 => value(AppTextSizeTokens.s28);
  double get s32 => value(AppTextSizeTokens.s32);
  double get s36 => value(AppTextSizeTokens.s36);
  double get s38 => value(AppTextSizeTokens.s38);
  double get s45 => value(AppTextSizeTokens.s45);
  double get s52 => value(AppTextSizeTokens.s52);
  double get s57 => value(AppTextSizeTokens.s57);
  double get s64 => value(AppTextSizeTokens.s64);
  double get s66 => value(AppTextSizeTokens.s66);
  double get s68 => value(AppTextSizeTokens.s68);
  double get s84 => value(AppTextSizeTokens.s84);
}

/// Base design tokens for contexts where a BuildContext is not available,
/// including static ThemeData construction.
class AppTextSizeTokens {
  const AppTextSizeTokens._();

  static const double s11 = 11;
  static const double s12 = 12;
  static const double s13 = 13;
  static const double s14 = 14;
  static const double s15 = 15;
  static const double s16 = 16;
  static const double s17 = 17;
  static const double s18 = 18;
  static const double s19 = 19;
  static const double s20 = 20;
  static const double s21 = 21;
  static const double s22 = 22;
  static const double s23 = 23;
  static const double s24 = 24;
  static const double s25 = 25;
  static const double s26 = 26;
  static const double s27 = 27;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s38 = 38;
  static const double s45 = 45;
  static const double s52 = 52;
  static const double s57 = 57;
  static const double s64 = 64;
  static const double s66 = 66;
  static const double s68 = 68;
  static const double s84 = 84;
}

extension AppTextSizesContext on BuildContext {
  AppTextSizes get textSizes => AppTextSizes.of(this);
}
