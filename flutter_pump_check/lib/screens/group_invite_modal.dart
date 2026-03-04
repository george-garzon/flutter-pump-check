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

      // Use StatefulBuilder to refresh checkboxes when tapped
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Invite Friends to Group 💌"),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView(
                children: allFriends.map((friend) {
                  final normalizedUsername = friend.username.replaceFirst(
                    '@',
                    '',
                  );
                  final alreadyInGroup = memberIds.contains(normalizedUsername);
                  final isSelected = selected.contains(normalizedUsername);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: alreadyInGroup
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(normalizedUsername);
                              } else {
                                selected.remove(normalizedUsername);
                              }
                            });
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
                  debugPrint("🚀 Send Invites pressed");
                  if (selected.isEmpty) {
                    debugPrint("⚠️ No friends selected");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Select at least one friend"),
                      ),
                    );
                    return;
                  }

                  for (final username in selected) {
                    debugPrint(
                      "🔍 Searching for user with username $username ...",
                    );

                    final query = await db
                        .collection('users')
                        .where('username', isEqualTo: '$username')
                        .limit(1)
                        .get();

                    if (query.docs.isEmpty) {
                      debugPrint("❌ No user found with username $username");
                      continue;
                    }

                    final friendDoc = query.docs.first;
                    final friendId = friendDoc.id;
                    final friendName = friendDoc.data()['name'] ?? username;

                    debugPrint("✅ Found user: $friendName ($friendId)");

                    try {
                      await db
                          .collection('groups')
                          .doc(groupId)
                          .collection('invitations')
                          .add({
                            'from': user.uid,
                            'to': friendId,
                            'status': 'pending',
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                      debugPrint("📩 Added to groups/$groupId/invitations");

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
                      debugPrint("📤 Added to top-level /group_invites");
                    } catch (e, st) {
                      debugPrint("❌ Firestore error: $e\n$st");
                    }
                  }

                  debugPrint("✅ Finished sending all invites");
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
    },
  );
}
