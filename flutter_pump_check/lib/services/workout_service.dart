import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkoutService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Adds a workout session and updates user score if goal met
  static Future<void> logPump(int minutes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final workoutDocId = '${user.uid}_$today';
    final workoutRef = _db.collection('workouts').doc(workoutDocId);
    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      // Fetch user data (for goal + score)
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;

      final userData = userSnap.data()!;
      final goalMinutes = (userData['goalMinutes'] ?? 0) as int;
      int score = (userData['score'] ?? 0) as int;

      // Fetch workout document for today
      final workoutSnap = await transaction.get(workoutRef);
      int totalMinutes = minutes;

      if (!workoutSnap.exists) {
        // New day entry
        transaction.set(workoutRef, {
          'userId': user.uid,
          'date': today,
          'totalMinutes': minutes,
          'pumpCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing day entry
        final data = workoutSnap.data()!;
        totalMinutes = (data['totalMinutes'] ?? 0) + minutes;
        transaction.update(workoutRef, {
          'totalMinutes': totalMinutes,
          'pumpCount': (data['pumpCount'] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 🏆 Check if goal met (and if we haven’t rewarded yet today)
      if (goalMinutes > 0 && totalMinutes >= goalMinutes) {
        // Optional: store a “goalMet” flag in the workout doc
        final alreadyRewarded =
            workoutSnap.exists && (workoutSnap.data()?['goalMet'] == true);
        if (!alreadyRewarded) {
          score += 1; // increment score
          transaction.update(userRef, {'score': score});
          transaction.update(workoutRef, {'goalMet': true});
        }
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
