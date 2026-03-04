import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pump_check/theme/theme.dart';
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

  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user's current Firestore profile
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
        _profilePhotoUrl = data['photoUrl']; // ✅ always from users collection
      } else {
        nameController.text = user.displayName ?? '';
        goalController.text = '45';
        _profilePhotoUrl = null;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Save updated name and goal to Firestore
  Future<void> _updateProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final newName = nameController.text.trim();
      final newGoal = int.tryParse(goalController.text.trim()) ?? 45;

      await user.updateDisplayName(newName);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'goalMinutes': newGoal,
        'photoUrl': _profilePhotoUrl, // ✅ keep Firestore as source of truth
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

  /// Log out
  Future<void> _logout() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }

      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
    final colors = context.theme.appColors;
    final photoUrl = _profilePhotoUrl;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colors.white,
      appBar: AppBar(
        title: Text(
            'Profile & Settings',
          style: TextStyle(
            color: colors.gray
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar + Email
            GestureDetector(
              onTap: () async {
                // Later you can allow image upload here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture editing coming soon! 😎'),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Image failed to load: $error");
                            return const Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.white,
                            );
                          },
                        )
                      : const Icon(Icons.person, size: 45, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.email ?? '',
              style: TextStyle(
                color: colors.gray,
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),

            // Display Name
            TextField(
              controller: nameController,
              style: TextStyle(
                color: colors.gray,
              ),
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

              ),
            ),
            const SizedBox(height: 16),

            // Workout Goal
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: colors.gray,
              ),
              decoration: InputDecoration(
                labelText: 'Workout Goal (minutes/day)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.gray,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),

            const Spacer(),

            // 🔹 Logout Button
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white, // ✅ white text
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
