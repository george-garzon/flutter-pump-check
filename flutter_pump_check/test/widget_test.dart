import 'package:flutter_pump_check/services/workout_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutService date helpers', () {
    test('dateKey formats dates for Firestore summary documents', () {
      expect(WorkoutService.dateKey(DateTime(2026, 8, 24)), '2026-08-24');
    });

    test('startOfWeek returns Monday', () {
      expect(
        WorkoutService.startOfWeek(DateTime(2026, 8, 24)),
        DateTime(2026, 8, 24),
      );
      expect(
        WorkoutService.startOfWeek(DateTime(2026, 8, 30)),
        DateTime(2026, 8, 24),
      );
    });
  });
}
