import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _usernameController = TextEditingController();
  final _goalController = TextEditingController();
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();

  /// 🔹 Username validation: only letters, numbers, underscore allowed
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Username cannot be empty";
    }

    final username = value.trim();
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(username)) {
      return "Only letters, numbers, and underscores are allowed";
    }

    if (username.length < 3 || username.length > 20) {
      return "Username must be 3–20 characters long";
    }

    return null;
  }

  /// 🔹 Goal validation
  String? _validateGoal(String? value) {
    if (value == null || value.isEmpty) return "Please enter a goal";
    final goal = int.tryParse(value);
    if (goal == null || goal <= 0) {
      return "Enter a valid number greater than 0";
    }
    return null;
  }

  Future<bool> _isUsernameTaken(String username) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final username = _usernameController.text.trim();
    final goalText = _goalController.text.trim();
    final goal = int.tryParse(goalText);

    setState(() => _loading = true);

    try {
      // 🔹 Check if username is already taken
      final taken = await _isUsernameTaken(username);
      if (!mounted) return;
      if (taken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username '$username' is already taken.")),
        );
        setState(() => _loading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email,
        'username': username,
        'goalCalories': goal,
        'defaultWorkoutMinutes': 30,
        'streakMode': 'strict',
        'themeMode': 'dark',
        'notificationsEnabled': true,
        'hiddenFriends': [],
        'score': 0,
        'friends': [],
        'groups': [],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Welcome to Burn Camp")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Let's get you started",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Choose a username",
                      hintText: "e.g. george_garzon",
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Daily calorie goal",
                      hintText: "e.g. 500",
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateGoal,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Continue"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
