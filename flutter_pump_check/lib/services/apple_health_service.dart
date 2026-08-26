import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'workout_service.dart';

class AppleHealthImportResult {
  final int importedWorkouts;
  final int calories;
  final int minutes;

  const AppleHealthImportResult({
    required this.importedWorkouts,
    required this.calories,
    required this.minutes,
  });
}

class AppleHealthService {
  AppleHealthService({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const _types = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const _permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

  bool get isAvailableOnDevice =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> requestAuthorization() async {
    if (!isAvailableOnDevice) return false;

    await _health.configure();
    return _health.requestAuthorization(_types, permissions: _permissions);
  }

  Future<AppleHealthImportResult> importRecentWorkouts({
    Duration lookback = const Duration(days: 7),
  }) async {
    if (!isAvailableOnDevice) {
      throw StateError('Apple Health is available on iPhone only.');
    }

    final authorized = await requestAuthorization();
    if (!authorized) {
      throw StateError('Apple Health permission was not granted.');
    }

    final now = DateTime.now();
    final start = now.subtract(lookback);
    final points = await _health.getHealthDataFromTypes(
      types: _types,
      startTime: start,
      endTime: now,
    );
    final uniquePoints = _health.removeDuplicates(points);
    final workoutPoints =
        uniquePoints
            .where((point) => point.type == HealthDataType.WORKOUT)
            .toList()
          ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final activeEnergyPoints = uniquePoints
        .where((point) => point.type == HealthDataType.ACTIVE_ENERGY_BURNED)
        .toList();

    var imported = 0;
    var totalCalories = 0;
    var totalMinutes = 0;

    for (final workoutPoint in workoutPoints) {
      final minutes = workoutPoint.dateTo
          .difference(workoutPoint.dateFrom)
          .inMinutes;
      if (minutes <= 0) continue;

      final calories =
          _workoutCalories(workoutPoint) ??
          _activeCaloriesForWorkout(workoutPoint, activeEnergyPoints);
      if (calories <= 0) continue;

      final didImport = await WorkoutService.logWorkout(
        caloriesBurned: calories,
        minutesTrained: minutes,
        date: workoutPoint.dateFrom,
        workoutType: _workoutTypeLabel(workoutPoint),
        notes: 'Imported from Apple Health',
        source: 'appleHealth',
        externalId: 'appleHealth:${workoutPoint.uuid}',
      );

      if (didImport) {
        imported++;
        totalCalories += calories;
        totalMinutes += minutes;
      }
    }

    return AppleHealthImportResult(
      importedWorkouts: imported,
      calories: totalCalories,
      minutes: totalMinutes,
    );
  }

  int? _workoutCalories(HealthDataPoint point) {
    final value = point.value;
    if (value is! WorkoutHealthValue) return null;

    final calories = value.totalEnergyBurned;
    if (calories == null || calories <= 0) return null;
    return calories;
  }

  int _activeCaloriesForWorkout(
    HealthDataPoint workout,
    List<HealthDataPoint> activeEnergyPoints,
  ) {
    final calories = activeEnergyPoints.fold<double>(0, (total, point) {
      if (point.dateTo.isBefore(workout.dateFrom) ||
          point.dateFrom.isAfter(workout.dateTo)) {
        return total;
      }

      final value = point.value;
      if (value is! NumericHealthValue) return total;
      return total + value.numericValue.toDouble();
    });

    return calories.round();
  }

  String _workoutTypeLabel(HealthDataPoint point) {
    final value = point.value;
    if (value is! WorkoutHealthValue) return 'Apple Health workout';

    final normalized = value.workoutActivityType.name.toLowerCase().replaceAll(
      '_',
      ' ',
    );
    return 'Apple Health $normalized';
  }
}
