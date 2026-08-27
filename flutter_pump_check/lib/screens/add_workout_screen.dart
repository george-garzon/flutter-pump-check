import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import '../services/workout_service.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s16),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes worked out',
              ),
            ),
            SizedBox(height: context.dimensions.values.s20),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(_controller.text) ?? 0;
                WorkoutService.logPump(minutes);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
