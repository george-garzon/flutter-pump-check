import 'package:firebase_auth/firebase_auth.dart';

class AuthStorage {
  static Future<bool> isLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
}