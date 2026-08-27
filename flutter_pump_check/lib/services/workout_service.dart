import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _dateFormatter = DateFormat('yyyy-MM-dd');
  static final _localSummariesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static const _localSummariesKey = 'workouts.localSummaries';

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

  static Future<bool> logWorkout({
    required int caloriesBurned,
    required int minutesTrained,
    DateTime? date,
    String? workoutType,
    String? notes,
    String? source,
    String? externalId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return _logLocalWorkout(
        caloriesBurned: caloriesBurned,
        minutesTrained: minutesTrained,
        date: date,
        workoutType: workoutType,
        notes: notes,
        source: source,
        externalId: externalId,
      );
    }

    final entryDate = startOfDay(date ?? DateTime.now());
    final key = dateKey(entryDate);
    final summaryDocId = '${user.uid}_$key';
    final summaryRef = _db.collection('workouts').doc(summaryDocId);
    final entryRef = summaryRef.collection('entries').doc();
    final userRef = _db.collection('users').doc(user.uid);

    return _db.runTransaction<bool>((transaction) async {
      final userSnap = await transaction.get(userRef);
      final summarySnap = await transaction.get(summaryRef);

      final userData = userSnap.data() ?? {};
      final goalCalories =
          (userData['goalCalories'] as num?)?.toInt() ??
          (userData['goalMinutes'] as num?)?.toInt() ??
          500;
      final currentScore = (userData['score'] as num?)?.toInt() ?? 0;

      final existing = summarySnap.data() ?? {};
      final importedIds = List<String>.from(
        existing['externalWorkoutIds'] ?? const [],
      );
      if (externalId != null && importedIds.contains(externalId)) {
        return false;
      }

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
        'source': source ?? 'manual',
        if (externalId != null) 'externalId': externalId,
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
        if (externalId != null)
          'externalWorkoutIds': FieldValue.arrayUnion([externalId]),
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

      return true;
    });
  }

  /// Backward-compatible wrapper for older minute-only screens.
  static Future<void> logPump(int minutes) async {
    await logWorkout(caloriesBurned: 0, minutesTrained: minutes);
  }

  static Future<Map<String, dynamic>?> getToday() async {
    final user = _auth.currentUser;
    if (user == null) {
      final today = dateKey(DateTime.now());
      final summaries = await _localSummaries();
      for (final summary in summaries) {
        if (summary['date'] == today) return summary;
      }
      return null;
    }

    final today = dateKey(DateTime.now());
    final docId = '${user.uid}_$today';
    final snapshot = await _db.collection('workouts').doc(docId).get();

    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  static Stream<Map<String, dynamic>?> watchDay({DateTime? date}) {
    final user = _auth.currentUser;
    if (user == null) {
      final key = dateKey(date ?? DateTime.now());
      return watchSummaries().map((summaries) {
        for (final summary in summaries) {
          if (summary['date'] == key) return summary;
        }
        return null;
      });
    }

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
    if (user == null) {
      return _watchLocalSummaries(from: from, limit: limit);
    }

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

  static Stream<List<Map<String, dynamic>>> _watchLocalSummaries({
    DateTime? from,
    int limit = 60,
  }) async* {
    yield _filterLocalSummaries(
      await _localSummaries(),
      from: from,
      limit: limit,
    );
    yield* _localSummariesController.stream.map(
      (summaries) => _filterLocalSummaries(summaries, from: from, limit: limit),
    );
  }

  static List<Map<String, dynamic>> _filterLocalSummaries(
    List<Map<String, dynamic>> summaries, {
    DateTime? from,
    required int limit,
  }) {
    final filtered = summaries.where((summary) {
      if (from == null) return true;
      final date = _summaryDate(summary);
      return !date.isBefore(startOfDay(from));
    }).toList();

    filtered.sort((a, b) => _summaryDate(b).compareTo(_summaryDate(a)));
    return filtered.take(limit).toList();
  }

  static Future<bool> _logLocalWorkout({
    required int caloriesBurned,
    required int minutesTrained,
    DateTime? date,
    String? workoutType,
    String? notes,
    String? source,
    String? externalId,
  }) async {
    final entryDate = startOfDay(date ?? DateTime.now());
    final key = dateKey(entryDate);
    final summaries = await _localSummaries();
    final index = summaries.indexWhere((summary) => summary['date'] == key);
    final existing = index == -1 ? <String, dynamic>{} : summaries[index];
    final externalIds = List<String>.from(
      existing['externalWorkoutIds'] ?? const [],
    );

    if (externalId != null && externalIds.contains(externalId)) {
      return false;
    }

    final previousCalories =
        (existing['totalCaloriesBurned'] as num?)?.toInt() ?? 0;
    final previousMinutes =
        (existing['totalMinutesTrained'] as num?)?.toInt() ?? 0;
    final previousEntryCount = (existing['entryCount'] as num?)?.toInt() ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final goalCalories =
        prefs.getInt('settings.goalCalories') ??
        prefs.getInt('onboarding.calorieGoal') ??
        (existing['goalCalories'] as num?)?.toInt() ??
        500;
    final totalCalories = previousCalories + caloriesBurned;
    final totalMinutes = previousMinutes + minutesTrained;

    if (externalId != null) externalIds.add(externalId);

    final summary = {
      ...existing,
      'id': 'local_$key',
      'userId': 'local',
      'date': key,
      'totalCaloriesBurned': totalCalories,
      'totalMinutesTrained': totalMinutes,
      'entryCount': previousEntryCount + 1,
      'goalCalories': goalCalories,
      'goalMet': goalCalories > 0 && totalCalories >= goalCalories,
      'externalWorkoutIds': externalIds,
      'lastWorkoutType': workoutType,
      'lastNotes': notes,
      'lastSource': source ?? 'manual',
      'updatedAt': DateTime.now().toIso8601String(),
      'createdAt':
          existing['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    };

    if (index == -1) {
      summaries.add(summary);
    } else {
      summaries[index] = summary;
    }

    await _saveLocalSummaries(summaries);
    return true;
  }

  static Future<void> updateGoalCalories(int goalCalories) async {
    final user = _auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('settings.goalCalories', goalCalories);
      final summaries = await _localSummaries();
      final updated = summaries.map((summary) {
        final calories = caloriesFromSummary(summary);
        return {
          ...summary,
          'goalCalories': goalCalories,
          'goalMet': goalCalories > 0 && calories >= goalCalories,
        };
      }).toList();
      await _saveLocalSummaries(updated);
      return;
    }

    final snapshots = await _db
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .get();
    WriteBatch? batch;
    var operationCount = 0;

    Future<void> commitBatch() async {
      if (batch == null || operationCount == 0) return;
      await batch!.commit();
      batch = null;
      operationCount = 0;
    }

    for (final doc in snapshots.docs) {
      batch ??= _db.batch();
      final summary = doc.data();
      final calories = caloriesFromSummary(summary);
      batch!.set(doc.reference, {
        'goalCalories': goalCalories,
        'goalMet': goalCalories > 0 && calories >= goalCalories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      operationCount++;

      if (operationCount >= 450) {
        await commitBatch();
      }
    }

    await commitBatch();
  }

  static Future<List<Map<String, dynamic>>> _localSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localSummariesKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> _saveLocalSummaries(
    List<Map<String, dynamic>> summaries,
  ) async {
    summaries.sort((a, b) => _summaryDate(b).compareTo(_summaryDate(a)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localSummariesKey, jsonEncode(summaries));
    _localSummariesController.add(summaries);
  }
}
