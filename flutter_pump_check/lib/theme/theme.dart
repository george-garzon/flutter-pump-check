import 'package:flutter/material.dart';
import 'claude_palette.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';

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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.primary,
            foregroundColor: appColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: appColors.gray2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: appColors.brownExtraLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: appColors.brownExtraLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: appColors.primary),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: appColors.white,
          titleTextStyle: AppTypography.typography.bodyLarge.copyWith(
            color: appColors.black,
            fontSize: 17,
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
              fontSize: 12,
            );
          }),
        ),
        scaffoldBackgroundColor: appColors.white,
      );

  static const appColors = AppColors(
    // Primary
    primary: ClaudePalette.accent,
    primaryShade1: Color(0xFFF8E7DE),
    primaryShade2: Color(0xFFF1CDBE),
    primaryShade3: Color(0xFFE8AD98),
    primaryShade4: Color(0xFFDF8F74),
    primaryShade5: Color(0xFFD97757),
    primaryTint1: Color(0xFFC96847),
    primaryTint2: ClaudePalette.accentPressed,
    primaryTint3: Color(0xFF7F3B28),
    primaryTint4: Color(0xFF5C2C20),
    primaryTint5: Color(0xFF3E211B),

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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appColors.primary,
        foregroundColor: appColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appColors.gray,
      labelStyle: TextStyle(color: appColors.gray4),
      hintStyle: TextStyle(color: appColors.gray4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.brown),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.brown),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.primary),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: appColors.black,
      titleTextStyle: AppTypography.typography.bodyLarge.copyWith(
        color: appColors.white,
        fontSize: 17,
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
          fontSize: 12,
        );
      }),
    ),
    scaffoldBackgroundColor: appColors.black,
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
