import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pump_check/theme/theme.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _selectedPhoto;

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

      var nextPhotoUrl = _profilePhotoUrl ?? '';
      if (_selectedPhoto != null) {
        nextPhotoUrl = await _uploadProfilePhoto(_selectedPhoto!);
      }

      await user.updateDisplayName(newName);
      await user.updatePhotoURL(
        nextPhotoUrl.trim().isEmpty ? null : nextPhotoUrl,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'goalMinutes': newGoal,
        'photoUrl': nextPhotoUrl, // ✅ keep Firestore as source of truth
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _profilePhotoUrl = nextPhotoUrl;
      _selectedPhoto = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _uploadProfilePhoto(File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(user.uid)
        .child('profile-$timestamp.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 900,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _selectedPhoto = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not choose photo: $e')));
    }
  }

  Future<void> _showPhotoSourceSheet() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from camera roll'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfilePhoto(ImageSource.gallery);
                },
              ),
              if ((_profilePhotoUrl ?? '').isNotEmpty || _selectedPhoto != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove current photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedPhoto = null;
                      _profilePhotoUrl = '';
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
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
      if (!mounted) return;
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Profile & Settings', style: TextStyle(color: colors.gray)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar + Email
            GestureDetector(
              onTap: _showPhotoSourceSheet,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.2,
                ),
                child: ClipOval(
                  child: _selectedPhoto != null
                      ? Image.file(
                          _selectedPhoto!,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        )
                      : photoUrl != null && photoUrl.isNotEmpty
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
              style: TextStyle(color: colors.gray),
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
              style: TextStyle(color: colors.gray),
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
