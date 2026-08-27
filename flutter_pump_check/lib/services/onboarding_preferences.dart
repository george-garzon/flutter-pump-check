import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  static const _completedKey = 'onboarding.completed';
  static const _goalKey = 'onboarding.goal';
  static const _levelKey = 'onboarding.level';
  static const _trainingDaysKey = 'onboarding.trainingDays';
  static const _focusAreasKey = 'onboarding.focusAreas';
  static const _calorieGoalKey = 'onboarding.calorieGoal';
  static const _trackingModeKey = 'onboarding.trackingMode';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fitnessGoal': prefs.getString(_goalKey),
      'experienceLevel': prefs.getString(_levelKey),
      'trainingDaysPerWeek': prefs.getString(_trainingDaysKey),
      'focusAreas': prefs.getStringList(_focusAreasKey) ?? const <String>[],
      'goalCalories': prefs.getInt(_calorieGoalKey) ?? 500,
      'workoutTrackingMode': prefs.getString(_trackingModeKey) ?? 'appleHealth',
      'onboardingCompleted': prefs.getBool(_completedKey) ?? false,
    };
  }

  static Future<void> save({
    required String fitnessGoal,
    required String experienceLevel,
    required String trainingDaysPerWeek,
    required List<String> focusAreas,
    required int goalCalories,
    required String workoutTrackingMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, fitnessGoal);
    await prefs.setString(_levelKey, experienceLevel);
    await prefs.setString(_trainingDaysKey, trainingDaysPerWeek);
    await prefs.setStringList(_focusAreasKey, focusAreas);
    await prefs.setInt(_calorieGoalKey, goalCalories);
    await prefs.setString(_trackingModeKey, workoutTrackingMode);
    await prefs.setBool(_completedKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_goalKey);
    await prefs.remove(_levelKey);
    await prefs.remove(_trainingDaysKey);
    await prefs.remove(_focusAreasKey);
    await prefs.remove(_calorieGoalKey);
    await prefs.remove(_trackingModeKey);
  }

  static Future<void> syncToCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = await load();
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userRef.get();
    final existing = snapshot.data() ?? {};

    await userRef.set({
      ...data,
      'uid': user.uid,
      'email': user.email ?? '',
      if (existing['name'] == null) 'name': user.displayName ?? '',
      if (existing['photoUrl'] == null) 'photoUrl': user.photoURL ?? '',
      if (existing['defaultWorkoutMinutes'] == null)
        'defaultWorkoutMinutes': 30,
      'workoutTrackingMode': data['workoutTrackingMode'] ?? 'appleHealth',
      if (existing['streakMode'] == null) 'streakMode': 'strict',
      if (existing['themeMode'] == null) 'themeMode': 'dark',
      if (existing['notificationsEnabled'] == null)
        'notificationsEnabled': true,
      if (existing['hiddenFriends'] == null) 'hiddenFriends': [],
      if (existing['score'] == null) 'score': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
