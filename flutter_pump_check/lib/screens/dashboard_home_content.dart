import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/friend.dart';
import '../models/group.dart';
import '../services/workout_service.dart';
import '../utils/messages.dart';
import '../widgets/friend_tile.dart';
import '../widgets/progress_ring.dart';
import 'edit_goal_screen.dart';
import 'message_dialog.dart';
import 'group_options_modal.dart';
import 'workout_modal.dart';
import 'add_friend_modal.dart';
import 'group_invite_modal.dart';
import 'package:intl/intl.dart';

class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  Group? currentGroup;

  // 🔹 Firestore Streams
  Stream<List<Friend>> getFriendsStream(String userId) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return userRef.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data['friends'] == null) return [];

      final friendIds = List<String>.from(data['friends']);
      if (friendIds.isEmpty) return [];

      final friendsSnap = await FirebaseFirestore.instance
          .collection('users') // 👈 pull friends from users collection
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();

      return friendsSnap.docs.map((doc) {
        final f = doc.data();
        return Friend(
          name: f['name'] ?? '',
          username: f['username'] ?? '',
          score: "${f['score'] ?? 0} 🏅",
          completion: 0.0, // 👈 you can compute progress later if needed
        );
      }).toList();
    });
  }

  Stream<List<Group>> getGroupsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final g = doc.data();
            return Group(
              id: doc.id,
              name: g['name'] ?? '',
              memberIds: List<String>.from(g['memberIds'] ?? []),
              ownerId: g['ownerId'], // ✅ include this safely
            );
          }).toList();
        });
  }

  // 🔹 UI BUILD
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9BBF9E)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No user data found"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Buddy';
        final goal = data['goalMinutes'] ?? 45;
        final score = data['score'] ?? 0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card (with Pump button)
                _profileCard(context, name, goal, score),

                const SizedBox(height: 20),
                _sectionHeader(
                  context,
                  "Groups",
                  onAdd: () async {
                    await showCreateGroupModal(context, []);
                    setState(() {});
                  },
                ),
                StreamBuilder<List<Group>>(
                  stream: getGroupsStream(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = snapshot.data!;
                    if (groups.isEmpty) {
                      return _placeholderCard(context, "No groups yet");
                    }
                    return Column(
                      children: groups
                          .map((g) => _groupCard(context, g))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _sectionHeader(
                  context,
                  "Friends",
                  onAdd: () async {
                    await showAddFriendModal(context);
                    setState(() {});
                  },
                  onAction: () {},
                  actionLabel: "Remind All",
                ),
                Expanded(
                  child: StreamBuilder<List<Friend>>(
                    stream: getFriendsStream(user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final friends = snapshot.data!;
                      if (friends.isEmpty) {
                        return _placeholderCard(context, "No friends yet");
                      }
                      return ListView(
                        children: friends
                            .map(
                              (f) => FriendTile(
                                friend: f,
                                onSend: () async {
                                  final chosen = await showMessageDialog(
                                    context,
                                    (messages.toList()..shuffle())
                                        .first, // ✅ fixed
                                  );
                                  if (chosen != null && chosen.isNotEmpty) {
                                    await FirebaseFirestore.instance
                                        .collection('messages')
                                        .add({
                                          'from': FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                          'to': f.username,
                                          'text': chosen,
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                        });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Sent to ${f.name}: $chosen",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Profile card
  Widget _profileCard(BuildContext context, String name, int goal, int score) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: WorkoutService.getToday(),
      builder: (context, snapshot) {
        final todayData = snapshot.data ?? {};
        final todayMinutes = todayData['totalMinutes'] ?? 0;
        final progress = goal > 0 ? (todayMinutes / goal).clamp(0.0, 1.0) : 0.0;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Progress ring
                ProgressRing(progress: progress, size: 70),
                const SizedBox(width: 16),

                // Main info + Pump button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await showWorkoutModal(context);
                              setState(() {});
                            },
                            icon: const Icon(Icons.fitness_center, size: 16),
                            label: const Text("Pump"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Today: $todayMinutes min',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Goal: $goal min',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Score
                Column(
                  children: [
                    Text('Score', style: theme.textTheme.bodySmall),
                    Text(
                      '$score 😁',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Section header (Groups/Friends)
  Widget _sectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onAdd,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            if (onAdd != null)
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 🔹 Group Card (with stats, delete/leave, and modal)
  Widget _groupCard(BuildContext context, Group group) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    final isOwner =
        group.ownerId == user.uid; // requires ownerId field in your group docs

    // --- Helpers ----------------------------------------------------------

    Future<Map<String, dynamic>> _getGroupStats() async {
      final members = group.memberIds;
      if (members.isEmpty) {
        return {'avgScore': 0.0, 'goalMetCount': 0, 'totalMembers': 0};
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
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final score = (data['score'] ?? 0) as int;
        totalScore += score;

        final workoutDoc = await db
            .collection('workouts')
            .doc('${uid}_$today')
            .get();
        if (workoutDoc.exists) {
          final w = workoutDoc.data()!;
          final mins = w['totalMinutes'] ?? 0;
          if (goal > 0 && mins >= goal) {
            goalMetCount++;
          }
        }
      }

      final avgScore = members.isNotEmpty ? (totalScore / members.length) : 0.0;
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
          content: Text('Delete "${group.name}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
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
            .doc(group.id)
            .collection('invitations')
            .get();
        for (final doc in invites.docs) {
          await doc.reference.delete();
        }
        await db.collection('groups').doc(group.id).delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group "${group.name}" deleted ✅')),
          );
        }
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
      }
    }

    Future<void> _leaveGroup() async {
      try {
        await db.collection('groups').doc(group.id).update({
          'memberIds': FieldValue.arrayRemove([user.uid]),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('You left ${group.name} 🚪')));
        }
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error leaving group: $e')));
      }
    }

    Future<void> _showGroupDetails() async {
      final theme = Theme.of(context);
      final stats = await _getGroupStats();
      final db = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser!;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('${group.name} — Today’s Performance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Average Score: ${stats['avgScore'].toStringAsFixed(1)}'),
                Text(
                  'Goals Met: ${stats['goalMetCount']}/${stats['totalMembers']}',
                ),
                const SizedBox(height: 16),
                const Divider(),

                // 🔹 Members list
                FutureBuilder(
                  future: db
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: group.memberIds)
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final members = snap.data!.docs;
                    return Column(
                      children: members.map((m) {
                        final data = m.data() as Map<String, dynamic>;
                        final username = data['username'] ?? 'Unknown';
                        final name = data['name'] ?? username;
                        final score = data['score'] ?? 0;

                        // Skip current user from message list
                        if (m.id == currentUser.uid) return const SizedBox();

                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: Text('Score: $score'),
                          trailing: IconButton(
                            icon: const Icon(Icons.message_outlined),
                            tooltip: 'Message $username',
                            onPressed: () async {
                              final chosen = await showMessageDialog(
                                context,
                                (messages.toList()..shuffle()).first,
                              );
                              if (chosen != null && chosen.isNotEmpty) {
                                await db.collection('messages').add({
                                  'from': currentUser.uid,
                                  'to': username,
                                  'text': chosen,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Sent to $name: $chosen"),
                                    ),
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

    // --- Card UI ----------------------------------------------------------

    return GestureDetector(
      onTap: _showGroupDetails,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isOwner ? Icons.delete_outline : Icons.exit_to_app,
                      color: isOwner ? Colors.redAccent : Colors.orangeAccent,
                    ),
                    tooltip: isOwner ? 'Delete Group' : 'Leave Group',
                    onPressed: isOwner ? _deleteGroup : _leaveGroup,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Member names (usernames, ellipsized)
              FutureBuilder<QuerySnapshot>(
                future: db
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: group.memberIds)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }

                  final users = snapshot.data!.docs;
                  final usernames = users.map((u) {
                    final data = u.data() as Map<String, dynamic>;
                    return data['username'] ?? data['name'] ?? 'User';
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      usernames.join(', '),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                },
              ),

              // Stats row
              FutureBuilder<Map<String, dynamic>>(
                future: _getGroupStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }

                  final stats = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avg Score: ${stats['avgScore'].toStringAsFixed(1)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Row(
                        children: [
                          Text(
                            'Today: ${stats['goalMetCount']}/${stats['totalMembers']}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1),
                            tooltip: "Invite Friends",
                            onPressed: () async {
                              final friends = await getFriendsStream(
                                user.uid,
                              ).first;
                              await showGroupInviteModal(
                                context,
                                group.id,
                                group.name,
                                group.memberIds,
                                friends,
                              );
                            },
                          ),
                        ],
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

  // 🔹 Placeholder Card
  Widget _placeholderCard(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text, style: theme.textTheme.bodySmall)),
      ),
    );
  }

  // 🔹 Floating Action Menu
  Widget _fabMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.fitness_center),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'workout', child: Text('Add Workout')),
        const PopupMenuItem(value: 'goal', child: Text('Edit Goal')),
      ],
      onSelected: (value) async {
        if (value == 'workout') {
          await showWorkoutModal(context);
          setState(() {});
        } else if (value == 'goal') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditGoalScreen()),
          );
        }
        setState(() {});
      },
    );
  }
}
