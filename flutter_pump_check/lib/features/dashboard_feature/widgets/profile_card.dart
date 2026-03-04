import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pump_check/screens/workout_modal.dart';
import 'package:flutter_pump_check/services/workout_service.dart';
import 'package:flutter_pump_check/widgets/progress_ring.dart';
import '../../../../theme/theme.dart';


class ProfileCard extends StatelessWidget {
  final String name;
  final int goal;
  final int score;
  final VoidCallback onWorkoutAdded;

  const ProfileCard({
    super.key,
    required this.name,
    required this.goal,
    required this.score,
    required this.onWorkoutAdded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.theme.appColors;
    final user = FirebaseAuth.instance.currentUser!;

    return FutureBuilder<Map<String, dynamic>?>(

      future: WorkoutService.getToday(),
      builder: (context, snapshot) {
        final todayData = snapshot.data ?? {};
        final todayMinutes = todayData['totalMinutes'] ?? 0;
        final progress = goal > 0 ? (todayMinutes / goal).clamp(0.0, 1.0) : 0.0;

        return Card(
          color: colors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProgressRing(progress: progress, size: 70),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: colors.black
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Today: $todayMinutes min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colors.gray,
                          )
                      ),
                      Text(
                        'Goal: $goal min',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.gray,
                        )
                      )
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  children: [
                    Text('Score', style: theme.textTheme.bodySmall),
                    Text(
                      '$score 😁',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final logged = await showWorkoutModal(context);

                        if (logged == true) {
                          onWorkoutAdded();
                        }
                      },
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text("Pump"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}