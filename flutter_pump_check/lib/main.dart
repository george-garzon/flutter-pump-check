import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/login_feature/screens/splash_screen.dart';
import 'features/dashboard_feature/screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const ProviderScope(
      child: WorkoutBuddyApp(),
    ),
  );
}

class WorkoutBuddyApp extends StatelessWidget {
  const WorkoutBuddyApp({super.key, this.themeMode});
  final ThemeMode? themeMode;


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pump Check',
      home: const SplashScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // home: const DashboardScreen(),
    );
  }
}
