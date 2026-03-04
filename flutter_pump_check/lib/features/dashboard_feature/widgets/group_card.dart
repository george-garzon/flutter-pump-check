import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pump_check/theme/theme.dart';
import 'package:intl/intl.dart';

import '../../../models/friend.dart';
import '../../../models/group.dart';
import '../../../screens/group_invite_modal.dart';
import '../../../screens/message_dialog.dart';

class GroupCard extends StatefulWidget {
  final Group group;
  final VoidCallback refresh;

  const GroupCard({
    super.key,
    required this.group,
    required this.refresh,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  final db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isOwner => widget.group.ownerId == user?.uid;

  Future<List<Friend>> _getFriends() async {
    if (user == null) return [];

    final userDoc = await db.collection('users').doc(user!.uid).get();
    final data = userDoc.data();

    if (data == null || data['friends'] == null) return [];

    final friendIds = List<String>.from(data['friends']);

    if (friendIds.isEmpty) return [];

    final friendsSnap = await db
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds.take(10).toList())
        .get();

    return friendsSnap.docs.map((doc) {
      final f = doc.data();
      return Friend(
        name: f['name'] ?? '',
        username: f['username'] ?? '',
        score: "${f['score'] ?? 0} 🏅",
        completion: 0.0,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> _getGroupStats() async {
    final members = widget.group.memberIds.take(10).toList();

    if (members.isEmpty) {
      return {
        'avgScore': 0.0,
        'goalMetCount': 0,
        'totalMembers': 0,
      };
    }

    final userDocs = await db
        .collection('users')
        .where(FieldPath.documentId, whereIn: members)
        .get();

    int totalScore = 0;
    int goalMetCount = 0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final doc in userDocs.docs) {
      final data = doc.data();
      final uid = doc.id;

      final goal = data['goalMinutes'] ?? 0;
      final score = (data['score'] ?? 0) as int;

      totalScore += score;

      final workoutDoc =
      await db.collection('workouts').doc('${uid}_$today').get();

      if (workoutDoc.exists) {
        final mins = workoutDoc.data()?['totalMinutes'] ?? 0;

        if (goal > 0 && mins >= goal) {
          goalMetCount++;
        }
      }
    }

    final avgScore =
    members.isNotEmpty ? (totalScore / members.length) : 0.0;

    return {
      'avgScore': avgScore,
      'goalMetCount': goalMetCount,
      'totalMembers': members.length,
    };
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Delete "${widget.group.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final invites = await db
          .collection('groups')
          .doc(widget.group.id)
          .collection('invitations')
          .get();

      for (final doc in invites.docs) {
        await doc.reference.delete();
      }

      await db.collection('groups').doc(widget.group.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${widget.group.name}" deleted ✅')),
        );
      }

      widget.refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group: $e')),
      );
    }
  }

  Future<void> _leaveGroup() async {
    if (user == null) return;

    try {
      await db.collection('groups').doc(widget.group.id).update({
        'memberIds': FieldValue.arrayRemove([user!.uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You left ${widget.group.name} 🚪')),
        );
      }

      widget.refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  Future<void> _showGroupDetails() async {
    final theme = Theme.of(context);
    final stats = await _getGroupStats();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('${widget.group.name} — Today’s Performance'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                  'Average Score: ${(stats['avgScore'] ?? 0).toStringAsFixed(1)}'),
              Text(
                  'Goals Met: ${stats['goalMetCount']}/${stats['totalMembers']}'),
              const SizedBox(height: 16),
              const Divider(),

              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: db
                    .collection('users')
                    .where(FieldPath.documentId,
                    whereIn: widget.group.memberIds.take(10).toList())
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final members = snap.data!.docs;

                  return Column(
                    children: members.map((m) {
                      final data = m.data();

                      final username = data['username'] ?? 'Unknown';
                      final name = data['name'] ?? username;
                      final score = data['score'] ?? 0;

                      if (m.id == user?.uid) {
                        return const SizedBox();
                      }

                      return ListTile(
                        dense: true,
                        title: Text(name),
                        subtitle: Text('Score: $score'),
                        trailing: IconButton(
                          icon: const Icon(Icons.message_outlined),
                          onPressed: () async {
                            final chosen =
                            await showMessageDialog(context, '');

                            if (chosen != null && chosen.isNotEmpty) {
                              await db.collection('messages').add({
                                'from': user?.uid,
                                'to': username,
                                'text': chosen,
                                'timestamp':
                                FieldValue.serverTimestamp(),
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                      Text("Sent to $name: $chosen")),
                                );
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.theme.appColors;

    return GestureDetector(
      onTap: _showGroupDetails,
      child: Card(
        color: colors.black,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.group.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 18,
                      )
                    ),
                  ),
                  // Invite button
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1),
                    tooltip: "Invite Friends",
                    onPressed: () async {
                      final friends = await _getFriends();

                      await showGroupInviteModal(
                        context,
                        widget.group.id,
                        widget.group.name,
                        widget.group.memberIds,
                        friends,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      isOwner
                          ? Icons.delete_outline
                          : Icons.exit_to_app,
                      color: isOwner
                          ? colors.primary
                          : colors.primary,
                    ),
                    tooltip: isOwner
                        ? 'Delete Group'
                        : 'Leave Group',
                    onPressed:
                    isOwner ? _deleteGroup : _leaveGroup,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              FutureBuilder<Map<String, dynamic>>(
                future: _getGroupStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(
                      minHeight: 2,
                    );
                  }

                  final stats = snapshot.data!;

                  return Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avg Score: ${(stats['avgScore'] ?? 0).toStringAsFixed(1)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Today: ${stats['goalMetCount']}/${stats['totalMembers']}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}