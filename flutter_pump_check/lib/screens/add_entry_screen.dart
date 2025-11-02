import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEntryScreen extends StatefulWidget {
  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      await FirebaseFirestore.instance.collection('weights').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'weight': weight,
        'date': Timestamp.now(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Weight')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (lbs)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter weight' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveEntry, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
