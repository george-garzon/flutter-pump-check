import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/login_feature/screens/login_screen.dart';
import '../features/dashboard_feature/screens/dashboard_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {

            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final doc = userSnapshot.data!;

            if (!doc.exists) {
              return const OnboardingScreen();
            }

            final data = doc.data() as Map<String, dynamic>;
            final username = data['username'];
            final goalMinutes = data['goalMinutes'];

            final needsOnboarding =
                username == null || username == '' || goalMinutes == null;

            if (needsOnboarding) {
              return const OnboardingScreen();
            }

            return const DashboardScreen();
          },
        );
      },
    );
  }
}
