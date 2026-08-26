import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/login_feature/screens/splash_screen.dart';
import 'package:flutter_pump_check/widgets/ad_supported_app_shell.dart';
import 'features/dashboard_feature/screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_scale.dart';
import 'theme/app_gradient_background.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme_mode.dart';
import 'theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: WorkoutBuddyApp()));
}

class WorkoutBuddyApp extends StatelessWidget {
  const WorkoutBuddyApp({super.key, this.themeMode});
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    if (themeMode != null) {
      appThemeModeNotifier.value = themeMode!;
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, activeThemeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Burn Camp',
          home: const SplashScreen(),
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
          },
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: activeThemeMode,
          scrollBehavior: const AppScrollBehavior(),
          builder: (context, child) {
            return AppGradientBackground(
              child: AppScale(
                child: AdSupportedAppShell(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          // home: const DashboardScreen(),
        );
      },
    );
  }
}
