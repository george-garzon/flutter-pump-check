import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ✅ Updated signInWithGoogle function (works for Web + Native)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final userCred = await FirebaseAuth.instance.signInWithPopup(
        googleProvider,
      );

      // Save user info to Firestore
      final user = userCred.user!;

      try {
        print("📝 Writing user to Firestore...");
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'goalMinutes': 45,
          'score': 0,
          'joinedAt': DateTime.now(),
        }, SetOptions(merge: true));
        print("✅ Firestore write success!");
      } catch (e, st) {
        print("🔥 Firestore write failed: $e");
        print(st);
      }

      return userCred;
    } else {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication gAuth = await gUser!.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Save user info to Firestore
      final user = userCred.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'goalMinutes': 45,
        'score': 0,
        'joinedAt': DateTime.now(),
      }, SetOptions(merge: true));

      return userCred;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            try {
              await signInWithGoogle();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
              }
            } finally {
              if (context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.login, color: Colors.white),
          label: const Text(
            "Sign in with Google",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9BBF9E), // light sage green
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
