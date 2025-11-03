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
          labelText: "Enter friend's username (e.g. kristen)",
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
              final db = FirebaseFirestore.instance;

              // 🔹 Find user by username
              final friendQuery = await db
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .limit(1)
                  .get();

              if (friendQuery.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No user found with that username."),
                  ),
                );
                return;
              }

              final friendDoc = friendQuery.docs.first;
              final friendId = friendDoc.id;
              final friendData = friendDoc.data();

              // 🔹 Prevent self-add
              if (friendId == user.uid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You can’t add yourself!")),
                );
                return;
              }

              // 🔹 Check if a request already exists
              final existingRequest = await db
                  .collection('friend_requests')
                  .where('fromUserId', isEqualTo: user.uid)
                  .where('toUserId', isEqualTo: friendId)
                  .where('status', isEqualTo: 'pending')
                  .limit(1)
                  .get();

              if (existingRequest.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Friend request already sent.")),
                );
                return;
              }

              // 🔹 Create friend request doc
              await db.collection('friend_requests').add({
                'fromUserId': user.uid,
                'fromUserName': user.displayName ?? user.email ?? 'Unknown',
                'toUserId': friendId,
                'toUserName': friendData['username'] ?? '',
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Friend request sent to ${friendData['username']} ✅",
                  ),
                ),
              );
            } catch (e) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          },
          child: const Text("Send Request"),
        ),
      ],
    ),
  );
}
