import 'package:flutter/material.dart';
import 'package:flutter_pump_check/screens/edit_goal_screen.dart';
import 'package:flutter_pump_check/screens/workout_modal.dart';

class FabMenu extends StatelessWidget {
  final VoidCallback refresh;

  const FabMenu({
    super.key,
    required this.refresh,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.fitness_center),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'workout', child: Text('Add Workout')),
        const PopupMenuItem(value: 'goal', child: Text('Edit Goal')),
      ],
      onSelected: (value) async {
        if (value == 'workout') {
          await showWorkoutModal(context);
          refresh();
        } else if (value == 'goal') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditGoalScreen(),
            ),
          );
        }
      },
    );
  }
}