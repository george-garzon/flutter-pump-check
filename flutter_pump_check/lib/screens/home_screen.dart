import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_entry_screen.dart';
// import '../widgets/weight_chart.dart';

class HomeScreen extends StatelessWidget {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final weightsRef = FirebaseFirestore.instance.collection('weights');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: weightsRef
            .where('userId', isEqualTo: uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final entries = snapshot.data!.docs;

          if (entries.isEmpty)
            return const Center(child: Text('No entries yet.'));

          return Column(
            children: [
              // Expanded(child: WeightChart(entries: entries)),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final weight = e['weight'];
                    final date = (e['date'] as Timestamp).toDate();
                    return ListTile(
                      title: Text('$weight lbs'),
                      subtitle: Text('${date.year}-${date.month}-${date.day}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => e.reference.delete(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEntryScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
