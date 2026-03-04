import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  Future<UserCredential> signInWithGoogle() async {
    UserCredential userCred;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      userCred = await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        throw Exception("User cancelled Google sign in");
      }

      final gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      userCred = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    await _saveUser(userCred.user!);

    return userCred;
  }

  Future<void> _saveUser(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'goalMinutes': 45,
      'score': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}