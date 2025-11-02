import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';

Future<void> showGroupInviteModal(
  BuildContext context,
  String groupId,
  String groupName,
  List<String> memberIds,
  List<Friend> allFriends,
) async {
  final selected = <String>{};
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  await showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Invite Friends to Group 💌"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: allFriends.map((friend) {
              final normalizedUsername = friend.username.replaceFirst('@', '');
              final alreadyInGroup = memberIds.contains(normalizedUsername);
              return CheckboxListTile(
                value: selected.contains(normalizedUsername),
                onChanged: alreadyInGroup
                    ? null
                    : (v) {
                        if (v == true) {
                          selected.add(normalizedUsername);
                        } else {
                          selected.remove(normalizedUsername);
                        }
                      },
                title: Text(friend.name),
                subtitle: Text(
                  alreadyInGroup ? "Already in group" : friend.username,
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selected.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Select at least one friend")),
                );
                return;
              }

              for (final username in selected) {
                final query = await db
                    .collection('users')
                    .where('username', isEqualTo: '@$username')
                    .limit(1)
                    .get();

                if (query.docs.isEmpty) continue;
                final friendDoc = query.docs.first;
                final friendId = friendDoc.id;
                final friendName = friendDoc.data()['name'] ?? username;

                // ✅ Save under group subcollection (for tracking)
                await db
                    .collection('groups')
                    .doc(groupId)
                    .collection('invitations')
                    .add({
                      'from': user.uid,
                      'to': username,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // ✅ Also save to top-level `group_invites` for SocialScreen
                await db.collection('group_invites').add({
                  'fromUserId': user.uid,
                  'fromUserName': user.displayName ?? '',
                  'toUserId': friendId,
                  'toUserName': friendName,
                  'groupId': groupId,
                  'groupName': groupName,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Invited ${selected.length} friend(s) to $groupName",
                  ),
                ),
              );
            },
            child: const Text("Send Invites"),
          ),
        ],
      );
    },
  );
}
