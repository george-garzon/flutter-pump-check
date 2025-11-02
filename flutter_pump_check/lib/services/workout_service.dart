import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkoutService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Adds a workout session to Firestore for the current user
  static Future<void> logPump(int minutes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${user.uid}_$today';
    final docRef = _db.collection('workouts').doc(docId);

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        // New day entry
        transaction.set(docRef, {
          'userId': user.uid,
          'date': today,
          'totalMinutes': minutes,
          'pumpCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing day entry
        final data = doc.data()!;
        transaction.update(docRef, {
          'totalMinutes': (data['totalMinutes'] ?? 0) + minutes,
          'pumpCount': (data['pumpCount'] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get today’s workout info (for showing in dashboard)
  static Future<Map<String, dynamic>?> getToday() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${user.uid}_$today';
    final snapshot = await _db.collection('workouts').doc(docId).get();

    if (!snapshot.exists) return null;
    return snapshot.data();
  }
}
