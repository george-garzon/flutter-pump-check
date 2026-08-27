import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';

Future<void> showCreateGroupModal(
  BuildContext context,
  List<Friend> friends,
) async {
  final TextEditingController nameController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final theme = Theme.of(context);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dimensions.values.s24),
      ),
      title: const Text("Create New Group"),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: "Group Name",
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
            final groupName = nameController.text.trim();
            if (groupName.isEmpty || user == null) return;

            final groupRef = FirebaseFirestore.instance
                .collection('groups')
                .doc();

            await groupRef.set({
              'name': groupName,
              'memberIds': [user.uid],
              'createdBy': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // also update the user's "groups" array
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'groups': FieldValue.arrayUnion([groupRef.id]),
                });

            Navigator.pop(ctx);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Group '$groupName' created successfully"),
              ),
            );
          },
          child: const Text("Create"),
        ),
      ],
    ),
  );
}
