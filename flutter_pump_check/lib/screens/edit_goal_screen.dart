import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditGoalScreen extends StatefulWidget {
  const EditGoalScreen({super.key});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
  }

  /// 🔹 Load current goal from Firestore
  Future<void> _loadCurrentGoal() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _controller.text = (data['goalMinutes'] ?? 45).toString();
      } else {
        _controller.text = '45';
      }
    } catch (e) {
      debugPrint('Error loading goal: $e');
      _controller.text = '45';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Save updated goal to Firestore
  Future<void> _saveGoal() async {
    if (_isSaving) return;

    final newGoal = int.tryParse(_controller.text.trim()) ?? 45;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'goalMinutes': newGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal updated to $newGoal minutes ✅')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating goal: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Workout Goal')),
      body: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s16),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal (minutes per day)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: context.dimensions.values.s20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: context.dimensions.values.s14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s16,
                    ),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
