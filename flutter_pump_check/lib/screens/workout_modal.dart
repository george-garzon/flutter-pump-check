import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/theme.dart';
import '../services/workout_service.dart';
import '../widgets/progress_ring.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

Future<bool> showWorkoutModal(BuildContext context) async {
  double selectedMinutes = 30; // default slider
  int todayMinutes = 0;
  int goalMinutes = 45; // You can later fetch this from Firestore 'users' doc
  final colors = context.theme.appColors;

  // Get today's data
  final todayData = await WorkoutService.getToday();
  if (todayData != null) {
    todayMinutes = todayData['totalMinutes'] ?? 0;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        backgroundColor: colors.gray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.dimensions.values.s20),
        ),
        content: StatefulBuilder(
          builder: (ctx, setState) {
            final progress = goalMinutes > 0 ? todayMinutes / goalMinutes : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Ring
                ProgressRing(
                  progress: progress.clamp(0.0, 1.0),
                  size: context.dimensions.values.s120,
                ),
                SizedBox(height: context.dimensions.values.s12),

                // Text labels
                Text(
                  "$todayMinutes min / $goalMinutes min",
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: context.dimensions.values.s12),

                // Selected minutes
                Text(
                  "${selectedMinutes.toStringAsFixed(0)} min",
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: context.textSizes.s22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Slider
                Slider(
                  value: selectedMinutes,
                  min: 0,
                  max: 180,
                  divisions: 36,
                  label: "${selectedMinutes.toStringAsFixed(0)} min",
                  onChanged: (v) => setState(() => selectedMinutes = v),
                ),

                SizedBox(height: context.dimensions.values.s10),

                // Preset buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _presetButton(
                      ctx,
                      label: "Quick Warmup",
                      minutes: 10,
                      onSelect: (m) =>
                          setState(() => selectedMinutes = m.toDouble()),
                    ),
                    _presetButton(
                      ctx,
                      label: "Full Workout",
                      minutes: 45,
                      onSelect: (m) =>
                          setState(() => selectedMinutes = m.toDouble()),
                    ),
                    _presetButton(
                      ctx,
                      label: "Marathon Day",
                      minutes: 90,
                      onSelect: (m) =>
                          setState(() => selectedMinutes = m.toDouble()),
                    ),
                  ],
                ),

                SizedBox(height: context.dimensions.values.s16),

                // Log button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.dimensions.values.s20,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: context.dimensions.values.s12,
                    ),
                  ),
                  onPressed: () async {
                    final mins = selectedMinutes.toInt();

                    await WorkoutService.logPump(mins);

                    // Update local state for instant feedback
                    setState(() {
                      todayMinutes += mins;
                    });

                    Navigator.pop(ctx, true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("💪 Pump logged: $mins min!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    "Log Workout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // Close button
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text("Close"),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  return result ?? false;
}

// Small preset button widget
Widget _presetButton(
  BuildContext context, {
  required String label,
  required int minutes,
  required ValueChanged<int> onSelect,
}) {
  final theme = Theme.of(context);
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dimensions.values.s20),
      ),
      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
    ),
    onPressed: () => onSelect(minutes),
    child: Text(label, style: theme.textTheme.bodySmall),
  );
}
