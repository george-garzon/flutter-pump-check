import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkoutService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime date) => _dateFormatter.format(date);

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final day = startOfDay(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  static Future<void> logWorkout({
    required int caloriesBurned,
    required int minutesTrained,
    DateTime? date,
    String? workoutType,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final entryDate = startOfDay(date ?? DateTime.now());
    final key = dateKey(entryDate);
    final summaryDocId = '${user.uid}_$key';
    final summaryRef = _db.collection('workouts').doc(summaryDocId);
    final entryRef = summaryRef.collection('entries').doc();
    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final summarySnap = await transaction.get(summaryRef);

      final userData = userSnap.data() ?? {};
      final goalCalories =
          (userData['goalCalories'] as num?)?.toInt() ??
          (userData['goalMinutes'] as num?)?.toInt() ??
          500;
      final currentScore = (userData['score'] as num?)?.toInt() ?? 0;

      final existing = summarySnap.data() ?? {};
      final previousCalories =
          (existing['totalCaloriesBurned'] as num?)?.toInt() ?? 0;
      final previousMinutes =
          (existing['totalMinutesTrained'] as num?)?.toInt() ??
          (existing['totalMinutes'] as num?)?.toInt() ??
          0;
      final previousEntryCount =
          (existing['entryCount'] as num?)?.toInt() ??
          (existing['pumpCount'] as num?)?.toInt() ??
          0;

      final totalCalories = previousCalories + caloriesBurned;
      final totalMinutes = previousMinutes + minutesTrained;
      final goalMet = goalCalories > 0 && totalCalories >= goalCalories;
      final wasGoalMet = existing['goalMet'] == true;

      transaction.set(entryRef, {
        'userId': user.uid,
        'date': Timestamp.fromDate(entryDate),
        'dateKey': key,
        'caloriesBurned': caloriesBurned,
        'minutesTrained': minutesTrained,
        'workoutType': workoutType,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(summaryRef, {
        'userId': user.uid,
        'date': key,
        'dateTimestamp': Timestamp.fromDate(entryDate),
        'totalCaloriesBurned': totalCalories,
        'totalMinutesTrained': totalMinutes,
        'entryCount': previousEntryCount + 1,
        'goalCalories': goalCalories,
        'goalMet': goalMet,
        'createdAt': summarySnap.exists
            ? existing['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (goalMet && !wasGoalMet) {
        transaction.set(userRef, {
          'score': currentScore + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Backward-compatible wrapper for older minute-only screens.
  static Future<void> logPump(int minutes) {
    return logWorkout(caloriesBurned: 0, minutesTrained: minutes);
  }

  static Future<Map<String, dynamic>?> getToday() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final today = dateKey(DateTime.now());
    final docId = '${user.uid}_$today';
    final snapshot = await _db.collection('workouts').doc(docId).get();

    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  static Stream<Map<String, dynamic>?> watchDay({DateTime? date}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final key = dateKey(date ?? DateTime.now());
    return _db.collection('workouts').doc('${user.uid}_$key').snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  static Stream<List<Map<String, dynamic>>> watchSummaries({
    DateTime? from,
    int limit = 60,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query<Map<String, dynamic>> query = _db
        .collection('workouts')
        .where('userId', isEqualTo: user.uid);

    if (from != null) {
      query = query.where(
        'dateTimestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay(from)),
      );
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final summaries = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      summaries.sort((a, b) {
        return _summaryDate(b).compareTo(_summaryDate(a));
      });

      return summaries;
    });
  }

  static int caloriesFromSummary(Map<String, dynamic>? summary) {
    return (summary?['totalCaloriesBurned'] as num?)?.toInt() ?? 0;
  }

  static int minutesFromSummary(Map<String, dynamic>? summary) {
    return (summary?['totalMinutesTrained'] as num?)?.toInt() ??
        (summary?['totalMinutes'] as num?)?.toInt() ??
        0;
  }

  static DateTime _summaryDate(Map<String, dynamic> summary) {
    final timestamp = summary['dateTimestamp'];
    if (timestamp is Timestamp) return timestamp.toDate();

    final date = summary['date'];
    if (date is String) return DateTime.tryParse(date) ?? DateTime(1970);

    return DateTime(1970);
  }
}
