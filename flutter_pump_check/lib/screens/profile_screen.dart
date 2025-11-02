import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final nameController = TextEditingController();
  final goalController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// 🔹 Load user's current Firestore profile
  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        nameController.text = data['name'] ?? user.displayName ?? '';
        goalController.text = (data['goalMinutes'] ?? 45).toString();
      } else {
        // If user doc doesn't exist yet, fallback
        nameController.text = user.displayName ?? '';
        goalController.text = '45';
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Save updated name and goal to Firestore
  Future<void> _updateProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final newName = nameController.text.trim();
      final newGoal = int.tryParse(goalController.text.trim()) ?? 45;

      // ✅ Update Firebase Auth displayName
      await user.updateDisplayName(newName);

      // ✅ Update Firestore user document
      final usersRef = FirebaseFirestore.instance.collection('users');
      await usersRef.doc(user.uid).set({
        'name': newName,
        'goalMinutes': newGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// 🔹 Log out
  Future<void> _logout() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect(); // 🔹 disconnect from Google
        await googleSignIn.signOut(); // 🔹 ensure local sign-out
      }

      await FirebaseAuth.instance.signOut(); // 🔹 sign out from Firebase

      // Optional: small delay to allow UI rebuild
      await Future.delayed(const Duration(milliseconds: 300));

      // Go back to AuthGate or LoginScreen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // or '/login' if you prefer
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = user.photoURL;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar + Name
            CircleAvatar(
              radius: 45,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 45)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(user.email ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Username field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Workout goal field
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Workout Goal (minutes/day)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save changes
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),

            const Spacer(),

            // Logout
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
