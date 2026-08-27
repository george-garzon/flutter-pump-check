import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/services/workout_service.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _minutesController = TextEditingController();
  bool _saving = false;

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);

    await WorkoutService.logWorkout(
      caloriesBurned: int.parse(_caloriesController.text.trim()),
      minutesTrained: int.parse(_minutesController.text.trim()),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Add Workout')),
      body: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories burned'),
                validator: _positiveNumberValidator,
              ),
              SizedBox(height: context.dimensions.values.s16),
              TextFormField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes trained'),
                validator: _positiveNumberValidator,
              ),
              SizedBox(height: context.dimensions.values.s24),
              SizedBox(
                width: double.infinity,
                height: context.dimensions.values.s52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveEntry,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Save workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return 'Enter a number greater than 0';
    }
    return null;
  }
}
