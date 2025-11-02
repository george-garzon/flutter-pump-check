import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  User? _user;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes once
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        setState(() {
          _user = null;
          _loading = false;
        });
        return;
      }

      // Logged in: check Firestore for onboarding completion
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          _needsOnboarding = true;
        } else {
          final data = doc.data() ?? {};
          final username = data['username'];
          final goalMinutes = data['goalMinutes'];
          _needsOnboarding =
              username == null || username == '' || goalMinutes == null;
        }

        setState(() {
          _user = user;
          _loading = false;
        });
      } catch (e) {
        debugPrint("AuthGate Firestore check error: $e");
        setState(() {
          _user = user;
          _needsOnboarding = true;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Not signed in
    if (_user == null) {
      return const LoginScreen();
    }

    // Signed in but missing info
    if (_needsOnboarding) {
      return const OnboardingScreen();
    }

    // Fully onboarded
    return const DashboardScreen();
  }
}
