import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showAddFriendModal(BuildContext context) async {
  final TextEditingController usernameController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final theme = Theme.of(context);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text("Add Friend by Username"),
      content: TextField(
        controller: usernameController,
        decoration: const InputDecoration(
          labelText: "Enter friend's username (e.g. @kristen)",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () async {
            final username = usernameController.text.trim();
            if (username.isEmpty || user == null) return;

            try {
              // 🔹 Find the user by username
              final result = await FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .limit(1)
                  .get();

              if (result.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No user found with that username."),
                  ),
                );
                return;
              }

              final friendDoc = result.docs.first;
              final friendId = friendDoc.id;

              // 🔹 Update both users' friend lists
              final currentUserRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid);
              final friendUserRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId);

              await FirebaseFirestore.instance.runTransaction((txn) async {
                txn.update(currentUserRef, {
                  'friends': FieldValue.arrayUnion([friendId]),
                });
                txn.update(friendUserRef, {
                  'friends': FieldValue.arrayUnion([user.uid]),
                });
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("You are now friends with ${username}")),
              );
            } catch (e) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error adding friend: $e")),
              );
            }
          },
          child: const Text("Add Friend"),
        ),
      ],
    ),
  );
}
