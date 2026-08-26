import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/dashboard_feature/screens/dashboard_screen.dart';
import '../services/onboarding_preferences.dart';
import '../theme/app_theme_mode.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingPreferences.isCompleted(),
      builder: (context, onboardingSnapshot) {
        if (!onboardingSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (onboardingSnapshot.data != true) {
          return const OnboardingScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = authSnapshot.data;
            if (user == null) {
              return const DashboardScreen();
            }

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = userSnapshot.data?.data();
                final nextThemeMode = themeModeFromString(
                  data?['themeMode'] as String?,
                );
                if (appThemeModeNotifier.value != nextThemeMode) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (appThemeModeNotifier.value != nextThemeMode) {
                      appThemeModeNotifier.value = nextThemeMode;
                    }
                  });
                }

                return const DashboardScreen();
              },
            );
          },
        );
      },
    );
  }
}
