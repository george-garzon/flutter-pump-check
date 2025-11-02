import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WorkoutBuddyApp());
}

class WorkoutBuddyApp extends StatelessWidget {
  const WorkoutBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pump Check',
      home: const AuthGate(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F5F0),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8BA989),
          secondary: Color(0xFFA4C3A2),
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1E2A24)),
          bodySmall: TextStyle(color: Color(0xFF556B56)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E2A24),
        cardColor: const Color(0xFF2E3B33),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9DBB9D),
          secondary: Color(0xFF7FA47C),
          surface: Color(0xFF2E3B33),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE6EDE6)),
          bodySmall: TextStyle(color: Color(0xFF9FB39D)),
        ),
      ),
      // home: const DashboardScreen(),
    );
  }
}
