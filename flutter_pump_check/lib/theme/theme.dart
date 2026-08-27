import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'claude_palette.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_sizes.dart';

class AppTheme {
  //
  // Light theme
  //
  static final light = ThemeData(fontFamily: GoogleFonts.inter().fontFamily)
      .copyWith(
        extensions: [appColors, AppTypography.typography],
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColors.primary,
          brightness: Brightness.light,
          primary: appColors.primary,
          secondary: appColors.secondary,
          surface: appColors.white,
          onSurface: appColors.black,
        ),
        cupertinoOverrideTheme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: appColors.primary,
          scaffoldBackgroundColor: Colors.transparent,
          barBackgroundColor: Colors.transparent,
          textTheme: CupertinoTextThemeData(
            primaryColor: appColors.primary,
            textStyle: TextStyle(color: appColors.black),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.primary,
            foregroundColor: appColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: appColors.gray2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
            borderSide: BorderSide(color: appColors.brownExtraLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
            borderSide: BorderSide(color: appColors.brownExtraLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
            borderSide: BorderSide(color: appColors.primary),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.typography.bodyLarge.copyWith(
            color: appColors.black,
            fontSize: AppTextSizeTokens.s17,
          ),
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: appColors.white,
          labelTextStyle: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            final Color color = states.contains(WidgetState.selected)
                ? appColors.primary
                : appColors.black;
            return TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: AppTextSizeTokens.s12,
            );
          }),
        ),
        scaffoldBackgroundColor: Colors.transparent,
      );

  static const appColors = AppColors(
    // Primary
    primary: ClaudePalette.accent,
    primaryShade1: Color(0xFFFFE4E0),
    primaryShade2: Color(0xFFFFC2BB),
    primaryShade3: Color(0xFFFF9288),
    primaryShade4: Color(0xFFF95D51),
    primaryShade5: Color(0xFFE6352E),
    primaryTint1: Color(0xFFD12B25),
    primaryTint2: ClaudePalette.accentPressed,
    primaryTint3: Color(0xFF8F1715),
    primaryTint4: Color(0xFF641210),
    primaryTint5: Color(0xFF3F0D0B),

    // Secondary
    secondary: Color(0xFF8B5E49),
    secondaryShade1: Color(0xFFF1E6DE),
    secondaryShade2: Color(0xFFE3CABD),
    secondaryShade3: Color(0xFFCFA993),
    secondaryShade4: Color(0xFFB98469),
    secondaryShade5: Color(0xFF8B5E49),
    secondaryTint1: Color(0xFF79513F),
    secondaryTint2: Color(0xFF614032),
    secondaryTint3: Color(0xFF493027),
    secondaryTint4: Color(0xFF33231D),
    secondaryTint5: Color(0xFF241A16),

    // Neutral
    white: ClaudePalette.cream,
    black: ClaudePalette.charcoal,
    gray: ClaudePalette.charcoalSurface,
    gray2: ClaudePalette.creamMuted,
    gray4: ClaudePalette.lightMutedText,

    // Graphic
    brown: ClaudePalette.selectedSurface,
    brownLight: Color(0xFF8B6B5A),
    brownExtraLight: Color(0xFFE6D8CA),

    // Status
    error: Color(0xFFFC3D3D),
    errorLight: Color(0xFFE00004),
    errorExtraLight: Color(0xFFFFE1E0),
    success: Color(0xFF6A8F5B),
    successLight: Color(0xFFAFC49B),
    warning: ClaudePalette.goal,
    warningLight: Color(0xFFF7E6C8),
  );

  //
  // Dark theme
  //
  static final dark = ThemeData.dark().copyWith(
    extensions: [appColors, AppTypography.typography],
    textTheme: TextTheme(
      bodyLarge: AppTypography.typography.bodyLarge.copyWith(
        color: appColors.white,
      ),
      bodyMedium: AppTypography.typography.bodyMedium.copyWith(
        color: appColors.white,
      ),
      bodySmall: AppTypography.typography.bodySmall.copyWith(
        color: appColors.white,
      ),
      displayLarge: AppTypography.typography.displayLarge.copyWith(
        color: appColors.white,
      ),
      displayMedium: AppTypography.typography.displayMedium.copyWith(
        color: appColors.white,
      ),
      displaySmall: AppTypography.typography.displaySmall.copyWith(
        color: appColors.white,
      ),
      labelLarge: AppTypography.typography.labelLarge.copyWith(
        color: appColors.white,
      ),
      labelMedium: AppTypography.typography.labelMedium.copyWith(
        color: appColors.white,
      ),
      labelSmall: AppTypography.typography.labelSmall.copyWith(
        color: appColors.white,
      ),
      headlineLarge: AppTypography.typography.headlineLarge.copyWith(
        color: appColors.white,
      ),
      headlineMedium: AppTypography.typography.headlineMedium.copyWith(
        color: appColors.white,
      ),
      headlineSmall: AppTypography.typography.headlineSmall.copyWith(
        color: appColors.white,
      ),
      titleLarge: AppTypography.typography.titleLarge.copyWith(
        color: appColors.white,
      ),
      titleMedium: AppTypography.typography.titleMedium.copyWith(
        color: appColors.white,
      ),
      titleSmall: AppTypography.typography.titleSmall.copyWith(
        color: appColors.white,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: appColors.primary,
      brightness: Brightness.dark,
      primary: appColors.primary,
      secondary: appColors.secondary,
      surface: appColors.gray,
      onSurface: appColors.white,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: appColors.primary,
      scaffoldBackgroundColor: Colors.transparent,
      barBackgroundColor: Colors.transparent,
      textTheme: CupertinoTextThemeData(
        primaryColor: appColors.primary,
        textStyle: TextStyle(color: appColors.white),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appColors.primary,
        foregroundColor: appColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appColors.gray,
      labelStyle: TextStyle(color: appColors.gray4),
      hintStyle: TextStyle(color: appColors.gray4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
        borderSide: BorderSide(color: appColors.brown),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
        borderSide: BorderSide(color: appColors.brown),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensionTokens.radius12),
        borderSide: BorderSide(color: appColors.primary),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.typography.bodyLarge.copyWith(
        color: appColors.white,
        fontSize: AppTextSizeTokens.s17,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: appColors.black,
      labelTextStyle: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        final Color color = states.contains(WidgetState.selected)
            ? appColors.primary
            : appColors.white;
        return TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: AppTextSizeTokens.s12,
        );
      }),
    ),
    scaffoldBackgroundColor: Colors.transparent,
  );
}

extension ColorThemeExtension on ThemeData {
  /// Usage example: Theme.of(context).appColors;
  AppColors get appColors => extension<AppColors>()!;
}

extension FontThemeExtension on ThemeData {
  /// Usage example: Theme.of(context).appTypography;
  AppTypography get appTypography => extension<AppTypography>()!;
}

extension ThemeGetter on BuildContext {
  // Usage example: `context.theme`
  ThemeData get theme => Theme.of(this);
}
